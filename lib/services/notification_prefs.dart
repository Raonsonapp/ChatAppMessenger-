import 'package:shared_preferences/shared_preferences.dart';

/// Танзимоти огоҳинома дар ҳофизаи дастгоҳ.
///
/// Онҳо дар Firestore низ нигоҳ дошта мешаванд (то дар дастгоҳи нав барқарор
/// шаванд), вале ҳангоми нишон додани огоҳинома Firestore хондан мумкин нест —
/// он метавонад дар изоляти паснамо бе шабака иҷро шавад. Барои ҳамин ҳамон
/// қиматҳо дар SharedPreferences низ нусхабардорӣ мешаванд.
class NotificationPrefs {
  static const _prefix = 'notif_';

  static Future<void> save(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefix$key', value);
    } catch (_) {
      // Танзимот дар Firestore ба ҳар ҳол сабт шуд.
    }
  }

  /// Ҳамаи чор танзимотро якбора нусхабардорӣ мекунад (ҳангоми воридшавӣ).
  static Future<void> saveAll(Map<String, dynamic>? settings) async {
    if (settings == null) return;
    for (final key in const [
      'messageNotifications',
      'notificationSound',
      'notificationVibration',
      'notificationPreview',
    ]) {
      final value = settings[key];
      if (value is bool) await save(key, value);
    }
  }

  /// `true` — агар танзимот гузошта нашуда бошад (пешфарз ҳамеша фаъол).
  static Future<bool> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_prefix$key') ?? true;
    } catch (_) {
      return true;
    }
  }
}
