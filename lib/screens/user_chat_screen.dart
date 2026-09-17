import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../models/chat_message.dart';
import '../models/app_call.dart';
import '../services/media_service.dart';
import '../services/push_service.dart';
import '../services/chat_media_service.dart';
import '../services/presence_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/message_bubble.dart';
import '../widgets/attachment_sheet.dart';
import '../widgets/voice_recorder_bar.dart';
import '../widgets/emoji_picker_sheet.dart';
import '../widgets/sticker_picker_sheet.dart';
import '../sheets/contact_picker_sheet.dart';
import 'contact_info_screen.dart';
import 'call_screen.dart';
import '../l10n/l10n.dart';

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
  bool _recording = false;

  /// Ҷустуҷӯ дар дохили ҳамин чат.
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  String _searchQuery = '';

  DocumentReference<Map<String, dynamic>> get _conversationRef =>
      FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId);

  CollectionReference<Map<String, dynamic>> get _messagesRef => _conversationRef.collection('messages');

  /// Пас аз ҳар паём сарлавҳаи сӯҳбат нав карда мешавад ва ҳисоби нохондашуда
  /// барои тарафи муқобил як воҳид зиёд мешавад — рӯйхати чатҳо ҳамин ҳисобро
  /// нишон медиҳад, бе он ки паёмҳоро аз нав ҳисоб кунад.
  Future<void> _touchConversation(String preview) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _conversationRef.set({
      'lastMessage': preview,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': uid,
      'unread': {widget.otherUserId: FieldValue.increment(1)},
      // Паёми нав чатро аз бойгонии ҳар ду тараф бармегардонад — чун WhatsApp.
      'archivedBy': FieldValue.arrayRemove([uid, widget.otherUserId]),
    }, SetOptions(merge: true));
  }

  /// Ҳангоми кушодани чат ҳисоби нохондашудаи ман сифр мешавад.
  Future<void> _clearMyUnread(String currentUid) async {
    await _conversationRef.set({
      'unread': {currentUid: 0},
    }, SetOptions(merge: true)).catchError((_) {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
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
        onVideoPicked: _sendVideoMessage,
        onDocumentPicked: _sendDocumentMessage,
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
    await _touchConversation('$sticker Стикер');
    _notifyOther('$sticker Стикер');
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
    await _touchConversation(text);
    _notifyOther(text);
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
      await _touchConversation('📷 Расм');
      _notifyOther('📷 Расм');
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(trf('k049', [e]))),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Боркунӣ ва фиристодани ҳар навъи файл (овоз, видео, ҳуҷҷат).
  Future<void> _sendMedia(Future<bool> Function() send, String preview) async {
    setState(() => _isUploading = true);
    try {
      if (await send()) {
        _notifyOther(preview);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trf('k247', [e]))));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String get _storageFolder => 'conversations/${widget.conversationId}';

  Future<void> _sendVideoMessage(XFile file) => _sendMedia(
        () => ChatMediaService.sendVideo(
          messagesRef: _messagesRef,
          parentRef: _conversationRef,
          storageFolder: _storageFolder,
          picked: file,
          unreadFor: widget.otherUserId,
        ),
        '🎥 Видео',
      );

  Future<void> _sendDocumentMessage(PlatformFile picked) => _sendMedia(
        () => ChatMediaService.sendDocument(
          messagesRef: _messagesRef,
          parentRef: _conversationRef,
          storageFolder: _storageFolder,
          picked: picked,
          unreadFor: widget.otherUserId,
        ),
        '📄 ${picked.name}',
      );

  Future<void> _sendVoiceMessage(File file, Duration duration) {
    setState(() => _recording = false);
    return _sendMedia(
      () => ChatMediaService.sendVoice(
        messagesRef: _messagesRef,
        parentRef: _conversationRef,
        storageFolder: _storageFolder,
        file: file,
        duration: duration,
        unreadFor: widget.otherUserId,
      ),
      '🎤 Паёми овозӣ',
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
      'read': false,
      if (replying != null) 'replyToText': replying.text,
      if (replying != null) 'replyToSenderId': replying.senderId,
    });

    await _touchConversation(text);

    _notifyOther(text);
    _scrollToBottom();
  }

  /// Ба ҳамсӯҳбат огоҳиномаи push мефиристад. Номи фиристанда аз ҳуҷҷати
  /// сӯҳбат гирифта мешавад, то дар огоҳинома номи воқеӣ намоён шавад.
  Future<void> _notifyOther(String preview) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final convo = await _conversationRef.get();
    // Агар гиранда ин чатро хомӯш карда бошад, огоҳинома намефиристем.
    final muted = List<String>.from(convo.data()?['mutedBy'] as List? ?? []);
    if (muted.contains(widget.otherUserId)) return;
    final names = (convo.data()?['participantNames'] as Map<String, dynamic>?) ?? {};
    final myName = '${names[uid] ?? tr('k002')}';
    await PushService.notify(
      toUid: widget.otherUserId,
      title: myName,
      body: preview,
      data: {
        'type': 'message',
        'conversationId': widget.conversationId,
        'otherUserId': uid,
        'otherUserName': myName,
      },
    );
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
    if (unread.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _clearMyUnread(currentUid));
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final d in unread) {
        d.reference.update({'read': true});
      }
      _clearMyUnread(currentUid);
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
                  _searching ? _buildSearchHeader() : _buildHeader(),
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
                        final allDocs = snapshot.data!.docs;
                        if (allDocs.isEmpty) {
                          return Center(
                            child: Text(
                              trf('k213', [widget.otherUserName]),
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          );
                        }
                        if (currentUid.isNotEmpty) {
                          _markIncomingAsRead(allDocs, currentUid);
                        }
                        // Ҳангоми ҷустуҷӯ танҳо паёмҳои мувофиқ мемонанд.
                        final docs = _searchQuery.isEmpty
                            ? allDocs
                            : allDocs.where((d) {
                                final text = (d.data()['text'] as String?) ?? '';
                                return text.toLowerCase().contains(_searchQuery);
                              }).toList();
                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              tr('k273'),
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          );
                        }
                        // Ҳангоми ҷустуҷӯ ба поён намепарем — натиҷа гум мешавад.
                        if (_searchQuery.isEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                        }
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
                              messageRef: _messagesRef.doc(message.id),
                              chatTitle: widget.otherUserName,
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
                trf('k214', [widget.otherUserName]),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
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

  void _openSearch() => setState(() => _searching = true);

  void _closeSearch() {
    _searchController.clear();
    setState(() {
      _searching = false;
      _searchQuery = '';
    });
  }

  /// Сарлавҳаи ҳолати ҷустуҷӯ — ба ҷои ном ва тугмаҳои занг.
  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
      child: GlassContainer(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          children: [
            IconButton(
              onPressed: _closeSearch,
              icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14.5),
                onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: tr('k272'),
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: Icon(LucideIcons.x, color: AppColors.textSecondary, size: 18),
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
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.otherUserName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          // «дар шабака» / «2 соат пеш» — бо эҳтироми танзимоти
                          // махфияти худи ҳамсӯҳбат.
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.otherUserId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final label = PresenceService.describe(snapshot.data?.data());
                              if (label == null) return const SizedBox.shrink();
                              return Text(
                                label.text,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: label.isOnline
                                      ? AppColors.neonEmerald
                                      : AppColors.textSecondary,
                                  fontSize: 11.5,
                                ),
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
            IconButton(
              onPressed: _openSearch,
              icon: Icon(LucideIcons.search, color: AppColors.textSecondary, size: 19),
            ),
            IconButton(
              onPressed: () => _startCall(CallType.video),
              icon: Icon(LucideIcons.video, color: AppColors.textSecondary, size: 20),
            ),
            IconButton(
              onPressed: () => _startCall(CallType.audio),
              icon: Icon(LucideIcons.phone, color: AppColors.textSecondary, size: 18),
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
