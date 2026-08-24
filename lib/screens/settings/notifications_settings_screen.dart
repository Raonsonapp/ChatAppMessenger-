import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _messageNotifications = true;
  bool _sound = true;
  bool _vibration = true;
  bool _showPreview = true;
  bool _isLoading = true;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final settings = doc.data()?['settings'] as Map<String, dynamic>?;
    if (settings != null) {
      _messageNotifications = (settings['messageNotifications'] ?? true) as bool;
      _sound = (settings['notificationSound'] ?? true) as bool;
      _vibration = (settings['notificationVibration'] ?? true) as bool;
      _showPreview = (settings['notificationPreview'] ?? true) as bool;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _update(String key, bool value) async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'settings': {key: value},
    }, SetOptions(merge: true));
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
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
                    ),
                    const Text(
                      'Огоҳиномаҳо',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.neonEmerald))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          GlassContainer(
                            borderRadius: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Column(
                              children: [
                                _switchRow('Огоҳиномаи паёмҳо', _messageNotifications, (v) {
                                  setState(() => _messageNotifications = v);
                                  _update('messageNotifications', v);
                                }),
                                const Divider(color: AppColors.glassBorder, height: 1),
                                _switchRow('Садо', _sound, (v) {
                                  setState(() => _sound = v);
                                  _update('notificationSound', v);
                                }),
                                const Divider(color: AppColors.glassBorder, height: 1),
                                _switchRow('Ларзиш', _vibration, (v) {
                                  setState(() => _vibration = v);
                                  _update('notificationVibration', v);
                                }),
                                const Divider(color: AppColors.glassBorder, height: 1),
                                _switchRow('Намоиши мазмуни паём', _showPreview, (v) {
                                  setState(() => _showPreview = v);
                                  _update('notificationPreview', v);
                                }, showDivider: false),
                              ],
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

  Widget _switchRow(String title, bool value, ValueChanged<bool> onChanged, {bool showDivider = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.neonEmerald),
        ],
      ),
    );
  }
}
