import 'package:flutter/material.dart';

/// Маҷмӯи рангҳои як мавзӯъ.
class AppPalette {
  final Brightness brightness;
  final Color background;
  final Color backgroundSecondary;
  final Color surface;
  final Color glassFill;
  final Color glassBorder;
  final Color neonEmerald;
  final Color neonCyan;
  final Color textPrimary;
  final Color textSecondary;

  const AppPalette({
    required this.brightness,
    required this.background,
    required this.backgroundSecondary,
    required this.surface,
    required this.glassFill,
    required this.glassBorder,
    required this.neonEmerald,
    required this.neonCyan,
    required this.textPrimary,
    required this.textSecondary,
  });
}

const AppPalette darkPalette = AppPalette(
  brightness: Brightness.dark,
  background: Color(0xFF060B14),
  backgroundSecondary: Color(0xFF0B121F),
  surface: Color(0xFF101826),
  glassFill: Color(0x14FFFFFF),
  glassBorder: Color(0x26FFFFFF),
  neonEmerald: Color(0xFF12F7B5),
  neonCyan: Color(0xFF22D3EE),
  textPrimary: Color(0xFFEAF2F5),
  textSecondary: Color(0xFF8A9BAE),
);

/// Дар мавзӯи равшан рангҳои неон торитар карда шудаанд, вагарна онҳо дар
/// заминаи сафед хонда намешаванд (контрасти нокифоя).
const AppPalette lightPalette = AppPalette(
  brightness: Brightness.light,
  background: Color(0xFFF4F7FA),
  backgroundSecondary: Color(0xFFE9EFF5),
  surface: Color(0xFFFFFFFF),
  glassFill: Color(0x0F000000),
  glassBorder: Color(0x1F000000),
  neonEmerald: Color(0xFF00A97E),
  neonCyan: Color(0xFF0E8CA8),
  textPrimary: Color(0xFF0B1220),
  textSecondary: Color(0xFF5B6B7C),
);

/// Рангҳои мавзӯи фаъол.
///
/// Инҳо getter-анд, на `const` — то мавзӯъ ҳангоми кор иваз шавад. Барои ҳамин
/// ҳар ҷое ки ин рангҳо истифода мешаванд, виҷет `const` шуда наметавонад.
class AppColors {
  static AppPalette _palette = darkPalette;

  static AppPalette get palette => _palette;
  static set palette(AppPalette value) => _palette = value;

  static bool get isDark => _palette.brightness == Brightness.dark;

  static Color get background => _palette.background;
  static Color get backgroundSecondary => _palette.backgroundSecondary;
  static Color get surface => _palette.surface;
  static Color get glassFill => _palette.glassFill;
  static Color get glassBorder => _palette.glassBorder;
  static Color get neonEmerald => _palette.neonEmerald;
  static Color get neonCyan => _palette.neonCyan;
  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;

  static LinearGradient get neonGradient => LinearGradient(
        colors: [neonEmerald, neonCyan],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class AppTheme {
  static ThemeData _build(AppPalette p) {
    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.background,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme(
        brightness: p.brightness,
        primary: p.neonEmerald,
        onPrimary: p.brightness == Brightness.dark ? p.background : Colors.white,
        secondary: p.neonCyan,
        onSecondary: p.brightness == Brightness.dark ? p.background : Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: p.surface,
        onSurface: p.textPrimary,
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: p.textPrimary),
      ),
    );
  }

  static ThemeData get darkTheme => _build(darkPalette);
  static ThemeData get lightTheme => _build(lightPalette);
}
