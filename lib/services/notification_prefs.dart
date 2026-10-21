import 'package:shared_preferences/shared_preferences.dart';

/// Танзимоти огоҳинома дар ҳофизаи дастгоҳ.
///
/// Ин танзимот маҳаллӣ мебошанд: огоҳиномаҳо бояд ҳатто дар изоляти паснамо
/// ва бе шабака хонда шаванд. Онҳо ба сервер навишта намешаванд.
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
