import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_conversation.dart';
import '../widgets/user_conversation_tile.dart';
import '../theme/app_theme.dart';
import '../utils/doc_sort.dart';
import '../l10n/l10n.dart';
import '../widgets/empty_state.dart';
import '../theme/app_scope.dart';

/// Рӯйхати чатҳои "Интихобшуда" (Favorites) — воқеӣ, бар асоси майдони
/// `favoriteBy` дар ҳуҷҷати сӯҳбат (ҳамон тарзе ки pin/archive/mute кор
/// мекунанд).
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        foregroundColor: AppColors.textPrimary,
        title: Text(tr('k412'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: currentUid == null
          ? const SizedBox.shrink()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .where('favoriteBy', arrayContains: currentUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                final docs = sortByTimeDesc(snapshot.data!.docs, 'lastMessageTime');
                final list = docs.map(AppConversation.fromDoc).where((c) => !c.isDeleted(currentUid)).toList();
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: EmptyState(
                        icon: LucideIcons.star,
                        title: tr('k433'),
                        description: tr('k434'),
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                  children: list
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: UserConversationTile(conversation: c, currentUid: currentUid),
                          ))
                      .toList(),
                );
              },
            ),
    );
  }
}
