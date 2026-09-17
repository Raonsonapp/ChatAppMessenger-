import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../models/app_status.dart';
import '../models/app_conversation.dart';
import '../services/push_service.dart';
import '../l10n/l10n.dart';
import '../widgets/user_avatar.dart';

/// Намоиши пурраи навсозиҳо (мисли Stories) — гузариши худкор, progress bar
/// дар боло, ва сабти воқеии viewedBy дар Firestore.
class StatusViewerScreen extends StatefulWidget {
  final List<AppStatus> statuses;
  final bool isOwn;
  const StatusViewerScreen({super.key, required this.statuses, this.isOwn = false});

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> {
  int _index = 0;
  Timer? _timer;
  final TextEditingController _replyController = TextEditingController();
  bool _sendingReply = false;
  double _progress = 0;
  static const _duration = Duration(seconds: 5);
  static const _tick = Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();
    _startTimer();
    _markViewed();
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0;
    _timer = Timer.periodic(_tick, (t) {
      setState(() => _progress += _tick.inMilliseconds / _duration.inMilliseconds);
      if (_progress >= 1) _next();
    });
  }

  /// Рӯйхати онҳое, ки ин навсозиро дидаанд.
  void _showViewers(List<String> viewers) {
    _timer?.cancel();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trf('k196', [viewers.length]),
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 10),
              if (viewers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(tr('k289'), style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: viewers.length,
                    itemBuilder: (context, i) => _ViewerRow(uid: viewers[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (mounted) _startTimer();
    });
  }

  void _markViewed() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.isOwn) return;
    final status = widget.statuses[_index];
    if (status.viewedBy.contains(uid)) return;
    FirebaseFirestore.instance
        .collection('statuses')
        .doc(status.ownerId)
        .collection('items')
        .doc(status.id)
        .update({
      'viewedBy': FieldValue.arrayUnion([uid]),
    });
  }

  void _next() {
    if (_index >= widget.statuses.length - 1) {
      Navigator.pop(context);
      return;
    }
    setState(() => _index++);
    _markViewed();
    _startTimer();
  }

  void _prev() {
    if (_index == 0) return;
    setState(() => _index--);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _replyController.dispose();
    super.dispose();
  }

  /// Ҷавоб ба навсозӣ — ҳамчун паёми одӣ ба сӯҳбати шахсӣ бо соҳиб меравад,
  /// бо иқтибоси кӯтоҳи худи навсозӣ (мисли WhatsApp).
  Future<void> _sendReply() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final text = _replyController.text.trim();
    if (uid == null || text.isEmpty || _sendingReply) return;

    final status = widget.statuses[_index];
    setState(() => _sendingReply = true);
    try {
      final db = FirebaseFirestore.instance;
      final conversationId = AppConversation.idFor(uid, status.ownerId);
      final myDoc = await db.collection('users').doc(uid).get();
      final myName = (myDoc.data()?['name'] as String?) ?? tr('k002');
      final convoRef = db.collection('conversations').doc(conversationId);

      // Сӯҳбат метавонад ҳанӯз вуҷуд надошта бошад — онро месозем.
      await convoRef.set({
        'participants': [uid, status.ownerId],
        'participantNames': {uid: myName, status.ownerId: status.ownerName},
      }, SetOptions(merge: true));

      final quoted = status.text?.trim().isNotEmpty == true ? status.text!.trim() : tr('k296');
      await convoRef.collection('messages').add({
        'text': text,
        'senderId': uid,
        'isAI': false,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'replyToText': quoted,
        'replyToSenderId': status.ownerId,
      });
      await convoRef.set({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': uid,
        'unread': {status.ownerId: FieldValue.increment(1)},
        'archivedBy': FieldValue.arrayRemove([uid, status.ownerId]),
        'deletedBy': FieldValue.arrayRemove([uid, status.ownerId]),
      }, SetOptions(merge: true));

      await PushService.notify(
        toUid: status.ownerId,
        title: myName,
        body: text,
        data: {
          'type': 'chat_message',
          'kind': 'direct',
          'threadId': conversationId,
          'threadName': myName,
          'senderId': uid,
          'senderName': myName,
        },
      );

      _replyController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k297'))));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trf('k049', [e]))));
      }
    } finally {
      if (mounted) setState(() => _sendingReply = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.statuses[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapUp: (details) {
            final width = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < width / 3) {
              _prev();
            } else {
              _next();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (status.imageUrl != null)
                Image.network(status.imageUrl!, fit: BoxFit.contain)
              else
                Container(
                  decoration: BoxDecoration(gradient: AppColors.neonGradient),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    status.text ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.background, fontWeight: FontWeight.w800, fontSize: 26),
                  ),
                ),
              if (status.imageUrl != null && status.text != null && status.text!.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 40,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(status.text!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                ),
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: List.generate(widget.statuses.length, (i) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: i < _index ? 1 : (i == _index ? _progress.clamp(0, 1) : 0),
                          child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Positioned(
                top: 20,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    UserAvatar(name: status.ownerName, uid: status.ownerId, size: 32),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(status.ownerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    // Соҳиб шумораи дидаҳоро мебинад ва бо зер кардан рӯйхати
                    // онҳоеро, ки дидаанд, мекушояд.
                    if (widget.isOwn)
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('statuses')
                            .doc(status.ownerId)
                            .collection('items')
                            .doc(status.id)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final viewers = List<String>.from(
                            snapshot.data?.data()?['viewedBy'] as List? ?? status.viewedBy,
                          );
                          return InkWell(
                            onTap: () => _showViewers(viewers),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.eye, color: Colors.white70, size: 15),
                                  const SizedBox(width: 4),
                                  Text(
                                    trf('k196', [viewers.length]),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
              // Ҷавоб ба навсозӣ — танҳо барои навсозии каси дигар.
              if (!widget.isOwn)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: TextField(
                            controller: _replyController,
                            style: const TextStyle(color: Colors.white, fontSize: 14.5),
                            onTap: () => _timer?.cancel(),
                            onSubmitted: (_) => _sendReply(),
                            decoration: InputDecoration(
                              hintText: tr('k298'),
                              hintStyle: const TextStyle(color: Colors.white60, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendingReply ? null : _sendReply,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.neonEmerald,
                          ),
                          child: _sendingReply
                              ? Padding(
                                  padding: const EdgeInsets.all(13),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.background,
                                  ),
                                )
                              : Icon(LucideIcons.send, color: AppColors.background, size: 19),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Як сатр дар рӯйхати дидаҳо — ном аз ҳуҷҷати корбар гирифта мешавад.
class _ViewerRow extends StatelessWidget {
  final String uid;
  const _ViewerRow({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        final name = (snapshot.data?.data()?['name'] as String?) ?? tr('k002');
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: UserAvatar(name: name, uid: uid, size: 38),
          title: Text(name, style: TextStyle(color: AppColors.textPrimary, fontSize: 14.5)),
        );
      },
    );
  }
}
