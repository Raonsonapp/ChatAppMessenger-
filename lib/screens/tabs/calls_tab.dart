import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_theme.dart';
import '../../models/app_call.dart';
import '../../utils/doc_sort.dart';
import '../call_screen.dart';
import '../dial_pad_screen.dart';
import '../scheduled_calls_screen.dart';
import '../favorites_screen.dart';
import '../../sheets/new_call_sheet.dart';
import '../../l10n/l10n.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/group_avatar.dart';
import '../../widgets/empty_state.dart';
import '../../theme/app_scope.dart';

class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  void _openNewCall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const NewCallSheet(),
    );
  }

  Future<void> _clearCallList(BuildContext context, String currentUid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('calls')
        .where('participants', arrayContains: currentUid)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  void _openMenu(BuildContext context, String currentUid) {
    final size = MediaQuery.of(context).size;
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(size.width - 210, 90, 12, 0),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.glassBorder)),
      items: [
        PopupMenuItem<void>(
          onTap: () => _clearCallList(context, currentUid),
          child: _menuRow(LucideIcons.trash, tr('k431')),
        ),
        PopupMenuItem<void>(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduledCallsScreen())),
          child: _menuRow(LucideIcons.timer, tr('k432')),
        ),
      ],
    );
  }

  Widget _menuRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textPrimary),
        const SizedBox(width: 14),
        Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _shortcut(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.accent, size: 21),
              ),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
          child: Row(
            children: [
              _shortcut(context, icon: LucideIcons.phone, label: tr('k428'), onTap: () => _openNewCall(context)),
              _shortcut(
                context,
                icon: LucideIcons.timer,
                label: tr('k429'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduledCallsScreen())),
              ),
              _shortcut(
                context,
                icon: Icons.dialpad,
                label: tr('k430'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DialPadScreen())),
              ),
              _shortcut(
                context,
                icon: LucideIcons.star,
                label: tr('k412'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
              ),
              IconButton(
                onPressed: () => _openMenu(context, currentUid),
                icon: Icon(LucideIcons.ellipsis_vertical, color: AppColors.textSecondary, size: 19),
              ),
            ],
          ),
        ),
        Divider(color: AppColors.glassBorder, height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                return Center(child: CircularProgressIndicator(color: AppColors.accent));
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
                        color: isMissed ? AppColors.missedRed : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          isOutgoing ? LucideIcons.arrow_up_right : LucideIcons.arrow_down_left,
                          size: 13,
                          color: isMissed ? AppColors.missedRed : AppColors.callGreen,
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
                        color: isGroupCall ? AppColors.textSecondary : AppColors.accent,
                        size: 19,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
