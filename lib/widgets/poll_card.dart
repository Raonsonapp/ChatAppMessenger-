import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import '../l10n/l10n.dart';

/// Пурсиш дар чат — савол, вариантҳо бо фоиз ва овози худи корбар.
class PollCard extends StatelessWidget {
  final ChatMessage message;
  final String currentUid;
  final bool isMe;

  /// `null` — агар овоз додан имконнопазир бошад (масалан дар чати AI).
  final void Function(ChatMessage message, int optionIndex)? onVote;

  const PollCard({
    super.key,
    required this.message,
    required this.currentUid,
    required this.isMe,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final tint = isMe ? AppColors.background : AppColors.textPrimary;
    final total = message.pollVotes.length;
    final myVote = message.pollVotes[currentUid];

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.chart_bar, size: 14, color: tint.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(
                tr('k344'),
                style: TextStyle(
                  color: tint.withValues(alpha: 0.8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.pollQuestion ?? '',
            style: TextStyle(color: tint, fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < message.pollOptions.length; i++) ...[
            _option(i, tint, total, myVote),
            const SizedBox(height: 8),
          ],
          Text(
            trf('k345', [total]),
            style: TextStyle(color: tint.withValues(alpha: 0.75), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _option(int index, Color tint, int total, int? myVote) {
    final votes = message.pollVotes.values.where((v) => v == index).length;
    final fraction = total == 0 ? 0.0 : votes / total;
    final chosen = myVote == index;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onVote == null ? null : () => onVote!(message, index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                chosen ? LucideIcons.circle_check : LucideIcons.circle,
                size: 15,
                color: chosen ? tint : tint.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.pollOptions[index],
                  style: TextStyle(
                    color: tint,
                    fontSize: 13.5,
                    fontWeight: chosen ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              Text(
                '${(fraction * 100).round()}%',
                style: TextStyle(color: tint.withValues(alpha: 0.8), fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 4,
              backgroundColor: tint.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(tint.withValues(alpha: chosen ? 1 : 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}
