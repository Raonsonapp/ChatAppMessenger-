import 'dart:async';
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
import '../widgets/user_avatar.dart';
import '../widgets/chat_wallpaper.dart';
import '../services/location_service.dart';
import '../widgets/pinned_message_bar.dart';

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

  /// Мӯҳлати нопадид шудани паёмҳо бо сония (0 — хомӯш). Аз ҳуҷҷати сӯҳбат
  /// хонда мешавад, то ҳангоми фиристодан фавран дастрас бошад.
  int _disappearIn = 0;

  /// Матни паёми пиншуда (холӣ — пин нест).
  String _pinnedText = '';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _convoSub;

  /// «Менависад…» — таймери хомӯшкунӣ пас аз таваққуфи чоп.
  Timer? _typingTimer;
  bool _typingSent = false;

  /// Барои он ки нишони «менависад…» пас аз мӯҳлат худаш ғайб занад, ҳатто
  /// агар аз Firestore навсозии нав наояд (масалан барнома хомӯш шуд).
  Timer? _typingExpiryTimer;
  DateTime? _watchedTypingAt;

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
  Future<void> _touchConversation(String preview, {String? type}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _conversationRef.set({
      'lastMessage': preview,
      // Навъи паём — то гиранда матни кӯтоҳро бо забони худаш бубинад.
      if (type != null) 'lastMessageType': type,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': uid,
      'unread': {widget.otherUserId: FieldValue.increment(1)},
      // Паёми нав чатро аз бойгонии ҳар ду тараф бармегардонад — чун WhatsApp.
      'archivedBy': FieldValue.arrayRemove([uid, widget.otherUserId]),
      'deletedBy': FieldValue.arrayRemove([uid, widget.otherUserId]),
    }, SetOptions(merge: true));
  }

  /// `true` — агар ҳамсӯҳбат дар 8 сонияи охир чизе навишта бошад. Тамға
  /// одатан худи барнома бардошта мешавад; ин мӯҳлат танҳо эҳтиёт аст, агар
  /// барнома пеш аз тоза кардан баста шавад.
  bool _otherIsTyping(Map<String, dynamic>? convoData) {
    final typing = convoData?['typing'] as Map<String, dynamic>?;
    final at = (typing?[widget.otherUserId] as Timestamp?)?.toDate();
    if (at == null) return false;
    final left = const Duration(seconds: 8) - DateTime.now().difference(at);
    if (left <= Duration.zero) return false;
    if (_watchedTypingAt != at) {
      _watchedTypingAt = at;
      _typingExpiryTimer?.cancel();
      _typingExpiryTimer = Timer(left, () {
        if (mounted) setState(() {});
      });
    }
    return true;
  }

  /// Пин кардани паём — матни он дар ҳуҷҷати сӯҳбат нигоҳ дошта мешавад, то
  /// барои ҳар ду тараф як хел бошад.
  Future<void> _pinMessage(ChatMessage message) async {
    final preview = message.text.trim().isNotEmpty ? message.text.trim() : tr('k286');
    await _conversationRef.set({
      'pinnedText': preview,
      'pinnedMessageId': message.id,
    }, SetOptions(merge: true));
  }

  Future<void> _unpinMessage() async {
    await _conversationRef.set({
      'pinnedText': '',
      'pinnedMessageId': '',
    }, SetOptions(merge: true));
  }

  /// Майдони мӯҳлат барои паёми нав — агар паёмҳои муваққатӣ фаъол бошанд.
  Map<String, dynamic> _expiryField() {
    if (_disappearIn <= 0) return const {};
    return {
      'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(seconds: _disappearIn))),
    };
  }

  /// Паёмҳои мӯҳлаташон гузашта воқеан нест карда мешаванд — то онҳо дар
  /// Firestore то абад намонанд. Ин ҳангоми кушодани чат як бор иҷро мешавад.
  void _purgeExpired(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    final expired = docs.where((d) {
      final at = (d.data()['expiresAt'] as Timestamp?)?.toDate();
      return at != null && now.isAfter(at);
    }).toList();
    if (expired.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final d in expired) {
        d.reference.delete().catchError((_) {});
      }
    });
  }

  /// Ба ҳамсӯҳбат хабар медиҳем, ки ман ҳозир менависам.
  Future<void> _setTyping(bool typing) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_typingSent == typing) return;
    _typingSent = typing;
    await _conversationRef.set({
      'typing': {uid: typing ? Timestamp.now() : FieldValue.delete()},
    }, SetOptions(merge: true)).catchError((_) {});
  }

  /// Ҳар тағйири матн нишонаро нав мекунад ва пас аз 4 сония онро мебардорад.
  void _onTyping(String value) {
    _typingTimer?.cancel();
    if (value.trim().isEmpty) {
      _setTyping(false);
      return;
    }
    _setTyping(true);
    _typingTimer = Timer(const Duration(seconds: 4), () => _setTyping(false));
  }

  /// Ҳангоми кушодани чат ҳисоби нохондашудаи ман сифр мешавад.
  Future<void> _clearMyUnread(String currentUid) async {
    await _conversationRef.set({
      'unread': {currentUid: 0},
    }, SetOptions(merge: true)).catchError((_) {});
  }

  @override
  void initState() {
    super.initState();
    _convoSub = _conversationRef.snapshots().listen((snap) {
      final data = snap.data();
      final value = (data?['disappearIn'] as num?)?.toInt() ?? 0;
      final pinned = (data?['pinnedText'] as String?) ?? '';
      if (!mounted) return;
      if (value != _disappearIn || pinned != _pinnedText) {
        setState(() {
          _disappearIn = value;
          _pinnedText = pinned;
        });
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _convoSub?.cancel();
    _typingTimer?.cancel();
    _typingExpiryTimer?.cancel();
    _setTyping(false);
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
        onLocationTap: _sendLocationMessage,
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
      ..._expiryField(),
      'mediaType': 'sticker',
    });
    await _touchConversation(tr('k314'), type: 'sticker');
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
      ..._expiryField(),
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
        ..._expiryField(),
        'mediaUrl': url,
        'mediaType': mediaType,
      });
      await _touchConversation(tr('k311'), type: 'image');
      _notifyOther(tr('k311'));
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
        parentRef: _conversationRef,
        latitude: position.latitude,
        longitude: position.longitude,
        preview: tr('k286'),
        unreadFor: [widget.otherUserId],
        disappearInSeconds: _disappearIn,
      ),
      tr('k286'),
    );
  }

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
          unreadFor: [widget.otherUserId],
        disappearInSeconds: _disappearIn,
        ),
        tr('k313'),
      );

  Future<void> _sendDocumentMessage(PlatformFile picked) => _sendMedia(
        () => ChatMediaService.sendDocument(
          messagesRef: _messagesRef,
          parentRef: _conversationRef,
          storageFolder: _storageFolder,
          picked: picked,
          unreadFor: [widget.otherUserId],
        disappearInSeconds: _disappearIn,
        ),
        trf('k316', [picked.name]),
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
        unreadFor: [widget.otherUserId],
        disappearInSeconds: _disappearIn,
      ),
      tr('k312'),
    );
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final replying = _replyingTo;
    _controller.clear();
    _typingTimer?.cancel();
    _setTyping(false);
    setState(() => _replyingTo = null);

    await _messagesRef.add({
      'text': text,
      'senderId': uid,
      'isAI': false,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      ..._expiryField(),
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
      // Калидҳо бояд маҳз ҳамонҳое бошанд, ки NotificationService интизор
      // аст — вагарна зер кардани огоҳинома ҳељ экранро намекушояд.
      data: {
        'type': 'chat_message',
        'kind': 'direct',
        'threadId': widget.conversationId,
        'threadName': myName,
        'senderId': uid,
        'senderName': myName,
      },
    );
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    await _messagesRef.doc(message.id).update({'deleted': true});
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

  /// [sendReceipts] — танзимоти «Хабари хондашуда». Агар хомӯш бошад, паём
  /// ҳамчун хонда қайд НАМЕШАВАД, яъне ҳамсӯҳбат ду тирчаи кабудро намебинад.
  /// Ҳисоби нохондашудаи худам ба ҳар ҳол сифр мешавад — он танҳо аз они ман аст.
  void _markIncomingAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String currentUid, {
    required bool sendReceipts,
  }) {
    if (!sendReceipts) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _clearMyUnread(currentUid));
      return;
    }
    _markIncomingAsReadInner(docs, currentUid);
  }

  void _markIncomingAsReadInner(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String currentUid) {
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
              final myData = userSnapshot.data?.data();
              final blockedList = List<String>.from(myData?['blockedUsers'] as List? ?? []);
              final iBlockedThem = blockedList.contains(widget.otherUserId);
              // «Хабари хондашуда» ду тарафа аст: касе ки онро хомӯш мекунад,
              // худаш низ тирчаҳои ҳамсӯҳбатро намебинад — мисли WhatsApp.
              final readReceipts =
                  ((myData?['settings'] as Map<String, dynamic>?)?['readReceipts'] ?? true) == true;

              return Column(
                children: [
                  _searching ? _buildSearchHeader() : _buildHeader(),
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
                        _purgeExpired(snapshot.data!.docs);
                        // Паёмҳое, ки ман барои худам нест кардаам ё мӯҳлаташон
                        // гузаштааст, намоён нестанд.
                        final now = DateTime.now();
                        final allDocs = snapshot.data!.docs.where((d) {
                          final data = d.data();
                          final hidden = List<String>.from(data['deletedFor'] as List? ?? []);
                          if (hidden.contains(currentUid)) return false;
                          final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
                          return expiresAt == null || now.isBefore(expiresAt);
                        }).toList();
                        if (allDocs.isEmpty) {
                          return Center(
                            child: Text(
                              trf('k213', [widget.otherUserName]),
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          );
                        }
                        if (currentUid.isNotEmpty) {
                          _markIncomingAsRead(allDocs, currentUid, sendReceipts: readReceipts);
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
                              showReadReceipts: readReceipts,
                              onReply: (m) => setState(() => _replyingTo = m),
                              onDelete: _deleteMessage,
                              onReact: _reactToMessage,
                              onEdit: _editMessage,
                              onDeleteForMe: _deleteForMe,
                              onPin: _pinMessage,
                              messageRef: _messagesRef.doc(message.id),
                              chatTitle: widget.otherUserName,
                            );
                          },
                        );
                      },
                    )),
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
                    UserAvatar(name: widget.otherUserName, uid: widget.otherUserId, size: 40),
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
                            stream: _conversationRef.snapshots(),
                            builder: (context, convoSnapshot) {
                              if (_otherIsTyping(convoSnapshot.data?.data())) {
                                return Text(
                                  tr('k279'),
                                  style: TextStyle(color: AppColors.neonEmerald, fontSize: 11.5),
                                );
                              }
                              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
            // Нишони паёмҳои муваққатӣ — то корбар фаромӯш накунад, ки он фаъол аст.
            if (_disappearIn > 0)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(LucideIcons.timer, color: AppColors.neonEmerald, size: 17),
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
                      onChanged: _onTyping,
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
