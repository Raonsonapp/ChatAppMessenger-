import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import 'community_chat_screen.dart';
import '../l10n/l10n.dart';
import '../utils/user_search.dart';

/// Сохтани ҷамъияти воқеӣ дар Cloud Firestore (`communities/{id}`) —
/// монанди CreateGroupScreen, вале бо тавсиф.
class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _results = [];
  final Map<String, String> _selected = {};
  bool _isSearching = false;
  bool _isCreating = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
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

  void _toggleSelect(String uid, String name) {
    setState(() {
      if (_selected.containsKey(uid)) {
        _selected.remove(uid);
      } else {
        _selected[uid] = name;
      }
    });
  }

  Future<void> _createCommunity() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = tr('k097'));
      return;
    }
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    setState(() {
      _isCreating = true;
      _error = null;
    });

    final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
    final myName = (currentUserDoc.data()?['name'] as String?) ?? tr('k015');

    final members = [currentUid, ..._selected.keys];
    final memberNames = {currentUid: myName, ..._selected};

    final doc = await FirebaseFirestore.instance.collection('communities').add({
      'name': name,
      'description': _descController.text.trim(),
      'members': members,
      'memberNames': memberNames,
      'admins': [currentUid],
      'createdBy': currentUid,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityChatScreen(communityId: doc.id, communityName: name, memberNames: memberNames),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                    ),
                    Text(tr('k086'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassContainer(
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: tr('k098'),
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassContainer(
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _descController,
                    style: TextStyle(color: AppColors.textPrimary),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: tr('k095'),
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selected.entries.map((e) {
                      return Chip(
                        label: Text(e.value, style: TextStyle(color: AppColors.background, fontSize: 12)),
                        backgroundColor: AppColors.neonEmerald,
                        deleteIcon: Icon(LucideIcons.x, size: 14, color: AppColors.background),
                        onDeleted: () => _toggleSelect(e.key, e.value),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassContainer(
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: AppColors.textPrimary),
                    onSubmitted: _search,
                    decoration: InputDecoration(
                      hintText: tr('k099'),
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      prefixIcon: Icon(LucideIcons.search, color: AppColors.textSecondary, size: 19),
                      suffixIcon: IconButton(
                        icon: Icon(LucideIcons.arrow_right, color: AppColors.neonEmerald, size: 19),
                        onPressed: () => _search(_searchController.text),
                      ),
                    ),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                ),
              Expanded(
                child: _isSearching
                    ? Center(child: CircularProgressIndicator(color: AppColors.neonEmerald))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          final uid = user['uid']!;
                          final name = user['name']!;
                          final isSelected = _selected.containsKey(uid);
                          return ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
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
                            subtitle: Text(user['phone'] ?? '', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            trailing: Icon(
                              isSelected ? LucideIcons.circle_check : LucideIcons.circle,
                              color: isSelected ? AppColors.neonEmerald : AppColors.textSecondary,
                              size: 20,
                            ),
                            onTap: () => _toggleSelect(uid, name),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonEmerald,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isCreating ? null : _createCommunity,
                    child: _isCreating
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                        : Text(tr('k100'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
