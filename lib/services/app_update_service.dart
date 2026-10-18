import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

const _installerChannel = MethodChannel('chatapp/update_installer');
const _latestReleaseUrl =
    'https://api.github.com/repos/Raonsonapp/ChatAppMessenger-/releases/latest';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.tagName,
    required this.versionCode,
    required this.downloadUrl,
    required this.releaseUrl,
    this.releaseNotes = '',
  });

  final String tagName;
  final int versionCode;
  final String downloadUrl;
  final String releaseUrl;
  final String releaseNotes;

  static AppUpdateInfo fromReleaseJson(Map<String, dynamic> json) {
    final body = json['body']?.toString() ?? '';
    final match = RegExp(r'versionCode\s*:\s*(\d+)', caseSensitive: false)
        .firstMatch(body);
    if (match == null) {
      throw const FormatException('Release metadata has no versionCode.');
    }
    final versionCode = int.parse(match.group(1)!);
    final assets = json['assets'];
    if (assets is! List) {
      throw const FormatException('Release has no APK asset.');
    }

    Map<String, dynamic>? apk;
    for (final item in assets) {
      if (item is Map<String, dynamic> &&
          (item['name']?.toString().toLowerCase().endsWith('.apk') ?? false)) {
        apk = item;
        break;
      }
    }
    if (apk == null) throw const FormatException('Release has no APK asset.');

    final downloadUrl = apk['browser_download_url']?.toString() ?? '';
    final uri = Uri.tryParse(downloadUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        !(uri.host == 'github.com' ||
            uri.host.endsWith('.githubusercontent.com') ||
            uri.host == 'objects.githubusercontent.com')) {
      throw const FormatException('APK download URL is not trusted.');
    }

    final releaseUrl = json['html_url']?.toString() ?? '';
    return AppUpdateInfo(
      tagName: json['tag_name']?.toString() ?? '',
      versionCode: versionCode,
      downloadUrl: downloadUrl,
      releaseUrl: releaseUrl,
      releaseNotes: body,
    );
  }
}

class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();
  final http.Client _client = http.Client();
  File? _downloadedApk;
  AppUpdateInfo? _downloadedUpdate;

  Future<String> currentVersionLabel() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  Future<AppUpdateInfo?> checkForUpdate() async {
    final response = await _client
        .get(
          Uri.parse(_latestReleaseUrl),
          headers: const {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
            'User-Agent': 'ChatApp-Android-Updater',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 404) {
      throw const AppUpdateException(
        'Ҳанӯз версияи нашршуда нест. Аввал build-и main бояд ба GitHub Release барояд.',
      );
    }
    if (response.statusCode != 200) {
      throw AppUpdateException(
        'GitHub барои санҷиши навсозӣ HTTP ${response.statusCode} баргардонд.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AppUpdateException('Маълумоти версияи нав нодуруст аст.');
    }

    final update = AppUpdateInfo.fromReleaseJson(decoded);
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
    return update.versionCode > currentBuild ? update : null;
  }

  Future<void> downloadAndInstall(
    AppUpdateInfo update, {
    void Function(double progress)? onProgress,
  }) async {
    final directory = await getTemporaryDirectory();
    final apkFile = File('${directory.path}/chatapp-update.apk');
    final partialFile = File('${directory.path}/chatapp-update.apk.part');
    if (await partialFile.exists()) await partialFile.delete();

    final request = http.Request('GET', Uri.parse(update.downloadUrl));
    request.headers['User-Agent'] = 'ChatApp-Android-Updater';
    final response = await _client.send(request).timeout(
          const Duration(seconds: 45),
        );
    if (response.statusCode != 200) {
      throw AppUpdateException(
        'Зеркашии APK ноком шуд: HTTP ${response.statusCode}.',
      );
    }

    final totalBytes = response.contentLength ?? 0;
    var receivedBytes = 0;
    final sink = partialFile.openWrite();
    try {
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 45),
      )) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress?.call((receivedBytes / totalBytes).clamp(0.0, 1.0));
        }
      }
    } catch (_) {
      await sink.close();
      if (await partialFile.exists()) await partialFile.delete();
      rethrow;
    }
    await sink.close();

    final actualLength = await partialFile.length();
    if (actualLength < 1024 * 1024 ||
        (totalBytes > 0 && actualLength != totalBytes)) {
      await partialFile.delete();
      throw const AppUpdateException('APK нопурра зеркашӣ шуд. Боз кӯшиш кун.');
    }
    if (await apkFile.exists()) await apkFile.delete();
    final savedFile = await partialFile.rename(apkFile.path);
    _downloadedApk = savedFile;
    _downloadedUpdate = update;
    await _launchInstaller(savedFile);
  }

  Future<void> continueInstall() async {
    final file = _downloadedApk;
    if (file == null || !await file.exists()) {
      throw const AppUpdateException('Аввал APK-и навро зеркашӣ кун.');
    }
    await _launchInstaller(file);
  }

  Future<void> openInstallPermissionSettings() async {
    await _installerChannel.invokeMethod<void>('openInstallPermissionSettings');
  }

  Future<void> _launchInstaller(File file) async {
    final result = await _installerChannel.invokeMethod<String>(
      'installApk',
      {'path': file.path},
    );
    if (result == 'permission_required') {
      throw const InstallPermissionRequired();
    }
    if (result != 'installer_opened') {
      throw const AppUpdateException('Android installer кушода нашуд.');
    }
  }
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

class InstallPermissionRequired implements Exception {
  const InstallPermissionRequired();
}
