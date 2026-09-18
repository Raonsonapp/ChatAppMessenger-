import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_scope.dart';

/// Тасвири шабакавӣ бо кэши диск.
///
/// Файлҳо як маротиба зеркашӣ шуда, баъд аз хотираи дастгоҳ хонда мешаванд,
/// бинобар ин рӯйхати чат ва медиа бе интернет ҳам зуд кушода мешавад.
class NetImage extends StatelessWidget {
  const NetImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.error,
    this.loading,
    this.memCacheWidth,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Чизе ки ҳангоми хатогӣ нишон дода мешавад.
  final Widget? error;

  /// Чизе ки ҳангоми зеркашӣ нишон дода мешавад.
  final Widget? loading;

  /// Маҳдудияти андозаи кэши хотира (пиксел) — барои рӯйхатҳои дароз.
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) =>
          loading ??
          Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            color: AppColors.surface,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: AppColors.neonEmerald,
                strokeWidth: 2,
              ),
            ),
          ),
      errorWidget: (_, __, ___) =>
          error ??
          Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            color: AppColors.surface,
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
    );
  }
}
