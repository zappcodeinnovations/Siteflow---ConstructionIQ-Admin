import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

enum DownloadState { downloading, completed, failed }

class DownloadEntry {
  final String id;
  final String fileName;
  final String location;
  final String displayLocation;
  final String mimeType;
  final int byteCount;
  final DateTime createdAt;
  final DownloadState state;
  final double? progress;
  final String? error;

  const DownloadEntry({
    required this.id,
    required this.fileName,
    required this.location,
    required this.displayLocation,
    required this.mimeType,
    required this.byteCount,
    required this.createdAt,
    required this.state,
    this.progress,
    this.error,
  });

  DownloadEntry copyWith({
    String? location,
    String? displayLocation,
    int? byteCount,
    DownloadState? state,
    double? progress,
    String? error,
  }) => DownloadEntry(
    id: id,
    fileName: fileName,
    location: location ?? this.location,
    displayLocation: displayLocation ?? this.displayLocation,
    mimeType: mimeType,
    byteCount: byteCount ?? this.byteCount,
    createdAt: createdAt,
    state: state ?? this.state,
    progress: progress ?? this.progress,
    error: error,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'file_name': fileName,
    'location': location,
    'display_location': displayLocation,
    'mime_type': mimeType,
    'byte_count': byteCount,
    'created_at': createdAt.toIso8601String(),
    'state': state.name,
    'error': error,
  };

  factory DownloadEntry.fromJson(Map<String, dynamic> json) => DownloadEntry(
    id: json['id']?.toString() ?? '',
    fileName: json['file_name']?.toString() ?? 'download',
    location: json['location']?.toString() ?? '',
    displayLocation: json['display_location']?.toString() ?? '',
    mimeType: json['mime_type']?.toString() ?? 'application/octet-stream',
    byteCount: json['byte_count'] is int ? json['byte_count'] as int : 0,
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now(),
    state: DownloadState.values.firstWhere(
      (value) => value.name == json['state'],
      orElse: () => DownloadState.completed,
    ),
    error: json['error']?.toString(),
  );
}

class DownloadManager extends ChangeNotifier {
  DownloadManager._();
  static final DownloadManager instance = DownloadManager._();

  static const _historyKey = 'siteflow_download_history_v1';
  static const _channel = MethodChannel(
    'com.euroside.siteflow_admin/downloads',
  );

