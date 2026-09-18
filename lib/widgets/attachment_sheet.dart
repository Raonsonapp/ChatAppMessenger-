import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../services/media_service.dart';
import '../l10n/l10n.dart';

/// Феҳристи замима ба тарзи WhatsApp: Галерея, Камера, Видео, Ҳуҷҷат,
/// Контакт, Ҷойгиршавӣ, Пурсиш, GIF ва Стикер.
class AttachmentSheet extends StatelessWidget {
  final ValueChanged<XFile> onImagePicked;
  /// Агар дода нашавад, банди «Контакт» нишон дода намешавад (масалан дар
  /// чати AI он маъно надорад).
  final VoidCallback? onContactTap;
  final ValueChanged<XFile>? onGifPicked;
  final VoidCallback? onStickerTap;
  final ValueChanged<XFile>? onVideoPicked;
  final ValueChanged<PlatformFile>? onDocumentPicked;
  final VoidCallback? onLocationTap;
  final VoidCallback? onPollTap;
  const AttachmentSheet({
    super.key,
    required this.onImagePicked,
    this.onContactTap,
    this.onGifPicked,
    this.onStickerTap,
    this.onVideoPicked,
    this.onDocumentPicked,
    this.onLocationTap,
    this.onPollTap,
  });

  Future<void> _pickGallery(BuildContext context) async {
    final file = await MediaService.pickFromGallery();
    if (!context.mounted) return;
    if (file != null) {
      Navigator.pop(context);
      onImagePicked(file);
    }
  }

  Future<void> _pickCamera(BuildContext context) async {
    final file = await MediaService.pickFromCamera();
    if (!context.mounted) return;
    if (file != null) {
      Navigator.pop(context);
      onImagePicked(file);
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    final file = await MediaService.pickVideoFromGallery();
    if (!context.mounted) return;
    if (file != null) {
      Navigator.pop(context);
      onVideoPicked?.call(file);
    }
  }

  Future<void> _pickDocument(BuildContext context) async {
    final file = await MediaService.pickDocument();
    if (!context.mounted) return;
    if (file != null) {
      Navigator.pop(context);
      onDocumentPicked?.call(file);
    }
  }

  Future<void> _pickGif(BuildContext context) async {
    final file = await MediaService.pickGif();
    if (!context.mounted) return;
    if (file != null) {
      Navigator.pop(context);
      onGifPicked?.call(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(4)),
            ),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              runSpacing: 16,
              children: [
                _item(
                  icon: LucideIcons.image,
                  color: const Color(0xFFBF59CF),
                  label: tr('k109'),
                  onTap: () => _pickGallery(context),
                ),
                _item(
                  icon: LucideIcons.camera,
                  color: const Color(0xFFE0567C),
                  label: tr('k043'),
                  onTap: () => _pickCamera(context),
                ),
                if (onVideoPicked != null)
                  _item(
                    icon: LucideIcons.video,
                    color: const Color(0xFFE879F9),
                    label: tr('k036'),
                    onTap: () => _pickVideo(context),
                  ),
                if (onDocumentPicked != null)
                  _item(
                    icon: LucideIcons.file_text,
                    color: const Color(0xFF60A5FA),
                    label: tr('k244'),
                    onTap: () => _pickDocument(context),
                  ),
                if (onContactTap != null)
                  _item(
                    icon: LucideIcons.user,
                    color: const Color(0xFF4B7BEC),
                    label: tr('k232'),
                    onTap: () {
                      Navigator.pop(context);
                      onContactTap!();
                    },
                  ),
                if (onLocationTap != null)
                  _item(
                    icon: LucideIcons.map_pin,
                    color: const Color(0xFFEF4444),
                    label: tr('k285'),
                    onTap: () {
                      Navigator.pop(context);
                      onLocationTap!();
                    },
                  ),
                if (onPollTap != null)
                  _item(
                    icon: LucideIcons.chart_bar,
                    color: const Color(0xFF8E44AD),
                    label: tr('k346'),
                    onTap: () {
                      Navigator.pop(context);
                      onPollTap!();
                    },
                  ),
                if (onGifPicked != null)
                  _item(
                    icon: LucideIcons.clapperboard,
                    color: const Color(0xFF2FAE60),
                    label: 'GIF',
                    onTap: () => _pickGif(context),
                  ),
                if (onStickerTap != null)
                  _item(
                    icon: LucideIcons.sticker,
                    color: const Color(0xFFE0A429),
                    label: tr('k233'),
                    onTap: () {
                      Navigator.pop(context);
                      onStickerTap!();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _item({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onTap,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 11.5)),
      ],
    );
  }
}
