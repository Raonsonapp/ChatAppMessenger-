import 'package:flutter/material.dart';

import 'page_transitions.dart';

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
  // Рангҳои иловагӣ барои ҳолатҳои занг (WhatsApp-услуб): сабз барои
  // занги воридотӣ/баровардашуда, сурх барои занги аз даст рафта.
  final Color callGreen;
  final Color missedRed;

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
    this.callGreen = const Color(0xFF25D366),
    this.missedRed = const Color(0xFFF15C6D),
  });
}

// Мавзӯи торик — услуби WhatsApp: замина қариб сиёҳ, сатҳҳои хокистарии
// тира (charcoal), ранги асосии кабуд (на сабз/cyan-и неон).
const AppPalette darkPalette = AppPalette(
  brightness: Brightness.dark,
  background: Color(0xFF0B141A),
  backgroundSecondary: Color(0xFF111B21),
  surface: Color(0xFF1F2C34),
  glassFill: Color(0x14FFFFFF),
  glassBorder: Color(0x1FFFFFFF),
  // Ду тобиши кабуд (на сабз) — барои градиенти FAB/avatar ва лаҳзаҳои
  // таъкидшаванда истифода мешаванд.
  neonEmerald: Color(0xFF4FA3F7),
  neonCyan: Color(0xFF1C77F2),
  textPrimary: Color(0xFFE9EDEF),
  textSecondary: Color(0xFF8696A0),
  callGreen: Color(0xFF25D366),
  missedRed: Color(0xFFF15C6D),
);

/// Дар мавзӯи равшан рангҳо торитар карда шудаанд, вагарна онҳо дар
/// заминаи сафед хонда намешаванд (контрасти нокифоя).
const AppPalette lightPalette = AppPalette(
  brightness: Brightness.light,
  background: Color(0xFFF4F7FA),
  backgroundSecondary: Color(0xFFE9EFF5),
  surface: Color(0xFFFFFFFF),
  glassFill: Color(0x0F000000),
  glassBorder: Color(0x1F000000),
  neonEmerald: Color(0xFF2E86E8),
  neonCyan: Color(0xFF0B63C5),
  textPrimary: Color(0xFF0B1220),
  textSecondary: Color(0xFF5B6B7C),
  callGreen: Color(0xFF1FA855),
  missedRed: Color(0xFFD23C4F),
);

// Мавзӯҳои "контрасти баланд" — барои "Имкониятҳои дастрасӣ" дар танзимот.
// Сиёҳу сафеди пурра (на хокистарии тира) ва матни бе шаффофият, то ҳарф
// ва тугмаҳо то ҳадди имкон равшан ва хонданӣ бошанд.
const AppPalette darkHighContrastPalette = AppPalette(
  brightness: Brightness.dark,
  background: Color(0xFF000000),
  backgroundSecondary: Color(0xFF000000),
  surface: Color(0xFF000000),
  glassFill: Color(0x26FFFFFF),
  glassBorder: Color(0x4DFFFFFF),
  neonEmerald: Color(0xFF6FB8FF),
  neonCyan: Color(0xFF3FA0FF),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFFE4E4E4),
  callGreen: Color(0xFF3FE07A),
  missedRed: Color(0xFFFF7A86),
);

const AppPalette lightHighContrastPalette = AppPalette(
  brightness: Brightness.light,
  background: Color(0xFFFFFFFF),
  backgroundSecondary: Color(0xFFFFFFFF),
  surface: Color(0xFFFFFFFF),
  glassFill: Color(0x26000000),
  glassBorder: Color(0x4D000000),
  neonEmerald: Color(0xFF0B63C5),
  neonCyan: Color(0xFF07407D),
  textPrimary: Color(0xFF000000),
  textSecondary: Color(0xFF262626),
  callGreen: Color(0xFF0E7A36),
  missedRed: Color(0xFFA8102A),
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
  static Color get callGreen => _palette.callGreen;
  static Color get missedRed => _palette.missedRed;

  /// Якҷо кардани мавзӯи торик/равшан бо парчами контрасти баланд — аз
  /// `main.dart` даъват мешавад, ҳар вақте ки ThemeController ё
  /// AccessibilityController тағйир меёбанд, то ҳеҷ кадоме аз ин ду якдигарро
  /// рад накунад.
  static void applyFlags({required bool isDark, required bool highContrast}) {
    if (highContrast) {
      _palette = isDark ? darkHighContrastPalette : lightHighContrastPalette;
    } else {
      _palette = isDark ? darkPalette : lightPalette;
    }
  }

  /// Ранги асосии амалҳо (тугмаи интихобшудаи навигатсия, фиристодан,
  /// пайвандҳо) — WhatsApp-услуб кабуд.
  static Color get accent => _palette.neonCyan;

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
      // Ҳамаи экранҳо бо як гузариши нарм кушода мешаванд.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static ThemeData get darkTheme => _build(darkPalette);
  static ThemeData get lightTheme => _build(lightPalette);
}
