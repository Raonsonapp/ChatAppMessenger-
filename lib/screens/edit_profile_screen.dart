import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorText;
  String? _savedMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = (data['name'] ?? '') as String;
      _nicknameController.text = (data['nickname'] ?? '') as String;
      _aboutController.text = (data['about'] ?? '') as String;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Номро ворид кунед');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorText = null;
      _savedMessage = null;
    });
    try {
      // САБТ: навсозии воқеии профил дар Cloud Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'nickname': _nicknameController.text.trim(),
        'about': _aboutController.text.trim(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _savedMessage = 'Профил сабт шуд';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = 'Хатои сабт: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.neonEmerald))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Профили ман',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
                          child: const Icon(LucideIcons.user, color: AppColors.background, size: 38),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                      ),
                      const SizedBox(height: 26),
                      _buildField('Ном', _nameController, hint: 'Масалан: Шаҳром'),
                      const SizedBox(height: 14),
                      _buildField('Nickname', _nicknameController, hint: '@shahron'),
                      const SizedBox(height: 14),
                      _buildField('Дар бораи ман', _aboutController, hint: 'Салом! Ман ChatApp истифода мебарам'),
                      if (_errorText != null) ...[
                        const SizedBox(height: 10),
                        Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                      ],
                      if (_savedMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(_savedMessage!, style: const TextStyle(color: AppColors.neonEmerald, fontSize: 12.5)),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonEmerald,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                                )
                              : const Text('Сабт кардан', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GlassContainer(
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
