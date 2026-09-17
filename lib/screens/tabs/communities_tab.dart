import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_theme.dart';
import '../../models/app_community.dart';
import '../../widgets/community_tile.dart';
import '../../utils/doc_sort.dart';
import '../create_community_screen.dart';
import '../../l10n/l10n.dart';

class CommunitiesTab extends StatelessWidget {
  const CommunitiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .where('members', arrayContains: currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                trf('k197', [snapshot.error]),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
        }
        final docs = sortByTimeDesc(snapshot.data!.docs, 'lastMessageTime');
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.hash, color: AppColors.textSecondary.withValues(alpha: 0.5), size: 48),
                  const SizedBox(height: 16),
                  Text(tr('k202'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    tr('k203'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCommunityScreen())),
                    icon: Icon(LucideIcons.plus, size: 16, color: AppColors.neonEmerald),
                    label: Text(tr('k100'), style: TextStyle(color: AppColors.textPrimary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.glassBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
          children: docs.map((doc) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: CommunityTile(community: AppCommunity.fromDoc(doc), currentUid: currentUid),
            );
          }).toList(),
        );
      },
    );
  }
}
