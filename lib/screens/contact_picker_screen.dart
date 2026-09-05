import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../theme/app_theme.dart';
import '../models/app_conversation.dart';
import 'user_chat_screen.dart';
import 'create_group_screen.dart';
import 'create_community_screen.dart';

/// Интихоби contact аз contact-ҳои воқеии телефон.
/// + дигар рақам талаб намекунад: contact аз телефон интихоб мешавад.
class ContactPickerScreen extends StatefulWidget {
  const ContactPickerScreen({super.key});

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filtered = [];
  Map<String, Map<String, dynamic>> _registeredUsersByPhone = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_filterContacts)
      ..dispose();
    super.dispose();
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  Future<void> _loadContacts() async {
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Барои дидани контактҳо иҷозаи Contacts лозим аст.';
        });
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      final clean = contacts
          .where((c) => c.displayName.trim().isNotEmpty || c.phones.isNotEmpty)
          .toList()
        ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

      await _loadRegisteredUsers(clean);

      if (!mounted) return;
      setState(() {
        _contacts = clean;
        _filtered = clean;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Контактҳоро бор кардан нашуд.';
      });
    }
  }

  Future<void> _loadRegisteredUsers(List<Contact> contacts) async {
    final phoneSet = <String>{};
    for (final contact in contacts) {
      for (final phone in contact.phones) {
        final normalized = _normalizePhone(phone.number);
        if (normalized.isNotEmpty) phoneSet.add(normalized);
      }
    }

    if (phoneSet.isEmpty) return;

    // Бе orderBy/compound query: index-и Firestore талаб намешавад.
    final snapshot = await FirebaseFirestore.instance.collection('users').limit(500).get();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    for (final doc in snapshot.docs) {
      if (doc.id == currentUid) continue;
      final data = doc.data();
      final phone = _normalizePhone('${data['phone'] ?? ''}');
      if (phone.isEmpty || !phoneSet.contains(phone)) continue;
      _registeredUsersByPhone[phone] = {
        'uid': doc.id,
        'name': '${data['name'] ?? 'Корбар'}',
      };
    }
  }

  void _filterContacts() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _contacts);
      return;
    }

    setState(() {
      _filtered = _contacts.where((contact) {
        final name = contact.displayName.toLowerCase();
        final phones = contact.phones.map((p) => p.number.toLowerCase()).join(' ');
        return name.contains(q) || phones.contains(q);
      }).toList();
    });
  }

  Future<void> _selectContact(Contact contact) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    String? otherUid;
    String otherName = contact.displayName.trim().isEmpty ? 'Корбар' : contact.displayName.trim();

    for (final phone in contact.phones) {
      final match = _registeredUsersByPhone[_normalizePhone(phone.number)];
      if (match != null) {
        otherUid = match['uid'] as String?;
        otherName = (match['name'] as String?)?.trim().isNotEmpty == true
            ? match['name'] as String
            : otherName;
        break;
      }
    }

    if (otherUid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ин contact ҳоло дар ChatApp сабтином нашудааст.')),
      );
      return;
    }

    final conversationId = AppConversation.idFor(currentUid, otherUid);
    final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
    final myName = '${currentUserDoc.data()?['name'] ?? 'Корбар'}';

    await FirebaseFirestore.instance.collection('conversations').doc(conversationId).set({
      'participants': [currentUid, otherUid],
      'participantNames': {
        currentUid: myName,
        otherUid: otherName,
      },
    }, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserChatScreen(
          conversationId: conversationId,
          otherUserName: otherName,
          otherUserId: otherUid!,
        ),
      ),
    );
  }

  Widget _topAction({required IconData icon, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.textPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Интихоби контакт',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(
              '${_contacts.length} контакт',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          _topAction(
            icon: LucideIcons.search,
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          ),
          _topAction(
            icon: LucideIcons.ellipsis_vertical,
            onTap: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: AppColors.surface,
              builder: (_) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(LucideIcons.refresh_cw, color: AppColors.textPrimary),
                      title: const Text('Навсозии контактҳо', style: TextStyle(color: AppColors.textPrimary)),
                      onTap: () {
                        Navigator.pop(context);
                        _loadContacts();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
            child: Column(
              children: [
                _quickAction(LucideIcons.users, 'Гурӯҳи нав', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
                }),
                _quickAction(LucideIcons.user_plus, 'Контакти нав', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Контактро дар телефони худ илова кунед, баъд ин ҷо навсозӣ кунед.')));
                }),
                _quickAction(LucideIcons.hash, 'Ҷамъияти нав', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCommunityScreen()));
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ҷустуҷӯ',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary, size: 19),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: AppColors.neonEmerald.withOpacity(0.14),
        child: Icon(icon, color: AppColors.neonEmerald),
      ),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.users, color: AppColors.textSecondary, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadContacts, child: const Text('Аз нав')),
            ],
          ),
        ),
      );
    }

    if (_filtered.isEmpty) {
      return const Center(
        child: Text('Контакт ёфт нашуд', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.glassBorder),
      itemBuilder: (context, index) {
        final contact = _filtered[index];
        final registered = contact.phones.any(
          (p) => _registeredUsersByPhone.containsKey(_normalizePhone(p.number)),
        );

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: CircleAvatar(
            radius: 27,
            backgroundColor: AppColors.surface,
            backgroundImage: contact.photo != null ? MemoryImage(contact.photo!) : null,
            child: contact.photo == null
                ? Text(
                    contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          title: Text(
            contact.displayName.isEmpty ? 'Бе ном' : contact.displayName,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            registered ? 'Дар ChatApp ҳаст' : (contact.phones.isNotEmpty ? contact.phones.first.number : ''),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          onTap: () => _selectContact(contact),
        );
      },
    );
  }
}
