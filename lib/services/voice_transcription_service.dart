import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/otp_server_config.dart';
import '../l10n/l10n.dart';

String _audioMimeType(String audioUrl, String? contentType) {
  const supported = <String>{
    'audio/mpeg', 'audio/mp4', 'audio/wav', 'audio/webm',
    'audio/ogg', 'audio/aac', 'audio/flac', 'audio/3gpp', 'audio/amr',
  };
  final headerType = (contentType ?? '').split(';').first.trim().toLowerCase();
  if (supported.contains(headerType)) return headerType;
  String path = '';
  try {
    path = Uri.decodeComponent(Uri.parse(audioUrl).path).toLowerCase();
  } catch (_) {}
  if (path.endsWith('.wav')) return 'audio/wav';
  if (path.endsWith('.mp3')) return 'audio/mpeg';
  if (path.endsWith('.ogg') || path.endsWith('.opus')) return 'audio/ogg';
  if (path.endsWith('.webm')) return 'audio/webm';
  if (path.endsWith('.aac')) return 'audio/aac';
  if (path.endsWith('.flac')) return 'audio/flac';
  if (path.endsWith('.3gp') || path.endsWith('.3gpp')) return 'audio/3gpp';
  if (path.endsWith('.amr')) return 'audio/amr';
  return 'audio/mp4';
}

/// Транскрипсияи паёми овозӣ тавассути Gemini API дар сервер.
/// Калиди Gemini дар APK ҷойгир намешавад.
class VoiceTranscriptionService {
  static Future<String> transcribe(String audioUrl) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw VoiceTranscriptionFailure(tr('k366'));
    }

    http.Response download;
    try {
      download = await http
          .get(Uri.parse(audioUrl))
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      throw VoiceTranscriptionFailure(tr('k367'));
    }
    if (download.statusCode != 200) {
      throw VoiceTranscriptionFailure(tr('k487'));
    }
    if (download.bodyBytes.length > 5 * 1024 * 1024) {
      throw VoiceTranscriptionFailure(tr('k712'));
    }

    final mimeType = _audioMimeType(audioUrl, download.headers['content-type']);

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${OtpServerConfig.baseUrl}/api/transcribe'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'audioBase64': base64Encode(download.bodyBytes),
              'mimeType': mimeType,
            }),
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw VoiceTranscriptionFailure(tr('k367'));
    }

    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      data = <String, dynamic>{};
    }
    if (response.statusCode == 503) {
      throw const VoiceTranscriptionFailure('Транскрипсияи овоз дар сервер фаъол нест. GEMINI_API_KEY-ро дар Render санҷед.');
    }
    if (response.statusCode == 401) {
      throw const VoiceTranscriptionFailure('Сессияи воридшавӣ гузаштааст. Аз нав ворид шавед.');
    }
    if (response.statusCode == 413) {
      throw const VoiceTranscriptionFailure('Овоз хеле калон аст. Овози кӯтоҳтарро санҷед.');
    }
    if (response.statusCode == 429) {
      throw VoiceTranscriptionFailure(tr('k713'));
    }
    if (response.statusCode != 200) {
      throw const VoiceTranscriptionFailure('Сервер овозро коркард накард. Танзимоти Gemini ва формати файлро санҷед.');
    }
    final text = (data['text'] as String? ?? '').trim();
    if (text.isEmpty) throw VoiceTranscriptionFailure(tr('k705'));
    return text;
  }
}

class VoiceTranscriptionFailure implements Exception {
  final String message;
  const VoiceTranscriptionFailure(this.message);

  @override
  String toString() => message;
}
