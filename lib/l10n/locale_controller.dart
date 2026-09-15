import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';

/// Забони интихобкардаи корбарро нигоҳ медорад.
///
/// Мисли мавзӯъ, дар SharedPreferences нигоҳ дошта мешавад — забон ба дастгоҳ
/// тааллуқ дорад ва бояд пеш аз вуруд низ кор кунад.
class LocaleController extends ChangeNotifier {
  static const String _prefsKey = 'app_language';

  AppLanguage _language = AppLanguage.tj;
  AppLanguage get language => _language;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _language = AppLanguage.fromCode(prefs.getString(_prefsKey));
    L10n.language = _language;
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    L10n.language = language;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.code);
  }
}

final LocaleController localeController = LocaleController();
