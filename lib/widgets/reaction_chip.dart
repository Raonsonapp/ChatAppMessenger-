import 'package:flutter/material.dart';

import '../theme/app_scope.dart';
import '../theme/app_theme.dart';

/// Ҳубобчаи вокунишҳои зери паём.
///
/// Вокуниши нав бо ҷаҳиши хурд пайдо мешавад: аз 0 то каме калонтар аз 1 ва
/// баъд ба 1 — ҳамон ҳиссиёти «часпид». Аниматсия танҳо ҳангоми ТАҒЙИР ЁФТАНИ
/// маҷмӯаи вокунишҳо иҷро мешавад, на дар ҳар кашидани рӯйхат — вагарна
/// варақ задани чат ҳубобҳои ҷаҳанда медод.
class ReactionChip extends StatefulWidget {
  const ReactionChip({super.key, required this.reactions});

  /// Вокунишҳои нотакрор, ба тартиби пайдоиш.
  final List<String> reactions;

  /// Беш аз се нишона ҳубобро калон мекунад ва паёмро мепӯшонад.
  static const int maxShown = 3;

  @override
  State<ReactionChip> createState() => _ReactionChipState();
}

class _ReactionChipState extends State<ReactionChip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 260),
    vsync: this,
  );

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    // `elasticOut` ҷаҳиши хеле шадид медиҳад; `easeOutBack` ҳамон ҳиссиёт бо
    // ҳаракати ками зиёдатӣ.
    curve: Curves.easeOutBack,
  );

  @override
  void initState() {
    super.initState();
    _controller.value = 1;
  }

  @override
  void didUpdateWidget(ReactionChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.reactions.take(ReactionChip.maxShown).join();
    final after = widget.reactions.take(ReactionChip.maxShown).join();
    if (before != after) {
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final shown = widget.reactions.take(ReactionChip.maxShown).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    final hidden = widget.reactions.length - shown.length;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(shown.join(' '), style: const TextStyle(fontSize: 12)),
            // Агар вокунишҳо зиёдтар бошанд, шумораи боқимонда нишон дода
            // мешавад — вагарна корбар фикр мекунад ки онҳо гум шудаанд.
            if (hidden > 0) ...[
              const SizedBox(width: 4),
              Text(
                '+$hidden',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
