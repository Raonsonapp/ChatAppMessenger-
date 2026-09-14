/// Пас аз deploy кардани server/otp-bot дар Railway (нигаред ба
/// server/otp-bot/README.md), ин ду қиматро бо маълумоти воқеӣ иваз кунед.
class OtpServerConfig {
  /// URL-и хидмати Railway.
  static const String baseUrl = 'https://chatappmessenger-production.up.railway.app';

  /// Username-и боти Telegram (бе '@').
  static const String telegramBotUsername = 'VerificationChatAppBot';

  static String get telegramBotDeepLink => 'https://t.me/$telegramBotUsername';
}
