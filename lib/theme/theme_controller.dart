import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// Интихоби мавзӯи корбарро нигоҳ медорад ва тағйирашро эълон мекунад.
///
/// Дар SharedPreferences нигоҳ дошта мешавад, на дар Firestore: мавзӯъ ба ин
/// дастгоҳ тааллуқ дорад ва бояд пеш аз вуруд низ кор кунад.
class ThemeController extends ChangeNotifier {
  static const String _prefsKey = 'is_dark_theme';

  bool _isDark = true;
  bool get isDark => _isDark;

  /// Пеш аз сохтани MaterialApp даъват мешавад, то аввалин кашидан дарҳол
  /// бо мавзӯи дуруст бошад ва мавзӯъ назди чашм наҷаҳад.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_prefsKey) ?? true;
    AppColors.palette = _isDark ? darkPalette : lightPalette;
  }

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    AppColors.palette = value ? darkPalette : lightPalette;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}

/// Як нусха барои тамоми барнома.
final ThemeController themeController = ThemeController();
