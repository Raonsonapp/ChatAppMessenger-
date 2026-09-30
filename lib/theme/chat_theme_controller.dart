import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Танзимоти намуди ЯК чат: ранги ҳубобча, замина ва нишона.
class ChatStyle {
  /// Шиносаи маҷмӯаи тайёр, ё `null` барои интихоби дастӣ.
  final String? presetId;

  /// Ранги ҳубобчаи паёмҳои ман.
  final int? bubbleColor;

  /// Ранги таъкид (тугмаҳо, нишонаҳо).
  final int? accentColor;

  /// Роҳи файли замина — акси интихобшуда.
  final String? wallpaperPath;

  /// Ранги якрангаи замина, агар акс интихоб нашуда бошад.
  final int? wallpaperColor;

  /// Нишонаи чат (номи нишона аз маҷмӯаи барнома).
  final String? icon;

  const ChatStyle({
    this.presetId,
    this.bubbleColor,
    this.accentColor,
    this.wallpaperPath,
    this.wallpaperColor,
    this.icon,
  });

  bool get isEmpty =>
      presetId == null &&
      bubbleColor == null &&
      accentColor == null &&
      wallpaperPath == null &&
      wallpaperColor == null &&
      icon == null;

  ChatStyle copyWith({
    Object? presetId = _unset,
    Object? bubbleColor = _unset,
    Object? accentColor = _unset,
    Object? wallpaperPath = _unset,
    Object? wallpaperColor = _unset,
    Object? icon = _unset,
  }) {
    return ChatStyle(
      presetId: presetId == _unset ? this.presetId : presetId as String?,
      bubbleColor: bubbleColor == _unset ? this.bubbleColor : bubbleColor as int?,
      accentColor: accentColor == _unset ? this.accentColor : accentColor as int?,
      wallpaperPath:
          wallpaperPath == _unset ? this.wallpaperPath : wallpaperPath as String?,
      wallpaperColor:
          wallpaperColor == _unset ? this.wallpaperColor : wallpaperColor as int?,
      icon: icon == _unset ? this.icon : icon as String?,
    );
  }

  /// Нишонаи «нагузошта шуд» — вагарна `null` гузоштан аз нагузоштан фарқ
  /// намекард.
  static const Object _unset = Object();

  Map<String, dynamic> toJson() => {
        if (presetId != null) 'presetId': presetId,
        if (bubbleColor != null) 'bubbleColor': bubbleColor,
        if (accentColor != null) 'accentColor': accentColor,
        if (wallpaperPath != null) 'wallpaperPath': wallpaperPath,
        if (wallpaperColor != null) 'wallpaperColor': wallpaperColor,
        if (icon != null) 'icon': icon,
      };

  factory ChatStyle.fromJson(Map<String, dynamic> json) => ChatStyle(
        presetId: json['presetId'] as String?,
        bubbleColor: (json['bubbleColor'] as num?)?.toInt(),
        accentColor: (json['accentColor'] as num?)?.toInt(),
        wallpaperPath: json['wallpaperPath'] as String?,
        wallpaperColor: (json['wallpaperColor'] as num?)?.toInt(),
        icon: json['icon'] as String?,
      );
}

/// Маҷмӯаи тайёри намуди чат.
class ChatThemePreset {
  final String id;

  /// Калиди тарҷума барои ном.
  final String nameKey;
  final Color bubble;
  final Color accent;
  final Color wallpaper;

  const ChatThemePreset({
    required this.id,
    required this.nameKey,
    required this.bubble,
    required this.accent,
    required this.wallpaper,
  });
}

/// Намуди ҳар чат — алоҳида барои ҳар сӯҳбат.
///
/// Танзимот дар ҳамин дастгоҳ нигоҳ дошта мешавад, на дар Firestore: ин
/// интихоби шахсии корбар аст, ҳамсӯҳбат онро намебинад ва барои он трафик
/// ва ҳуқуқи навиштан ба ҳуҷҷати муштарак лозим нест.
class ChatThemeController extends ChangeNotifier {
  static const String _prefsKey = 'chat_styles_v1';

  /// Калиди намуди умумӣ — он ба ҳамаи чатҳое татбиқ мешавад, ки намуди
  /// шахсии худро надоранд.
  ///
  /// Ин сатр ҳељ гоҳ ID-и чати воқеӣ шуда наметавонад: ID-и сӯҳбат
  /// `uidA_uidB` аст ва ID-и гурӯҳ аз Firestore меояд.
  static const String defaultChatId = '__default__';

  final Map<String, ChatStyle> _styles = {};

  /// Намуди умумӣ — он ки дар «Намуди зоҳирӣ» интихоб мешавад.
  ChatStyle get defaultStyle => _styles[defaultChatId] ?? const ChatStyle();

