import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String currentUid;
  final String? senderLabel;
  final bool showReadReceipts;
  final ValueChanged<ChatMessage>? onReply;
  final ValueChanged<ChatMessage>? onDelete;
  final void Function(ChatMessage message, String emoji)? onReact;
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUid,
    this.senderLabel,
    this.showReadReceipts = true,
    this.onReply,
    this.onDelete,
    this.onReact,
  });

  static const List<String> _quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

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
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _quickReactions.map((emoji) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.pop(context);
                      onReact?.call(message, emoji);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
              const Divider(color: AppColors.glassBorder, height: 20),
              _actionTile(
                context,
                icon: Icons.reply_rounded,
                label: 'Ҷавоб додан',
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call(message);
                },
              ),
              if (message.mediaUrl == null)
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
    final hasImage = !message.deleted && message.mediaUrl != null && message.mediaType == 'image';
    final distinctReactions = message.reactions.values.toSet().toList();

    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
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
                )
              else if (!isMe && senderLabel != null && senderLabel!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 3),
                  child: Text(
                    senderLabel!,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.neonCyan.withOpacity(0.85)),
                  ),
                ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: hasImage
                        ? const EdgeInsets.all(4)
                        : const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: (isMe && !message.deleted && !hasImage) ? AppColors.neonGradient : null,
                      color: (isMe && !message.deleted && !hasImage) ? null : AppColors.glassFill,
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
                            margin: EdgeInsets.only(bottom: 6, left: hasImage ? 4 : 0, right: hasImage ? 4 : 0, top: hasImage ? 4 : 0),
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
                                color: (isMe && !hasImage ? AppColors.background : AppColors.textPrimary).withOpacity(0.75),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        if (hasImage)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              message.mediaUrl!,
                              width: 220,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  width: 220,
                                  height: 220,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(color: AppColors.neonEmerald, strokeWidth: 2),
                                );
                              },
                              errorBuilder: (context, error, stack) => Container(
                                width: 220,
                                height: 120,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image_rounded, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        if (message.text.isNotEmpty || message.deleted)
                          Padding(
                            padding: hasImage ? const EdgeInsets.fromLTRB(8, 6, 8, 4) : EdgeInsets.zero,
                            child: Text(
                              message.deleted ? 'Паём нест карда шуд' : message.text,
                              style: TextStyle(
                                color: (isMe && !hasImage) ? AppColors.background : AppColors.textPrimary,
                                fontSize: 14.5,
                                height: 1.3,
                                fontStyle: message.deleted ? FontStyle.italic : FontStyle.normal,
                                fontWeight: (isMe && !hasImage) ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (distinctReactions.isNotEmpty)
                    Positioned(
                      bottom: -10,
                      right: isMe ? 6 : null,
                      left: isMe ? null : 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Text(
                          distinctReactions.take(3).join(' '),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 10),
                    ),
                    if (isMe && !isAI && showReadReceipts) ...[
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
