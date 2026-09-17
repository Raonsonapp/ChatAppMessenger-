import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chat_conversation.dart';
import '../../models/app_conversation.dart';
import '../../models/app_group.dart';
import '../../widgets/chat_tile.dart';
import '../../widgets/user_conversation_tile.dart';
import '../../widgets/group_tile.dart';
import '../../theme/app_theme.dart';
import '../../utils/doc_sort.dart';
import '../../l10n/l10n.dart';
import '../archived_chats_screen.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
      children: [
        const ChatTile(conversation: AppChats.aiAssistant, pinned: true),
        const SizedBox(height: 4),
        if (currentUid != null) ...[
          // Гурӯҳҳо
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('groups')
                .where('members', arrayContains: currentUid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    trf('k200', [snapshot.error]),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                );
              }
              if (!snapshot.hasData) return const SizedBox.shrink();
              final docs = sortByTimeDesc(snapshot.data!.docs, 'lastMessageTime');
              if (docs.isEmpty) return const SizedBox.shrink();
              return Column(
                children: docs.map((doc) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: GroupTile(group: AppGroup.fromDoc(doc), currentUid: currentUid),
                  );
                }).toList(),
              );
            },
          ),
          // Сӯҳбатҳои шахсӣ
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('conversations')
                .where('participants', arrayContains: currentUid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    trf('k197', [snapshot.error]),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(color: AppColors.neonEmerald)),
                );
              }
              final all = sortByTimeDesc(snapshot.data!.docs, 'lastMessageTime')
                  .map(AppConversation.fromDoc)
                  .toList();
              // Чатҳои несткардашуда умуман нишон дода намешаванд.
              final visibleAll = all.where((c) => !c.isDeleted(currentUid)).toList();
              final archived = visibleAll.where((c) => c.isArchived(currentUid)).toList();
              // Чатҳои мустаҳкамшуда ҳамеша дар боло — мисли WhatsApp.
              final visible = visibleAll.where((c) => !c.isArchived(currentUid)).toList()
                ..sort((a, b) {
                  final pa = a.isPinned(currentUid) ? 0 : 1;
                  final pb = b.isPinned(currentUid) ? 0 : 1;
                  return pa.compareTo(pb);
                });

              if (visibleAll.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    tr('k201'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 12.5),
                  ),
                );
              }
              return Column(
                children: [
                  if (archived.isNotEmpty)
                    _ArchivedRow(
                      count: archived.length,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ArchivedChatsScreen()),
                      ),
                    ),
                  ...visible.map((convo) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: UserConversationTile(conversation: convo, currentUid: currentUid),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Сатри «Чатҳои бойгонӣ» дар болои рӯйхат.
class _ArchivedRow extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _ArchivedRow({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.glassBorder, width: 0.6)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.archive, color: AppColors.textSecondary, size: 19),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  tr('k269'),
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
              ),
              Text('$count', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}
