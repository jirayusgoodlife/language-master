import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateStatus {
  idle,
  checking,
  updateAvailable,
  upToDate,
  downloading,
  readyToInstall,
  error,
}

class AppUpdateInfo {
  final String version;
  final String tagName;
  final String title;
  final String releaseNotes;
  final DateTime? publishedAt;
  final String htmlUrl;
  final String? downloadUrl;
  final int? assetSize;
  final bool isNewer;

  AppUpdateInfo({
    required this.version,
    required this.tagName,
    required this.title,
    required this.releaseNotes,
    this.publishedAt,
    required this.htmlUrl,
    this.downloadUrl,
    this.assetSize,
    required this.isNewer,
  });
}

class UpdateService extends ChangeNotifier {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String repoOwner = 'jirayusgoodlife';
  static const String repoName = 'language-master';
  static const String _lastCheckKey = 'last_github_update_check_time';

  UpdateStatus _status = UpdateStatus.idle;
  AppUpdateInfo? _updateInfo;
  String? _downloadedFilePath;
  double _downloadProgress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  http.Client? _activeClient;
  bool _isBackgroundDownloading = false;

  UpdateStatus get status => _status;
  AppUpdateInfo? get updateInfo => _updateInfo;
  String? get downloadedFilePath => _downloadedFilePath;
  double get downloadProgress => _downloadProgress;
  int get receivedBytes => _receivedBytes;
  int get totalBytes => _totalBytes;
  String? get errorMessage => _errorMessage;
  bool get isBackgroundDownloading => _isBackgroundDownloading;

  /// Clean any existing leftover update APKs in temp dir on app launch
  Future<void> cleanLeftoverFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final entities = tempDir.listSync();
      for (final entity in entities) {
        if (entity is File &&
            (entity.path.endsWith('.apk') ||
                entity.path.contains('language_0_update'))) {
          await entity.delete();
          debugPrint('Cleaned leftover update file: ${entity.path}');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning leftover files: $e');
    }
  }

