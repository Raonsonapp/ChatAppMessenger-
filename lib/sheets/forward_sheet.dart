import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import '../models/chat_message.dart';
import '../models/app_conversation.dart';
import '../utils/doc_sort.dart';
import '../widgets/glass_container.dart';
import '../l10n/l10n.dart';

/// Интихоби чат барои фиристодани нусхаи паём.
///
/// Ҳам сӯҳбатҳои шахсӣ ва ҳам гурӯҳҳо нишон дода мешаванд — паём ба ҳамон
/// сохтори `.../messages` нусхабардорӣ мешавад.
class ForwardSheet extends StatelessWidget {
  final ChatMessage message;
  const ForwardSheet({super.key, required this.message});

  Future<void> _forwardTo(
    BuildContext context, {
    required DocumentReference<Map<String, dynamic>> parentRef,
    required String preview,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await parentRef.collection('messages').add({
      'text': message.text,
      'senderId': uid,
      'isAI': false,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'forwarded': true,
      if (message.mediaUrl != null) 'mediaUrl': message.mediaUrl,
      if (message.mediaType != null) 'mediaType': message.mediaType,
      if (message.mediaDuration != null) 'mediaDuration': message.mediaDuration,
      if (message.mediaName != null) 'mediaName': message.mediaName,
      if (message.mediaSize != null) 'mediaSize': message.mediaSize,
    });
    await parentRef.set({
      'lastMessage': preview,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': uid,
    }, SetOptions(merge: true));

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k255'))));
    }
  }

  String get _preview {
    if (message.text.isNotEmpty) return message.text;
    return switch (message.mediaType) {
      'image' || 'gif' => '📷 Расм',
      'audio' => '🎤 Паёми овозӣ',
      'video' => '🎥 Видео',
      'document' => '📄 ${message.mediaName ?? ''}',
      'sticker' => '🙂 Стикер',
      'location' => tr('k286'),
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    final db = FirebaseFirestore.instance;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('k254'),
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: db.collection('conversations').where('participants', arrayContains: uid).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final docs = sortByTimeDesc(snapshot.data!.docs, 'lastMessageTime');
                        return Column(
                          children: docs.map((doc) {
                            final convo = AppConversation.fromDoc(doc);
                            return _tile(
                              context,
                              icon: LucideIcons.user,
                              title: convo.otherName(uid),
                              onTap: () => _forwardTo(context, parentRef: doc.reference, preview: _preview),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: db.collection('groups').where('members', arrayContains: uid).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final docs = sortByTimeDesc(snapshot.data!.docs, 'lastMessageTime');
                        return Column(
                          children: docs.map((doc) {
                            return _tile(
                              context,
                              icon: LucideIcons.users,
                              title: '${doc.data()['name'] ?? tr('k005')}',
                              onTap: () => _forwardTo(context, parentRef: doc.reference, preview: _preview),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassFill,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, color: AppColors.neonCyan, size: 18),
      ),
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: Icon(LucideIcons.corner_up_right, color: AppColors.textSecondary, size: 18),
      onTap: onTap,
    );
  }
}
