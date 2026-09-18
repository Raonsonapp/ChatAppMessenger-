import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/l10n.dart';
import '../services/media_download_service.dart';
import '../theme/app_scope.dart';
import '../utils/download_error.dart';
import '../widgets/net_image.dart';

/// Расми пурраи экран бо имкони калон кардан — мисли WhatsApp.
class ImageViewerScreen extends StatefulWidget {
  final String url;

  /// Номи фиристанда ё чат — дар болои расм нишон дода мешавад.
  final String? title;
  const ImageViewerScreen({super.key, required this.url, this.title});

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    String message;
    try {
      await MediaDownloadService.saveImage(widget.url);
      message = tr('k376');
    } catch (error) {
      message = describeDownloadError(error);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: NetImage(
                  url: widget.url,
                  fit: BoxFit.contain,
                  loading: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: const Icon(
                    LucideIcons.triangle_alert,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, color: Colors.white, size: 22),
                ),
                Expanded(
                  child: Text(
                    widget.title ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                IconButton(
                  tooltip: tr('k377'),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.download, color: Colors.white, size: 20),
                ),
                IconButton(
                  onPressed: () =>
                      launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication),
                  icon: const Icon(LucideIcons.external_link, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
