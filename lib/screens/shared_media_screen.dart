import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/media_service.dart';
import '../theme/app_theme.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/empty_state.dart';
import 'image_viewer_screen.dart';
import '../l10n/l10n.dart';

/// «Медиа, ҳуҷҷатҳо» — ҳамаи файлҳое, ки дар ҳамин чат мубодила шудаанд.
///
/// Дархост бе филтри `mediaUrl` аст: Firestore барои `!= null` индекси
/// алоҳида талаб мекунад, ва рӯйхатро дар Dart ҷудо кардан осонтар аст.
class SharedMediaScreen extends StatelessWidget {
  /// Роҳи ҳуҷҷати сӯҳбат, гурӯҳ ё ҷамъият — `.../messages` аз ҳамин ҷо меояд.
  final String parentPath;
  final String title;
  const SharedMediaScreen({super.key, required this.parentPath, required this.title});

  @override
  Widget build(BuildContext context) {
    final messages = FirebaseFirestore.instance.doc(parentPath).collection('messages');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 22),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: messages.orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
                    }
                    final media = (snapshot.data?.docs ?? const [])
                        .where((d) {
                          final data = d.data();
                          return data['mediaUrl'] != null &&
                              data['deleted'] != true &&
                              data['mediaType'] != 'location';
                        })
                        .toList();
                    if (media.isEmpty) {
                      return EmptyState(icon: LucideIcons.images, title: tr('k340'));
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemCount: media.length,
                      itemBuilder: (context, i) {
                        final data = media[i].data();
                        final url = data['mediaUrl'] as String;
                        final type = data['mediaType'] as String?;
                        final isImage = type == 'image' || type == 'gif' || type == 'sticker';
                        return InkWell(
                          onTap: () => isImage
                              ? Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ImageViewerScreen(url: url, title: title),
                                  ),
                                )
                              : launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: isImage
                                ? Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _placeholder(type, data),
                                  )
                                : _placeholder(type, data),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(String? type, Map<String, dynamic> data) {
    final icon = switch (type) {
      'video' => LucideIcons.video,
      'audio' => LucideIcons.mic,
      'document' => LucideIcons.file_text,
      _ => LucideIcons.image,
    };
    final size = (data['mediaSize'] as num?)?.toInt();
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 24),
          if (data['mediaName'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${data['mediaName']}',
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
            ),
          ],
          if (size != null)
            Text(
              MediaService.formatBytes(size),
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 9),
            ),
        ],
      ),
    );
  }
}
