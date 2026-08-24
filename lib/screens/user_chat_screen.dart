import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';
import '../models/chat_message.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/message_bubble.dart';

/// Экрани чати воқеӣ байни ду корбари бо телефон бақайдгирифташуда.
/// Дастгирии Reply, Delete ва тикҳои "хонда шуд" (read receipts).
class UserChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserId;
  const UserChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatMessage? _replyingTo;

  DocumentReference<Map<String, dynamic>> get _conversationRef =>
      FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId);

  CollectionReference<Map<String, dynamic>> get _messagesRef => _conversationRef.collection('messages');

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final replying = _replyingTo;
    _controller.clear();
    setState(() => _replyingTo = null);

    await _messagesRef.add({
      'text': text,
      'senderId': uid,
      'isAI': false,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      if (replying != null) 'replyToText': replying.text,
      if (replying != null) 'replyToSenderId': replying.senderId,
    });

    // САБТ: навсозии ҳуҷҷати волидайн барои феҳристи чат
    await _conversationRef.set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': uid,
    }, SetOptions(merge: true));

    _scrollToBottom();
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    await _messagesRef.doc(message.id).update({'deleted': true});
  }

  void _markIncomingAsRead(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String currentUid) {
    final unread = docs.where((d) {
      final data = d.data();
      return data['senderId'] != currentUid && (data['read'] != true);
    }).toList();
    if (unread.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final d in unread) {
        d.reference.update({'read': true});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _messagesRef.orderBy('createdAt', descending: false).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Хатои Firestore: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'Оғози сӯҳбат бо ${widget.otherUserName} кунед',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      );
                    }
                    if (currentUid != null) {
                      _markIncomingAsRead(docs, currentUid);
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final message = ChatMessage.fromDoc(docs[index]);
                        return MessageBubble(
                          message: message,
                          isMe: message.senderId == currentUid,
                          onReply: (m) => setState(() => _replyingTo = m),
                          onDelete: _deleteMessage,
                        );
                      },
                    );
                  },
                ),
              ),
              if (_replyingTo != null) _buildReplyPreview(),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: GlassContainer(
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(width: 3, height: 30, color: AppColors.neonCyan.withOpacity(0.7)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _replyingTo!.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _replyingTo = null),
              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
      child: GlassContainer(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Center(
                child: Text(
                  widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherUserName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            IconButton(
              onPressed: () => showComingSoonSnack(context, 'Занги видео'),
              icon: const Icon(Icons.videocam_rounded, color: AppColors.textSecondary, size: 22),
            ),
            IconButton(
              onPressed: () => showComingSoonSnack(context, 'Занг'),
              icon: const Icon(Icons.call_rounded, color: AppColors.textSecondary, size: 19),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Паём нависед...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
                child: const Icon(Icons.arrow_upward_rounded, color: AppColors.background, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