  /// Намуди чат: аввал намуди шахсии ҳамин чат, баъд намуди умумӣ.
  ChatStyle styleFor(String chatId) =>
      _styles[chatId] ?? _styles[defaultChatId] ?? const ChatStyle();

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _styles
        ..clear()
        ..addAll(decoded.map(
          (key, value) => MapEntry(
            key,
            ChatStyle.fromJson(Map<String, dynamic>.from(value as Map)),
          ),
        ));
      // Аксҳои нестшуда фаромӯш карда мешаванд — вагарна чат бо заминаи
      // холӣ мемонад.
      for (final entry in _styles.entries.toList()) {
        final path = entry.value.wallpaperPath;
        if (path != null && !File(path).existsSync()) {
          _styles[entry.key] = entry.value.copyWith(wallpaperPath: null);
        }
      }
    } catch (_) {
      // Танзимоти вайрон набояд барномаро вайрон кунад.
    }
  }

  Future<void> update(String chatId, ChatStyle style) async {
    if (style.isEmpty) {
      _styles.remove(chatId);
    } else {
      _styles[chatId] = style;
    }
    notifyListeners();
    await _save();
  }

  /// Ҳамаи танзимоти ин чатро бармегардонад.
  Future<void> reset(String chatId) => update(chatId, const ChatStyle());

  /// Аксро ба ҳофизаи барнома нусхабардорӣ карда, ҳамчун замина мегузорад.
  ///
  /// Файли аслӣ метавонад нест шавад (масалан аз кэши камера), бинобар ин
  /// нусха гирифта мешавад.
  Future<void> setWallpaperFromPath(String chatId, String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final target =
        '${dir.path}/chat_bg_${chatId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(sourcePath).copy(target);

    final previous = styleFor(chatId).wallpaperPath;
    await update(
      chatId,
      styleFor(chatId).copyWith(wallpaperPath: target, wallpaperColor: null),
    );
    // Акси кӯҳна ҷои бехударо ишғол мекунад.
    if (previous != null && previous != target) {
      try {
        await File(previous).delete();
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(_styles.map((k, v) => MapEntry(k, v.toJson()))),
      );
    } catch (_) {}
  }

  /// Маҷмӯаҳои тайёр.
  static const List<ChatThemePreset> presets = [
    ChatThemePreset(
      id: 'chatapp_neon',
      nameKey: 'k417',
      bubble: Color(0xFF00E5A0),
      accent: Color(0xFF00E5A0),
      wallpaper: Color(0xFF0A0E14),
    ),
    ChatThemePreset(
      id: 'ocean',
      nameKey: 'k418',
      bubble: Color(0xFF1E88E5),
      accent: Color(0xFF29B6F6),
      wallpaper: Color(0xFF07131F),
    ),
    ChatThemePreset(
      id: 'purple_neon',
      nameKey: 'k419',
      bubble: Color(0xFF9C4DFF),
      accent: Color(0xFFB388FF),
      wallpaper: Color(0xFF120A1C),
    ),
    ChatThemePreset(
      id: 'midnight',
      nameKey: 'k420',
      bubble: Color(0xFF3F51B5),
      accent: Color(0xFF7986CB),
      wallpaper: Color(0xFF05070F),
    ),
    ChatThemePreset(
      id: 'emerald',
      nameKey: 'k421',
      bubble: Color(0xFF2E9E6B),
      accent: Color(0xFF4CD9A0),
      wallpaper: Color(0xFF07140F),
    ),
    ChatThemePreset(
      id: 'sunset',
      nameKey: 'k422',
      bubble: Color(0xFFFF7043),
      accent: Color(0xFFFFAB91),
      wallpaper: Color(0xFF1A0E0A),
    ),
    ChatThemePreset(
      id: 'cyber_neon',
      nameKey: 'k423',
      bubble: Color(0xFF00E5FF),
      accent: Color(0xFF18FFFF),
      wallpaper: Color(0xFF060F14),
    ),
    ChatThemePreset(
      id: 'minimal_dark',
      nameKey: 'k424',
      bubble: Color(0xFF4A5568),
      accent: Color(0xFF90A4AE),
      wallpaper: Color(0xFF0D0D0D),
    ),
  ];

  static ChatThemePreset? presetById(String? id) {
    if (id == null) return null;
    for (final preset in presets) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  /// Рангҳои дастрас барои интихоби дастӣ.
  static const List<Color> palette = [
    Color(0xFF00E5A0), // ChatApp neon
    Color(0xFF00E5FF), // neon cyan
    Color(0xFF26A69A), // teal
    Color(0xFF4CAF50), // green
    Color(0xFF2E7D32), // dark green
    Color(0xFF29B6F6), // cyan
    Color(0xFF1E88E5), // blue
    Color(0xFF1A237E), // dark blue
    Color(0xFF7E57C2), // purple
    Color(0xFF9C4DFF), // violet
    Color(0xFFEC407A), // pink
    Color(0xFFE53935), // red
    Color(0xFFFB8C00), // orange
    Color(0xFF6D4C41), // brown
    Color(0xFF607D8B), // gray
  ];
}

/// Як нусхаи умумӣ — мисли контроллерҳои дигари барнома.
final chatThemeController = ChatThemeController();
