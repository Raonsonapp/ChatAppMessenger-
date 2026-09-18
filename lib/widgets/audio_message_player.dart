import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import '../services/media_service.dart';
import '../theme/app_scope.dart';

/// Паёми овозӣ дар чат: тугмаи пахш, хати пешравии кашидашаванда, вақт ва
/// суръати пахш (1x / 1.5x / 2x).
class AudioMessagePlayer extends StatefulWidget {
  final String url;

  /// Давомнокии ҳангоми сабт ҳисобшуда — то пеш аз боркунӣ ҳам вақт намоён бошад.
  final int? durationSeconds;
  final bool isMe;

  const AudioMessagePlayer({
    super.key,
    required this.url,
    required this.isMe,
    this.durationSeconds,
  });

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  late final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subs = [];

  Duration _position = Duration.zero;
  Duration? _total;
  bool _playing = false;

  /// Суръати пахш — 1x, 1.5x, 2x, мисли WhatsApp.
  static const List<double> _speeds = [1.0, 1.5, 2.0];
  int _speedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.durationSeconds != null) {
      _total = Duration(seconds: widget.durationSeconds!);
    }
    _subs.add(_player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    }));
    _subs.add(_player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    }));
    _subs.add(_player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    }));
  }

  Future<void> _cycleSpeed() async {
    setState(() => _speedIndex = (_speedIndex + 1) % _speeds.length);
    await _player.setPlaybackRate(_speeds[_speedIndex]);
  }

  /// Ба ҷои дилхоҳи паём гузаштан — кашидани хати пешравӣ.
  Future<void> _seekTo(double fraction) async {
    final total = _total;
    if (total == null || total.inMilliseconds == 0) return;
    final target = Duration(
      milliseconds: (total.inMilliseconds * fraction.clamp(0.0, 1.0)).round(),
    );
    setState(() => _position = target);
    await _player.seek(target);
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    await _player.play(UrlSource(widget.url));
    if (mounted) setState(() => _playing = true);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final total = _total ?? Duration.zero;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final tint = widget.isMe ? AppColors.background : AppColors.textPrimary;

    return SizedBox(
      width: 210,
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (widget.isMe ? AppColors.background : AppColors.neonEmerald)
                    .withValues(alpha: 0.18),
              ),
              child: Icon(_playing ? LucideIcons.pause : LucideIcons.play, color: tint, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Хат ҳам пешравиро нишон медиҳад, ҳам барои гузаштан кашида мешавад.
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => _seekTo(d.localPosition.dx / constraints.maxWidth),
                      onHorizontalDragUpdate: (d) =>
                          _seekTo(d.localPosition.dx / constraints.maxWidth),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: tint.withValues(alpha: 0.22),
                            valueColor: AlwaysStoppedAnimation<Color>(tint),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    Text(
                      MediaService.formatDuration(
                          _playing || _position > Duration.zero ? _position : total),
                      style: TextStyle(color: tint.withValues(alpha: 0.85), fontSize: 11.5),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _cycleSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_speeds[_speedIndex]}x'.replaceAll('.0x', 'x'),
                          style: TextStyle(
                            color: tint,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
