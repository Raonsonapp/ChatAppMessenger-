import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/otp_server_config.dart';

/// Чат бо Gemini тавассути сервер; API key ҳеҷ гоҳ ба Flutter намерасад.
class ChatAiService {
  static Future<String> reply(List<Map<String, String>> messages) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw const ChatAiFailure();

    final response = await http
        .post(
          Uri.parse('${OtpServerConfig.baseUrl}/api/ai/chat'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'messages': messages}),
        )
        .timeout(const Duration(seconds: 40));

    if (response.statusCode == 401) throw const ChatAiFailure();
    if (response.statusCode == 429) throw const ChatAiFailure();
    if (response.statusCode == 503) throw const ChatAiFailure();

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 ||
        data is! Map<String, dynamic> ||
        data['reply'] is! String ||
        (data['reply'] as String).trim().isEmpty) {
      throw const ChatAiFailure();
    }
    return (data['reply'] as String).trim();
  }

  /// Генерасияи медиа тавассути адаптери серверӣ. Калидҳои провайдер ба апп намеоянд.
  static Future<GeneratedChatMedia> generateMedia({
    required String kind,
    required String prompt,
    int durationSeconds = 8,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw const ChatAiFailure();

    final response = await http
        .post(
          Uri.parse('${OtpServerConfig.baseUrl}/api/ai/generate/$kind'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'prompt': prompt,
            if (kind == 'video') 'durationSeconds': durationSeconds.clamp(1, 30),
          }),
        )
        .timeout(const Duration(seconds: 95));

    if (response.statusCode == 401 ||
        response.statusCode == 429 ||
        response.statusCode == 503) {
      throw const ChatAiFailure();
    }
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 ||
        data is! Map<String, dynamic> ||
        data['url'] is! String ||
        !(data['url'] as String).startsWith('https://')) {
      throw const ChatAiFailure();
    }
    return GeneratedChatMedia(
      kind: kind,
      url: data['url'] as String,
      durationSeconds: data['durationSeconds'] is num
          ? (data['durationSeconds'] as num).round()
          : null,
    );
  }
}

class GeneratedChatMedia {
  final String kind;
  final String url;
  final int? durationSeconds;

  const GeneratedChatMedia({
    required this.kind,
    required this.url,
    this.durationSeconds,
  });
  static Future<GeneratedChatMedia> generateMedia({
    required String kind,
    required String prompt,
    int durationSeconds = 30,
  }) async {
    if (!const {'image', 'video', 'music'}.contains(kind)) {
      throw const ChatAiFailure();
    }
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw const ChatAiFailure();

    final response = await http
        .post(
          Uri.parse('${OtpServerConfig.baseUrl}/api/ai/generate/$kind'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'prompt': prompt,
            if (kind == 'video') 'durationSeconds': durationSeconds,
          }),
        )
        .timeout(const Duration(seconds: 100));

    if (response.statusCode != 200) throw const ChatAiFailure();
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> ||
        data['url'] is! String ||
        !(data['url'] as String).startsWith('https://')) {
      throw const ChatAiFailure();
    }
    return GeneratedChatMedia(
      kind: kind,
      url: data['url'] as String,
      durationSeconds: data['durationSeconds'] is num
          ? (data['durationSeconds'] as num).toInt()
          : null,
    );
  }
}

class GeneratedChatMedia {
  final String kind;
  final String url;
  final int? durationSeconds;
  const GeneratedChatMedia({
    required this.kind,
    required this.url,
    this.durationSeconds,
  });
}

class ChatAiFailure implements Exception {
  const ChatAiFailure();
}
