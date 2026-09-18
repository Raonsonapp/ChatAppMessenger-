import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../services/star_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/empty_state.dart';
import '../l10n/l10n.dart';
import '../l10n/media_preview.dart';

/// Рӯйхати паёмҳои ситорадори корбар — мисли «Избранные» дар WhatsApp.
class StarredMessagesScreen extends StatelessWidget {
  const StarredMessagesScreen({super.key});

  String _preview(Map<String, dynamic> data) {
    final text = (data['text'] as String?)?.trim() ?? '';
    if (text.isNotEmpty) return text;
    return mediaPreviewLabel(
      data['mediaType'] as String?,
      name: data['mediaName'] as String?,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      tr('k260'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: StarService.watch(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
                    }
                    final docs = snapshot.data?.docs ?? const [];
                    if (docs.isEmpty) {
                      return EmptyState(icon: LucideIcons.star, title: tr('k261'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final doc = docs[i];
                        final data = doc.data();
                        final mediaUrl = data['mediaUrl'] as String?;
                        final isImage = mediaUrl != null &&
                            (data['mediaType'] == 'image' || data['mediaType'] == 'gif' || data['mediaType'] == 'sticker');
                        return GlassContainer(
                          borderRadius: 16,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isImage)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(mediaUrl, width: 44, height: 44, fit: BoxFit.cover),
                                )
                              else
                                Icon(LucideIcons.star, color: AppColors.neonEmerald, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (data['chatTitle'] as String?)?.trim().isNotEmpty == true
                                          ? data['chatTitle'] as String
                                          : tr('k002'),
                                      style: TextStyle(
                                        color: AppColors.neonCyan,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _preview(data),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatChatTime((data['originalAt'] as Timestamp?)?.toDate()),
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => StarService.remove(doc.id),
                                icon: Icon(LucideIcons.star_off, color: AppColors.textSecondary, size: 18),
                              ),
                            ],
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
}
