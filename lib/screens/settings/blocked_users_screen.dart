import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../widgets/user_avatar.dart';
import '../../l10n/l10n.dart';

/// Рӯйхати корбарони манъшуда.
///
/// Пештар манъро танҳо аз чати ҳамон шахс бардоштан мумкин буд — агар чат нест
/// карда шуда бошад, роҳи баргардонидан набуд.
class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _unblock(String uid, String otherUid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set({
      'blockedUsers': FieldValue.arrayRemove([otherUid]),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                    ),
                    Text(
                      tr('k320'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: uid == null
                    ? const SizedBox.shrink()
                    : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
                          }
                          final blocked =
                              List<String>.from(snapshot.data?.data()?['blockedUsers'] as List? ?? []);
                          if (blocked.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.shield_check, color: AppColors.textSecondary, size: 36),
                                  const SizedBox(height: 10),
                                  Text(
                                    tr('k321'),
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: blocked.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) => _BlockedRow(
                              otherUid: blocked[i],
                              onUnblock: () => _unblock(uid, blocked[i]),
                            ),
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

class _BlockedRow extends StatelessWidget {
  final String otherUid;
  final VoidCallback onUnblock;
  const _BlockedRow({required this.otherUid, required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = (data?['name'] as String?) ?? tr('k002');
        final phone = (data?['phone'] as String?) ?? '';

        return GlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              UserAvatar(name: name, uid: otherUid, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5),
                    ),
                    if (phone.isNotEmpty)
                      Text(phone, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              TextButton(
                onPressed: onUnblock,
                child: Text(tr('k075'), style: TextStyle(color: AppColors.neonEmerald, fontSize: 13)),
              ),
            ],
          ),
        );
      },
    );
  }
}
