import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/media_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/user_avatar.dart';
import '../widgets/neon_backdrop.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';
import '../utils/upload_error.dart';

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
  bool _isUploadingPhoto = false;
  String? _photoUrl;
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
      _photoUrl = data['photoUrl'] as String?;
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

  /// Гузоштани акси профил — фавран бор карда, дар профил сабт мешавад.
  Future<void> _pickPhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final file = await MediaService.pickFromGallery();
    if (file == null || !mounted) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final url = await MediaService.uploadImage(file, 'avatars/$uid');
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'photoUrl': url,
      }, SetOptions(merge: true));
      UserAvatar.updateCache(uid, url);
      if (!mounted) return;
      setState(() => _photoUrl = url);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = describeUploadError(e));
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = tr('k060'));
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
        _savedMessage = tr('k114');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = describeUploadError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.neonEmerald))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr('k115'),
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: _isUploadingPhoto ? null : _pickPhoto,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              UserAvatar(
                                name: _nameController.text,
                                photoUrl: _photoUrl,
                                size: 84,
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.neonEmerald,
                                ),
                                child: _isUploadingPhoto
                                    ? SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.background,
                                        ),
                                      )
                                    : Icon(LucideIcons.camera, color: AppColors.background, size: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(phone, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                      ),
                      const SizedBox(height: 26),
                      _buildField(tr('k063'), _nameController, hint: tr('k064')),
                      const SizedBox(height: 14),
                      _buildField(tr('k319'), _nicknameController, hint: '@shahron'),
                      const SizedBox(height: 14),
                      _buildField(tr('k116'), _aboutController, hint: tr('k067')),
                      if (_errorText != null) ...[
                        const SizedBox(height: 10),
                        Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                      ],
                      if (_savedMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(_savedMessage!, style: TextStyle(color: AppColors.neonEmerald, fontSize: 12.5)),
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
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                                )
                              : Text(tr('k117'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GlassContainer(
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            controller: controller,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
