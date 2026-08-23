import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isAI = message.isAI;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isAI)
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.neonCyan),
                    const SizedBox(width: 4),
                    Text('ChatAI', style: TextStyle(fontSize: 10, color: AppColors.neonCyan.withOpacity(0.9))),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                gradient: isMe ? AppColors.neonGradient : null,
                color: isMe ? null : AppColors.glassFill,
                border: isMe
                    ? null
                    : Border.all(color: isAI ? AppColors.neonCyan.withOpacity(0.4) : AppColors.glassBorder),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: isAI ? [BoxShadow(color: AppColors.neonCyan.withOpacity(0.15), blurRadius: 12)] : null,
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isMe ? AppColors.background : AppColors.textPrimary,
                  fontSize: 14.5,
                  height: 1.3,
                  fontWeight: isMe ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? t) {
    if (t == null) return '...';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