  /// Get current app version from package_info_plus or fallback
  Future<String> getCurrentAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version.isNotEmpty ? info.version : '1.0.0';
    } catch (_) {
      return '1.0.0';
    }
  }

  /// Compare two semantic version strings (e.g. 1.0.1 > 1.0.0)
  bool _isVersionNewer(String latest, String current) {
    try {
      String cleanLatest = latest.replaceAll(RegExp(r'^[vV]'), '').split('+').first.trim();
      String cleanCurrent = current.replaceAll(RegExp(r'^[vV]'), '').split('+').first.trim();

      List<int> latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      while (latestParts.length < 3) {
        latestParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check GitHub releases for updates
  Future<AppUpdateInfo?> checkForUpdate({bool force = false}) async {
    if (_status == UpdateStatus.downloading) {
      return _updateInfo;
    }

    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckMillis = prefs.getInt(_lastCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      // Debounce checks within 15 minutes unless forced
      if (now - lastCheckMillis < 15 * 60 * 1000 && _updateInfo != null) {
        return _updateInfo;
      }
    }

    _status = UpdateStatus.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$repoOwner/$repoName/releases/latest',
      );
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
      }).timeout(const Duration(seconds: 10));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final tagName = (data['tag_name'] as String?) ?? '';
        final cleanTag = tagName.replaceAll(RegExp(r'^[vV]'), '');
        final title = (data['name'] as String?) ?? 'Release $tagName';
        final body = (data['body'] as String?) ?? 'No release notes provided.';
        final htmlUrl = (data['html_url'] as String?) ?? 'https://github.com/$repoOwner/$repoName/releases';
        final publishedStr = data['published_at'] as String?;
        final publishedAt = publishedStr != null ? DateTime.tryParse(publishedStr) : null;

        String? apkDownloadUrl;
        int? assetSize;
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final assetName = (asset['name'] as String? ?? '').toLowerCase();
          if (assetName.endsWith('.apk')) {
            apkDownloadUrl = asset['browser_download_url'] as String?;
            assetSize = asset['size'] as int?;
            break;
          }
        }

        // If no APK asset explicitly matched, use the first asset or fallback
        if (apkDownloadUrl == null && assets.isNotEmpty) {
          apkDownloadUrl = assets.first['browser_download_url'] as String?;
          assetSize = assets.first['size'] as int?;
        }

        final currentVersion = await getCurrentAppVersion();
        final isNewer = _isVersionNewer(cleanTag, currentVersion);

        _updateInfo = AppUpdateInfo(
          version: cleanTag,
          tagName: tagName,
          title: title,
          releaseNotes: body,
          publishedAt: publishedAt,
          htmlUrl: htmlUrl,
          downloadUrl: apkDownloadUrl,
          assetSize: assetSize,
          isNewer: isNewer,
        );

        _status = isNewer ? UpdateStatus.updateAvailable : UpdateStatus.upToDate;
        notifyListeners();
        return _updateInfo;
      } else if (response.statusCode == 404) {
        // No release exists yet
        _status = UpdateStatus.upToDate;
        _updateInfo = null;
        notifyListeners();
        return null;
      } else {
        _status = UpdateStatus.error;
        _errorMessage = 'GitHub API Error: ${response.statusCode}';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = 'ไม่สามารถตรวจสอบการอัปเดตได้: $e';
      notifyListeners();
      return null;
    }
  }

  /// Download update in background
  Future<bool> startDownload({bool runInBackground = false}) async {
    final info = _updateInfo;
    if (info == null || info.downloadUrl == null) {
      if (info != null && info.htmlUrl.isNotEmpty) {
        await launchUrl(Uri.parse(info.htmlUrl), mode: LaunchMode.externalApplication);
      }
      return false;
    }

    _isBackgroundDownloading = runInBackground;
    _status = UpdateStatus.downloading;
    _downloadProgress = 0.0;
    _receivedBytes = 0;
    _totalBytes = info.assetSize ?? 0;
    _errorMessage = null;
    notifyListeners();

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'language_0_${info.tagName.replaceAll('.', '_')}.apk';
      final file = File('${tempDir.path}/$fileName');

      if (await file.exists()) {
        await file.delete();
      }

      _activeClient = http.Client();
      final request = http.Request('GET', Uri.parse(info.downloadUrl!));
      request.headers['Accept'] = 'application/octet-stream';
      final response = await _activeClient!.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? info.assetSize ?? 0;
      _totalBytes = contentLength;

      final sink = file.openWrite();
      await response.stream.listen(
        (chunk) {
          sink.add(chunk);
          _receivedBytes += chunk.length;
          if (_totalBytes > 0) {
            _downloadProgress = _receivedBytes / _totalBytes;
          }
          notifyListeners();
        },
        cancelOnError: true,
      ).asFuture();

      await sink.flush();
      await sink.close();

      _downloadedFilePath = file.path;
      _status = UpdateStatus.readyToInstall;
      _isBackgroundDownloading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (_status != UpdateStatus.idle) {
        _status = UpdateStatus.error;
        _errorMessage = 'ดาวน์โหลดล้มเหลว: $e';
        _isBackgroundDownloading = false;
        notifyListeners();
      }
      return false;
    } finally {
      _activeClient?.close();
      _activeClient = null;
    }
  }

  /// Cancel current download and clean partial file
  Future<void> cancelDownload() async {
    _activeClient?.close();
    _activeClient = null;
    _status = UpdateStatus.idle;
    _isBackgroundDownloading = false;
    _downloadProgress = 0.0;
    await cleanDownloadedFiles();
    notifyListeners();
  }

  /// Install downloaded APK or open release page
  Future<void> installUpdate() async {
    if (_downloadedFilePath != null && File(_downloadedFilePath!).existsSync()) {
      try {
        final result = await OpenFilex.open(
          _downloadedFilePath!,
          type: 'application/vnd.android.package-archive',
        );
        debugPrint('Install result: ${result.message}');
      } catch (e) {
        debugPrint('OpenFilex error: $e');
        if (_updateInfo != null) {
          await launchUrl(Uri.parse(_updateInfo!.htmlUrl), mode: LaunchMode.externalApplication);
        }
      }
    } else if (_updateInfo != null) {
      await launchUrl(Uri.parse(_updateInfo!.htmlUrl), mode: LaunchMode.externalApplication);
    }
  }

  /// Clean downloaded APK file to save device storage
  Future<void> cleanDownloadedFiles() async {
    try {
      if (_downloadedFilePath != null) {
        final file = File(_downloadedFilePath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Cleaned downloaded file: $_downloadedFilePath');
        }
        _downloadedFilePath = null;
      }
      await cleanLeftoverFiles();
      if (_status == UpdateStatus.readyToInstall) {
        _status = UpdateStatus.updateAvailable;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error cleaning downloaded file: $e');
    }
  }
}
