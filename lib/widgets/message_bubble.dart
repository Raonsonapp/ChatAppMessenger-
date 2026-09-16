import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../services/media_service.dart';
import 'audio_message_player.dart';
import 'video_message_player.dart';
import '../models/chat_message.dart';
import '../l10n/l10n.dart';

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
              Divider(color: AppColors.glassBorder, height: 20),
              _actionTile(
                context,
                icon: LucideIcons.corner_up_left,
                label: tr('k239'),
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call(message);
                },
              ),
              if (message.mediaUrl == null)
                _actionTile(
                  context,
                  icon: LucideIcons.copy,
                  label: tr('k240'),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: message.text));
                  },
                ),
              if (isMe)
                _actionTile(
                  context,
                  icon: LucideIcons.trash,
                  label: tr('k241'),
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
    Color? color,
  }) {
    final tint = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: tint, size: 20),
      title: Text(label, style: TextStyle(color: tint, fontWeight: FontWeight.w600, fontSize: 14)),
      onTap: onTap,
    );
  }

  /// Ҳуҷҷат: нишона, ном ва ҳаҷм. Пахш карда — дар браузер/барномаи мувофиқ.
  Widget _documentTile(BuildContext context) {
    final tint = isMe ? AppColors.background : AppColors.textPrimary;
    final size = message.mediaSize;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => launchUrl(Uri.parse(message.mediaUrl!), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: tint.withValues(alpha: 0.16),
              ),
              child: Icon(LucideIcons.file_text, color: tint, size: 19),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.mediaName ?? 'file',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tint, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  if (size != null)
                    Text(
                      MediaService.formatBytes(size),
                      style: TextStyle(color: tint.withValues(alpha: 0.8), fontSize: 11.5),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAI = message.isAI;
    final isSticker = !message.deleted && message.mediaType == 'sticker';
    final hasMedia = !message.deleted && message.mediaUrl != null;
    final hasImage = hasMedia && (message.mediaType == 'image' || message.mediaType == 'gif');
    final hasAudio = hasMedia && message.mediaType == 'audio';
    final hasVideo = hasMedia && message.mediaType == 'video';
    final hasDocument = hasMedia && message.mediaType == 'document';
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
                      Icon(LucideIcons.zap, size: 11, color: AppColors.neonCyan),
                      const SizedBox(width: 4),
                      Text('ChatAI', style: TextStyle(fontSize: 10, color: AppColors.neonCyan.withValues(alpha: 0.9))),
                    ],
                  ),
                )
              else if (!isMe && senderLabel != null && senderLabel!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 3),
                  child: Text(
                    senderLabel!,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.neonCyan.withValues(alpha: 0.85)),
                  ),
                ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: isSticker
                        ? EdgeInsets.zero
                        : hasImage
                            ? const EdgeInsets.all(4)
                            : const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: isSticker
                        ? null
                        : BoxDecoration(
                            gradient: (isMe && !message.deleted && !hasImage) ? AppColors.neonGradient : null,
                            color: (isMe && !message.deleted && !hasImage) ? null : AppColors.glassFill,
                            border: isMe
                                ? null
                                : Border.all(color: isAI ? AppColors.neonCyan.withValues(alpha: 0.4) : AppColors.glassBorder),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMe ? 18 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 18),
                            ),
                            boxShadow: isAI ? [BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.15), blurRadius: 12)] : null,
                          ),
                    child: isSticker
                        ? Text(message.text, style: const TextStyle(fontSize: 92))
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!message.deleted && message.replyToText != null && message.replyToText!.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(bottom: 6, left: hasImage ? 4 : 0, right: hasImage ? 4 : 0, top: hasImage ? 4 : 0),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(left: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.7), width: 2.5)),
                            ),
                            child: Text(
                              message.replyToText!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: (isMe && !hasImage ? AppColors.background : AppColors.textPrimary).withValues(alpha: 0.75),
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
                                  child: CircularProgressIndicator(color: AppColors.neonEmerald, strokeWidth: 2),
                                );
                              },
                              errorBuilder: (context, error, stack) => Container(
                                width: 220,
                                height: 120,
                                alignment: Alignment.center,
                                child: Icon(LucideIcons.triangle_alert, color: AppColors.textSecondary),
                              ),
                            ),
                          ),
                        if (hasAudio)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
                            child: AudioMessagePlayer(
                              url: message.mediaUrl!,
                              isMe: isMe,
                              durationSeconds: message.mediaDuration,
                            ),
                          ),
                        if (hasVideo)
                          Padding(
                            padding: const EdgeInsets.all(3),
                            child: VideoMessagePlayer(url: message.mediaUrl!),
                          ),
                        if (hasDocument)
                          _documentTile(context),
                        if (message.text.isNotEmpty || message.deleted)
                          Padding(
                            padding: hasImage ? const EdgeInsets.fromLTRB(8, 6, 8, 4) : EdgeInsets.zero,
                            child: Text(
                              message.deleted ? tr('k242') : message.text,
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
                      style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 10),
                    ),
                    if (isMe && !isAI && showReadReceipts) ...[
                      const SizedBox(width: 3),
                      _buildReadReceipt(),
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

  /// Feather надорад иконаи "ду галочка"-и WhatsApp — бо ду
  /// LucideIcons.check-и рӯйиҳамафтода шабеҳсозӣ мешавад.
  Widget _buildReadReceipt() {
    final color = message.read ? AppColors.neonEmerald : AppColors.textSecondary.withValues(alpha: 0.6);
    if (!message.read) {
      return Icon(LucideIcons.check, size: 13, color: color);
    }
    return SizedBox(
      width: 16,
      height: 13,
      child: Stack(
        children: [
          Icon(LucideIcons.check, size: 13, color: color),
          Positioned(left: 4, child: Icon(LucideIcons.check, size: 13, color: color)),
        ],
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
