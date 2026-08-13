import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/chat_conversation.dart';
import '../widgets/glass_container.dart';
import '../screens/chat_detail_screen.dart';

class NewChatSheet extends StatelessWidget {
  const NewChatSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const Text('Контакти нав', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            ...AppChats.all.map(
              (c) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: c.isAIChat ? AppColors.neonGradient : null,
                    color: c.isAIChat ? null : AppColors.surface,
                    border: c.isAIChat ? null : Border.all(color: AppColors.glassBorder),
                  ),
                  child: Icon(c.avatarIcon, color: c.isAIChat ? AppColors.background : AppColors.textSecondary, size: 20),
                ),
                title: Text(c.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(conversation: c)));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
