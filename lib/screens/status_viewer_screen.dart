import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../models/app_status.dart';

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
    super.dispose();
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
                  decoration: const BoxDecoration(gradient: AppColors.neonGradient),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    status.text ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.w800, fontSize: 26),
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
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.surface,
                      child: Text(status.ownerName.isNotEmpty ? status.ownerName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(status.ownerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    if (widget.isOwn)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text('${status.viewedBy.length} дида', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x, color: Colors.white, size: 22),
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
