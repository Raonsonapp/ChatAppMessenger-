import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/l10n.dart';
import '../models/listing.dart';
import '../theme/app_scope.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';
import 'net_image.dart';

/// Корти эълон дар рӯйхати Бозор.
class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  /// Нарх ҳамчун «3 000 сомонӣ». Фосила байни ҳазорҳо хонданро осон мекунад.
  static String formatPrice(num value) {
    final whole = value.round();
    final digits = whole.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final sign = whole < 0 ? '-' : '';
    return '$sign$buffer ${tr('k574')}';
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final cover = listing.coverImage;
    final price = listing.price;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        borderRadius: 18,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: cover == null
                        ? Container(
                            width: 78,
                            height: 78,
                            color: AppColors.surface,
                            alignment: Alignment.center,
                            child: Icon(
                              _iconFor(listing.kind),
                              color: AppColors.textSecondary,
                              size: 24,
                            ),
                          )
                        : NetImage(url: cover, width: 78, height: 78, memCacheWidth: 234),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price == null ? tr('k580') : formatPrice(price),
                          style: TextStyle(
                            color: price == null ? AppColors.textSecondary : AppColors.neonEmerald,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        if (listing.city.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(LucideIcons.map_pin, size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  listing.city,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(ListingKind kind) => switch (kind) {
        ListingKind.product => LucideIcons.package,
        ListingKind.service => LucideIcons.wrench,
        ListingKind.job => LucideIcons.briefcase_business,
        ListingKind.ad => LucideIcons.megaphone,
      };

  /// Нишонаи навъ — экранҳои дигар низ ҳамонро истифода мебаранд.
  static IconData iconFor(ListingKind kind) => _iconFor(kind);
}
