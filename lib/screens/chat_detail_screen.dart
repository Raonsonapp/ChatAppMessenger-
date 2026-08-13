import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../models/mock_ai_replies.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_bubble.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatConversation conversation;
  final String? initialText;
  const ChatDetailScreen({super.key, required this.conversation, this.initialText});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAITyping = false;

  CollectionReference<Map<String, dynamic>> get _messagesRef => FirebaseFirestore.instance
      .collection('chats')
      .doc(widget.conversation.id)
      .collection('messages');

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _controller.text = widget.initialText!;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    _controller.clear();

    await _messagesRef.add({
      'text': text,
      'senderId': uid,
      'isAI': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _scrollToBottom();

    if (widget.conversation.isAIChat) {
      _simulateAIReply();
    }
  }

  void _simulateAIReply() {
    setState(() => _isAITyping = true);
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 1400), () async {
      if (!mounted) return;
      final reply = MockAIReplies.replies[DateTime.now().millisecond % MockAIReplies.replies.length];
      await _messagesRef.add({
        'text': reply,
        'senderId': 'ai_bot',
        'isAI': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() => _isAITyping = false);
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final convo = widget.conversation;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(convo),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _messagesRef.orderBy('createdAt', descending: false).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Хатои Firestore: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
                    }
                    final docs = snapshot.data!.docs;
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      itemCount: docs.length + (_isAITyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isAITyping && index == docs.length) {
                          return const TypingBubble();
                        }
                        final message = ChatMessage.fromDoc(docs[index]);
                        return MessageBubble(message: message, isMe: message.senderId == currentUid);
                      },
                    );
                  },
                ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ChatConversation convo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
      child: GlassContainer(
        borderRadius: 18,
        glow: convo.isAIChat,
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
                gradient: convo.isAIChat ? AppColors.neonGradient : null,
                color: convo.isAIChat ? null : AppColors.surface,
                border: convo.isAIChat ? null : Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(
                convo.avatarIcon,
                color: convo.isAIChat ? AppColors.background : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    convo.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  Text(
                    convo.isAIChat ? 'Ҳамеша дастрас' : 'Firestore · вақти воқеӣ',
                    style: const TextStyle(color: AppColors.neonEmerald, fontSize: 11),
                  ),
                ],
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
