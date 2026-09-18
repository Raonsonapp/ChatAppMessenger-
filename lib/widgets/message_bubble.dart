import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../services/media_service.dart';
import '../services/star_service.dart';
import 'audio_message_player.dart';
import 'video_message_player.dart';
import '../models/chat_message.dart';
import '../l10n/l10n.dart';
import '../sheets/forward_sheet.dart';
import '../screens/image_viewer_screen.dart';
import '../theme/text_scale_controller.dart';
import 'poll_card.dart';
import '../theme/app_scope.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String currentUid;
  final String? senderLabel;
  final bool showReadReceipts;
  final ValueChanged<ChatMessage>? onReply;
  final ValueChanged<ChatMessage>? onDelete;

  /// Нест кардан танҳо барои худам — паём дар тарафи ҳамсӯҳбат мемонад.
  final ValueChanged<ChatMessage>? onDeleteForMe;

  /// Тағйир додани матни паёми худам.
  final void Function(ChatMessage message, String newText)? onEdit;

  /// «Ҷавоби шахсӣ» — танҳо дар гурӯҳ ва ҷамъият маънӣ дорад.
  final ValueChanged<ChatMessage>? onReplyPrivately;

  /// Овоз додан дар пурсиш.
  final void Function(ChatMessage message, int optionIndex)? onVote;

  /// Пин кардани паём дар болои чат.
  final ValueChanged<ChatMessage>? onPin;

  /// Танҳо барои охирин паём фаъол мешавад — паёми нав нарм пайдо мешавад.
  final bool animateIn;

  /// Паёми пешина аз ҳамон шахс ва дар ҳамон дақиқаҳо буд — он гоҳ паёмҳо
  /// ба ҳам наздиктар кашида мешаванд ва номи фиристанда такрор намешавад.
  final bool grouped;

  /// Ҳолати интихоби гурӯҳии паёмҳо.
  final bool selectionActive;
  final bool selected;
  final ValueChanged<ChatMessage>? onSelectToggle;
  final void Function(ChatMessage message, String emoji)? onReact;

  /// Ҳуҷҷати худи паём — барои ситорадор кардан лозим аст.
  final DocumentReference<Map<String, dynamic>>? messageRef;

  /// Номи чат — дар рӯйхати паёмҳои ситорадор нишон дода мешавад.
  final String? chatTitle;
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUid,
    this.senderLabel,
    this.showReadReceipts = true,
    this.onReply,
    this.onDelete,
    this.onDeleteForMe,
    this.onEdit,
    this.onReplyPrivately,
    this.onPin,
    this.onVote,
    this.animateIn = false,
    this.grouped = false,
    this.selectionActive = false,
    this.selected = false,
    this.onSelectToggle,
    this.onReact,
    this.messageRef,
    this.chatTitle,
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
              _actionTile(
                context,
                icon: LucideIcons.corner_up_right,
                label: tr('k256'),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => ForwardSheet(message: message),
                  );
                },
              ),
              if (!isMe && onReplyPrivately != null)
                _actionTile(
                  context,
                  icon: LucideIcons.message_circle,
                  label: tr('k304'),
                  onTap: () {
                    Navigator.pop(context);
                    onReplyPrivately?.call(message);
                  },
                ),
              if (onSelectToggle != null)
                _actionTile(
                  context,
                  icon: LucideIcons.check_check,
                  label: tr('k331'),
                  onTap: () {
                    Navigator.pop(context);
                    onSelectToggle?.call(message);
                  },
                ),
              if (onPin != null)
                _actionTile(
                  context,
                  icon: LucideIcons.pin,
                  label: tr('k307'),
                  onTap: () {
                    Navigator.pop(context);
                    onPin?.call(message);
                  },
                ),
              if (messageRef != null) _starTile(context),
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
              if (isMe && _canEdit)
                _actionTile(
                  context,
                  icon: LucideIcons.pencil,
                  label: tr('k274'),
                  onTap: () {
                    Navigator.pop(context);
                    _promptEdit(context);
                  },
                ),
              if (onDeleteForMe != null)
                _actionTile(
                  context,
                  icon: LucideIcons.eye_off,
                  label: tr('k275'),
                  onTap: () {
                    Navigator.pop(context);
                    onDeleteForMe?.call(message);
                  },
                ),
              if (isMe)
                _actionTile(
                  context,
                  icon: LucideIcons.trash,
                  label: onDeleteForMe == null ? tr('k241') : tr('k276'),
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

  /// Матнро танҳо дар 15 дақиқаи аввал тағйир додан мумкин аст — ҳамон
  /// маҳдудияте, ки WhatsApp дорад.
  bool get _canEdit {
    if (onEdit == null || message.mediaUrl != null || message.text.isEmpty) return false;
    final sentAt = message.timestamp;
    if (sentAt == null) return true;
    return DateTime.now().difference(sentAt) < const Duration(minutes: 15);
  }

  void _promptEdit(BuildContext context) {
    final controller = TextEditingController(text: message.text);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr('k274'), style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          minLines: 1,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr('k277'), style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(dialogContext);
              if (text.isNotEmpty && text != message.text) onEdit?.call(message, text);
            },
            child: Text(tr('k117'), style: TextStyle(color: AppColors.neonEmerald)),
          ),
        ],
      ),
    );
  }

  /// Тугмаи ситора — навиштаҷот вобаста ба он ки паём аллакай ситорадор аст.
  Widget _starTile(BuildContext context) {
    final ref = messageRef!;
    return FutureBuilder<bool>(
      future: StarService.isStarred(ref),
      builder: (context, snapshot) {
        final starred = snapshot.data ?? false;
        return _actionTile(
          context,
          icon: starred ? LucideIcons.star_off : LucideIcons.star,
          label: starred ? tr('k259') : tr('k258'),
          onTap: () async {
            Navigator.pop(context);
            final now = await StarService.toggle(
              messageRef: ref,
              message: message,
              chatTitle: chatTitle ?? '',
            );
            if (now && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k262'))));
            }
          },
        );
      },
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
  /// Корти ҷойгиршавӣ — бо зер кардан харита кушода мешавад.
  Widget _locationTile(BuildContext context) {
    final tint = isMe ? AppColors.background : AppColors.textPrimary;
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
              child: Icon(LucideIcons.map_pin, color: tint, size: 19),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr('k285'),
                    style: TextStyle(color: tint, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    tr('k287'),
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
    AppScope.watch(context);
    final isAI = message.isAI;
    final isSticker = !message.deleted && message.mediaType == 'sticker';
    final hasMedia = !message.deleted && message.mediaUrl != null;
    final hasImage = hasMedia && (message.mediaType == 'image' || message.mediaType == 'gif');
    final hasAudio = hasMedia && message.mediaType == 'audio';
    final hasVideo = hasMedia && message.mediaType == 'video';
    final hasDocument = hasMedia && message.mediaType == 'document';
    final hasLocation = hasMedia && message.mediaType == 'location';
    final hasPoll = !message.deleted && message.mediaType == 'poll';
    final distinctReactions = message.reactions.values.toSet().toList();

    // Кашидан ба рост — ҷавоб додан, ҳамон ишораи WhatsApp. `confirmDismiss`
    // ҳамеша `false` бармегардонад, бинобар ин паём нест намешавад — танҳо
    // ба ҳолати аввал бармегардад.
    final bubble = _buildSwipeable(context, isMe, isAI, isSticker, hasImage, hasAudio,
        hasVideo, hasDocument, hasLocation, hasPoll, distinctReactions);
    if (!animateIn) return bubble;

    // Паёми нав нарм пайдо мешавад: каме аз поён ва бо шаффофият.
    return TweenAnimationBuilder<double>(
      key: ValueKey('in_${message.id}'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child),
        );
      },
      child: bubble,
    );
  }

  Widget _buildSwipeable(
    BuildContext context,
    bool isMe,
    bool isAI,
    bool isSticker,
    bool hasImage,
    bool hasAudio,
    bool hasVideo,
    bool hasDocument,
    bool hasLocation,
    bool hasPoll,
    List<String> distinctReactions,
  ) {
    return Dismissible(
      key: ValueKey('swipe_${message.id}'),
      // Ҳангоми интихоби гурӯҳӣ кашидан хомӯш аст — вагарна интихоб кардан
      // ва ҷавоб додан бо ҳам омехта мешаванд.
      direction: (onReply == null || message.deleted || selectionActive)
          ? DismissDirection.none
          : DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.25},
      confirmDismiss: (_) async {
        onReply?.call(message);
        return false;
      },
      background: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Icon(LucideIcons.corner_up_left, color: AppColors.textSecondary, size: 18),
        ),
      ),
      child: GestureDetector(
      // Дар ҳолати интихоб дарозфишорӣ низ интихобро иваз мекунад; вагарна
      // менюи паём кушода мешавад (интихоб аз ҳамон ҷо оғоз мешавад).
      onLongPress: () =>
          selectionActive ? onSelectToggle?.call(message) : _showActions(context),
      onTap: selectionActive ? () => onSelectToggle?.call(message) : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          margin: EdgeInsets.symmetric(vertical: grouped ? 1.5 : 5),
          padding: selected ? const EdgeInsets.all(4) : EdgeInsets.zero,
          decoration: selected
              ? BoxDecoration(
                  color: AppColors.neonEmerald.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
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
              else if (!isMe && !grouped && senderLabel != null && senderLabel!.isNotEmpty)
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
                        ? Text(message.text, style: TextStyle(fontSize: 92 * textScaleController.scale))
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
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ImageViewerScreen(
                                  url: message.mediaUrl!,
                                  title: senderLabel ?? chatTitle,
                                ),
                              ),
                            ),
                            child: ClipRRect(
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
                          ),
                        if (message.forwarded && !message.deleted)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.corner_up_right,
                                  size: 11,
                                  color: (isMe && !hasImage ? AppColors.background : AppColors.textSecondary)
                                      .withValues(alpha: 0.75),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tr('k257'),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontStyle: FontStyle.italic,
                                    color: (isMe && !hasImage ? AppColors.background : AppColors.textSecondary)
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
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
                        if (hasLocation)
                          _locationTile(context),
                        if (hasPoll)
                          PollCard(
                            message: message,
                            currentUid: currentUid,
                            isMe: isMe,
                            onVote: onVote,
                          ),
                        if (message.text.isNotEmpty || message.deleted)
                          Padding(
                            padding: hasImage ? const EdgeInsets.fromLTRB(8, 6, 8, 4) : EdgeInsets.zero,
                            child: Text(
                              message.deleted ? tr('k242') : message.text,
                              style: TextStyle(
                                color: (isMe && !hasImage) ? AppColors.background : AppColors.textPrimary,
                                fontSize: 14.5 * textScaleController.scale,
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
                    if (message.edited) ...[
                      Text(
                        tr('k278'),
                        style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 10),
                      ),
                      const SizedBox(width: 4),
                    ],
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
