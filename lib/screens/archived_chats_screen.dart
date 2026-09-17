import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../models/app_conversation.dart';
import '../theme/app_theme.dart';
import '../utils/doc_sort.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/user_conversation_tile.dart';
import '../l10n/l10n.dart';

/// Чатҳои бойгонишуда. Дарозфишорӣ ҳамон менюро мекушояд, бинобар ин
/// баргардондан аз ҳамин ҷо низ имконпазир аст.
class ArchivedChatsScreen extends StatelessWidget {
  const ArchivedChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 22),
                    ),
                    Text(
                      tr('k269'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: uid == null
                    ? const SizedBox.shrink()
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        // Филтр маҳз аз рӯи `participants` аст, на `archivedBy`:
                        // қоидаҳои Firestore хонишро танҳо ба иштирокчиён
                        // иҷозат медиҳанд ва дархост бояд ҳаминро кафолат
                        // диҳад. Бойгониро дар Dart ҷудо мекунем.
                        stream: FirebaseFirestore.instance
                            .collection('conversations')
                            .where('participants', arrayContains: uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
                          }
                          final docs = sortByTimeDesc(snapshot.data?.docs ?? const [], 'lastMessageTime')
                              .map(AppConversation.fromDoc)
                              .where((c) => c.isArchived(uid) && !c.isDeleted(uid))
                              .toList();
                          if (docs.isEmpty) {
                            return Center(
                              child: Text(
                                tr('k270'),
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            );
                          }
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                            children: docs.map((convo) {
                              return UserConversationTile(conversation: convo, currentUid: uid);
                            }).toList(),
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
