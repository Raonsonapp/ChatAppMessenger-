import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/l10n.dart';
import '../theme/app_scope.dart';
import '../theme/app_theme.dart';

/// Огоҳӣ дар бораи нокомии ҷараёни Firestore.
///
/// Бе ин хатои ҷараён ҳамчун рӯйхати ХОЛӢ нишон дода мешавад: корбар фикр
/// мекунад, ки маълумоташ гум шудааст, ҳол он ки масъала дар пайвастшавӣ ё
/// қоидаи Firestore аст. Ҳамин ҳолат дар ин лоиҳа аллакай як маротиба рӯй дод —
/// қоидаи навсозиҳо хато буд ва статусҳои ҳамаи корбарони кӯҳна «набуданд».
class StreamErrorNotice extends StatelessWidget {
  const StreamErrorNotice({super.key, this.error, this.compact = false});

  final Object? error;

  /// Ҳолати ҷамъушуда — барои ҷои танг (масалан дар корт).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);

    // Матни хатои Firestore ба корбар чизе намегӯяд, вале ҳангоми ислоҳ хеле
    // лозим аст — бинобар ин он танҳо дар debug чоп мешавад.
    if (error != null) {
      debugPrint('StreamBuilder хато дод: $error');
    }

    final text = Text(
      tr('k641'),
      textAlign: compact ? TextAlign.start : TextAlign.center,
      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(LucideIcons.cloud_off, color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 10),
            Expanded(child: text),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.cloud_off, color: AppColors.textSecondary, size: 30),
          const SizedBox(height: 12),
          text,
        ],
      ),
    );
  }
}
