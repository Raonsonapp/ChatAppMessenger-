import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:video_player/video_player.dart';

import '../l10n/l10n.dart';
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
  bool _failed = false;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });

    VideoPlayerController? controller;
    try {
      controller = await _createController();
      await controller.initialize();
    } catch (_) {
      // Пештар ин истисно ҳељ гирифта намешуд: давра то абад чарх мезад ва
      // корбар намедонист, ки видео кушода нашуд.
      controller?.dispose();
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
      return;
    }

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

  /// Агар видео аллакай дар кэш бошад, аз файл хонда мешавад — фавран ва бе
  /// интернет. Вагарна аз шабака.
  Future<VideoPlayerController> _createController() async {
    try {
      final cached = await DefaultCacheManager().getFileFromCache(widget.url);
      if (cached != null && await cached.file.exists()) {
        return VideoPlayerController.file(File(cached.file.path));
      }
      // Дар паси замина зеркашӣ мешавад, то дафъаи дигар аз кэш кушода шавад.
      unawaited(DefaultCacheManager().downloadFile(widget.url));
    } catch (_) {
      // Кэш дастнорас — бевосита аз шабака.
    }
    return VideoPlayerController.networkUrl(Uri.parse(widget.url));
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
                : _failed
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.triangle_alert, color: Colors.white70, size: 26),
                          const SizedBox(height: 6),
                          Text(
                            tr('k383'),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      )
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
