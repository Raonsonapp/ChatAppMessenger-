/// Пас аз deploy кардани server/otp-bot дар Railway (нигаред ба
/// server/otp-bot/README.md), ин ду қиматро бо маълумоти воқеӣ иваз кунед.
class OtpServerConfig {
  /// URL-и хидмати Railway, масалан:
  /// 'https://chatapp-otp-bot-production.up.railway.app'
  static const String baseUrl = 'https://YOUR-OTP-BOT.up.railway.app';

  /// Username-и боти Telegram (бе '@'), масалан: 'chatapp_otp_bot'
  static const String telegramBotUsername = 'YOUR_BOT_USERNAME';

  static String get telegramBotDeepLink => 'https://t.me/$telegramBotUsername';
}
