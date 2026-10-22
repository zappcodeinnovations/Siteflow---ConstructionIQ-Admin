import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../network/api_endpoints.dart';

/// Numeric app version. "1.10.0" > "1.9.0"; build numbers ("+5") and
/// pre-release tags ("-beta") are ignored, so 1.2.2+5 == 1.2.2+6.
class AppVersion implements Comparable<AppVersion> {
  AppVersion._(this._parts);

  final List<int> _parts;

  static final RegExp _pattern = RegExp(r'^\d{1,6}(\.\d{1,6}){0,3}$');

  static AppVersion? tryParse(String? raw) {
    final cleaned = (raw ?? '').trim().split(RegExp(r'[+\-\s]')).first;
    if (!_pattern.hasMatch(cleaned)) return null;
    final parts = cleaned.split('.').map(int.parse).toList();
    while (parts.length < 4) {
      parts.add(0);
    }
    return AppVersion._(parts);
  }

  @override
  int compareTo(AppVersion other) {
    for (var i = 0; i < 4; i++) {
      final diff = _parts[i] - other._parts[i];
      if (diff != 0) return diff.sign;
    }
    return 0;
  }

  bool operator <(AppVersion other) => compareTo(other) < 0;
}

/// Response of GET /api/app/version/ (edited in Django admin).
class AppUpdateConfig {
  const AppUpdateConfig({
    required this.latestVersion,
    required this.minimumSupportedVersion,
    required this.androidStoreUrl,
    required this.iosStoreUrl,
    required this.updateMessage,
    required this.forceUpdate,
  });

  final String latestVersion;
  final String minimumSupportedVersion;
  final String androidStoreUrl;
  final String iosStoreUrl;
  final String updateMessage;
  final bool forceUpdate;

  static const String defaultMessage =
      'A new version of the app is available. Please update to the latest '
      'version for the best experience and latest improvements.';

  factory AppUpdateConfig.fromJson(Map<String, dynamic> json) {
    String text(String key) => (json[key] ?? '').toString().trim();
    final message = text('update_message');
    return AppUpdateConfig(
      latestVersion: text('latest_version'),
      minimumSupportedVersion: text('minimum_supported_version'),
      androidStoreUrl: text('android_store_url'),
      iosStoreUrl: text('ios_store_url'),
      updateMessage: message.isEmpty ? defaultMessage : message,
      forceUpdate: json['force_update'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'latest_version': latestVersion,
    'minimum_supported_version': minimumSupportedVersion,
    'android_store_url': androidStoreUrl,
    'ios_store_url': iosStoreUrl,
    'update_message': updateMessage,
    'force_update': forceUpdate,
  };
}

enum AppUpdateKind { none, optional, mandatory }

AppUpdateKind evaluateUpdatePolicy({
  required String installedVersion,
  required AppUpdateConfig config,
}) {
  final installed = AppVersion.tryParse(installedVersion);
  if (installed == null) return AppUpdateKind.none;

  final minimum = AppVersion.tryParse(config.minimumSupportedVersion);
  if (minimum != null && installed < minimum) return AppUpdateKind.mandatory;

  final latest = AppVersion.tryParse(config.latestVersion);
  if (latest == null || !(installed < latest)) return AppUpdateKind.none;

  return config.forceUpdate ? AppUpdateKind.mandatory : AppUpdateKind.optional;
}

const List<String> _androidStoreHosts = ['play.google.com'];
const List<String> _iosStoreHosts = ['apps.apple.com', 'itunes.apple.com'];

/// Only https listings on the official store hosts are ever opened, whatever
/// the server sends.
Uri? validatedStoreUri(String raw, {required bool isIOS}) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || uri.scheme != 'https') return null;
  final hosts = isIOS ? _iosStoreHosts : _androidStoreHosts;
  return hosts.contains(uri.host.toLowerCase()) ? uri : null;
}

/// Store-app deep link for a validated listing, or null to use https only.
Uri? nativeStoreUri(Uri webUri, {required bool isIOS}) {
  if (isIOS) return webUri.replace(scheme: 'itms-apps');
  final packageId = webUri.queryParameters['id'] ?? '';
  if (!RegExp(r'^[A-Za-z][\w]*(\.[A-Za-z][\w]*)+$').hasMatch(packageId)) {
    return null;
  }
  return Uri(scheme: 'market', host: 'details', queryParameters: {'id': packageId});
}

class AppUpdatePrompt {
  const AppUpdatePrompt({required this.mandatory, required this.config});

  final bool mandatory;
  final AppUpdateConfig config;
}

/// Checks the update policy on launch and on resume, and publishes the popup
/// state through [prompt] (rendered by AppUpdateOverlay in main.dart).
/// Mirrors the operative app's service; the backend config is per app.
class AppUpdateService {
  AppUpdateService._();

  static const String _endpoint = '/app/version/?app=admin';
  static const String _cacheKey = 'app_update_config_v1';
  static const Duration _requestTimeout = Duration(seconds: 8);
  static const Duration _recheckInterval = Duration(minutes: 30);

  static final ValueNotifier<AppUpdatePrompt?> prompt =
      ValueNotifier<AppUpdatePrompt?>(null);

  @visibleForTesting
  static Future<AppUpdateConfig?> Function() fetchConfig = _fetchConfig;
  @visibleForTesting
  static Future<String> Function() loadInstalledVersion = _loadInstalledVersion;
  @visibleForTesting
  static bool Function() isIOS = () => Platform.isIOS;
  @visibleForTesting
  static Future<bool> Function(Uri uri) launchStoreUri = _launchStoreUri;

