import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_theme.dart';
import '../../models/app_call.dart';
import '../call_screen.dart';

class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('calls')
          .where('participants', arrayContains: currentUid)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Хатои Firestore (эҳтимол index лозим аст): ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
        }
        final calls = snapshot.data!.docs.map(AppCall.fromDoc).toList();
        if (calls.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.phone, color: AppColors.textSecondary.withOpacity(0.5), size: 48),
                  const SizedBox(height: 16),
                  const Text('Ягон занг нест', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    'Зангҳои шумо дар ин ҷо намоён мешаванд',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          itemCount: calls.length,
          separatorBuilder: (_, __) => const Divider(color: AppColors.glassBorder, height: 1),
          itemBuilder: (context, index) {
            final call = calls[index];
            final isOutgoing = call.isOutgoing(currentUid);
            final isMissed = call.outcome == CallOutcome.missed && !isOutgoing;
            final otherName = call.otherName(currentUid);
            final otherUid = call.otherUid(currentUid);

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Center(
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                ),
              ),
              title: Text(
                otherName,
                style: TextStyle(
                  color: isMissed ? Colors.redAccent : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              subtitle: Row(
                children: [
                  Icon(
                    isOutgoing ? LucideIcons.arrow_up_right : LucideIcons.arrow_down_left,
                    size: 13,
                    color: isMissed ? Colors.redAccent : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    call.createdAt == null
                        ? '...'
                        : '${call.createdAt!.day}/${call.createdAt!.month} · ${call.createdAt!.hour.toString().padLeft(2, '0')}:${call.createdAt!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                ],
              ),
              trailing: IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CallScreen(otherUserId: otherUid, otherUserName: otherName, type: call.type)),
                ),
                icon: Icon(
                  call.type == CallType.video ? LucideIcons.video : LucideIcons.phone,
                  color: AppColors.neonEmerald,
                  size: 19,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
