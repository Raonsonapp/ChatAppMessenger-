import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';
import '../models/chat_message.dart';
import '../services/media_service.dart';
import '../services/chat_media_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/message_bubble.dart';
import '../widgets/attachment_sheet.dart';
import '../widgets/voice_recorder_bar.dart';
import '../widgets/emoji_picker_sheet.dart';
import '../widgets/sticker_picker_sheet.dart';
import '../sheets/contact_picker_sheet.dart';
import 'group_info_screen.dart';
import '../l10n/l10n.dart';

/// Чати воқеии гурӯҳӣ — паёмҳои дохилшаванда номи фиристандаро нишон
/// медиҳанд. Сарлавҳа ба GroupInfoScreen (аъзоён, admin, баромадан) мегузарад.
class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final Map<String, String> memberNames;
  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.memberNames,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatMessage? _replyingTo;
  bool _isUploading = false;
  bool _recording = false;

  DocumentReference<Map<String, dynamic>> get _groupRef =>
      FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
  CollectionReference<Map<String, dynamic>> get _messagesRef => _groupRef.collection('messages');

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
          _controller.text = text.replaceRange(start, end, emoji);
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
        onVideoPicked: _sendVideoMessage,
        onDocumentPicked: _sendDocumentMessage,
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
    await _messagesRef.add({'text': sticker, 'senderId': uid, 'isAI': false, 'createdAt': FieldValue.serverTimestamp(), 'mediaType': 'sticker'});
    await _groupRef.set({
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
      builder: (_) => ContactPickerSheet(
        onSelected: (contact) async {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) return;
          final text = '👤 ${contact['name']}\n${contact['phone']}';
          await _messagesRef.add({'text': text, 'senderId': uid, 'isAI': false, 'createdAt': FieldValue.serverTimestamp()});
          await _groupRef.set({
            'lastMessage': text,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'lastSenderId': uid,
          }, SetOptions(merge: true));
          _scrollToBottom();
        },
      ),
    );
  }

  Future<void> _sendImageMessage(XFile file, {String mediaType = 'image'}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isUploading = true);
    try {
      final url = await MediaService.uploadImage(file, 'groups/${widget.groupId}');
      await _messagesRef.add({
        'text': '',
        'senderId': uid,
        'isAI': false,
        'createdAt': FieldValue.serverTimestamp(),
        'mediaUrl': url,
        'mediaType': mediaType,
      });
      await _groupRef.set({
        'lastMessage': '📷 Расм',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': uid,
      }, SetOptions(merge: true));
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trf('k049', [e]))));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _sendMedia(Future<bool> Function() send) async {
    setState(() => _isUploading = true);
    try {
      if (await send()) _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trf('k247', [e]))));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String get _storageFolder => 'groups/${widget.groupId}';

  Future<void> _sendVideoMessage(XFile file) => _sendMedia(
        () => ChatMediaService.sendVideo(
          messagesRef: _messagesRef,
          parentRef: _groupRef,
          storageFolder: _storageFolder,
          picked: file,
        ),
      );

  Future<void> _sendDocumentMessage(PlatformFile picked) => _sendMedia(
        () => ChatMediaService.sendDocument(
          messagesRef: _messagesRef,
          parentRef: _groupRef,
          storageFolder: _storageFolder,
          picked: picked,
        ),
      );

  Future<void> _sendVoiceMessage(File file, Duration duration) {
    setState(() => _recording = false);
    return _sendMedia(
      () => ChatMediaService.sendVoice(
        messagesRef: _messagesRef,
        parentRef: _groupRef,
        storageFolder: _storageFolder,
        file: file,
        duration: duration,
      ),
    );
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
      if (replying != null) 'replyToText': replying.text,
      if (replying != null) 'replyToSenderId': replying.senderId,
    });
    await _groupRef.set({
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

  void _openGroupInfo() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupInfoScreen(groupId: widget.groupId)));
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
                            trf('k029', [snapshot.error]),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          trf('k050', [widget.groupName]),
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      );
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final message = ChatMessage.fromDoc(docs[index]);
                        final isMe = message.senderId == currentUid;
                        return MessageBubble(
                          message: message,
                          isMe: isMe,
                          currentUid: currentUid,
                          senderLabel: isMe ? null : widget.memberNames[message.senderId],
                          showReadReceipts: false,
                          onReply: (m) => setState(() => _replyingTo = m),
                          onDelete: _deleteMessage,
                          onReact: _reactToMessage,
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
            Container(width: 3, height: 30, color: AppColors.neonCyan.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _replyingTo!.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _replyingTo = null),
              icon: Icon(LucideIcons.x, color: AppColors.textSecondary, size: 17),
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
              icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openGroupInfo,
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
                      child: Icon(LucideIcons.users, color: AppColors.textSecondary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.groupName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          Text(trf('k051', [widget.memberNames.length]), style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: () => showComingSoonSnack(context, tr('k040')),
              icon: Icon(LucideIcons.video, color: AppColors.textSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    // Ҳангоми сабти овоз ба ҷои майдони матн панели сабт нишон дода мешавад.
    if (_recording) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: VoiceRecorderBar(
            onRecorded: _sendVoiceMessage,
            onCancel: () => setState(() => _recording = false),
          ),
        ),
      );
    }

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
                    icon: Icon(LucideIcons.face_slightly_smiling, color: AppColors.textSecondary, size: 21),
                  ),
                  IconButton(
                    onPressed: _openStickerPicker,
                    icon: Icon(LucideIcons.sticker, color: AppColors.textSecondary, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: AppColors.textPrimary),
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: tr('k042'),
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  IconButton(
                    onPressed: _isUploading ? null : _openAttachmentSheet,
                    icon: Icon(LucideIcons.paperclip, color: AppColors.textSecondary, size: 20),
                  ),
                  IconButton(
                    onPressed: _isUploading
                        ? null
                        : () async {
                            final file = await MediaService.pickFromCamera();
                            if (file != null) _sendImageMessage(file);
                          },
                    icon: Icon(LucideIcons.camera, color: AppColors.textSecondary, size: 20),
                  ),
                  IconButton(
                    onPressed: _isUploading ? null : () => setState(() => _recording = true),
                    icon: Icon(LucideIcons.mic, color: AppColors.textSecondary, size: 20),
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
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
              child: _isUploading
                  ? Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                    )
                  : Icon(LucideIcons.arrow_up, color: AppColors.background, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}
