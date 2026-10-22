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
      throw ChatAiFailure(_responseMessage(response));
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
    String provider = 'grok',
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
            'provider': provider,
            if (kind == 'video') 'durationSeconds': durationSeconds.clamp(1, 30),
          }),
        )
        .timeout(const Duration(seconds: 100));

    if (response.statusCode != 200) {
      throw ChatAiFailure(_responseMessage(response));
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) throw const ChatAiFailure();
    final url = data['url'];
    final base64 = data['base64'];
    final mimeType = data['mimeType'];
    final mediaUrl = url is String && url.startsWith('https://')
        ? url
        : (base64 is String && mimeType is String && mimeType.startsWith('image/')
            ? 'data:$mimeType;base64,$base64'
            : null);
    if (mediaUrl == null) throw const ChatAiFailure();
    return GeneratedChatMedia(
      kind: kind,
      url: mediaUrl,
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

String _responseMessage(http.Response response) {
  String code = '';
  try {
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) code = body['error']?.toString() ?? '';
  } catch (_) {}
  if (response.statusCode == 401) return 'Аз нав ба аккаунти ChatApp ворид шавед.';
  if (response.statusCode == 429 || code == 'too-many-requests' || code == 'provider-rate-limited') {
    return 'Gemini лимити дархостро баргардонд. Квотаи Google AI Studio-ро санҷед ё каме баъдтар такрор кунед.';
  }
  if (code == 'provider-auth-failed') {
    return 'Калиди Gemini қабул нашуд. GEMINI_API_KEY-ро дар Render бо калиди дурусти Google AI Studio иваз кунед.';
  }
  if (code == 'provider-model-unavailable') {
    return 'Модели Gemini дар сервер дастрас нест. GEMINI_CHAT_MODEL-ро тоза кунед ё ба gemini-2.5-flash гузоред.';
  }
  if (response.statusCode == 503 || code == 'ai-not-configured' || code == 'provider-not-configured') {
    return 'ChatAI танзим нашудааст. GEMINI_API_KEY-ро дар Render санҷед.';
  }
  if (response.statusCode == 502 || code == 'ai-request-failed' || code == 'provider-request-failed') {
    return 'Gemini дархостро қабул накард. Номи модел, калиди API ва квотаро дар Render санҷед.';
  }
  if (response.statusCode == 413 || code == 'conversation-too-long') return 'Гуфтугӯ хеле дароз аст; паёми кӯтоҳтар фиристед.';
  return 'ChatAI хатои HTTP ${response.statusCode} дод. Интернет ва серверро санҷед.';
}

class ChatAiFailure implements Exception {
  final String message;
  const ChatAiFailure([this.message = 'ChatAI ҷавоб надод.']);
  @override
  String toString() => message;
}