  static bool _started = false;
  static Future<void>? _inFlight;
  static DateTime? _lastServerCheck;
  static bool _openedStore = false;

  /// "Later" (or a store visit) for this latest_version, this session only.
  static String? _snoozedVersion;

  /// Call once, before runApp, so Back is seen before the Navigator's
  /// handler while a mandatory popup is up.
  static void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(_AppUpdateLifecycleObserver());
    unawaited(checkForUpdate(force: true));
  }

  /// Concurrent callers share one request; non-forced checks are throttled.
  static Future<void> checkForUpdate({bool force = false}) {
    final running = _inFlight;
    if (running != null) return running;

    final last = _lastServerCheck;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _recheckInterval) {
      return Future<void>.value();
    }

    final future = _check().whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  static Future<void> _check() async {
    try {
      final installedVersion = await loadInstalledVersion();
      final fresh = await fetchConfig();
      final config = fresh ?? await _loadCachedConfig();
      if (config == null) return;

      if (fresh != null) {
        _lastServerCheck = DateTime.now();
        await _saveCachedConfig(fresh);
      }

      var kind = evaluateUpdatePolicy(
        installedVersion: installedVersion,
        config: config,
      );
      if (fresh == null && kind != AppUpdateKind.mandatory) {
        // Offline: only a previously-known mandatory policy may block the
        // app; otherwise leave whatever is on screen as it is.
        return;
      }
      if (kind != AppUpdateKind.none && _storeUriFor(config) == null) {
        debugPrint('App update: no valid store URL configured, popup skipped');
        kind = AppUpdateKind.none;
      }
      _apply(kind, config);
    } catch (e) {
      debugPrint('App update check skipped: ${e.runtimeType}');
    }
  }

  static void _apply(AppUpdateKind kind, AppUpdateConfig config) {
    switch (kind) {
      case AppUpdateKind.none:
        prompt.value = null;
      case AppUpdateKind.mandatory:
        prompt.value = AppUpdatePrompt(mandatory: true, config: config);
      case AppUpdateKind.optional:
        if (_snoozedVersion == config.latestVersion) return;
        prompt.value = AppUpdatePrompt(mandatory: false, config: config);
    }
  }

  static void dismissOptional() {
    final current = prompt.value;
    if (current == null || current.mandatory) return;
    _snoozedVersion = current.config.latestVersion;
    prompt.value = null;
  }

  /// Returns false when no store could be opened.
  static Future<bool> openStore() async {
    final current = prompt.value;
    if (current == null) return false;

    final ios = isIOS();
    final webUri = _storeUriFor(current.config);
    if (webUri == null) return false;
    final nativeUri = nativeStoreUri(webUri, isIOS: ios);

    var opened = false;
    for (final uri in [?nativeUri, webUri]) {
      if (await launchStoreUri(uri)) {
        opened = true;
        break;
      }
    }

    if (opened) {
      _openedStore = true;
      // An optional popup is not re-shown after a store visit this session;
      // a mandatory one stays until the installed version is high enough.
      if (!current.mandatory) dismissOptional();
    }
    return opened;
  }

  static Uri? _storeUriFor(AppUpdateConfig config) {
    final ios = isIOS();
    return validatedStoreUri(
      ios ? config.iosStoreUrl : config.androidStoreUrl,
      isIOS: ios,
    );
  }

  static void _onResumed() {
    final mustRecheck = _openedStore || (prompt.value?.mandatory ?? false);
    _openedStore = false;
    unawaited(checkForUpdate(force: mustRecheck));
  }

  /// Swallows Back while a popup is visible; Back dismisses an optional one.
  static bool _handleBack() {
    final current = prompt.value;
    if (current == null) return false;
    if (!current.mandatory) dismissOptional();
    return true;
  }

  // Plain http instead of ApiClient: this public, background check must not
  // trigger auth/refresh/logout handling.
  static Future<AppUpdateConfig?> _fetchConfig() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiEndpoints.baseUrl + _endpoint),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(_requestTimeout);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return AppUpdateConfig.fromJson(decoded);
    } catch (e) {
      debugPrint('App update config unavailable: ${e.runtimeType}');
      return null;
    }
  }

  static Future<String> _loadInstalledVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static Future<bool> _launchStoreUri(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // e.g. market:// with no Play Store installed - caller falls back.
      return false;
    }
  }

  static Future<AppUpdateConfig?> _loadCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? AppUpdateConfig.fromJson(decoded)
          : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveCachedConfig(AppUpdateConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(config.toJson()));
    } catch (_) {}
  }

  @visibleForTesting
  static void resetForTesting() {
    prompt.value = null;
    fetchConfig = _fetchConfig;
    loadInstalledVersion = _loadInstalledVersion;
    isIOS = () => Platform.isIOS;
    launchStoreUri = _launchStoreUri;
    _inFlight = null;
    _lastServerCheck = null;
    _openedStore = false;
    _snoozedVersion = null;
  }

  @visibleForTesting
  static void simulateResume() => _onResumed();

  @visibleForTesting
  static bool simulateBack() => _handleBack();
}

class _AppUpdateLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) AppUpdateService._onResumed();
  }

  @override
  Future<bool> didPopRoute() async => AppUpdateService._handleBack();
}
