import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
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
import '../widgets/chat_wallpaper.dart';
import '../services/location_service.dart';
import '../widgets/group_avatar.dart';
import '../models/app_call.dart';
import 'group_call_screen.dart';
import '../services/push_service.dart';
import '../models/app_conversation.dart';
import 'user_chat_screen.dart';
import '../widgets/pinned_message_bar.dart';
import 'dart:async';
import '../widgets/user_avatar.dart';

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

  /// Матни паёми пиншуда (холӣ — пин нест).
  String _pinnedText = '';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _pinSub;

  DocumentReference<Map<String, dynamic>> get _groupRef =>
      FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
  CollectionReference<Map<String, dynamic>> get _messagesRef => _groupRef.collection('messages');

  /// Сарлавҳаи гурӯҳро нав мекунад ва барои ҳар узв ба ғайр аз худам ҳисоби
  /// нохондашударо як воҳид зиёд мекунад.
  /// Ба ҳамаи аъзоён огоҳинома мефиристад. Хатогӣ фиристодани паёмро вайрон
  /// намекунад — паём аллакай дар Firestore аст.
  Future<void> _notifyMembers(String preview) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final myName = widget.memberNames[uid] ?? tr('k002');
    await PushService.notifyMany(
      toUids: _others,
      title: widget.groupName,
      body: '$myName: $preview',
      data: {
        'type': 'chat_message',
        'kind': 'group',
        'threadId': widget.groupId,
        'threadName': widget.groupName,
        'senderId': uid,
        'senderName': myName,
      },
    );
  }

  Future<void> _touchGroup(String preview) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final counters = <String, Object>{
      for (final member in widget.memberNames.keys)
        if (member != uid) member: FieldValue.increment(1),
    };
    await _groupRef.set({
      'lastMessage': preview,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': uid,
      if (counters.isNotEmpty) 'unread': counters,
    }, SetOptions(merge: true));
    _notifyMembers(preview);
  }

  /// Ҳамаи аъзоён ба ғайр аз худам — барои ҳисоби нохондашуда.
  List<String> get _others {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return widget.memberNames.keys.where((m) => m != uid).toList();
  }

  /// Ҳангоми кушодани гурӯҳ ҳисоби нохондашудаи ман сифр мешавад.
  Future<void> _clearMyUnread() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _groupRef.set({
      'unread': {uid: 0},
    }, SetOptions(merge: true)).catchError((_) {});
  }

  @override
  void initState() {
    super.initState();
    _clearMyUnread();
    _pinSub = _groupRef.snapshots().listen((snap) {
      final pinned = (snap.data()?['pinnedText'] as String?) ?? '';
      if (pinned != _pinnedText && mounted) setState(() => _pinnedText = pinned);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _pinSub?.cancel();
    _clearMyUnread();
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
        onLocationTap: _sendLocationMessage,
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
    await _touchGroup('$sticker Стикер');
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
          await _touchGroup(text);
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
      await _touchGroup('📷 Расм');
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trf('k049', [e]))));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Ҷойгиршавии ҳозираро ҳамчун паём мефиристад.
  Future<void> _sendLocationMessage() async {
    final position = await LocationService.current();
    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k288'))));
      }
      return;
    }
    await _sendMedia(
      () => ChatMediaService.sendLocation(
        messagesRef: _messagesRef,
        parentRef: _groupRef,
        latitude: position.latitude,
        longitude: position.longitude,
        preview: tr('k286'),
        unreadFor: _others,
      ),
    );
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
          unreadFor: _others,
        ),
      );

  Future<void> _sendDocumentMessage(PlatformFile picked) => _sendMedia(
        () => ChatMediaService.sendDocument(
          messagesRef: _messagesRef,
          parentRef: _groupRef,
          storageFolder: _storageFolder,
          picked: picked,
          unreadFor: _others,
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
        unreadFor: _others,
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
    await _touchGroup(text);
    _scrollToBottom();
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    await _messagesRef.doc(message.id).update({'deleted': true});
  }

  /// Ҷавоби шахсӣ — сӯҳбати шахсӣ бо фиристанда кушода мешавад (агар набошад,
  /// сохта мешавад) ва матни паём ҳамчун иқтибос гузошта мешавад.
  Future<void> _replyPrivately(ChatMessage message) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || message.senderId == uid) return;
    final otherName = widget.memberNames[message.senderId] ?? tr('k002');
    final conversationId = AppConversation.idFor(uid, message.senderId);
    final myName = widget.memberNames[uid] ?? tr('k002');

    await FirebaseFirestore.instance.collection('conversations').doc(conversationId).set({
      'participants': [uid, message.senderId],
      'participantNames': {uid: myName, message.senderId: otherName},
    }, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserChatScreen(
          conversationId: conversationId,
          otherUserName: otherName,
          otherUserId: message.senderId,
        ),
      ),
    );
  }

  /// Ҳангоми навиштани `@` рӯйхати аъзоён кушода мешавад — мисли WhatsApp.
  void _onInputChanged(String value) {
    if (!value.endsWith('@')) return;
    _showMentionPicker();
  }

  void _showMentionPicker() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final members = widget.memberNames.entries.where((e) => e.key != uid).toList();
    if (members.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Text(
                  tr('k310'),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: members.map((entry) {
                    return ListTile(
                      leading: UserAvatar(name: entry.value, uid: entry.key, size: 36),
                      title: Text(
                        entry.value,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14.5),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _insertMention(entry.value);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ном ба ҷои `@`-и навишташуда гузошта мешавад.
  void _insertMention(String name) {
    final text = _controller.text;
    final withoutAt = text.endsWith('@') ? text.substring(0, text.length - 1) : text;
    _controller.text = '$withoutAt@$name ';
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  /// Пин кардани паём дар болои чат — барои ҳамаи аъзоён як хел.
  Future<void> _pinMessage(ChatMessage message) async {
    final preview = message.text.trim().isNotEmpty ? message.text.trim() : tr('k286');
    await _groupRef.set({
      'pinnedText': preview,
      'pinnedMessageId': message.id,
    }, SetOptions(merge: true));
  }

  Future<void> _unpinMessage() async {
    await _groupRef.set({'pinnedText': '', 'pinnedMessageId': ''}, SetOptions(merge: true));
  }

  Future<void> _editMessage(ChatMessage message, String newText) async {
    await _messagesRef.doc(message.id).update({'text': newText, 'edited': true});
  }

  /// Нест кардан танҳо барои худам — ҳуҷҷат мемонад, вале дар рӯйхати ман
  /// нишон дода намешавад.
  Future<void> _deleteForMe(ChatMessage message) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _messagesRef.doc(message.id).update({
      'deletedFor': FieldValue.arrayUnion([uid]),
    });
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
              if (_pinnedText.isNotEmpty)
                PinnedMessageBar(text: _pinnedText, onUnpin: _unpinMessage),
              Expanded(
                child: ChatWallpaper(
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
                    // Паёмҳое, ки ман барои худам нест кардаам, намоён нестанд.
                    final docs = snapshot.data!.docs.where((d) {
                      final hidden = List<String>.from(d.data()['deletedFor'] as List? ?? []);
                      return !hidden.contains(currentUid);
                    }).toList();
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
                          onEdit: _editMessage,
                          onReplyPrivately: _replyPrivately,
                          onPin: _pinMessage,
                          onDeleteForMe: _deleteForMe,
                          messageRef: _messagesRef.doc(message.id),
                          chatTitle: widget.groupName,
                        );
                      },
                    );
                  },
                )),
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

  /// Занги гурӯҳӣ — ҳама аъзоён занг мегиранд ва ба як канал ҳамроҳ мешаванд.
  void _startGroupCall(CallType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupCallScreen(
          groupId: widget.groupId,
          groupName: widget.groupName,
          type: type,
          memberNames: widget.memberNames,
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
                    // Акси гурӯҳ метавонад дар вақти сӯҳбат иваз шавад.
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: _groupRef.snapshots(),
                      builder: (context, snapshot) {
                        return GroupAvatar(
                          photoUrl: snapshot.data?.data()?['photoUrl'] as String?,
                          size: 40,
                        );
                      },
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
              onPressed: () => _startGroupCall(CallType.audio),
              icon: Icon(LucideIcons.phone, color: AppColors.textSecondary, size: 18),
            ),
            IconButton(
              onPressed: () => _startGroupCall(CallType.video),
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
                      onChanged: _onInputChanged,
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
