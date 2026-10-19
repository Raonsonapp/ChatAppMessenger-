import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/otp_server_config.dart';

/// Чат бо Gemini тавассути сервер; API key ҳеҷ гоҳ ба Flutter намерасад.
class ChatAiService {
  static Future<List<Map<String, String>>> availableProviders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return const [{'id': 'gemini', 'label': 'Gemini'}];

    try {
      final response = await http.get(
        Uri.parse('${OtpServerConfig.baseUrl}/api/ai/providers'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return const [{'id': 'gemini', 'label': 'Gemini'}];
      }
      final data = jsonDecode(response.body);
      final raw = data is Map<String, dynamic> ? data['providers'] : null;
      if (raw is! List) return const [{'id': 'gemini', 'label': 'Gemini'}];
      final providers = raw
          .whereType<Map<String, dynamic>>()
          .where((item) => item['id'] is String && item['label'] is String)
          .map((item) => {
                'id': item['id']! as String,
                'label': item['label']! as String,
              })
          .toList();
      return providers.isEmpty ? const [{'id': 'gemini', 'label': 'Gemini'}] : providers;
    } catch (_) {
      return const [{'id': 'gemini', 'label': 'Gemini'}];
    }
  }

  static Future<String> reply(
    List<Map<String, String>> messages, {
    String provider = 'gemini',
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw const ChatAiFailure('Аввал ба аккаунти ChatApp ворид шавед.');

    final response = await http
        .post(
          Uri.parse('${OtpServerConfig.baseUrl}/api/ai/chat'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'messages': messages, 'provider': provider}),
        )
        .timeout(const Duration(seconds: 40));

    if (response.statusCode != 200) {
      throw ChatAiFailure(_responseMessage(response, provider: provider));
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic> ||
        data['reply'] is! String ||
        (data['reply'] as String).trim().isEmpty) {
      throw const ChatAiFailure();
    }
    return (data['reply'] as String).trim();
  }

  /// Тавлиди медиа тавассути адаптери серверӣ. Калидҳои API ба Flutter намеоянд.
  static Future<GeneratedChatMedia> generateMedia({
    required String kind,
    required String prompt,
    int durationSeconds = 8,
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
            if (kind == 'video') 'durationSeconds': durationSeconds.clamp(1, 30),
          }),
        )
        .timeout(const Duration(seconds: 100));

    if (response.statusCode != 200) {
      throw ChatAiFailure(_responseMessage(response));
    }
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
}

String _responseMessage(http.Response response, {String provider = 'gemini'}) {
  final providerLabel = switch (provider) {
    'openai' => 'OpenAI',
    'grok' => 'Grok',
    _ => 'Gemini',
  };
  String code = '';
  try {
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) code = body['error']?.toString() ?? '';
  } catch (_) {}
  if (response.statusCode == 401) return 'Аз нав ба аккаунти ChatApp ворид шавед.';
  if (response.statusCode == 429 || code == 'too-many-requests') return 'Дархостҳои AI маҳдуд шуданд. Каме баъдтар такрор кунед.';
  if (response.statusCode == 503 || code == 'ai-not-configured' || code == 'provider-not-configured') return 'Провайдери $providerLabel дар сервер фаъол нест. API key ва ALLOW_PAID_AI_PROVIDERS-ро дар Render санҷед.';
  if (response.statusCode == 502 || code == 'ai-request-failed' || code == 'provider-request-failed' || code == 'ai-empty-response') return '$providerLabel ҷавоб надод. API key, бақияи ҳисоб, квота ва номи моделро дар Render санҷед.';
  if (response.statusCode == 413 || code == 'conversation-too-long') return 'Гуфтугӯ хеле дароз аст; паёми кӯтоҳтар фиристед.';
  return 'ChatAI хатои HTTP ${response.statusCode} дод. Интернет ва серверро санҷед.';
}

class ChatAiFailure implements Exception {
  final String message;
  const ChatAiFailure([this.message = 'ChatAI ҷавоб надод.']);
  @override
  String toString() => message;
}
