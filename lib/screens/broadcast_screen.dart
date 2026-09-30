import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../l10n/l10n.dart';
import '../services/broadcast_service.dart';
import '../theme/app_scope.dart';
import '../theme/app_theme.dart';
import '../utils/user_search.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/user_avatar.dart';

/// Пахши умумӣ: як матн ба чанд чати шахсӣ.
class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final Map<String, String> _selected = {};
  List<Map<String, String>> _results = [];
  bool _isSearching = false;
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
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
      return userMatchesQuery(doc.data(), q);
    }).map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'name': (data['name'] ?? tr('k002')) as String,
        'phone': (data['phone'] ?? '') as String,
        'photoUrl': (data['photoUrl'] ?? '') as String,
      };
    }).toList();
    if (!mounted) return;
    setState(() {
      _results = matches;
      _isSearching = false;
    });
  }

  void _toggle(String uid, String name) {
    setState(() {
      if (_selected.containsKey(uid)) {
        _selected.remove(uid);
      } else if (_selected.length >= BroadcastService.maxRecipients) {
        _error = tr('k543');
      } else {
        _selected[uid] = name;
        _error = null;
      }
    });
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (_selected.isEmpty) {
      setState(() => _error = tr('k504'));
      return;
    }
    if (text.isEmpty) {
      setState(() => _error = tr('k498'));
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      final myDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final myName = (myDoc.data()?['name'] as String?)?.trim().isNotEmpty == true
          ? myDoc.data()!['name'] as String
          : tr('k002');

      final result = await BroadcastService.send(
        fromUid: uid,
        fromName: myName,
        recipients: Map<String, String>.from(_selected),
        text: text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.allSent ? tr('k505') : '${tr('k505')} (${result.sent}/${result.sent + result.failed})')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = tr('k543');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
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
                    Expanded(
                      child: Text(
                        tr('k493'),
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                    ),
                    if (_selected.isNotEmpty)
                      Text(
                        '${_selected.length}',
                        style: TextStyle(color: AppColors.neonEmerald, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                  ],
                ),
              ),
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selected.entries
                        .map((e) => Chip(
                              label: Text(e.value, style: TextStyle(color: AppColors.background, fontSize: 12)),
                              backgroundColor: AppColors.neonEmerald,
                              deleteIcon: Icon(LucideIcons.x, size: 14, color: AppColors.background),
                              onDeleted: () => _toggle(e.key, e.value),
                            ))
                        .toList(),
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
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          final uid = user['uid']!;
                          final name = user['name']!;
                          final selected = _selected.containsKey(uid);
                          return ListTile(
                            leading: UserAvatar(
                              name: name,
                              photoUrl: (user['photoUrl'] ?? '').isEmpty ? null : user['photoUrl'],
                              size: 44,
                            ),
                            title: Text(name, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                            subtitle: Text(user['phone'] ?? '', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            trailing: Icon(
                              selected ? LucideIcons.circle_check : LucideIcons.circle,
                              color: selected ? AppColors.neonEmerald : AppColors.textSecondary,
                              size: 20,
                            ),
                            onTap: () => _toggle(uid, name),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: AppColors.textPrimary),
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: tr('k498'),
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonEmerald,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSending ? null : _send,
                    child: _isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                          )
                        : Text(tr('k256'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
