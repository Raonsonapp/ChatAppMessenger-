import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/otp_server_config.dart';

/// Боркунии файлҳо ба Cloudflare R2.
///
/// Калидҳои R2 дар барнома нигоҳ дошта намешаванд — онҳоро аз APK кашида
/// гирифтан мумкин аст. Ба ҷои он барнома аз сервери худамон ҳаволаи
/// кӯтоҳмуддати имзошуда мегирад ва файлро БЕВОСИТА ба R2 мефиристад:
/// ҳам бехатар, ҳам трафики сервер сарф намешавад.
class StorageService {
  /// Ҳиссаи боршудаи файли ҷорӣ (0…1). `null` — ҳоло чизе бор намешавад.
  ///
  /// Бе ин корбар ҳангоми фиристодани видеои калон танҳо як давраи
  /// беохирро мебинад ва намедонад, ки кор пеш меравад ё не.
  static final ValueNotifier<double?> progress = ValueNotifier<double?>(null);

  /// Файлро бор мекунад ва суроғаи ҷамъиятии онро бармегардонад.
  static Future<String> upload(File file, String name, String folder) async {
    if (!await file.exists()) {
      throw const StorageFailure(StorageFailureKind.missingFile);
    }

    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw const StorageFailure(StorageFailureKind.notSignedIn);
    }

    // Андоза пешакӣ ба сервер фиристода мешавад ва ба имзо дохил мегардад,
    // бинобар ин байни ин ҷо ва PUT он набояд тағйир ёбад.
    final length = await file.length();
    final contentType = _contentTypeFor(name);
    final ticket = await _requestTicket(
      idToken: idToken,
      name: name,
      folder: folder,
      contentType: contentType,
      size: length,
    );

    progress.value = 0;
    try {
      await _put(file, length, ticket.uploadUrl, contentType);
    } finally {
      progress.value = null;
    }
    return ticket.fileUrl;
  }

  static Future<_UploadTicket> _requestTicket({
    required String idToken,
    required String name,
    required String folder,
    required String contentType,
    required int size,
  }) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${OtpServerConfig.baseUrl}/api/upload-url'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'folder': folder,
              'name': name,
              'contentType': contentType,
              'size': size,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const StorageFailure(StorageFailureKind.network);
    }

    if (response.statusCode == 503) {
      throw const StorageFailure(StorageFailureKind.notConfigured);
    }
    if (response.statusCode == 413) {
      throw const StorageFailure(StorageFailureKind.tooLarge);
    }
    if (response.statusCode == 429) {
      throw const StorageFailure(StorageFailureKind.tooManyUploads);
    }
    if (response.statusCode != 200) {
      throw const StorageFailure(StorageFailureKind.server);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final uploadUrl = data['uploadUrl'] as String?;
    final fileUrl = data['fileUrl'] as String?;
    if (uploadUrl == null) throw const StorageFailure(StorageFailureKind.server);
    // Бе суроғаи ҷамъиятӣ файл бор мешавад, вале ҳељ кас онро дида
    // наметавонад — ин ҳолатро пинҳон кардан лозим нест.
    if (fileUrl == null) throw const StorageFailure(StorageFailureKind.noPublicUrl);

    return _UploadTicket(uploadUrl, fileUrl);
  }

  /// Файл ҷараёнӣ фиристода мешавад — видеои калон набояд тамоман ба хотира
  /// бор карда шавад.
  static Future<void> _put(
    File file,
    int length,
    String uploadUrl,
    String contentType,
  ) async {
    final request = http.StreamedRequest('PUT', Uri.parse(uploadUrl))
      ..headers['Content-Type'] = contentType
      ..contentLength = length;

    var sent = 0;
    file.openRead().listen(
      (chunk) {
        request.sink.add(chunk);
        sent += chunk.length;
        // Танҳо ҳиссаи хондашуда ҳисоб мешавад — ин ба фиристодани воқеӣ
        // хеле наздик аст ва ба ҳељ плагини иловагӣ ниёз надорад.
        if (length > 0) progress.value = (sent / length).clamp(0.0, 1.0);
      },
      onDone: request.sink.close,
      onError: (Object _) => request.sink.close(),
      cancelOnError: true,
    );

    http.StreamedResponse response;
    try {
      response = await request.send().timeout(const Duration(minutes: 5));
    } catch (_) {
      throw const StorageFailure(StorageFailureKind.network);
    }
    // Ҷавобро то охир мехонем, вагарна пайваст кушода мемонад.
    await response.stream.drain<void>();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StorageFailure(
        response.statusCode == 403
            ? StorageFailureKind.rejected
            : StorageFailureKind.uploadFailed,
      );
    }
  }

  static String _contentTypeFor(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      '3gp' => 'video/3gpp',
      'm4a' => 'audio/mp4',
      'aac' => 'audio/aac',
      'mp3' => 'audio/mpeg',
      'ogg' || 'opus' => 'audio/ogg',
      'wav' => 'audio/wav',
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'txt' => 'text/plain',
      'zip' => 'application/zip',
      _ => 'application/octet-stream',
    };
  }
}

/// Сабаби нобарории боркунӣ — то корбар паёми фаҳмо бубинад.
enum StorageFailureKind {
  missingFile,
  notSignedIn,
  network,
  notConfigured,
  noPublicUrl,
  rejected,
  uploadFailed,
  tooLarge,
  tooManyUploads,
  server,
}

class StorageFailure implements Exception {
  final StorageFailureKind kind;
  const StorageFailure(this.kind);

  @override
  String toString() => 'StorageFailure(${kind.name})';
}

class _UploadTicket {
  final String uploadUrl;
  final String fileUrl;
  const _UploadTicket(this.uploadUrl, this.fileUrl);
}
