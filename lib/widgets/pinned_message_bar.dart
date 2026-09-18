import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';

/// Панели паёми пиншуда дар болои рӯйхати паёмҳо — мисли WhatsApp.
class PinnedMessageBar extends StatelessWidget {
  final String text;
  final VoidCallback onUnpin;
  const PinnedMessageBar({super.key, required this.text, required this.onUnpin});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppColors.neonEmerald, width: 3),
          top: BorderSide(color: AppColors.glassBorder),
          right: BorderSide(color: AppColors.glassBorder),
          bottom: BorderSide(color: AppColors.glassBorder),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.pin, size: 14, color: AppColors.neonEmerald),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr('k308'),
                  style: TextStyle(color: AppColors.neonEmerald, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: tr('k309'),
            onPressed: onUnpin,
            icon: Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
