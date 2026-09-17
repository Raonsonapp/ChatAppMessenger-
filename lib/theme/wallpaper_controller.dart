import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Заминаи чат (wallpaper) — мисли WhatsApp.
///
/// Акс ба ҳофизаи худи дастгоҳ нусхабардорӣ мешавад, на ба Storage: ин интихоби
/// шахсии ҳамин дастгоҳ аст, ҳамсӯҳбат онро намебинад ва барои он трафик сарф
/// кардан лозим нест.
class WallpaperController extends ChangeNotifier {
  static const String _prefsKey = 'chat_wallpaper_path';

  String? _path;

  /// Роҳи файли замина ё `null`, агар интихоб нашуда бошад.
  String? get path => _path;

  File? get file {
    final p = _path;
    if (p == null) return null;
    final f = File(p);
    return f.existsSync() ? f : null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _path = prefs.getString(_prefsKey);
    // Агар файл дигар набошад (масалан пас аз тоза кардани ҳофиза), интихобро
    // фаромӯш мекунем — вагарна чат бо заминаи холӣ мемонад.
    if (_path != null && !File(_path!).existsSync()) {
      _path = null;
      await prefs.remove(_prefsKey);
    }
  }

  /// Аксро ба ҳофизаи барнома нусхабардорӣ мекунад ва ҳамчун замина мегузорад.
  Future<void> setFromPath(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = '${dir.path}/chat_wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(sourcePath).copy(target);

    final old = _path;
    _path = target;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, target);
    // Нусхаи кӯҳна дигар лозим нест.
    if (old != null && old != target) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
  }

  Future<void> clear() async {
    final old = _path;
    _path = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    if (old != null) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
  }
}

/// Як нусха барои тамоми барнома.
final WallpaperController wallpaperController = WallpaperController();
