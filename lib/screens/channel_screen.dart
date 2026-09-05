import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../models/chat_message.dart';
import '../services/media_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/message_bubble.dart';
import '../widgets/attachment_sheet.dart';

/// Тасмаи пахши канал — танҳо соҳиб (ownerId) паём мефиристад,
/// обунашудагон танҳо мехонанд.
class ChannelScreen extends StatefulWidget {
  final String channelId;
  const ChannelScreen({super.key, required this.channelId});

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isUploading = false;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>> get _channelRef =>
      FirebaseFirestore.instance.collection('channels').doc(widget.channelId);
  CollectionReference<Map<String, dynamic>> get _messagesRef => _channelRef.collection('messages');

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

  Future<void> _toggleFollow(bool isFollowing) async {
    await _channelRef.update({
      'followers': isFollowing ? FieldValue.arrayRemove([_currentUid]) : FieldValue.arrayUnion([_currentUid]),
    });
  }

  Future<void> _post() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _messagesRef.add({
      'text': text,
      'senderId': _currentUid,
      'isAI': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _channelRef.set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _scrollToBottom();
  }

  Future<void> _postImage(XFile file) async {
    setState(() => _isUploading = true);
    try {
      final url = await MediaService.uploadImage(file, 'channels/${widget.channelId}');
      await _messagesRef.add({
        'text': '',
        'senderId': _currentUid,
        'isAI': false,
        'createdAt': FieldValue.serverTimestamp(),
        'mediaUrl': url,
        'mediaType': 'image',
      });
      await _channelRef.set({
        'lastMessage': '📷 Расм',
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _openAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachmentSheet(onImagePicked: _postImage, onContactTap: () {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: NeonBackdrop(
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _channelRef.snapshots(),
            builder: (context, channelSnap) {
              if (!channelSnap.hasData || !channelSnap.data!.exists) {
                return const Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
              }
              final data = channelSnap.data!.data()!;
              final name = (data['name'] ?? 'Канал') as String;
              final ownerId = (data['ownerId'] ?? '') as String;
              final followers = List<String>.from(data['followers'] as List? ?? []);
              final isOwner = ownerId == _currentUid;
              final isFollowing = followers.contains(_currentUid);

              return Column(
                children: [
                  _buildHeader(name, followers.length, isOwner),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _messagesRef.orderBy('createdAt', descending: false).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
                        }
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return Center(
                            child: Text(
                              isOwner ? 'Аввалин паёмро дар канали худ нашр кунед' : 'Ин канал ҳанӯз паём нашр накардааст',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                            return MessageBubble(message: message, isMe: false, currentUid: _currentUid, showReadReceipts: false);
                          },
                        );
                      },
                    ),
                  ),
                  if (isOwner) _buildInputBar() else _buildFollowBar(isFollowing),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, int followerCount, bool isOwner) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
      child: GlassContainer(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 18),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: AppColors.glassBorder)),
              child: const Icon(LucideIcons.hash, color: AppColors.textSecondary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('$followerCount обунашуда', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowBar(bool isFollowing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _toggleFollow(isFollowing),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: isFollowing ? Colors.redAccent : AppColors.neonEmerald),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            isFollowing ? 'Бекор кардани обуна' : 'Обуна шудан',
            style: TextStyle(color: isFollowing ? Colors.redAccent : AppColors.neonEmerald, fontWeight: FontWeight.w700),
          ),
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
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppColors.textPrimary),
                      maxLines: 4,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Паёми нашрӣ',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isUploading ? null : _openAttachmentSheet,
                    icon: const Icon(LucideIcons.paperclip, color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isUploading ? null : _post,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
              child: _isUploading
                  ? const Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                  : const Icon(LucideIcons.arrow_up, color: AppColors.background, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}
