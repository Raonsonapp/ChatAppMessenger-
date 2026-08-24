import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final ValueChanged<ChatMessage>? onReply;
  final ValueChanged<ChatMessage>? onDelete;
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onDelete,
  });

  void _showActions(BuildContext context) {
    if (message.deleted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionTile(
                context,
                icon: Icons.reply_rounded,
                label: 'Ҷавоб додан',
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call(message);
                },
              ),
              _actionTile(
                context,
                icon: Icons.copy_rounded,
                label: 'Нусхабардорӣ',
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.text));
                },
              ),
              if (isMe)
                _actionTile(
                  context,
                  icon: Icons.delete_outline_rounded,
                  label: 'Нест кардан',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    onDelete?.call(message);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.textPrimary,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAI = message.isAI;

    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Align(
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
                  gradient: (isMe && !message.deleted) ? AppColors.neonGradient : null,
                  color: (isMe && !message.deleted) ? null : AppColors.glassFill,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!message.deleted && message.replyToText != null && message.replyToText!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(left: BorderSide(color: AppColors.neonCyan.withOpacity(0.7), width: 2.5)),
                        ),
                        child: Text(
                          message.replyToText!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: (isMe ? AppColors.background : AppColors.textPrimary).withOpacity(0.75),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    Text(
                      message.deleted ? 'Паём нест карда шуд' : message.text,
                      style: TextStyle(
                        color: isMe ? AppColors.background : AppColors.textPrimary,
                        fontSize: 14.5,
                        height: 1.3,
                        fontStyle: message.deleted ? FontStyle.italic : FontStyle.normal,
                        fontWeight: isMe ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 10),
                    ),
                    if (isMe && !isAI) ...[
                      const SizedBox(width: 3),
                      Icon(
                        message.read ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 13,
                        color: message.read ? AppColors.neonEmerald : AppColors.textSecondary.withOpacity(0.6),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
