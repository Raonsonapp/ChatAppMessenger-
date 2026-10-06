import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Заминаи чат (wallpaper) — мисли WhatsApp.
///
/// Акс ба ҳофизаи худи дастгоҳ нусхабардорӣ мешавад, на ба Storage: ин интихоби
/// шахсии ҳамин дастгоҳ аст, ҳамсӯҳбат онро намебинад ва барои он трафик сарф
/// кардан лозим нест.
///
/// Ба ғайр аз заминаи умумии барнома (`path`/`file`), ҳар чат метавонад
/// заминаи ХОСИ худро дошта бошад (`pathFor`/`colorFor`) — мисли мавзӯи
/// чат дар WhatsApp. Агар чат заминаи хос надошта бошад, заминаи умумӣ
/// истифода мешавад.
class WallpaperController extends ChangeNotifier {
  static const String _prefsKey = 'chat_wallpaper_path';
  static const String _perChatKey = 'chat_wallpaper_per_chat_v1';

  String? _path;
  Map<String, String> _perChat = {};

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
    try {
      final raw = prefs.getString(_perChatKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _perChat = decoded.map((k, v) => MapEntry(k, v as String));
      }
    } catch (_) {
      _perChat = {};
    }
  }

  Future<void> _savePerChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_perChatKey, jsonEncode(_perChat));
  }

  /// Қимати замина барои як чати мушаххас: роҳи файл, ё `color:0xFFRRGGBB`
  /// барои ранги якранг, ё `null` агар он чат заминаи хос надошта бошад
  /// (он гоҳ заминаи умумии барнома истифода мешавад).
  String? rawFor(String chatId) => _perChat[chatId];

  /// Аксро (аз галерея) ба ҳофизаи барнома нусхабардорӣ мекунад ва ҳамчун
  /// заминаи ҳамин чат мегузорад.
  Future<void> setImageForChat(String chatId, String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = '${dir.path}/chat_wallpaper_${chatId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(sourcePath).copy(target);
    final old = _perChat[chatId];
    _perChat[chatId] = target;
    notifyListeners();
    await _savePerChat();
    if (old != null && old != target && !old.startsWith('color:')) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
  }

  /// Ранги якрангро ҳамчун заминаи ҳамин чат мегузорад.
  Future<void> setColorForChat(String chatId, int colorValue) async {
    _perChat[chatId] = 'color:$colorValue';
    notifyListeners();
    await _savePerChat();
  }

  /// Заминаи хоси ин чатро бар мегардонад ба пешфарз (заминаи умумии барнома).
  Future<void> clearForChat(String chatId) async {
    _perChat.remove(chatId);
    notifyListeners();
    await _savePerChat();
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
