import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_scope.dart';
import '../theme/app_theme.dart';

/// Як банди менюи чат.
class ChatMenuAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  /// Банде ки зермену мекушояд — бо тирча нишон дода мешавад.
  final bool hasSubmenu;

  const ChatMenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.hasSubmenu = false,
  });
}

/// Менюи сенуқтагии чат.
///
/// Ду сатҳ дорад: менюи асосӣ ва «Боз» — то рӯйхат хеле дароз нашавад.
class ChatMenuSheet extends StatelessWidget {
  const ChatMenuSheet({super.key, required this.title, required this.actions});

  final String title;
  final List<ChatMenuAction> actions;

  /// Менюро бо аниматсияи нарм мекушояд.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<ChatMenuAction> actions,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Аниматсияи кушодан — ҳамон 200–350 мс, ки тамоми барнома истифода
      // мебарад.
      builder: (_) => ChatMenuSheet(title: title, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 6),
                itemCount: actions.length,
                separatorBuilder: (_, __) =>
                    Divider(color: AppColors.glassBorder, height: 1, indent: 52),
                itemBuilder: (context, index) => _tile(context, actions[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, ChatMenuAction action) {
    final color = action.danger ? Colors.redAccent : AppColors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          action.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(
                action.icon,
                size: 19,
                color: action.danger ? Colors.redAccent : AppColors.neonCyan,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  action.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (action.hasSubmenu)
                Icon(
                  LucideIcons.chevron_right,
                  size: 17,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
