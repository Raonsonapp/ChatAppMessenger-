import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_scope.dart';
import '../widgets/net_image.dart';

/// Расми пурраи экран бо имкони калон кардан — мисли WhatsApp.
class ImageViewerScreen extends StatelessWidget {
  final String url;

  /// Номи фиристанда ё чат — дар болои расм нишон дода мешавад.
  final String? title;
  const ImageViewerScreen({super.key, required this.url, this.title});

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
                  url: url,
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
                    title ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                IconButton(
                  onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
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
