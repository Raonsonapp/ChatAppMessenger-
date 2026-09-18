import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_theme.dart';
import '../theme/app_scope.dart';

/// Видео дар чат. То даме ки корбар пахш накунад, видео боргирӣ намешавад —
/// вагарна ҳар кушодани чат ҳамаи видеоҳоро мекашид.
class VideoMessagePlayer extends StatefulWidget {
  final String url;
  const VideoMessagePlayer({super.key, required this.url});

  @override
  State<VideoMessagePlayer> createState() => _VideoMessagePlayerState();
}

class _VideoMessagePlayerState extends State<VideoMessagePlayer> {
  VideoPlayerController? _controller;
  bool _loading = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await controller.initialize();
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _loading = false;
    });
    await controller.play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final controller = _controller;

    if (controller == null) {
      return GestureDetector(
        onTap: _loading ? null : _load,
        child: Container(
          width: 220,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black.withValues(alpha: 0.45),
          ),
          child: Center(
            child: _loading
                ? CircularProgressIndicator(color: AppColors.neonEmerald, strokeWidth: 2)
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    child: const Icon(LucideIcons.play, color: Colors.black, size: 22),
                  ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 220,
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(controller),
              VideoProgressIndicator(controller, allowScrubbing: true),
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      controller.value.isPlaying ? controller.pause() : controller.play();
                    });
                  },
                  child: controller.value.isPlaying
                      ? const SizedBox.shrink()
                      : Container(
                          color: Colors.black26,
                          child: const Icon(LucideIcons.play, color: Colors.white, size: 40),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
