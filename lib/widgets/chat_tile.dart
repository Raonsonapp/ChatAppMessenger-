import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../models/chat_conversation.dart';
import '../screens/chat_detail_screen.dart';

/// Сатри чат — WhatsApp-тарз: ҳамаи қаторҳо якхела ба назар мерасанд.
/// ChatAI танҳо бо нишони сӯзан (pin) фарқ мекунад — на бо банер/glow.
class ChatTile extends StatelessWidget {
  final ChatConversation conversation;
  final bool pinned;
  const ChatTile({super.key, required this.conversation, this.pinned = false});

  Stream<QuerySnapshot<Map<String, dynamic>>> get _lastMessageStream => FirebaseFirestore
      .instance
      .collection('chats')
      .doc(conversation.id)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots();

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
          MaterialPageRoute(builder: (_) => ChatDetailScreen(conversation: conversation)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.glassBorder, width: 0.6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: conversation.isAIChat ? AppColors.neonGradient : null,
                  color: conversation.isAIChat ? null : AppColors.surface,
                  border: conversation.isAIChat ? null : Border.all(color: AppColors.glassBorder),
                ),
                child: Icon(
                  conversation.avatarIcon,
                  color: conversation.isAIChat ? AppColors.background : AppColors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _lastMessageStream,
                  builder: (context, snapshot) {
                    String preview = conversation.isAIChat ? 'Ба ман чизе нависед...' : 'Оғози сӯҳбат кунед';
                    String time = '';
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final data = snapshot.data!.docs.first.data();
                      preview = (data['text'] ?? preview) as String;
                      time = _formatTime((data['createdAt'] as Timestamp?)?.toDate());
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      conversation.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15.5,
                                      ),
                                    ),
                                  ),
                                  if (conversation.isAIChat) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.neonGradient,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'AI',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (pinned)
                              Icon(LucideIcons.bookmark, size: 13, color: AppColors.textSecondary.withValues(alpha: 0.6))
                            else
                              Text(
                                time,
                                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 11.5),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
