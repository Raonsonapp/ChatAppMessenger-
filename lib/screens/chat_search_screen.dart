Import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../models/chat_conversation.dart';
import '../models/app_conversation.dart';
import '../widgets/chat_tile.dart';
import '../widgets/user_conversation_tile.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/glass_container.dart';

/// Ҷустуҷӯи воқеӣ дар байни ChatAI ва сӯҳбатҳои воқеии корбар.
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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
                    ),
                    Expanded(
                      child: GlassContainer(
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          style: const TextStyle(color: AppColors.textPrimary),
                          onChanged: (v) => setState(() => _query = v),
                          decoration: const InputDecoration(
                            hintText: 'Ҷустуҷӯи чат...',
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            border: InputBorder.none,
                            icon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
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
                          final matches = snapshot.data!.docs.where((doc) {
                            final convo = AppConversation.fromDoc(doc);
                            return ql.isEmpty || convo.otherName(currentUid).toLowerCase().contains(ql);
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
