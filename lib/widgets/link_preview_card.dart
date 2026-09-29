import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/link_preview_service.dart';
import '../theme/app_scope.dart';
import '../theme/app_theme.dart';
import 'net_image.dart';

/// Корти пешнамоиши ҳавола дар зери матни паём.
///
/// То даме ки маълумот наомадааст, ҳељ чиз нишон дода намешавад: ҷои холии
/// парканда паёмҳоро ҷаҳиш медиҳонад ва хонданро душвор мекунад.
class LinkPreviewCard extends StatelessWidget {
  const LinkPreviewCard({super.key, required this.url, required this.isMe});

  final String url;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);

    return FutureBuilder<LinkPreview?>(
      future: LinkPreviewService.fetch(url),
      builder: (context, snapshot) {
        final preview = snapshot.data;
        if (preview == null) return const SizedBox.shrink();
        return _card(context, preview);
      },
    );
  }

  Widget _card(BuildContext context, LinkPreview preview) {
    final tint = isMe
        ? AppColors.background.withValues(alpha: 0.12)
        : AppColors.glassFill;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => launchUrl(
            Uri.parse(preview.url),
            mode: LaunchMode.externalApplication,
          ),
          child: Container(
            width: 240,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (preview.image != null)
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: NetImage(
                      url: preview.image!,
                      fit: BoxFit.cover,
                      memCacheWidth: 480,
                      // Агар акс кушода нашавад, корт бе он нишон дода
                      // мешавад — сарлавҳа ба ҳар ҳол муфид аст.
                      error: const SizedBox.shrink(),
                      loading: const SizedBox.shrink(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (preview.siteName != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            preview.siteName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.neonCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (preview.title != null)
                        Text(
                          preview.title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      if (preview.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            preview.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
