import 'package:flutter/material.dart';

import '../services/plus_service.dart';
import '../theme/app_scope.dart';
import '../theme/app_theme.dart';

/// Нишони ChatApp Plus ва нишони Соҳиб.
///
/// Тарҳи ChatApp: ситорачаи чоршоха (✦) барои Plus ва тоҷ барои соҳиб. Ин
/// махсус ба тасдиқи кабуди шабакаҳои дигар монанд нест — он чизи дигар
/// маъно дорад ва омехта кардани онҳо корбарро гумроҳ мекунад.
class PlusBadge extends StatelessWidget {
  const PlusBadge({super.key, required this.status, this.compact = false});

  final PlusStatus status;

  /// Ҳолати ҷамъушуда — танҳо нишона, бе матн (барои назди ном дар рӯйхат).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    if (!status.active) return const SizedBox.shrink();

    final owner = status.isOwner;
    final color = owner ? const Color(0xFFFFC857) : AppColors.neonCyan;
    final symbol = owner ? '♛' : '✦';
    final label = owner ? 'OWNER' : 'PLUS';

    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(left: 5),
        child: Text(
          symbol,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symbol,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}
