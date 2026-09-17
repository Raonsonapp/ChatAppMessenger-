import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../models/app_call.dart';
import 'call_screen.dart';
import '../l10n/l10n.dart';
import '../widgets/user_avatar.dart';

/// Маълумоти воқеии контакт — mute/манъ/тоза кардани чат ҳама воқеан
/// дар Firestore сабт мешаванд.
class ContactInfoScreen extends StatelessWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  const ContactInfoScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
  });

  Future<void> _toggleMute(bool currentlyMuted) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('conversations').doc(conversationId).update({
      'mutedBy': currentlyMuted ? FieldValue.arrayRemove([uid]) : FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> _toggleBlock(BuildContext context, bool currentlyBlocked) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'blockedUsers': currentlyBlocked ? FieldValue.arrayRemove([otherUserId]) : FieldValue.arrayUnion([otherUserId]),
    }, SetOptions(merge: true));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(currentlyBlocked ? tr('k069') : trf('k070', [otherUserName]))),
      );
    }
  }

  Future<void> _clearChat(BuildContext context) async {
    final ref = FirebaseFirestore.instance.collection('conversations').doc(conversationId).collection('messages');
    final docs = await ref.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in docs.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k071'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                    ),
                    Text(
                      tr('k072'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
                  builder: (context, userSnapshot) {
                    final blockedList = List<String>.from(userSnapshot.data?.data()?['blockedUsers'] as List? ?? []);
                    final isBlocked = blockedList.contains(otherUserId);

                    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('conversations').doc(conversationId).snapshots(),
                      builder: (context, convoSnapshot) {
                        final mutedBy = List<String>.from(convoSnapshot.data?.data()?['mutedBy'] as List? ?? []);
                        final isMuted = mutedBy.contains(currentUid);

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          children: [
                            Center(
                              child: UserAvatar(
                                name: otherUserName,
                                uid: otherUserId,
                                size: 84,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                otherUserName,
                                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _callButton(
                                  context,
                                  icon: LucideIcons.phone,
                                  label: tr('k041'),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CallScreen(otherUserId: otherUserId, otherUserName: otherUserName, type: CallType.audio),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                _callButton(
                                  context,
                                  icon: LucideIcons.video,
                                  label: tr('k036'),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CallScreen(otherUserId: otherUserId, otherUserName: otherUserName, type: CallType.video),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            GlassContainer(
                              borderRadius: 16,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    value: isMuted,
                                    onChanged: (_) => _toggleMute(isMuted),
                                    activeThumbColor: AppColors.neonEmerald,
                                    title: Text(
                                      tr('k073'),
                                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ),
                                  Divider(color: AppColors.glassBorder, height: 1),
                                  ListTile(
                                    leading: Icon(LucideIcons.trash, color: AppColors.neonCyan, size: 20),
                                    title: Text(
                                      tr('k074'),
                                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    onTap: () => _clearChat(context),
                                  ),
                                  Divider(color: AppColors.glassBorder, height: 1),
                                  ListTile(
                                    leading: Icon(LucideIcons.slash, color: isBlocked ? AppColors.neonEmerald : Colors.redAccent, size: 20),
                                    title: Text(
                                      isBlocked ? tr('k075') : tr('k076'),
                                      style: TextStyle(
                                        color: isBlocked ? AppColors.neonEmerald : Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onTap: () => _toggleBlock(context, isBlocked),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
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

  Widget _callButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.glassFill,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(icon, color: AppColors.neonEmerald, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
      ],
    );
  }
}
