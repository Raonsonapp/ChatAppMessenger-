import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/app_group.dart';
import '../screens/group_chat_screen.dart';
import '../l10n/l10n.dart';
import '../utils/time_format.dart';
import 'unread_badge.dart';
import 'group_avatar.dart';

class GroupTile extends StatelessWidget {
  final AppGroup group;

  /// Барои нишон додани шумораи нохондашуда маҳз барои ҳамин корбар.
  final String? currentUid;
  const GroupTile({super.key, required this.group, this.currentUid});

  @override
  Widget build(BuildContext context) {
    final unread = currentUid == null ? 0 : group.unreadFor(currentUid!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(
              groupId: group.id,
              groupName: group.name,
              memberNames: group.memberNames,
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
              GroupAvatar(photoUrl: group.photoUrl, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15.5),
                          ),
                        ),
                        Text(
                          formatChatTime(group.lastMessageTime),
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
                            group.lastMessage.isEmpty ? tr('k238') : group.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                          ),
                        ),
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
