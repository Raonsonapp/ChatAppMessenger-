import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import '../models/app_community.dart';
import '../screens/community_chat_screen.dart';
import '../l10n/l10n.dart';
import '../l10n/media_preview.dart';
import '../utils/time_format.dart';
import 'group_avatar.dart';
import 'unread_badge.dart';
import '../theme/app_scope.dart';

class CommunityTile extends StatelessWidget {
  final AppCommunity community;

  /// Барои нишон додани шумораи нохондашуда маҳз барои ҳамин корбар.
  final String? currentUid;
  const CommunityTile({super.key, required this.community, this.currentUid});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final unread = currentUid == null ? 0 : community.unreadFor(currentUid!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommunityChatScreen(
              communityId: community.id,
              communityName: community.name,
              memberNames: community.memberNames,
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
              GroupAvatar(photoUrl: community.photoUrl, size: 52, icon: LucideIcons.hash),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            community.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15.5),
                          ),
                        ),
                        Text(
                          formatChatTime(community.lastMessageTime),
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
                            community.lastMessage.isEmpty
                                ? trf('k051', [community.members.length])
                                : mediaPreviewLabel(
                                    community.lastMessageType,
                                    fallback: community.lastMessage,
                                    name: community.lastMessageName,
                                  ),
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
