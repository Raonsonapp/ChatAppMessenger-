import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/l10n.dart';
import '../services/media_settings_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_scope.dart';

/// Тасвири шабакавӣ бо кэши диск.
///
/// Файлҳо як маротиба зеркашӣ шуда, баъд аз хотираи дастгоҳ хонда мешаванд,
/// бинобар ин рӯйхати чат ва медиа бе интернет ҳам зуд кушода мешавад.
class NetImage extends StatefulWidget {
  const NetImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.error,
    this.loading,
    this.memCacheWidth,
    this.respectAutoDownload = false,
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

  /// Оё танзимоти «Боркунии худкор» ба ин тасвир дахл дорад.
  ///
  /// Барои аксҳои чат — ҳа: онҳо калонанд ва трафикро мехӯранд. Барои аватар,
  /// нишонаи ҳавола ва наққошиҳои хурд — не: онҳо чанд килобайтанд ва бе онҳо
  /// барнома вайрон менамояд.
  final bool respectAutoDownload;

  @override
  State<NetImage> createState() => _NetImageState();
}

class _NetImageState extends State<NetImage> {
  /// `null` — ҳанӯз намедонем оё файл дар кэш ҳаст.
  bool? _inCache;

  /// Корбар худаш «бор кун»-ро пахш кард.
  bool _manual = false;

  @override
  void initState() {
    super.initState();
    if (widget.respectAutoDownload) _checkCache();
  }

  @override
  void didUpdateWidget(NetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _manual = false;
      _inCache = null;
      if (widget.respectAutoDownload) _checkCache();
    }
  }

  /// Файли аллакай зеркашишуда бе назардошти танзимот нишон дода мешавад —
  /// трафик аллакай сарф шудааст, пинҳон кардани он бемаънист.
  Future<void> _checkCache() async {
    try {
      final info = await DefaultCacheManager().getFileFromCache(widget.url);
      if (!mounted) return;
      setState(() => _inCache = info != null);
    } catch (_) {
      if (mounted) setState(() => _inCache = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);

    if (widget.respectAutoDownload && !_manual) {
      if (_inCache == null) return _placeholder(spinner: true);
      if (!_inCache! && !mediaSettings.allowsPhotoAutoDownload) {
        return _tapToLoad();
      }
    }
    return _image();
  }

  Widget _placeholder({bool spinner = false}) {
    return Container(
      width: widget.width,
      height: widget.height ?? widget.width,
      alignment: Alignment.center,
      color: AppColors.surface,
      child: spinner
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: AppColors.neonEmerald, strokeWidth: 2),
            )
          : null,
    );
  }

  /// Ҷои акс бо тугмаи «бор кардан» — ҳамон тавре ки WhatsApp ҳангоми
  /// хомӯш будани боркунии худкор мекунад.
  Widget _tapToLoad() {
    return GestureDetector(
      onTap: () => setState(() => _manual = true),
      child: Container(
        width: widget.width,
        height: widget.height ?? widget.width ?? 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.download, color: AppColors.neonEmerald, size: 26),
            const SizedBox(height: 8),
            Text(
              tr('k545'),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    final url = widget.url;
    final fit = widget.fit;
    final width = widget.width;
    final height = widget.height;
    final memCacheWidth = widget.memCacheWidth;
    final loading = widget.loading;
    final error = widget.error;

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
