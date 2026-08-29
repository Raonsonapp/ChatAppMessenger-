import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/app_group.dart';
import '../screens/group_chat_screen.dart';

class GroupTile extends StatelessWidget {
  final AppGroup group;
  const GroupTile({super.key, required this.group});

  String _formatTime(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    if (now.difference(t).inDays >= 1) return '${t.day}/${t.month}';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
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
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.glassBorder, width: 0.6)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Icon(Icons.groups_rounded, color: AppColors.textSecondary, size: 24),
              ),
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
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15.5),
                          ),
                        ),
                        Text(
                          _formatTime(group.lastMessageTime),
                          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 11.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      group.lastMessage.isEmpty ? 'Гурӯҳ сохта шуд' : group.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
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
