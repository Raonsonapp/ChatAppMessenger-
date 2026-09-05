import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../models/app_call.dart';
import '../screens/call_screen.dart';

/// Интихоби корбар барои сар кардани занги нав (садоӣ ё видеоӣ).
class NewCallSheet extends StatefulWidget {
  const NewCallSheet({super.key});

  @override
  State<NewCallSheet> createState() => _NewCallSheetState();
}

class _NewCallSheetState extends State<NewCallSheet> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
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
      _hasSearched = true;
    });
  }

  void _startCall(String uid, String name, CallType type) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(otherUserId: uid, otherUserName: name, type: type)));
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const Text('Занги нав', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
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
            else if (_hasSearched && _results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Ҳеҷ корбаре ёфт нашуд',
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12.5),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    final uid = user['uid']!;
                    final name = user['name']!;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
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
                            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      subtitle: Text(user['phone'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _startCall(uid, name, CallType.audio),
                            icon: const Icon(LucideIcons.phone, color: AppColors.neonEmerald, size: 19),
                          ),
                          IconButton(
                            onPressed: () => _startCall(uid, name, CallType.video),
                            icon: const Icon(LucideIcons.video, color: AppColors.neonCyan, size: 19),
                          ),
                        ],
                      ),
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
