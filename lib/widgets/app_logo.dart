import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.neonGradient,
        boxShadow: [
          BoxShadow(color: AppColors.neonEmerald.withOpacity(0.5), blurRadius: 16, spreadRadius: 0.5),
        ],
      ),
      child: Icon(Icons.bolt_rounded, color: AppColors.background, size: size * 0.6),
    );
  }
}
