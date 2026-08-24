import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chat_conversation.dart';
import '../../models/app_conversation.dart';
import '../../widgets/chat_tile.dart';
import '../../widgets/user_conversation_tile.dart';
import '../../theme/app_theme.dart';

/// Бахши "Чатҳо" — ChatAI дар боло (собит) + рӯйхати сӯҳбатҳои воқеии
/// корбарони бо телефон бақайдгирифташуда (аз Firestore, вақти воқеӣ).
class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
      children: [
        const ChatTile(conversation: AppChats.aiAssistant, highlighted: true),
        const SizedBox(height: 10),
        if (currentUid != null)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('conversations')
                .where('participants', arrayContains: currentUid)
                .orderBy('lastMessageTime', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Хатои Firestore (эҳтимол index лозим аст): ${snapshot.error}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(color: AppColors.neonEmerald)),
                );
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Ҳанӯз чат надоред — тугмаи "+" -ро пахш карда корбарро ёбед',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12.5),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final convo = AppConversation.fromDoc(doc);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: UserConversationTile(conversation: convo, currentUid: currentUid),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}
