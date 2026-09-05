import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../models/mock_ai_replies.dart';
import '../services/media_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_bubble.dart';
import '../widgets/attachment_sheet.dart';
import '../widgets/emoji_picker_sheet.dart';

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
  bool _isUploading = false;
  int _lastReplyIndex = -1;
  ChatMessage? _replyingTo;

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

  void _fillPrompt(String prompt) {
    _controller.text = prompt;
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  void _openEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => EmojiPickerSheet(
        onEmojiSelected: (emoji) {
          final text = _controller.text;
          final selection = _controller.selection;
          final newText = text.replaceRange(
            selection.start >= 0 ? selection.start : text.length,
            selection.end >= 0 ? selection.end : text.length,
            emoji,
          );
          _controller.text = newText;
          _controller.selection = TextSelection.collapsed(offset: (selection.start >= 0 ? selection.start : text.length) + emoji.length);
        },
      ),
    );
  }

  void _openAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachmentSheet(
        onImagePicked: _sendImageMessage,
        onContactTap: () => showComingSoonSnack(context, 'Мубодилаи контакт дар ChatAI'),
      ),
    );
  }

  Future<void> _sendImageMessage(XFile file) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    setState(() => _isUploading = true);
    try {
      final url = await MediaService.uploadImage(file, 'chats/${widget.conversation.id}');
      await _messagesRef.add({
        'text': '',
        'senderId': uid,
        'isAI': false,
        'createdAt': FieldValue.serverTimestamp(),
        'mediaUrl': url,
        'mediaType': 'image',
      });
      _scrollToBottom();
      if (widget.conversation.isAIChat) {
        _simulateAIReply();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Хатои боркунии расм: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    final replying = _replyingTo;
    _controller.clear();
    setState(() => _replyingTo = null);

    await _messagesRef.add({
      'text': text,
      'senderId': uid,
      'isAI': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (replying != null) 'replyToText': replying.text,
      if (replying != null) 'replyToSenderId': replying.senderId,
    });
    _scrollToBottom();

    if (widget.conversation.isAIChat) {
      _simulateAIReply();
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    await _messagesRef.doc(message.id).update({'deleted': true});
  }

  // ЭЗОҲ: ин ҷавоб ҳанӯз шабеҳсозишуда аст (на AI-и воқеӣ). Барои пайвасти
  // воқеӣ ба Gemini API, дар ин ҷо ба ҷои интихоб аз рӯйхат, дархости HTTP
  // фиристода, посухи гирифташударо истифода баред.
  void _simulateAIReply() {
    setState(() => _isAITyping = true);
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 1400), () async {
      if (!mounted) return;
      int index = DateTime.now().millisecond % MockAIReplies.replies.length;
      if (index == _lastReplyIndex) {
        index = (index + 1) % MockAIReplies.replies.length;
      }
      _lastReplyIndex = index;
      final reply = MockAIReplies.replies[index];
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

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

                    if (docs.isEmpty && convo.isAIChat) {
                      return _buildEmptyAiState();
                    }

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
                        return MessageBubble(
                          message: message,
                          isMe: message.senderId == currentUid,
                          currentUid: currentUid,
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
              icon: const Icon(LucideIcons.x, color: AppColors.textSecondary, size: 17),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAiState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
              child: const Icon(LucideIcons.zap, color: AppColors.background, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Аз ChatAI бипурсед',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Савол диҳед, ё яке аз инҳоро озмоед',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _suggestionChip(LucideIcons.image, 'Расм', 'Лутфан барои ман расме эҷод кун: '),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _suggestionChip(LucideIcons.music, 'Мусиқӣ', 'Лутфан барои ман мусиқие эҷод кун: '),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _suggestionChip(LucideIcons.video, 'Видео', 'Лутфан барои ман видеое эҷод кун: '),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(IconData icon, String label, String prompt) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _fillPrompt(prompt),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.neonCyan, size: 20),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600)),
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
              icon: const Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
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
              icon: const Icon(LucideIcons.video, color: AppColors.textSecondary, size: 20),
            ),
            IconButton(
              onPressed: () => showComingSoonSnack(context, 'Занг'),
              icon: const Icon(LucideIcons.phone, color: AppColors.textSecondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  /// Композитори тарзи WhatsApp: emoji (берун) — матн+замима+камера (дохили pill) — SEND (берун)
  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: GlassContainer(
              borderRadius: 24,
              padding: const EdgeInsets.only(left: 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _openEmojiPicker,
                    icon: const Icon(LucideIcons.face_slightly_smiling, color: AppColors.textSecondary, size: 21),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppColors.textPrimary),
                      maxLines: 4,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Паём',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  IconButton(
                    onPressed: _isUploading ? null : _openAttachmentSheet,
                    icon: const Icon(LucideIcons.paperclip, color: AppColors.textSecondary, size: 20),
                  ),
                  IconButton(
                    onPressed: _isUploading
                        ? null
                        : () async {
                            final file = await MediaService.pickFromCamera();
                            if (file != null) _sendImageMessage(file);
                          },
                    icon: const Icon(LucideIcons.camera, color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isUploading ? null : _handleSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
              child: _isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                    )
                  : const Icon(LucideIcons.arrow_up, color: AppColors.background, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}
