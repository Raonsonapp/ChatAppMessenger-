import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ҳолати холӣ — нишона дар доираи мулоим, сарлавҳа ва тавзеҳ.
///
/// Пештар ҳар экран холигиро бо як сатри хокистарӣ нишон медод; ин виҷет ҳама
/// ҷо як намуди ягона медиҳад.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;

  /// Тугмаи ихтиёрӣ — масалан «Чати нав».
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonEmerald.withValues(alpha: 0.10),
                border: Border.all(color: AppColors.neonEmerald.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: AppColors.neonEmerald, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonEmerald,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
