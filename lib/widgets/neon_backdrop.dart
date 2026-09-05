import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NeonBackdrop extends StatelessWidget {
  final Widget child;
  const NeonBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, AppColors.backgroundSecondary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(top: -80, left: -60, child: _blurCircle(AppColors.neonEmerald.withValues(alpha: 0.25), 220)),
        Positioned(bottom: -100, right: -70, child: _blurCircle(AppColors.neonCyan.withValues(alpha: 0.20), 260)),
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _blurCircle(Color color, double size) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
