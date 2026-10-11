import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Иваз кардани нишонаи воқеии launcher дар Android тавассути activity-alias.
class LauncherIconService {
  LauncherIconService._();

  static const MethodChannel _channel = MethodChannel('chatapp/launcher_icon');
  static const int iconCount = 10;

  static Future<int> selectedIcon() async {
    try {
      final icon = await _channel.invokeMethod<int>('getSelectedIcon');
      if (icon != null && icon >= 1 && icon <= iconCount) return icon;
      return 1;
    } on PlatformException catch (error) {
      debugPrint('Хатои хондани нишонаи launcher: ${error.message}');
      rethrow;
    } on MissingPluginException {
      throw StateError('Дастгирии ивазкунии логотип дар APK нест. APK-и нав созед.');
    }
  }

  static Future<int> setIcon(int icon) async {
    if (icon < 1 || icon > iconCount) {
      throw ArgumentError.value(icon, 'icon', 'Нишона бояд аз 1 то $iconCount бошад');
    }
    try {
      final selected = await _channel.invokeMethod<int>(
        'setLauncherIcon',
        <String, Object>{'icon': icon},
      );
      return selected ?? icon;
    } on PlatformException catch (error) {
      throw StateError(error.message ?? 'Android нишонаи барномаро иваз карда натавонист.');
    } on MissingPluginException {
      throw StateError('Дастгирии ивазкунии логотип дар APK нест. APK-и нав созед.');
    }
  }
}
