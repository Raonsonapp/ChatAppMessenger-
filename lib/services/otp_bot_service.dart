import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/otp_server_config.dart';
import '../l10n/l10n.dart';

class OtpVerifyException implements Exception {
  final String message;
  OtpVerifyException(this.message);
  @override
  String toString() => message;
}

/// Муштарии сервери OTP-бот (server/otp-bot) — рамзи 6-рақамаро на тавассути
/// Firebase SMS, балки тавассути боти Telegram мефиристад ва тасдиқ мекунад.
class OtpBotService {
  /// Боти Telegram-ро мекушояд, то корбар рақами худро мубодила карда рамзро гирад.
  static Future<bool> openTelegramBot(String phone) {
    final uri = Uri.parse(OtpServerConfig.telegramBotDeepLink(phone));
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Рамзи гирифташударо бо сервер тасдиқ мекунад ва Firebase custom token бармегардонад.
  static Future<String> verifyCode({required String phone, required String code}) async {
    final uri = Uri.parse('${OtpServerConfig.baseUrl}/api/otp/verify');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code}),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw OtpVerifyException(body['error'] as String? ?? tr('k225'));
    }
    return body['token'] as String;
  }
}
