import 'dart:async';

import 'package:euroside_admin/core/services/app_update_service.dart';
import 'package:euroside_admin/core/widgets/app_update_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _androidUrl =
    'https://play.google.com/store/apps/details?id=com.siteflow.constructioniq';
const _iosUrl =
    'https://apps.apple.com/in/app/siteflow-constructioniq/id6784659672';

AppUpdateConfig _config({
  String latest = '1.3.0',
  String minimum = '1.0.0',
  bool force = false,
  String androidUrl = _androidUrl,
}) {
  return AppUpdateConfig.fromJson({
    'latest_version': latest,
    'minimum_supported_version': minimum,
    'android_store_url': androidUrl,
    'ios_store_url': _iosUrl,
    'update_message': 'Please update.',
    'force_update': force,
  });
}

void main() {
  group('AppVersion', () {
    test('compares numerically, not alphabetically', () {
      expect(
        AppVersion.tryParse('1.10.0')!.compareTo(AppVersion.tryParse('1.9.0')!),
        1,
      );
      expect(AppVersion.tryParse('1.2')!.compareTo(AppVersion.tryParse('1.2.0')!), 0);
    });

    test('ignores build numbers and rejects malformed values', () {
      expect(
        AppVersion.tryParse('1.2.2+5')!.compareTo(AppVersion.tryParse('1.2.2+9')!),
        0,
      );
      expect(AppVersion.tryParse(''), isNull);
      expect(AppVersion.tryParse('v1.2'), isNull);
      expect(AppVersion.tryParse('1..2'), isNull);
      expect(AppVersion.tryParse('99999999999999999999'), isNull);
    });
  });

  group('evaluateUpdatePolicy', () {
    AppUpdateKind kind(String installed, AppUpdateConfig config) =>
        evaluateUpdatePolicy(installedVersion: installed, config: config);

    test('up to date or newer shows nothing', () {
      expect(kind('1.3.0', _config()), AppUpdateKind.none);
      expect(kind('1.4.0', _config()), AppUpdateKind.none);
    });

    test('older but supported is optional', () {
      expect(kind('1.2.2', _config(minimum: '1.2.0')), AppUpdateKind.optional);
      expect(kind('1.9.0', _config(latest: '1.10.0', minimum: '1.9.0')),
          AppUpdateKind.optional);
    });

    test('below minimum, or force_update, is mandatory', () {
      expect(kind('1.1.9', _config(minimum: '1.2.0')), AppUpdateKind.mandatory);
      expect(kind('1.2.2', _config(force: true)), AppUpdateKind.mandatory);
    });

    test('blank or malformed config never shows a popup', () {
      expect(kind('1.0.0', _config(latest: '', minimum: '')), AppUpdateKind.none);
      expect(kind('1.0.0', _config(latest: 'abc', minimum: '')), AppUpdateKind.none);
      expect(kind('garbage', _config()), AppUpdateKind.none);
    });
  });

  group('store URLs', () {
    test('only https official store hosts are accepted', () {
      expect(validatedStoreUri(_androidUrl, isIOS: false), isNotNull);
      expect(validatedStoreUri(_iosUrl, isIOS: true), isNotNull);
      expect(validatedStoreUri(_iosUrl, isIOS: false), isNull);
      expect(validatedStoreUri('http://play.google.com/x', isIOS: false), isNull);
      expect(validatedStoreUri('https://evil.example.com/?id=a.b', isIOS: false), isNull);
      expect(validatedStoreUri('https://play.google.com.evil.io/', isIOS: false), isNull);
    });

    test('native store links are derived from the configured listing', () {
      expect(
        nativeStoreUri(Uri.parse(_androidUrl), isIOS: false).toString(),
        'market://details?id=com.siteflow.constructioniq',
      );
      expect(
        nativeStoreUri(Uri.parse(_iosUrl), isIOS: true).toString(),
        'itms-apps://apps.apple.com/in/app/siteflow-constructioniq/id6784659672',
      );
    });
  });

  group('AppUpdateService', () {
    late List<Uri> launched;
    late int fetchCount;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AppUpdateService.resetForTesting();
      launched = [];
      fetchCount = 0;
      AppUpdateService.loadInstalledVersion = () async => '1.2.2';
      AppUpdateService.isIOS = () => false;
      AppUpdateService.launchStoreUri = (uri) async {
        launched.add(uri);
        return true;
      };
    });

    tearDown(AppUpdateService.resetForTesting);

    void serve(AppUpdateConfig? config) {
      AppUpdateService.fetchConfig = () async {
        fetchCount++;
        return config;
      };
    }

    test('concurrent checks share one request', () async {
      final gate = Completer<AppUpdateConfig?>();
      AppUpdateService.fetchConfig = () {
        fetchCount++;
        return gate.future;
      };
      final a = AppUpdateService.checkForUpdate(force: true);
      final b = AppUpdateService.checkForUpdate(force: true);
      gate.complete(_config());
      await Future.wait([a, b]);
      expect(fetchCount, 1);
      expect(AppUpdateService.prompt.value?.mandatory, false);
    });

    test('Later hides an optional popup for the rest of the session', () async {
      serve(_config());
      await AppUpdateService.checkForUpdate(force: true);
      AppUpdateService.dismissOptional();
      await AppUpdateService.checkForUpdate(force: true);
      expect(AppUpdateService.prompt.value, isNull);
    });

    test('offline without a cached policy does not block the app', () async {
      serve(null);
      await AppUpdateService.checkForUpdate(force: true);
      expect(AppUpdateService.prompt.value, isNull);
    });

    test('offline with a cached mandatory policy still blocks', () async {
      serve(_config(minimum: '1.3.0'));
      await AppUpdateService.checkForUpdate(force: true);
      AppUpdateService.prompt.value = null; // simulate a fresh session
      serve(null);
      await AppUpdateService.checkForUpdate(force: true);
      expect(AppUpdateService.prompt.value?.mandatory, true);
    });

    test('Update Now opens the Play Store app first, Later is not re-shown', () async {
      serve(_config());
      await AppUpdateService.checkForUpdate(force: true);
      expect(await AppUpdateService.openStore(), true);
      expect(launched.single.toString(),
          'market://details?id=com.siteflow.constructioniq');
      expect(AppUpdateService.prompt.value, isNull);
    });

    test('falls back to https when the store app cannot open', () async {
      AppUpdateService.isIOS = () => true;
      AppUpdateService.launchStoreUri = (uri) async {
        launched.add(uri);
        return uri.scheme == 'https';
      };
      serve(_config(minimum: '1.3.0'));
      await AppUpdateService.checkForUpdate(force: true);
      expect(await AppUpdateService.openStore(), true);
      expect(launched.map((u) => u.scheme), ['itms-apps', 'https']);
      expect(launched.last.toString(), _iosUrl);
      expect(AppUpdateService.prompt.value?.mandatory, true);
    });

    test('resume after updating clears a mandatory popup', () async {
      serve(_config(minimum: '1.3.0'));
      await AppUpdateService.checkForUpdate(force: true);
      await AppUpdateService.openStore();
      AppUpdateService.loadInstalledVersion = () async => '1.3.0';
      AppUpdateService.simulateResume();
      await AppUpdateService.checkForUpdate();
      expect(AppUpdateService.prompt.value, isNull);
      expect(fetchCount, 2);
    });

    test('Back is swallowed by a mandatory popup and closes an optional one', () async {
      serve(_config(minimum: '1.3.0'));
      await AppUpdateService.checkForUpdate(force: true);
      expect(AppUpdateService.simulateBack(), true);
      expect(AppUpdateService.prompt.value?.mandatory, true);

      AppUpdateService.resetForTesting();
      AppUpdateService.loadInstalledVersion = () async => '1.2.2';
      AppUpdateService.isIOS = () => false;
      serve(_config());
      await AppUpdateService.checkForUpdate(force: true);
      expect(AppUpdateService.simulateBack(), true);
      expect(AppUpdateService.prompt.value, isNull);
      expect(AppUpdateService.simulateBack(), false);
    });

    test('an untrusted store URL never produces a popup', () async {
      serve(_config(minimum: '1.3.0', androidUrl: 'https://evil.example.com/?id=a.b'));
      await AppUpdateService.checkForUpdate(force: true);
      expect(AppUpdateService.prompt.value, isNull);
    });
  });

  group('AppUpdateDialog', () {
    Future<void> pump(
      WidgetTester tester, {
      required bool mandatory,
      Future<bool> Function()? onUpdate,
      VoidCallback? onLater,
    }) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              const Scaffold(body: Text('Behind')),
              Positioned.fill(
                child: AppUpdateDialog(
                  mandatory: mandatory,
                  message: 'Please update.',
                  onUpdate: onUpdate ?? () async => true,
                  onLater: onLater ?? () {},
                ),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('optional popup offers Later and dismisses on outside tap', (
      tester,
    ) async {
      var later = 0;
      await pump(tester, mandatory: false, onLater: () => later++);
      expect(find.text('Update Available!'), findsOneWidget);
      await tester.tap(find.text('Later'));
      await tester.tapAt(const Offset(5, 5));
      expect(later, 2);
    });

    testWidgets('mandatory popup has no Later and ignores outside taps', (
      tester,
    ) async {
      var later = 0;
      await pump(tester, mandatory: true, onLater: () => later++);
      expect(find.text('Later'), findsNothing);
      expect(find.textContaining('required'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      expect(later, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a message when the store cannot be opened', (
      tester,
    ) async {
      await pump(tester, mandatory: true, onUpdate: () async => false);
      await tester.tap(find.text('Update Now'));
      await tester.pump();
      expect(find.textContaining("Couldn't open the store"), findsOneWidget);
    });
  });
}
