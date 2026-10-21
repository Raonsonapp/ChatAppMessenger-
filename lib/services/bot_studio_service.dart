import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/otp_server_config.dart';

class BotStudioService {
  static Uri get _baseUri => Uri.parse('${OtpServerConfig.baseUrl}/api/bots');

  static Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Аввал ба ChatApp ворид шавед.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('Сессияи воридшавӣ дастрас нест.');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'] as String? ?? 'request-failed';
      throw Exception(_messageFor(error));
    }
    return body;
  }

  static String _messageFor(String error) => switch (error) {
        'bot-limit-reached' => 'Шумо ҳадди аксар 20 бот сохта метавонед.',
        'too-many-bot-creates' => 'Шумораи сохтани бот зиёд шуд. Баъдтар кӯшиш кунед.',
        'too-many-bot-messages' => 'Шумораи санҷиши бот зиёд шуд. Каме баъдтар кӯшиш кунед.',
        'ai-not-configured' => 'AI дар сервер ҳоло танзим нашудааст.',
        'donation-guide-required' => 'Барои ботҳои донати алмаз амали «Роҳнамои донат»-ро интихоб кунед.',
        'name-invalid' => 'Номи бот бояд аз 2 то 40 аломат бошад.',
        'task-invalid' => 'Вазифаи бот нодуруст аст.',
        'actions-invalid' => 'Яке аз амалҳои интихобшуда дастгирӣ намешавад.',
        'bot-forbidden' => 'Ин бот ба ҳисоби шумо тааллуқ надорад.',
        'bot-not-found' => 'Бот ёфт нашуд.',
        _ => 'Дархост иҷро нашуд. Пайвасти интернет ва серверро санҷед.',
      };

  static Future<List<Map<String, dynamic>>> listBots() async {
    final response = await http.get(_baseUri, headers: await _headers());
    final body = _decode(response);
    return (body['bots'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static Future<Map<String, dynamic>> createBot({
    required String name,
    required String description,
    required String task,
    required String instructions,
    required List<String> actions,
  }) async {
    final response = await http.post(
      _baseUri,
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'description': description,
        'task': task,
        'instructions': instructions,
        'actions': actions,
      }),
    );
    return _decode(response);
  }

  static Future<Map<String, dynamic>> chatBot({
    required String botId,
    required String message,
  }) async {
    final response = await http.post(
      _baseUri.resolve('/api/bots/${Uri.encodeComponent(botId)}/chat'),
      headers: await _headers(),
      body: jsonEncode({'message': message}),
    );
    return _decode(response);
  }

  static Future<void> deleteBot(String botId) async {
    final response = await http.delete(
      _baseUri.resolve('/api/bots/${Uri.encodeComponent(botId)}'),
      headers: await _headers(),
    );
    _decode(response);
  }
}
