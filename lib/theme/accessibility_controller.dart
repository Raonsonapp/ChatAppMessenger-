import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Имкониятҳои воқеии дастрасӣ: контрасти баланд (ранги дигар дар тамоми
/// барнома) ва камтар аниматсия (гузариши соддаи экранҳо). Ҳарду дар
/// SharedPreferences нигоҳ дошта мешаванд — ба дастгоҳ тааллуқ доранд, на ба
/// ҳисоб.
///
/// Ин контролер худаш AppColors-ро иваз намекунад — он кори `main.dart` аст
/// (ниг. `AppColors.applyFlags`), то бо ThemeController муноқиша накунад.
class AccessibilityController extends ChangeNotifier {
  static const String _contrastKey = 'accessibility_high_contrast';
  static const String _motionKey = 'accessibility_reduce_motion';

  bool _highContrast = false;
  bool _reduceMotion = false;

  bool get highContrast => _highContrast;
  bool get reduceMotion => _reduceMotion;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _highContrast = prefs.getBool(_contrastKey) ?? false;
      _reduceMotion = prefs.getBool(_motionKey) ?? false;
    } catch (_) {
      _highContrast = false;
      _reduceMotion = false;
    }
  }

  Future<void> setHighContrast(bool value) async {
    if (_highContrast == value) return;
    _highContrast = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_contrastKey, value);
    } catch (_) {
      // Дар ҳамин сессия бо ҳар ҳол фаъол аст.
    }
  }

  Future<void> setReduceMotion(bool value) async {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_motionKey, value);
    } catch (_) {
      // Дар ҳамин сессия бо ҳар ҳол фаъол аст.
    }
  }
}

/// Як нусха барои тамоми барнома.
final AccessibilityController accessibilityController = AccessibilityController();
