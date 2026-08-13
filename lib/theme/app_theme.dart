import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF060B14);
  static const Color backgroundSecondary = Color(0xFF0B121F);
  static const Color surface = Color(0xFF101826);
  static const Color glassFill = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);
  static const Color neonEmerald = Color(0xFF12F7B5);
  static const Color neonCyan = Color(0xFF22D3EE);
  static const Color textPrimary = Color(0xFFEAF2F5);
  static const Color textSecondary = Color(0xFF8A9BAE);

  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonEmerald, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.neonEmerald,
        secondary: AppColors.neonCyan,
        surface: AppColors.surface,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}
