import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'accessibility_controller.dart';

/// Се ҳолати мавзӯъ. `system` ба танзими худи телефон гӯш медиҳад.
enum AppThemeMode { system, light, dark }

/// Интихоби мавзӯи корбарро нигоҳ медорад ва тағйирашро эълон мекунад.
///
/// Дар SharedPreferences нигоҳ дошта мешавад, на дар Firestore: мавзӯъ ба ин
/// дастгоҳ тааллуқ дорад ва бояд пеш аз вуруд низ кор кунад.
class ThemeController extends ChangeNotifier {
  /// Калиди кӯҳна — нусхаҳои пештара танҳо `bool` нигоҳ медоштанд. Он хонда
  /// мешавад, то корбари кӯҳна интихобашро гум накунад.
  static const String _legacyKey = 'is_dark_theme';
  static const String _modeKey = 'app_theme_mode';

  AppThemeMode _mode = AppThemeMode.dark;
  AppThemeMode get mode => _mode;

  /// Мавзӯи воқеии ҳозира: дар ҳолати `system` аз рӯи танзими телефон.
  bool get isDark => switch (_mode) {
        AppThemeMode.dark => true,
        AppThemeMode.light => false,
        AppThemeMode.system => _platformIsDark,
      };

  bool get _platformIsDark =>
      PlatformDispatcher.instance.platformBrightness == Brightness.dark;

  /// Пеш аз сохтани MaterialApp даъват мешавад, то аввалин кашидан дарҳол
  /// бо мавзӯи дуруст бошад ва мавзӯъ назди чашм наҷаҳад.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_modeKey);
    if (stored != null) {
      _mode = _parse(stored);
    } else {
      // Гузариш аз калиди кӯҳна: `true` → торик, `false` → равшан.
      final legacy = prefs.getBool(_legacyKey);
      _mode = legacy == null
          ? AppThemeMode.dark
          : (legacy ? AppThemeMode.dark : AppThemeMode.light);
    }
    _apply();
    _listenToPlatform();
  }

  bool _listening = false;

  /// Дар ҳолати `system` бояд ба тағйири танзими телефон дарҳол вокуниш кунем —
  /// вагарна корбар шаби худкорро фақат баъди аз нав кушодани барнома мебинад.
  void _listenToPlatform() {
    if (_listening) return;
    _listening = true;
    final previous = PlatformDispatcher.instance.onPlatformBrightnessChanged;
    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
      previous?.call();
      if (_mode != AppThemeMode.system) return;
      _apply();
      notifyListeners();
    };
  }

  Future<void> setMode(AppThemeMode value) async {
    if (_mode == value) return;
    _mode = value;
    _apply();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, value.name);
    // Калиди кӯҳна низ нав карда мешавад, то нусхаи кӯҳнаи барнома (агар
    // корбар ба он баргардад) ҳамон мавзӯъро бинад.
    await prefs.setBool(_legacyKey, isDark);
  }

  void _apply() {
    // Палитра тавассути `applyFlags` гузошта мешавад, на рост — вагарна
    // контрасти баланди «Имкониятҳои дастрасӣ» пахш мешуд: ин ҷо мо танҳо
    // торик/равшанро медонем, на он калидро.
    AppColors.applyFlags(
      isDark: isDark,
      highContrast: accessibilityController.highContrast,
    );
  }

  static AppThemeMode _parse(String raw) {
    for (final mode in AppThemeMode.values) {
      if (mode.name == raw) return mode;
    }
    return AppThemeMode.dark;
  }
}

/// Як нусха барои тамоми барнома.
final ThemeController themeController = ThemeController();
