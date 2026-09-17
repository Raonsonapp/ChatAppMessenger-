import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Доирачаи сабзи шумораи паёмҳои нохонда.
class UnreadBadge extends StatelessWidget {
  final int count;
  const UnreadBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.neonEmerald,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(color: AppColors.background, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}
