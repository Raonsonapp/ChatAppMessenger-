import 'package:flutter/material.dart';

/// Шакли матни статус: заминаи ранга, ҳарф ва ҷойгиршавӣ.
///
/// Дар ҳуҷҷати статус ҳамчун се рақами хурд нигоҳ дошта мешавад — на ҳамчун
/// ранги омода. Ин маънои онро дорад, ки палитраро баъдтар иваз карда
/// метавонем ва статусҳои кӯҳна вайрон намешаванд.
class StatusStyle {
  const StatusStyle({this.background = 0, this.font = 0, this.align = 1, this.frame = 0, this.effect = 0});

  final int background;
  final int font;

  /// 0 — чап, 1 — марказ, 2 — рост.
  final int align;
  final int frame;
  final int effect;

  StatusStyle copyWith({int? background, int? font, int? align, int? frame, int? effect}) => StatusStyle(
        background: background ?? this.background,
        font: font ?? this.font,
        align: align ?? this.align,
        frame: frame ?? this.frame,
        effect: effect ?? this.effect,
      );

  Map<String, dynamic> toMap() => {
        'styleBackground': background,
        'styleFont': font,
        'styleAlign': align,
        'styleFrame': frame,
        'styleEffect': effect,
      };

  factory StatusStyle.fromMap(Map<String, dynamic> data) {
    return StatusStyle(
      background: _clamp(data['styleBackground'], backgrounds.length),
      font: _clamp(data['styleFont'], fonts.length),
      align: _clamp(data['styleAlign'], 3, fallback: 1),
      frame: _clamp(data['styleFrame'], 4),
      effect: _clamp(data['styleEffect'], 4),
    );
  }

  /// Рақами нодуруст ё берун аз ҳудуд набояд экранро вайрон кунад.
  static int _clamp(Object? raw, int length, {int fallback = 0}) {
    final value = raw is int ? raw : (raw is num ? raw.toInt() : null);
    if (value == null || value < 0 || value >= length) return fallback;
    return value;
  }

  /// Заминаҳо. Аввалин — градиенти худи ChatApp, то статусҳои кӯҳна ҳамон
  /// тавре бинмоянд, ки буданд.
  static const List<List<Color>> backgrounds = [
    [Color(0xFF00E5A0), Color(0xFF00B4D8)],
    [Color(0xFF1A1A2E), Color(0xFF16213E)],
    [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    [Color(0xFF7B2FF7), Color(0xFFF107A3)],
    [Color(0xFF0F3443), Color(0xFF34E89E)],
    [Color(0xFFFFD166), Color(0xFFEF476F)],
    [Color(0xFF2193B0), Color(0xFF6DD5ED)],
    [Color(0xFF232526), Color(0xFF414345)],
    [Color(0xFF654EA3), Color(0xFFEAAFC8)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    // Ду заминаи равшан — дар онҳо матн торик мешавад (ниг. `textColor`).
    [Color(0xFFFDFBF7), Color(0xFFE8E2D5)],
    [Color(0xFFFFE29F), Color(0xFFFFD1A4)],
  ];

  static const List<String> fontNames = ['Classic', 'Bold', 'Serif', 'Light'];

  /// Услуби ҳарф. Танҳо хосиятҳои дохилии Flutter истифода мешаванд — файли
  /// шрифти иловагӣ ба барнома вазн зам намекунад.
  static const List<TextStyle> fonts = [
    TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
    TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
    TextStyle(fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, letterSpacing: 0.2),
    TextStyle(fontWeight: FontWeight.w400, letterSpacing: 1.2),
  ];

  Color? get frameColor => switch (frame) {
        1 => Colors.white,
        2 => const Color(0xFF00E5A0),
        3 => const Color(0xFFF107A3),
        _ => null,
      };

  ColorFilter? get imageFilter => switch (effect) {
        1 => const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ]),
        2 => const ColorFilter.matrix(<double>[
            1.08, 0.04, 0.02, 0, 8,
            0.03, 1.02, 0.01, 0, 4,
            0.01, 0.02, 0.88, 0, 0,
            0, 0, 0, 1, 0,
          ]),
        3 => const ColorFilter.matrix(<double>[
            0.85, 0.02, 0.08, 0, 0,
            0.02, 0.95, 0.08, 0, 0,
            0.08, 0.12, 1.12, 0, 8,
            0, 0, 0, 1, 0,
          ]),
        _ => null,
      };

  LinearGradient get gradient => LinearGradient(
        colors: backgrounds[background],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  TextAlign get textAlign => switch (align) {
        0 => TextAlign.left,
        2 => TextAlign.right,
        _ => TextAlign.center,
      };

  /// Ранги матн аз равшании замина ҳисоб мешавад — вагарна дар заминаи равшан
  /// матни сафед нахонда мемонад.
  Color get textColor {
    final colors = backgrounds[background];
    final luminance =
        (colors.first.computeLuminance() + colors.last.computeLuminance()) / 2;
    return luminance > 0.5 ? const Color(0xFF10131A) : Colors.white;
  }

  /// Матни дароз бояд хурдтар шавад, вагарна аз экран мебарояд.
  double fontSizeFor(String text, {double base = 26}) {
    final length = text.characters.length;
    if (length <= 40) return base;
    if (length <= 90) return base * 0.78;
    if (length <= 160) return base * 0.62;
    return base * 0.5;
  }

  TextStyle textStyleFor(String text, {double base = 26}) {
    return fonts[font].copyWith(
      color: textColor,
      fontSize: fontSizeFor(text, base: base),
      height: 1.25,
    );
  }
}
