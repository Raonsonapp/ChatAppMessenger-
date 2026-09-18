import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Андозаи ҳарфҳо дар паёмҳо — «Хурд / Муқаррарӣ / Калон», мисли WhatsApp.
///
/// Танҳо ба матни паём таъсир мекунад, на ба тамоми барнома: калон кардани
/// ҳамаи навиштаҷот метавонад тарҳи экранҳоро вайрон кунад.
class TextScaleController extends ChangeNotifier {
  static const String _prefsKey = 'chat_text_scale';

  /// Зарбкунандаи андоза: 0.9, 1.0 ё 1.15.
  double _scale = 1.0;
  double get scale => _scale;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _scale = prefs.getDouble(_prefsKey) ?? 1.0;
    } catch (_) {
      _scale = 1.0;
    }
  }

  Future<void> setScale(double value) async {
    if (_scale == value) return;
    _scale = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsKey, value);
    } catch (_) {
      // Андоза дар ин сессия ба ҳар ҳол иваз шуд.
    }
  }
}

/// Як нусха барои тамоми барнома.
final TextScaleController textScaleController = TextScaleController();
