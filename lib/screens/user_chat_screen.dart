import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../models/chat_message.dart';
import '../models/app_call.dart';
import '../services/media_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/message_bubble.dart';
import '../widgets/attachment_sheet.dart';
import '../widgets/emoji_picker_sheet.dart';
import '../widgets/sticker_picker_sheet.dart';
import '../sheets/contact_picker_sheet.dart';
import 'contact_info_screen.dart';
import 'call_screen.dart';

/// Экрани чати воқеӣ байни ду корбари бо телефон бақайдгирифташуда.
/// Сарлавҳа ба ContactInfoScreen мегузарад; агар корбар манъ (block)
/// карда шуда бошад, майдони фиристодан хомӯш мешавад.
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
  bool _isUploading = false;

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

  void _openEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => EmojiPickerSheet(
        onEmojiSelected: (emoji) {
          final text = _controller.text;
          final selection = _controller.selection;
          final start = selection.start >= 0 ? selection.start : text.length;
          final end = selection.end >= 0 ? selection.end : text.length;
          final newText = text.replaceRange(start, end, emoji);
          _controller.text = newText;
          _controller.selection = TextSelection.collapsed(offset: start + emoji.length);
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
        onContactTap: _openContactPicker,
        onGifPicked: (file) => _sendImageMessage(file, mediaType: 'gif'),
        onStickerTap: _openStickerPicker,
      ),
    );
  }

  void _openStickerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StickerPickerSheet(onStickerSelected: _sendSticker),
    );
  }

  Future<void> _sendSticker(String sticker) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _messagesRef.add({
      'text': sticker,
      'senderId': uid,
      'isAI': false,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'mediaType': 'sticker',
    });
    await _conversationRef.set({
      'lastMessage': '$sticker Стикер',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': uid,
    }, SetOptions(merge: true));
    _scrollToBottom();
  }

  void _openContactPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ContactPickerSheet(onSelected: _sendContactMessage),
    );
  }

  Future<void> _sendContactMessage(Map<String, String> contact) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final text = '👤 ${contact['name']}\n${contact['phone']}';
    await _messagesRef.add({
      'text': text,
      'senderId': uid,
      'isAI': false,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
    await _conversationRef.set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': uid,
    }, SetOptions(merge: true));
    _scrollToBottom();
  }

  Future<void> _sendImageMessage(XFile file, {String mediaType = 'image'}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isUploading = true);
    try {
      final url = await MediaService.uploadImage(file, 'conversations/${widget.conversationId}');
      await _messagesRef.add({
        'text': '',
        'senderId': uid,
        'isAI': false,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'mediaUrl': url,
        'mediaType': mediaType,
      });
      await _conversationRef.set({
        'lastMessage': '📷 Расм',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': uid,
      }, SetOptions(merge: true));
      _scrollToBottom();
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

  Future<void> _reactToMessage(ChatMessage message, String emoji) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _messagesRef.doc(message.id).update({'reactions.$uid': emoji});
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

  void _startCall(CallType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(otherUserId: widget.otherUserId, otherUserName: widget.otherUserName, type: type),
      ),
    );
  }

  void _openContactInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactInfoScreen(
          conversationId: widget.conversationId,
          otherUserId: widget.otherUserId,
          otherUserName: widget.otherUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: NeonBackdrop(
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
            builder: (context, userSnapshot) {
              final blockedList = List<String>.from(userSnapshot.data?.data()?['blockedUsers'] as List? ?? []);
              final iBlockedThem = blockedList.contains(widget.otherUserId);

              return Column(
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
                        if (currentUid.isNotEmpty) {
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
                              currentUid: currentUid,
                              onReply: (m) => setState(() => _replyingTo = m),
                              onDelete: _deleteMessage,
                              onReact: _reactToMessage,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (_replyingTo != null && !iBlockedThem) _buildReplyPreview(),
                  if (iBlockedThem) _buildBlockedBanner() else _buildInputBar(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(LucideIcons.slash, color: Colors.redAccent, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Шумо ${widget.otherUserName}-ро манъ кардаед — паём фиристода наметавонед',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
            ),
          ],
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
              icon: const Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openContactInfo,
                child: Row(
                  children: [
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
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => _startCall(CallType.video),
              icon: const Icon(LucideIcons.video, color: AppColors.textSecondary, size: 20),
            ),
            IconButton(
              onPressed: () => _startCall(CallType.audio),
              icon: const Icon(LucideIcons.phone, color: AppColors.textSecondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

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
                  IconButton(
                    onPressed: _openStickerPicker,
                    icon: const Icon(LucideIcons.sticker, color: AppColors.textSecondary, size: 20),
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
