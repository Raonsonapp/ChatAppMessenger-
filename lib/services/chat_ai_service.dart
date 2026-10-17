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
}

class ChatAiFailure implements Exception {
  const ChatAiFailure();
}
