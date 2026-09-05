import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../models/app_conversation.dart';
import '../screens/user_chat_screen.dart';
import '../screens/create_group_screen.dart';
import '../screens/contact_picker_screen.dart';

/// Феҳристи ҷустуҷӯи корбарони воқеӣ + гузаргоҳ ба сохтани гурӯҳи нав.
class NewChatSheet extends StatefulWidget {
  const NewChatSheet({super.key});

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
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
      return {
        'uid': doc.id,
        'name': (data['name'] ?? 'Корбар') as String,
        'phone': (data['phone'] ?? '') as String,
      };
    }).toList();

    if (!mounted) return;
    setState(() {
      _results = matches;
      _isSearching = false;
      _hasSearched = true;
    });
  }

  Future<void> _openChatWith(String otherUid, String otherName) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final conversationId = AppConversation.idFor(currentUid, otherUid);

    final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
    final myName = (currentUserDoc.data()?['name'] as String?) ?? 'Корбар';

    await FirebaseFirestore.instance.collection('conversations').doc(conversationId).set({
      'participants': [currentUid, otherUid],
      'participantNames': {
        currentUid: myName,
        otherUid: otherName,
      },
    }, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserChatScreen(
          conversationId: conversationId,
          otherUserName: otherName,
          otherUserId: otherUid,
        ),
      ),
    );
  }

  void _openCreateGroup() {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
  }

  void _openDeviceContacts() {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactPickerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
            const Text('Контакти нав', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            // Гурӯҳи нав — ҷои доимӣ дар боло, мисли WhatsApp
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
                child: const Icon(LucideIcons.users, color: AppColors.background, size: 20),
              ),
              title: const Text('Гурӯҳи нав', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              onTap: _openCreateGroup,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: AppColors.glassBorder)),
                child: const Icon(LucideIcons.smartphone, color: AppColors.neonCyan, size: 19),
              ),
              title: const Text('Контактҳои телефон', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              onTap: _openDeviceContacts,
            ),
            const Divider(color: AppColors.glassBorder, height: 4),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                onSubmitted: _search,
                decoration: InputDecoration(
                  hintText: '+992...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary, size: 19),
                  suffixIcon: IconButton(
                    icon: const Icon(LucideIcons.arrow_right, color: AppColors.neonEmerald, size: 19),
                    onPressed: () => _search(_searchController.text),
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
                  'Ҳеҷ корбаре бо ин рақам/ном ёфт нашуд',
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 12.5),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    final name = user['name'] as String;
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
                      subtitle: Text(user['phone'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      onTap: () => _openChatWith(user['uid'] as String, name),
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
