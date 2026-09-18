import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_theme.dart';
import '../../models/app_call.dart';
import '../../utils/doc_sort.dart';
import '../call_screen.dart';
import '../../l10n/l10n.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/group_avatar.dart';
import '../../widgets/empty_state.dart';

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
          .limit(100)
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
        final calls = sortByTimeDesc(snapshot.data!.docs, 'createdAt').map(AppCall.fromDoc).toList();
        if (calls.isEmpty) {
          return EmptyState(
            icon: LucideIcons.phone,
            title: tr('k198'),
            description: tr('k199'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          itemCount: calls.length,
          separatorBuilder: (_, __) => Divider(color: AppColors.glassBorder, height: 1),
          itemBuilder: (context, index) {
            final call = calls[index];
            final isOutgoing = call.isOutgoing(currentUid);
            final isMissed = call.outcome == CallOutcome.missed && !isOutgoing;
            final otherName = call.otherName(currentUid);
            final otherUid = call.otherUid(currentUid);
            final isGroupCall = call.groupName != null;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              // Занги гурӯҳӣ бо нишонаи гурӯҳ нишон дода мешавад; такрор
              // задани он аз таърих маъно надорад, чун рӯйхати аъзоён ин ҷо
              // нест — барои он ба худи гурӯҳ даромадан лозим аст.
              leading: isGroupCall
                  ? const GroupAvatar(size: 48)
                  : UserAvatar(name: otherName, uid: otherUid, size: 48),
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
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                ],
              ),
              trailing: IconButton(
                onPressed: isGroupCall
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CallScreen(
                              otherUserId: otherUid,
                              otherUserName: otherName,
                              type: call.type,
                            ),
                          ),
                        ),
                icon: Icon(
                  call.type == CallType.video ? LucideIcons.video : LucideIcons.phone,
                  color: isGroupCall ? AppColors.textSecondary : AppColors.neonEmerald,
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
