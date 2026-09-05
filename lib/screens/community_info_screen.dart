import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';

/// Маълумоти воқеии ҷамъият — сохти монанд ба GroupInfoScreen.
class CommunityInfoScreen extends StatelessWidget {
  final String communityId;
  const CommunityInfoScreen({super.key, required this.communityId});

  DocumentReference<Map<String, dynamic>> get _communityRef =>
      FirebaseFirestore.instance.collection('communities').doc(communityId);

  Future<void> _promote(String uid) => _communityRef.update({
        'admins': FieldValue.arrayUnion([uid]),
      });

  Future<void> _demote(String uid) => _communityRef.update({
        'admins': FieldValue.arrayRemove([uid]),
      });

  Future<void> _removeMember(String uid) => _communityRef.update({
        'members': FieldValue.arrayRemove([uid]),
        'admins': FieldValue.arrayRemove([uid]),
        'memberNames.$uid': FieldValue.delete(),
      });

  Future<void> _leaveCommunity(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _removeMember(uid);
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _addMember(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddMemberSheet(
        onSelected: (uid, name) async {
          await _communityRef.update({
            'members': FieldValue.arrayUnion([uid]),
            'memberNames.$uid': name,
          });
        },
      ),
    );
  }

  void _showMemberActions(BuildContext context, String uid, String name, bool isAdmin, bool amIAdmin, String currentUid) {
    if (!amIAdmin || uid == currentUid) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isAdmin ? LucideIcons.user_x : LucideIcons.shield,
                  color: AppColors.neonCyan,
                  size: 20,
                ),
                title: Text(
                  isAdmin ? 'Хориҷ аз admin' : 'Таъин ба admin',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  isAdmin ? _demote(uid) : _promote(uid);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.user_minus, color: Colors.redAccent, size: 20),
                title: const Text('Хориҷ аз ҷамъият', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _removeMember(uid);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _communityRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
              }
              final data = snapshot.data!.data()!;
              final name = (data['name'] ?? 'Ҷамъият') as String;
              final description = (data['description'] ?? '') as String;
              final members = List<String>.from(data['members'] as List? ?? []);
              final admins = List<String>.from(data['admins'] as List? ?? []);
              final memberNames = (data['memberNames'] as Map<String, dynamic>? ?? {})
                  .map((k, v) => MapEntry(k, v as String));
              final amIAdmin = admins.contains(currentUid);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 20, 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 18),
                        ),
                        const Text(
                          'Маълумоти ҷамъият',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        Center(
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
                            child: const Icon(LucideIcons.hash, color: AppColors.background, size: 36),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            name,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Center(
                            child: Text(description, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                          ),
                        ],
                        Center(
                          child: Text('${members.length} аъзо', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'АЪЗОЁН',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, letterSpacing: 1.2, fontWeight: FontWeight.w600),
                            ),
                            if (amIAdmin)
                              GestureDetector(
                                onTap: () => _addMember(context),
                                child: const Icon(LucideIcons.user_plus, color: AppColors.neonEmerald, size: 19),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GlassContainer(
                          borderRadius: 16,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: members.map((uid) {
                              final isAdmin = admins.contains(uid);
                              final memberName = memberNames[uid] ?? 'Корбар';
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surface,
                                    border: Border.all(color: AppColors.glassBorder),
                                  ),
                                  child: Center(
                                    child: Text(
                                      memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  uid == currentUid ? '$memberName (Шумо)' : memberName,
                                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                trailing: isAdmin
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(gradient: AppColors.neonGradient, borderRadius: BorderRadius.circular(8)),
                                        child: const Text('Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black)),
                                      )
                                    : null,
                                onTap: () => _showMemberActions(context, uid, memberName, isAdmin, amIAdmin, currentUid),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _leaveCommunity(context),
                            icon: const Icon(LucideIcons.log_out, color: Colors.redAccent, size: 18),
                            label: const Text('Баромадан аз ҷамъият', style: TextStyle(color: Colors.redAccent)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  final Future<void> Function(String uid, String name) onSelected;
  const _AddMemberSheet({required this.onSelected});

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final snapshot = await FirebaseFirestore.instance.collection('users').limit(50).get();
    final ql = q.toLowerCase();
    final matches = snapshot.docs.where((doc) {
      if (doc.id == currentUid) return false;
      final data = doc.data();
      final phone = (data['phone'] ?? '') as String;
      final name = (data['name'] ?? '') as String;
      return phone.contains(q) || name.toLowerCase().contains(ql);
    }).map((doc) {
      final data = doc.data();
      return {'uid': doc.id, 'name': (data['name'] ?? 'Корбар') as String, 'phone': (data['phone'] ?? '') as String};
    }).toList();
    if (!mounted) return;
    setState(() {
      _results = matches;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Илова кардани аъзо', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: AppColors.textPrimary),
                onSubmitted: _search,
                decoration: InputDecoration(
                  hintText: '+992...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary, size: 19),
                  suffixIcon: IconButton(
                    icon: const Icon(LucideIcons.arrow_right, color: AppColors.neonEmerald, size: 19),
                    onPressed: () => _search(_controller.text),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: AppColors.neonEmerald)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    final name = user['name'] ?? '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      onTap: () async {
                        Navigator.pop(context);
                        await widget.onSelected(user['uid']!, name);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
