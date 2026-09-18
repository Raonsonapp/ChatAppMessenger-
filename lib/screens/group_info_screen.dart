import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../l10n/l10n.dart';
import '../services/media_service.dart';
import '../widgets/group_avatar.dart';
import 'shared_media_screen.dart';
import '../utils/user_search.dart';
import '../services/group_invite_service.dart';
import 'package:flutter/services.dart';

/// Маълумоти воқеии гурӯҳ — аъзоён аз Firestore, амалҳои admin воқеан
/// дар `groups/{id}` сабт мешаванд (на fake).
class GroupInfoScreen extends StatelessWidget {
  final String groupId;
  const GroupInfoScreen({super.key, required this.groupId});

  DocumentReference<Map<String, dynamic>> get _groupRef =>
      FirebaseFirestore.instance.collection('groups').doc(groupId);

  /// Ҳаволаи даъват — рамз сохта ё нишон дода мешавад.
  Future<void> _showInviteCode(BuildContext context, String name) async {
    final code = await GroupInviteService.ensureCode(groupId, name);
    if (code == null || !context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr('k351'),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr('k352'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    color: AppColors.neonEmerald,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr('k353'))),
                          );
                        }
                      },
                      icon: Icon(LucideIcons.copy, size: 16, color: AppColors.neonEmerald),
                      label: Text(tr('k240'), style: TextStyle(color: AppColors.textPrimary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.glassBorder),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await GroupInviteService.revokeCode(groupId);
                        await GroupInviteService.ensureCode(groupId, name);
                      },
                      icon: Icon(LucideIcons.refresh_cw, size: 16, color: AppColors.neonCyan),
                      label: Text(tr('k354'), style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.glassBorder),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Номи гурӯҳро иваз мекунад — танҳо администратор.
  void _renameGroup(BuildContext context, String current) {
    final controller = TextEditingController(text: current);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr('k305'), style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr('k277'), style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              Navigator.pop(dialogContext);
              if (value.isNotEmpty && value != current) {
                _groupRef.set({'name': value}, SetOptions(merge: true));
              }
            },
            child: Text(tr('k117'), style: TextStyle(color: AppColors.neonEmerald)),
          ),
        ],
      ),
    );
  }

  /// Акси гурӯҳ — танҳо администратор онро иваз карда метавонад.
  Future<void> _pickPhoto(BuildContext context) async {
    final file = await MediaService.pickFromGallery();
    if (file == null) return;
    try {
      final url = await MediaService.uploadImage(file, 'groups/$groupId');
      await _groupRef.set({'photoUrl': url}, SetOptions(merge: true));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(trf('k049', [e]))));
      }
    }
  }

  Future<void> _promote(String uid) => _groupRef.update({
        'admins': FieldValue.arrayUnion([uid]),
      });

  Future<void> _demote(String uid) => _groupRef.update({
        'admins': FieldValue.arrayRemove([uid]),
      });

  Future<void> _removeMember(String uid) => _groupRef.update({
        'members': FieldValue.arrayRemove([uid]),
        'admins': FieldValue.arrayRemove([uid]),
        'memberNames.$uid': FieldValue.delete(),
      });

  Future<void> _leaveGroup(BuildContext context) async {
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
          await _groupRef.update({
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
                  isAdmin ? tr('k052') : tr('k053'),
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  isAdmin ? _demote(uid) : _promote(uid);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.user_minus, color: Colors.redAccent, size: 20),
                title: Text(tr('k118'), style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
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
            stream: _groupRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
              }
              final data = snapshot.data!.data()!;
              final name = (data['name'] ?? tr('k005')) as String;
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
                          icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                        ),
                        Text(
                          tr('k119'),
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
                          child: GestureDetector(
                            onTap: amIAdmin ? () => _pickPhoto(context) : null,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                GroupAvatar(photoUrl: data['photoUrl'] as String?, size: 84),
                                if (amIAdmin)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.neonEmerald,
                                    ),
                                    child: Icon(LucideIcons.camera, color: AppColors.background, size: 14),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: InkWell(
                            onTap: amIAdmin ? () => _renameGroup(context, name) : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  if (amIAdmin) ...[
                                    const SizedBox(width: 6),
                                    Icon(LucideIcons.pencil, color: AppColors.textSecondary, size: 15),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(trf('k051', [members.length]), style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr('k056'),
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, letterSpacing: 1.2, fontWeight: FontWeight.w600),
                            ),
                            if (amIAdmin)
                              GestureDetector(
                                onTap: () => _addMember(context),
                                child: Icon(LucideIcons.user_plus, color: AppColors.neonEmerald, size: 19),
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
                              final memberName = memberNames[uid] ?? tr('k002');
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
                                      style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  uid == currentUid ? trf('k057', [memberName]) : memberName,
                                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                trailing: isAdmin
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(gradient: AppColors.neonGradient, borderRadius: BorderRadius.circular(8)),
                                        child: Text(tr('k318'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black)),
                                      )
                                    : null,
                                onTap: () => _showMemberActions(context, uid, memberName, isAdmin, amIAdmin, currentUid),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (amIAdmin)
                          GlassContainer(
                            borderRadius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: SwitchListTile(
                              value: (data['onlyAdminsCanSend'] ?? false) == true,
                              activeThumbColor: AppColors.neonEmerald,
                              onChanged: (value) => _groupRef.set(
                                {'onlyAdminsCanSend': value},
                                SetOptions(merge: true),
                              ),
                              secondary: Icon(LucideIcons.lock, color: AppColors.neonCyan, size: 20),
                              title: Text(
                                tr('k342'),
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        if (amIAdmin) const SizedBox(height: 10),
                        if (amIAdmin)
                          GlassContainer(
                            borderRadius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: ListTile(
                              leading: Icon(LucideIcons.link, color: AppColors.neonCyan, size: 20),
                              title: Text(
                                tr('k351'),
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Icon(LucideIcons.chevron_right, color: AppColors.textSecondary, size: 17),
                              onTap: () => _showInviteCode(context, name),
                            ),
                          ),
                        if (amIAdmin) const SizedBox(height: 10),
                        GlassContainer(
                          borderRadius: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: ListTile(
                            leading: Icon(LucideIcons.images, color: AppColors.neonCyan, size: 20),
                            title: Text(
                              tr('k294'),
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            trailing: Icon(LucideIcons.chevron_right, color: AppColors.textSecondary, size: 17),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SharedMediaScreen(
                                  parentPath: 'groups/$groupId',
                                  title: tr('k294'),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _leaveGroup(context),
                            icon: const Icon(LucideIcons.log_out, color: Colors.redAccent, size: 18),
                            label: Text(tr('k120'), style: TextStyle(color: Colors.redAccent)),
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
    final snapshot = await FirebaseFirestore.instance.collection('users').limit(kUserSearchLimit).get();
    final matches = snapshot.docs.where((doc) {
      if (doc.id == currentUid) return false;
      final data = doc.data();
      return userMatchesQuery(data, q);
    }).map((doc) {
      final data = doc.data();
      return {'uid': doc.id, 'name': (data['name'] ?? tr('k002')) as String, 'phone': (data['phone'] ?? '') as String};
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
            Text(tr('k059'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
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
                style: TextStyle(color: AppColors.textPrimary),
                onSubmitted: _search,
                decoration: InputDecoration(
                  hintText: '+992...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  prefixIcon: Icon(LucideIcons.search, color: AppColors.textSecondary, size: 19),
                  suffixIcon: IconButton(
                    icon: Icon(LucideIcons.arrow_right, color: AppColors.neonEmerald, size: 19),
                    onPressed: () => _search(_controller.text),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_isSearching)
              Padding(
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
                            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      title: Text(name, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
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
