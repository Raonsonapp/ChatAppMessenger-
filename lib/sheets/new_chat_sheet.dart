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
import '../l10n/l10n.dart';
import '../widgets/user_avatar.dart';
import '../utils/user_search.dart';

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
    final myName = (currentUserDoc.data()?['name'] as String?) ?? tr('k002');

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
            Text(tr('k084'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            // Гурӯҳи нав — ҷои доимӣ дар боло, мисли WhatsApp
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
                child: Icon(LucideIcons.users, color: AppColors.background, size: 20),
              ),
              title: Text(tr('k083'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              onTap: _openCreateGroup,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: AppColors.glassBorder)),
                child: Icon(LucideIcons.smartphone, color: AppColors.neonCyan, size: 19),
              ),
              title: Text(tr('k228'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              onTap: _openDeviceContacts,
            ),
            Divider(color: AppColors.glassBorder, height: 4),
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
                style: TextStyle(color: AppColors.textPrimary),
                onSubmitted: _search,
                decoration: InputDecoration(
                  hintText: '+992...',
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
            const SizedBox(height: 10),
            if (_isSearching)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: AppColors.neonEmerald)),
              )
            else if (_hasSearched && _results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  tr('k229'),
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
                      leading: UserAvatar(name: name, uid: user['uid'] as String, size: 44),
                      title: Text(name, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      subtitle: Text(user['phone'] as String, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
