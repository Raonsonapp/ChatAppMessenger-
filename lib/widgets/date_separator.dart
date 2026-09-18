import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';

/// Ҷудокунандаи рӯз дар байни паёмҳо — «Имрӯз», «Дирӯз» ё сана.
class DateSeparator extends StatelessWidget {
  final DateTime date;
  const DateSeparator({super.key, required this.date});

  /// `true` — агар байни ду паём рӯз иваз шуда бошад.
  static bool isNewDay(DateTime? previous, DateTime? current) {
    if (current == null) return false;
    if (previous == null) return true;
    return previous.year != current.year ||
        previous.month != current.month ||
        previous.day != current.day;
  }

  static String label(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diff = today.difference(that).inDays;

    if (diff == 0) return tr('k329');
    if (diff == 1) return tr('k330');
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Text(
            label(date),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
