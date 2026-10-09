/// Пас аз deploy кардани server/otp-bot (нигаред ба
/// server/otp-bot/README.md), ин ду қиматро бо маълумоти воқеӣ иваз кунед.
class OtpServerConfig {
  /// URL-и хидмати Render.
  static const String baseUrl = 'https://chatappmessenger.onrender.com';

  /// Username-и боти Telegram (бе '@').
  static const String telegramBotUsername = 'VerificationChatAppBot';

  /// Бо `?start=` — Telegram ботро худкор оғоз мекунад ва рақамро ҳамчун
  /// payload мефиристад, то бот донад, ки барнома кадом рақамро интизор аст.
  static String telegramBotDeepLink(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return 'https://t.me/$telegramBotUsername?start=$digits';
  }
}