  final List<DownloadEntry> _entries = [];
  List<DownloadEntry> get entries => List.unmodifiable(_entries);
  DownloadEntry? get activeEntry => _entries
      .where((entry) => entry.state == DownloadState.downloading)
      .firstOrNull;
  DownloadEntry? _latestVisible;
  DownloadEntry? get latestVisible => activeEntry ?? _latestVisible;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_historyKey) ?? const [];
    _entries
      ..clear()
      ..addAll(
        saved.map((item) {
          try {
            return DownloadEntry.fromJson(
              jsonDecode(item) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        }).whereType<DownloadEntry>(),
      );
    notifyListeners();
  }

  Future<DownloadEntry?> downloadUrl({
    required String url,
    required String fileName,
    required String mimeType,
  }) async {
    final pending = _begin(fileName, mimeType);
    try {
      final response = await ApiClient.get(url);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          response.bodyBytes.isEmpty) {
        throw HttpException(
          'Download failed with status ${response.statusCode}.',
        );
      }
      if (mimeType == 'application/pdf' &&
          (response.bodyBytes.length < 4 ||
              String.fromCharCodes(response.bodyBytes.take(4)) != '%PDF')) {
        throw const HttpException(
          'The server did not return a valid PDF file.',
        );
      }
      _update(pending.id, progress: .8);
      return await _saveBytes(pending, response.bodyBytes);
    } catch (error) {
      _fail(pending.id, error.toString());
      return null;
    }
  }

  Future<DownloadEntry?> saveBytes({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final pending = _begin(fileName, mimeType);
    try {
      _update(pending.id, progress: .75);
      return await _saveBytes(pending, Uint8List.fromList(bytes));
    } catch (error) {
      _fail(pending.id, error.toString());
      return null;
    }
  }

  DownloadEntry _begin(String requestedName, String mimeType) {
    final safeName = requestedName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final entry = DownloadEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      fileName: safeName,
      location: '',
      displayLocation: 'Downloads/Euroside/$safeName',
      mimeType: mimeType,
      byteCount: 0,
      createdAt: DateTime.now(),
      state: DownloadState.downloading,
      progress: null,
    );
    _entries.insert(0, entry);
    _latestVisible = entry;
    notifyListeners();
    return entry;
  }

  Future<DownloadEntry> _saveBytes(
    DownloadEntry pending,
    Uint8List bytes,
  ) async {
    String location;
    String displayLocation;
    if (Platform.isAndroid) {
      location =
          await _channel.invokeMethod<String>('saveFile', {
            'bytes': bytes,
            'fileName': pending.fileName,
            'mimeType': pending.mimeType,
          }) ??
          '';
      displayLocation = 'Downloads/Euroside/${pending.fileName}';
    } else {
      final root = await getApplicationDocumentsDirectory();
      final folder = Directory(
        '${root.path}${Platform.pathSeparator}Euroside Downloads',
      );
      await folder.create(recursive: true);
      final file = File(
        '${folder.path}${Platform.pathSeparator}${pending.fileName}',
      );
      await file.writeAsBytes(bytes, flush: true);
      location = file.path;
      displayLocation = file.path;
    }
    if (location.isEmpty) {
      throw const FileSystemException('Unable to save downloaded file.');
    }
    final completed = pending.copyWith(
      location: location,
      displayLocation: displayLocation,
      byteCount: bytes.length,
      state: DownloadState.completed,
      progress: 1,
    );
    _replace(completed);
    _latestVisible = completed;
    await _persist();
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (_latestVisible?.id == completed.id) {
        _latestVisible = null;
        notifyListeners();
      }
    });
    return completed;
  }

  Future<bool> open(DownloadEntry entry) async {
    if (entry.location.isEmpty) return false;
    if (Platform.isAndroid) {
      return await _channel.invokeMethod<bool>('openFile', {
            'location': entry.location,
            'mimeType': entry.mimeType,
          }) ??
          false;
    }
    return false;
  }

  Future<bool> delete(DownloadEntry entry) async {
    bool removed =
        entry.location.isEmpty || entry.state == DownloadState.failed;
    try {
      if (!removed && Platform.isAndroid) {
        removed =
            await _channel.invokeMethod<bool>('deleteFile', {
              'location': entry.location,
            }) ??
            false;
      } else if (!removed) {
        final file = File(entry.location);
        if (await file.exists()) await file.delete();
        removed = true;
      }
    } catch (_) {
      removed = false;
    }
    if (removed) {
      _entries.removeWhere((item) => item.id == entry.id);
      if (_latestVisible?.id == entry.id) {
        _latestVisible = null;
      }
      await _persist();
      notifyListeners();
    }
    return removed;
  }

  Future<void> clearMissingOrFailed() async {
    _entries.removeWhere((entry) => entry.state != DownloadState.completed);
    await _persist();
    notifyListeners();
  }

  void _update(String id, {double? progress}) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    _entries[index] = _entries[index].copyWith(progress: progress);
    _latestVisible = _entries[index];
    notifyListeners();
  }

  void _fail(String id, String error) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    _entries[index] = _entries[index].copyWith(
      state: DownloadState.failed,
      error: error,
      progress: 1,
    );
    _latestVisible = _entries[index];
    _persist();
    notifyListeners();
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (_latestVisible?.id == id) {
        _latestVisible = null;
        notifyListeners();
      }
    });
  }

  void _replace(DownloadEntry entry) {
    final index = _entries.indexWhere((item) => item.id == entry.id);
    if (index >= 0) _entries[index] = entry;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = _entries
        .where((entry) => entry.state != DownloadState.downloading)
        .take(100);
    await prefs.setStringList(
      _historyKey,
      completed.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
