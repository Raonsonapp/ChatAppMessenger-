import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';

/// Истифода мешавад ҳамчун Scaffold.floatingActionButton бо
/// floatingActionButtonLocation: endFloat (кунҷи поёни рост), мисли WhatsApp.
class NeonFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  const NeonFab({super.key, required this.onPressed, this.icon = LucideIcons.plus});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.neonGradient,
        boxShadow: [
          BoxShadow(color: AppColors.neonEmerald.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 1),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(icon, color: AppColors.background, size: 26),
        ),
      ),
    );
  }
}
