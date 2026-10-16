import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/otp_server_config.dart';
import '../l10n/l10n.dart';

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

    var mimeType = (download.headers['content-type'] ?? '').split(';').first.trim().toLowerCase();
    if (!mimeType.startsWith('audio/')) {
      final path = Uri.tryParse(audioUrl)?.path.toLowerCase() ?? '';
      mimeType = path.endsWith('.wav')
          ? 'audio/wav'
          : path.endsWith('.mp3')
              ? 'audio/mpeg'
              : path.endsWith('.ogg')
                  ? 'audio/ogg'
                  : path.endsWith('.aac')
                      ? 'audio/aac'
                      : path.endsWith('.m4a')
                          ? 'audio/mp4'
                          : 'audio/mp4';
    }

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

    if (response.statusCode == 503) {
      throw VoiceTranscriptionFailure(tr('k710'));
    }
    if (response.statusCode == 429) {
      throw VoiceTranscriptionFailure(tr('k713'));
    }
    if (response.statusCode != 200) {
      throw VoiceTranscriptionFailure(tr('k487'));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
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
