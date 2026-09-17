import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../models/chat_conversation.dart';
import '../models/app_conversation.dart';
import '../models/app_group.dart';
import '../widgets/chat_tile.dart';
import '../widgets/user_conversation_tile.dart';
import '../widgets/group_tile.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/glass_container.dart';
import '../l10n/l10n.dart';

/// Ҷустуҷӯи умумӣ: ChatAI, сӯҳбатҳои шахсӣ ва гурӯҳҳо — ҳам аз рӯи ном ва
/// ҳам аз рӯи матни охирин паём.
class ChatSearchScreen extends StatefulWidget {
  const ChatSearchScreen({super.key});

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final ql = _query.trim().toLowerCase();
    final showAi = ql.isEmpty || AppChats.aiAssistant.name.toLowerCase().contains(ql);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                    ),
                    Expanded(
                      child: GlassContainer(
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          style: TextStyle(color: AppColors.textPrimary),
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: tr('k048'),
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            border: InputBorder.none,
                            icon: Icon(LucideIcons.search, color: AppColors.textSecondary, size: 19),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
                  children: [
                    if (showAi) const ChatTile(conversation: AppChats.aiAssistant, pinned: true),
                    if (currentUid != null)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('conversations')
                            .where('participants', arrayContains: currentUid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          // Ҳам номи ҳамсӯҳбат ва ҳам матни охирин паём —
                          // WhatsApp низ ҳар дуро меҷӯяд.
                          final matches = snapshot.data!.docs.where((doc) {
                            final convo = AppConversation.fromDoc(doc);
                            if (convo.isDeleted(currentUid)) return false;
                            if (ql.isEmpty) return true;
                            return convo.otherName(currentUid).toLowerCase().contains(ql) ||
                                convo.lastMessage.toLowerCase().contains(ql);
                          }).toList();
                          if (matches.isEmpty) return const SizedBox.shrink();
                          return Column(
                            children: matches.map((doc) {
                              final convo = AppConversation.fromDoc(doc);
                              return UserConversationTile(conversation: convo, currentUid: currentUid);
                            }).toList(),
                          );
                        },
                      ),
                    if (currentUid != null)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('groups')
                            .where('members', arrayContains: currentUid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          final matches = snapshot.data!.docs.where((doc) {
                            final group = AppGroup.fromDoc(doc);
                            if (ql.isEmpty) return true;
                            return group.name.toLowerCase().contains(ql) ||
                                group.lastMessage.toLowerCase().contains(ql);
                          }).toList();
                          if (matches.isEmpty) return const SizedBox.shrink();
                          return Column(
                            children: matches
                                .map((doc) => GroupTile(
                                      group: AppGroup.fromDoc(doc),
                                      currentUid: currentUid,
                                    ))
                                .toList(),
                          );
                        },
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
