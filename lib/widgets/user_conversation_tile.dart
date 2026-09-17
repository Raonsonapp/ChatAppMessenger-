import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import '../models/app_conversation.dart';
import '../screens/user_chat_screen.dart';
import '../services/conversation_actions.dart';
import '../widgets/user_avatar.dart';
import '../widgets/unread_badge.dart';
import '../l10n/l10n.dart';
import '../utils/time_format.dart';

class UserConversationTile extends StatelessWidget {
  final AppConversation conversation;
  final String currentUid;
  const UserConversationTile({super.key, required this.conversation, required this.currentUid});

  /// Менюи дарозфишорӣ — мисли WhatsApp: мустаҳкам, бойгонӣ, хомӯш, хондашуда.
  void _showActions(BuildContext context) {
    final pinned = conversation.isPinned(currentUid);
    final archived = conversation.isArchived(currentUid);
    final muted = conversation.isMuted(currentUid);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
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
                sheetContext,
                icon: pinned ? LucideIcons.pin_off : LucideIcons.pin,
                label: pinned ? tr('k264') : tr('k263'),
                onTap: () => ConversationActions.setPinned(conversation.id, currentUid, !pinned),
              ),
              _actionTile(
                sheetContext,
                icon: archived ? LucideIcons.archive_restore : LucideIcons.archive,
                label: archived ? tr('k266') : tr('k265'),
                onTap: () => ConversationActions.setArchived(conversation.id, currentUid, !archived),
              ),
              _actionTile(
                sheetContext,
                icon: muted ? LucideIcons.bell : LucideIcons.bell_off,
                label: muted ? tr('k268') : tr('k267'),
                onTap: () => ConversationActions.setMuted(conversation.id, currentUid, !muted),
              ),
              if (conversation.unreadFor(currentUid) > 0)
                _actionTile(
                  sheetContext,
                  icon: LucideIcons.check_check,
                  label: tr('k271'),
                  onTap: () => ConversationActions.markRead(conversation.id, currentUid),
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
    required Future<void> Function() onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.neonCyan, size: 19),
      title: Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.5)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = conversation.otherName(currentUid);
    final otherUid = conversation.otherUid(currentUid);
    final unread = conversation.unreadFor(currentUid);
    final muted = conversation.isMuted(currentUid);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onLongPress: () => _showActions(context),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserChatScreen(
              conversationId: conversation.id,
              otherUserName: name,
              otherUserId: otherUid,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.glassBorder, width: 0.6)),
          ),
          child: Row(
            children: [
              UserAvatar(name: name, uid: otherUid, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15.5),
                          ),
                        ),
                        Text(
                          formatChatTime(conversation.lastMessageTime),
                          style: TextStyle(
                            color: unread > 0 ? AppColors.neonEmerald : AppColors.textSecondary.withValues(alpha: 0.7),
                            fontSize: 11.5,
                            fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage.isEmpty ? tr('k236') : conversation.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                          ),
                        ),
                        if (muted) ...[
                          const SizedBox(width: 6),
                          Icon(LucideIcons.bell_off, size: 14, color: AppColors.textSecondary),
                        ],
                        if (conversation.isPinned(currentUid)) ...[
                          const SizedBox(width: 6),
                          Icon(LucideIcons.pin, size: 14, color: AppColors.textSecondary),
                        ],
                        if (unread > 0) ...[
                          const SizedBox(width: 6),
                          UnreadBadge(count: unread),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
