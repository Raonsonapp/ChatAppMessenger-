import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_scope.dart';
import '../archived_chats_screen.dart';
import '../starred_messages_screen.dart';
import 'appearance_settings_screen.dart';

/// "Чаты" — архив, интихобшудаҳо, миёнбур ба замина/мавзӯи пешфарз, ва
/// тоза кардани воқеии ҳамаи паёмҳои сӯҳбатҳои шахсӣ (на гурӯҳ/ҳамҷомеъа,
/// чун нест кардани паёми дигарон аз берун дуруст нест).
class ChatsSettingsScreen extends StatefulWidget {
  const ChatsSettingsScreen({super.key});

  @override
  State<ChatsSettingsScreen> createState() => _ChatsSettingsScreenState();
}

class _ChatsSettingsScreenState extends State<ChatsSettingsScreen> {
  bool _clearing = false;

  Future<void> _clearAllChats(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(tr('k460'), style: TextStyle(color: AppColors.textPrimary)),
            content: Text(tr('k461'), style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('k462'))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('k463'), style: const TextStyle(color: Colors.redAccent))),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => _clearing = true);
    try {
      final conversations = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: uid)
          .get();
      for (final convo in conversations.docs) {
        final messages = await convo.reference.collection('messages').get();
        final batch = FirebaseFirestore.instance.batch();
        for (final m in messages.docs) {
          batch.delete(m.reference);
        }
        await batch.commit();
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k464'))));
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
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                    ),
                    Text(
                      tr('k044'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(LucideIcons.archive, color: AppColors.neonCyan, size: 19),
                            title: Text(tr('k269'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                            trailing: Icon(LucideIcons.chevron_right, color: AppColors.textSecondary, size: 17),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedChatsScreen())),
                          ),
                          Divider(color: AppColors.glassBorder, height: 1),
                          ListTile(
                            leading: Icon(LucideIcons.star, color: AppColors.neonCyan, size: 19),
                            title: Text(tr('k260'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                            trailing: Icon(LucideIcons.chevron_right, color: AppColors.textSecondary, size: 17),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StarredMessagesScreen())),
                          ),
                          Divider(color: AppColors.glassBorder, height: 1),
                          ListTile(
                            leading: Icon(LucideIcons.image, color: AppColors.neonCyan, size: 19),
                            title: Text(tr('k147'), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                            trailing: Icon(LucideIcons.chevron_right, color: AppColors.textSecondary, size: 17),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen())),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassContainer(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: ListTile(
                        leading: _clearing
                            ? SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
                            : Icon(LucideIcons.trash, color: Colors.redAccent, size: 19),
                        title: Text(tr('k071'), style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 14)),
                        onTap: _clearing ? null : () => _clearAllChats(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
