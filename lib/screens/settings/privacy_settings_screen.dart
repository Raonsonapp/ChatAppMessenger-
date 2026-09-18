import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../l10n/l10n.dart';
import 'blocked_users_screen.dart';

/// Танзимоти воқеии махфият — ҳар тағйирот фавран дар
/// `users/{uid}` (майдони `settings`) сабт мешавад ва пас аз
/// боз кардани барнома нигоҳ дошта мешавад.
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _lastSeenVisible = true;
  bool _onlineVisible = true;
  bool _readReceipts = true;
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
      _lastSeenVisible = (settings['lastSeenVisible'] ?? true) as bool;
      _onlineVisible = (settings['onlineVisible'] ?? true) as bool;
      _readReceipts = (settings['readReceipts'] ?? true) as bool;
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
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                    ),
                    Text(
                      tr('k174'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: AppColors.neonEmerald))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        children: [
                          GlassContainer(
                            borderRadius: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Column(
                              children: [
                                _switchRow(
                                  tr('k175'),
                                  tr('k176'),
                                  _lastSeenVisible,
                                  (v) {
                                    setState(() => _lastSeenVisible = v);
                                    _update('lastSeenVisible', v);
                                  },
                                ),
                                Divider(color: AppColors.glassBorder, height: 1),
                                _switchRow(
                                  tr('k177'),
                                  tr('k178'),
                                  _onlineVisible,
                                  (v) {
                                    setState(() => _onlineVisible = v);
                                    _update('onlineVisible', v);
                                  },
                                ),
                                Divider(color: AppColors.glassBorder, height: 1),
                                _switchRow(
                                  tr('k179'),
                                  tr('k180'),
                                  _readReceipts,
                                  (v) {
                                    setState(() => _readReceipts = v);
                                    _update('readReceipts', v);
                                  },
                                  showDivider: false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassContainer(
                            borderRadius: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: ListTile(
                              leading: Icon(LucideIcons.shield_off, color: AppColors.neonCyan, size: 20),
                              title: Text(
                                tr('k320'),
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Icon(LucideIcons.chevron_right, color: AppColors.textSecondary, size: 17),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
                              ),
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

  Widget _switchRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged, {bool showDivider = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 11.5)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.neonEmerald,
          ),
        ],
      ),
    );
  }
}
