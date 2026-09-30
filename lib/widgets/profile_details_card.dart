import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

/// Маълумоти профили корбар: «Дар бораи», `@username`, рақам, Instagram, сайт.
///
/// Танҳо майдонҳое нишон дода мешаванд, ки воқеан пур шудаанд — корти холӣ
/// тамоман намоён намешавад.
class ProfileDetailsCard extends StatelessWidget {
  const ProfileDetailsCard({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        if (data == null) return const SizedBox.shrink();

        final about = (data['about'] as String?)?.trim() ?? '';
        final username = (data['username'] as String?)?.trim() ?? '';
        final phone = (data['phone'] as String?)?.trim() ?? '';
        final instagram = (data['instagram'] as String?)?.trim() ?? '';
        final website = (data['website'] as String?)?.trim() ?? '';

        final rows = <Widget>[
          if (about.isNotEmpty)
            _row(icon: LucideIcons.info, label: tr('k116'), value: about),
          if (username.isNotEmpty)
            _row(
              icon: LucideIcons.at_sign,
              label: tr('k511'),
              value: '@$username',
              onLongPress: () => _copy(context, '@$username'),
            ),
          if (phone.isNotEmpty)
            _row(
              icon: LucideIcons.phone,
              label: tr('k544'),
              value: phone,
              onLongPress: () => _copy(context, phone),
            ),
          if (instagram.isNotEmpty)
            _row(
              icon: LucideIcons.aperture,
              label: 'Instagram',
              value: '@$instagram',
              onTap: () => _open('https://instagram.com/$instagram'),
            ),
          if (website.isNotEmpty)
            _row(
              icon: LucideIcons.globe,
              label: tr('k512'),
              value: website,
              onTap: () => _open(website),
            ),
        ];
        if (rows.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(children: rows),
          ),
        );
      },
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final linked = onTap != null;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.neonCyan),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: linked ? AppColors.neonEmerald : AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (linked)
              Icon(LucideIcons.external_link, size: 15, color: AppColors.textSecondary.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Барномаи кушоянда нест — беҳтар аст хомӯш монад, на вайрон шавад.
    }
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k353'))));
  }
}
