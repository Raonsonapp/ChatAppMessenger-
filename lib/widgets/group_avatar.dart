import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';

/// Акси гурӯҳ ё ҷамъият бо бозгашт ба нишонаи одамон.
class GroupAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;
  final IconData icon;
  const GroupAvatar({
    super.key,
    this.photoUrl,
    this.size = 52,
    this.icon = LucideIcons.users,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(icon, color: AppColors.textSecondary, size: size * 0.42),
            )
          : Icon(icon, color: AppColors.textSecondary, size: size * 0.42),
    );
  }
}
