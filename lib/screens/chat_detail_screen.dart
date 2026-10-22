import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';

import '../theme/app_theme.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../services/media_service.dart';
import '../services/chat_ai_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_bubble.dart';
import '../widgets/attachment_sheet.dart';
import '../widgets/emoji_picker_sheet.dart';
import '../widgets/sticker_picker_sheet.dart';
import '../l10n/l10n.dart';
import '../widgets/chat_wallpaper.dart';
import '../theme/app_scope.dart';
import '../widgets/upload_indicator.dart';

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
  bool _isGeneratingMedia = false;
  bool _isUploading = false;
  ChatMessage? _replyingTo;
  List<Map<String, String>> _aiProviders = const [{'id': 'gemini', 'label': 'Gemini'}];
  String _selectedAiProvider = 'gemini';
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _recordingTimer;
  DateTime? _recordingStartedAt;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  bool _isRecordingAudio = false;
  bool _isPausedAudio = false;
  bool _isLockedAudio = false;
  bool _cancelAudioByGesture = false;
  bool _showRecordedAudioPreview = false;
  String? _recordingVideoPath;
  bool _isLockedVideo = false;
  bool _cancelVideoByGesture = false;
  bool _isRecordingVideo = false;
  Duration _videoDuration = Duration.zero;
  Timer? _videoTimer;


  CollectionReference<Map<String, dynamic>> get _messagesRef {
    final firestore = FirebaseFirestore.instance;
    if (widget.conversation.isAIChat) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Таърихи AI барои ҳар корбар ҷудо ва махфӣ нигоҳ дошта мешавад.
        return firestore
            .collection('users')
            .doc(uid)
            .collection('aiChat')
            .doc('main')
            .collection('messages');
      }
    }
    return firestore
        .collection('chats')
        .doc(widget.conversation.id)
        .collection('messages');
  }

  @override
  void initState() {
    super.initState();
    if (widget.conversation.isAIChat) _loadAiProviders();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _controller.text = widget.initialText!;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  Future<void> _loadAiProviders() async {
    final providers = await ChatAiService.availableProviders();
    if (!mounted) return;
    setState(() {
      _aiProviders = providers;
      if (!providers.any((item) => item['id'] == _selectedAiProvider)) {
        _selectedAiProvider = providers.first['id'] ?? 'gemini';
      }
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _videoTimer?.cancel();
    _audioRecorder.dispose();
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
      // Ба ChatAI контакт фиристодан ва ба он занг задан маъно надорад,
      // бинобар ин он бандҳо умуман нишон дода намешаванд — ин аз «ба зудӣ»
      // гуфтан ростқавлона аст.
      builder: (_) => AttachmentSheet(
        onImagePicked: _sendImageMessage,
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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    await _messagesRef.add({
      'text': sticker,
      'senderId': uid,
      'isAI': false,
      'createdAt': FieldValue.serverTimestamp(),
      'mediaType': 'sticker',
    });
    _scrollToBottom();
  }

  Future<void> _sendImageMessage(XFile file, {String mediaType = 'image'}) async {
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
        'mediaType': mediaType,
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(trf('k028', [e]))),
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
      _requestAIReply(text);
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    await _messagesRef.doc(message.id).update({'deleted': true});
  }

  /// Ба AI-и воқеӣ тавассути сервер муроҷиат мекунад; ҷавобҳои сохта истифода намешаванд.
  Future<void> _requestAIReply(String latestPrompt) async {
    if (!mounted) return;
    setState(() => _isAITyping = true);
    _scrollToBottom();
    try {
      final snapshot = await _messagesRef
          .orderBy('createdAt', descending: false)
          .limitToLast(12)
          .get();
      final history = <Map<String, String>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final text = (data['text'] ?? '').toString().trim();
        if (text.isEmpty || data['deleted'] == true) continue;
        history.add({
          'role': data['isAI'] == true ? 'assistant' : 'user',
          'text': text,
        });
      }
      if (history.isEmpty ||
          history.last['role'] != 'user' ||
          history.last['text'] != latestPrompt) {
        history.add({'role': 'user', 'text': latestPrompt});
      }
      final reply = await ChatAiService.reply(history, provider: _selectedAiProvider);
      await _messagesRef.add({
        'text': reply,
        'senderId': 'ai_bot',
        'isAI': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _scrollToBottom();
    } catch (error) {
      if (mounted) {
        final message = error is ChatAiFailure
            ? error.message
            : 'Ба ChatAI пайваст нашуд. Интернет ва серверро санҷед.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) setState(() => _isAITyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
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
                child: ChatWallpaper(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _messagesRef.orderBy('createdAt', descending: false).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            trf('k029', [snapshot.error]),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
                    }
                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty && convo.isAIChat) {
                      return _buildEmptyAiState();
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      itemCount: docs.length + ((_isAITyping || _isGeneratingMedia) ? 1 : 0),
                      itemBuilder: (context, index) {
                        if ((_isAITyping || _isGeneratingMedia) && index == docs.length) {
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
                )),
              ),
              if (_replyingTo != null) _buildReplyPreview(),
              if (convo.isAIChat) _buildAiTools(),
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

  Widget _buildAiTools() {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _aiToolButton(LucideIcons.image, tr('k720'), 'image'),
          const SizedBox(width: 8),
          _aiToolButton(LucideIcons.video, tr('k721'), 'video'),
          const SizedBox(width: 8),
          _aiToolButton(LucideIcons.music, tr('k722'), 'music'),
        ],
      ),
    );
  }

  Widget _aiToolButton(IconData icon, String label, String kind) {
    return OutlinedButton.icon(
      onPressed: _isAITyping || _isGeneratingMedia || _isUploading ? null : () => _openMediaGeneration(kind),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.neonCyan,
        side: BorderSide(color: AppColors.glassBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _openMediaGeneration(String kind) async {
    final promptController = TextEditingController();
    var durationSeconds = 8;
    final prompt = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            kind == 'image' ? tr('k720') : kind == 'video' ? tr('k721') : tr('k722'),
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: promptController,
                  autofocus: true,
                  maxLines: 4,
                  minLines: 2,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: tr('k042'),
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                if (kind == 'video') ...[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${tr('k723')}: $durationSeconds'),
                  ),
                  Slider(
                    value: durationSeconds.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: '$durationSeconds',
                    onChanged: (value) => setDialogState(() => durationSeconds = value.round()),
                  ),
                ],
                const SizedBox(height: 8),
                Text(tr('k728'), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr('k715')),
            ),
            FilledButton(
              onPressed: () {
                final value = promptController.text.trim();
                if (value.length >= 3) Navigator.pop(dialogContext, value);
              },
              child: Text(tr('k724')),
            ),
          ],
        ),
      ),
    );
    promptController.dispose();
    if (prompt == null || prompt.trim().isEmpty || !mounted) return;

    setState(() => _isGeneratingMedia = true);
    try {
      final result = await ChatAiService.generateMedia(
        kind: kind,
        prompt: prompt,
        durationSeconds: durationSeconds,
      );
      await _messagesRef.add({
        'text': prompt,
        'senderId': 'ai_bot',
        'isAI': true,
        'createdAt': FieldValue.serverTimestamp(),
        'mediaUrl': result.url,
        'mediaType': kind == 'music' ? 'audio' : kind,
        if (result.durationSeconds != null) 'mediaDuration': result.durationSeconds,
      });
      _scrollToBottom();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k726'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k730'))));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingMedia = false);
    }
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
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
              child: Icon(LucideIcons.zap, color: AppColors.background, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              tr('k030'),
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              tr('k031'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 12.5),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _suggestionChip(LucideIcons.image, tr('k032'), tr('k033')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _suggestionChip(LucideIcons.music, tr('k034'), tr('k035')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _suggestionChip(LucideIcons.video, tr('k036'), tr('k037')),
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
              Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600)),
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
              icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
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
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  Text(
                    convo.isAIChat ? tr('k038') : tr('k039'),
                    style: TextStyle(color: AppColors.neonEmerald, fontSize: 11),
                  ),
                  if (convo.isAIChat && _aiProviders.length > 1)
                    SizedBox(
                      height: 30,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _aiProviders.any((item) => item['id'] == _selectedAiProvider)
                              ? _selectedAiProvider
                              : _aiProviders.first['id'],
                          isDense: true,
                          dropdownColor: AppColors.surface,
                          style: TextStyle(color: AppColors.neonCyan, fontSize: 12),
                          items: _aiProviders.map((item) => DropdownMenuItem<String>(
                            value: item['id'],
                            child: Text(item['label'] ?? item['id'] ?? 'AI'),
                          )).toList(),
                          onChanged: _isAITyping ? null : (value) {
                            if (value != null) setState(() => _selectedAiProvider = value);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  /// Композитори тарзи WhatsApp: emoji (берун) — матн+замима+камера (дохили pill) — SEND (берун)
  Future<String> _audioTempPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/chatapp-voice-${DateTime.now().microsecondsSinceEpoch}.m4a';
  }

  Future<void> _startAudioRecording({bool locked = false}) async {
    if (_isRecordingAudio || _isUploading) return;
    try {
      final allowed = await _audioRecorder.hasPermission();
      if (!allowed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Барои сабти овоз иҷозати микрофон лозим аст.')),
          );
        }
        return;
      }
      final path = await _audioTempPath();
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 96000, sampleRate: 44100),
        path: path,
      );
      if (!mounted) {
        await _audioRecorder.cancel();
        return;
      }
      setState(() {
        _recordingPath = path;
        _recordingStartedAt = DateTime.now();
        _recordingDuration = Duration.zero;
        _isRecordingAudio = true;
        _isPausedAudio = false;
        _isLockedAudio = locked;
        _cancelAudioByGesture = false;
        _showRecordedAudioPreview = false;
      });
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted || !_isRecordingAudio || _isPausedAudio || _recordingStartedAt == null) return;
        setState(() => _recordingDuration = DateTime.now().difference(_recordingStartedAt!));
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сабти овоз оғоз нашуд. Иҷозати микрофонро санҷед.')),
      );
    }
  }

  Future<void> _pauseOrResumeAudio() async {
    if (!_isRecordingAudio) return;
    try {
      if (_isPausedAudio) {
        await _audioRecorder.resume();
        setState(() {
          _isPausedAudio = false;
          _recordingStartedAt = DateTime.now().subtract(_recordingDuration);
        });
      } else {
        await _audioRecorder.pause();
        setState(() {
          _isPausedAudio = true;
          if (_recordingStartedAt != null) _recordingDuration = DateTime.now().difference(_recordingStartedAt!);
        });
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Идора кардани сабти овоз муваффақ нашуд.')),
      );
    }
  }

  Future<void> _cancelAudioRecording() async {
    _recordingTimer?.cancel();
    try { await _audioRecorder.cancel(); } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isRecordingAudio = false;
      _isPausedAudio = false;
      _isLockedAudio = false;
      _recordingPath = null;
      _showRecordedAudioPreview = false;
      _recordingDuration = Duration.zero;
    });
  }

  Future<void> _finishAudioRecordingForPreview() async {
    _recordingTimer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      if (!mounted) return;
      setState(() {
        _recordingPath = path ?? _recordingPath;
        _isRecordingAudio = false;
        _isPausedAudio = false;
        _isLockedAudio = false;
        _showRecordedAudioPreview = true;
      });
    } catch (_) {
      await _cancelAudioRecording();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сабти овоз нигоҳ дошта нашуд. Боз кӯшиш кунед.')),
      );
    }
  }

  Future<void> _uploadAndSendAudio() async {
    final path = _recordingPath;
    if (path == null || !File(path).existsSync()) return;
    _recordingTimer?.cancel();
    try {
      final duration = _recordingDuration;
      final url = await MediaService.uploadFile(File(path), 'voice-${DateTime.now().millisecondsSinceEpoch}.m4a', 'chats/${widget.conversation.id}');
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw StateError('auth-required');
      await _messagesRef.add({
        'text': '',
        'senderId': uid,
        'isAI': false,
        'createdAt': FieldValue.serverTimestamp(),
        'mediaUrl': url,
        'mediaType': 'audio',
        'durationMs': duration.inMilliseconds,
      });
      if (!mounted) return;
      setState(() {
        _isRecordingAudio = false;
        _isPausedAudio = false;
        _isLockedAudio = false;
        _recordingPath = null;
        _showRecordedAudioPreview = false;
        _recordingDuration = Duration.zero;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Овози сабтшуда фиристода нашуд. Интернет ва иҷозати боркуниро санҷед.')),
      );
    }
  }

  Future<void> _startVideoCapture() async {
    if (_isRecordingVideo || _isUploading) return;
    try {
      final file = await MediaService.recordVideo();
      if (file == null || !mounted) return;
      setState(() {
        _recordingVideoPath = file.path;
        _videoDuration = Duration.zero;
        _isRecordingVideo = true;
        _isLockedVideo = false;
        _cancelVideoByGesture = false;
      });
      _videoTimer?.cancel();
      _videoTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted || !_isRecordingVideo) return;
        setState(() => _videoDuration += const Duration(milliseconds: 200));
      });
      await _sendImageMessage(file, mediaType: 'video');
      if (!mounted) return;
      setState(() => _isRecordingVideo = false);
      _videoTimer?.cancel();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Камераи видео кушода нашуд. Иҷозати камераро санҷед.')),
      );
    }
  }

  String _formatRecordTime(Duration value) {
    final total = value.inSeconds;
    return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
  }

  Widget _recordingAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Expanded(
      child: Material(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingPreview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: _isPausedAudio ? AppColors.textSecondary : const Color(0xFFFF5263), shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Text(_formatRecordTime(_recordingDuration), style: TextStyle(color: AppColors.textPrimary, fontSize: 23, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(18, (i) => Container(
                    width: 3,
                    height: 8 + ((i * 7 + _recordingDuration.inMilliseconds ~/ 100) % 21).toDouble(),
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: AppColors.neonCyan.withValues(alpha: 0.45 + (i % 3) * 0.15), borderRadius: BorderRadius.circular(3)),
                  )),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: _isPausedAudio ? 'Давом додан' : 'Таваққуф',
                  onPressed: _pauseOrResumeAudio,
                  icon: Icon(_isPausedAudio ? LucideIcons.play : LucideIcons.pause, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Нест кардани сабт',
                  onPressed: _cancelAudioRecording,
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF51232D), foregroundColor: const Color(0xFFFF6878)),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(child: _recordingAction(
                  icon: LucideIcons.mic,
                  label: _isPausedAudio ? 'Сабт таваққуф аст' : 'Сабт шуда истодааст',
                  onTap: _pauseOrResumeAudio,
                )),
                const SizedBox(width: 10),
                IconButton.filled(
                  tooltip: 'Фиристодани овоз',
                  onPressed: _isUploading ? null : _uploadAndSendAudio,
                  style: IconButton.styleFrom(backgroundColor: AppColors.neonCyan, foregroundColor: AppColors.background, fixedSize: const Size(54,54)),
                  icon: _isUploading ? const SizedBox(width: 18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(LucideIcons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    if (_isRecordingAudio || _showRecordedAudioPreview) {
      return _buildRecordingPreview();
    }
    if (_isRecordingVideo) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(28)),
          child: Row(children: [
            const Icon(LucideIcons.circle, color: Color(0xFFFF5263), size: 13),
            const SizedBox(width: 10),
            Text('Видео ${_formatRecordTime(_videoDuration)}', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(onPressed: () { setState(() => _isRecordingVideo = false); _videoTimer?.cancel(); }, icon: const Icon(LucideIcons.x, color: Color(0xFFFF6878))),
          ]),
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
                    tooltip: 'Сабти видео',
                    onPressed: _isUploading ? null : _startVideoCapture,
                    icon: Icon(LucideIcons.camera, color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (_controller.text.trim().isEmpty)
            GestureDetector(
              onLongPressStart: (_) => _startAudioRecording(),
              onLongPressMoveUpdate: (details) {
                if (!_isRecordingAudio) return;
                if (details.offsetFromOrigin.dy < -90 && !_isLockedAudio) {
                  setState(() => _isLockedAudio = true);
                }
                if (details.offsetFromOrigin.dx < -100) {
                  setState(() => _cancelAudioByGesture = true);
                }
              },
              onLongPressEnd: (details) {
                if (!_isRecordingAudio || _isLockedAudio) return;
                if (_cancelAudioByGesture) {
                  _cancelAudioRecording();
                } else {
                  _finishAudioRecordingForPreview();
                }
              },
              child: GestureDetector(
                onTap: _startAudioRecording,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.neonCyan),
                  child: Icon(LucideIcons.mic, color: AppColors.background, size: 26),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _isUploading ? null : _handleSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
                child: _isUploading
                    ? Center(child: UploadIndicator(color: AppColors.background))
                    : Icon(LucideIcons.arrow_up, color: AppColors.background, size: 19),
              ),
            ),
        ],
      ),
    );
  }
}
