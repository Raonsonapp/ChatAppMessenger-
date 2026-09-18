import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/l10n.dart';
import '../theme/app_scope.dart';
import '../theme/app_theme.dart';

/// Хатчаи «Интернет нест».
///
/// Бе ин корбар мебинад, ки паём намеравад, вале сабабашро намедонад ва
/// гумон мекунад, ки барнома вайрон аст.
///
/// Ҳолати пайвастшавӣ на аз интерфейси шабака, балки аз худи Firestore
/// гирифта мешавад: `isFromCache` маҳз он вақт рост мешавад, ки сервер
/// дастрас набошад — яъне Wi-Fi ҳаст, вале интернет нест ҳам гирифта
/// мешавад.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        final offline = snapshot.hasData && snapshot.data!.metadata.isFromCache;

        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: offline
              ? Container(
                  width: double.infinity,
                  color: Colors.orange.withValues(alpha: 0.18),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.wifi_off, size: 15, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          tr('k382'),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        );
      },
    );
  }
}
