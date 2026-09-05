import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../services/media_service.dart';

/// Феҳристи замима ба тарзи WhatsApp. Танҳо имконоти воқеан коркунанда
/// нишон дода мешаванд (Галерея, Камера, Контакт) — Ҳуҷҷат/Аудио/
/// Ҷойгиршавӣ дар қадами навбатӣ илова мешаванд (бо пакетҳои иловагӣ).
class AttachmentSheet extends StatelessWidget {
  final ValueChanged<XFile> onImagePicked;
  final VoidCallback onContactTap;
  final ValueChanged<XFile>? onGifPicked;
  final VoidCallback? onStickerTap;
  const AttachmentSheet({
    super.key,
    required this.onImagePicked,
    required this.onContactTap,
    this.onGifPicked,
    this.onStickerTap,
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
                  label: 'Галерея',
                  onTap: () => _pickGallery(context),
                ),
                _item(
                  icon: LucideIcons.camera,
                  color: const Color(0xFFE0567C),
                  label: 'Камера',
                  onTap: () => _pickCamera(context),
                ),
                _item(
                  icon: LucideIcons.user,
                  color: const Color(0xFF4B7BEC),
                  label: 'Контакт',
                  onTap: () {
                    Navigator.pop(context);
                    onContactTap();
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
                    label: 'Стикер',
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
        Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5)),
      ],
    );
  }
}
