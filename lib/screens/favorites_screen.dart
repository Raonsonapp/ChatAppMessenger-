import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/l10n.dart';
import '../models/app_call.dart';
import '../services/favorites_service.dart';
import '../theme/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/user_avatar.dart';
import 'call_screen.dart';
import '../widgets/stream_error_notice.dart';

/// Контактҳои дӯстдошта — занги зуд.
///
/// Танҳо корбарони ВОҚЕӢ нишон дода мешаванд: рӯйхат аз ҳуҷҷати худи корбар
/// хонда шуда, ҳар кадом аз `users` гирифта мешавад.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left,
                          color: AppColors.textPrimary, size: 20),
                    ),
                    Text(
                      tr('k482'),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: uid == null
                    ? const SizedBox.shrink()
                    : StreamBuilder<List<String>>(
                        stream: FavoritesService.watch(uid),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return StreamErrorNotice(error: snapshot.error);
                          }
                          final ids = snapshot.data ?? const [];
                          if (ids.isEmpty) {
                            return EmptyState(
                              icon: LucideIcons.star,
                              title: tr('k483'),
                              description: tr('k484'),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                            itemCount: ids.length,
                            itemBuilder: (context, index) =>
                                _FavoriteTile(uid: ids[index]),
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

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        // Агар корбар ҳисобашро нест карда бошад, сатр нишон дода намешавад.
        if (snapshot.hasData && data == null) return const SizedBox.shrink();

        final name = (data?['name'] as String?) ?? tr('k002');

        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                UserAvatar(name: name, uid: uid, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                _callButton(context, name, CallType.audio, LucideIcons.phone),
                const SizedBox(width: 6),
                _callButton(context, name, CallType.video, LucideIcons.video),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _callButton(
      BuildContext context, String name, CallType type, IconData icon) {
    return IconButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            otherUserId: uid,
            otherUserName: name,
            type: type,
          ),
        ),
      ),
      icon: Icon(icon, color: AppColors.neonEmerald, size: 19),
    );
  }
}
