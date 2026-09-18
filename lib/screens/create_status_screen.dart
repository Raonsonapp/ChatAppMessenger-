import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../models/app_status.dart';
import '../services/media_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';
import '../utils/upload_error.dart';

/// Сохтани навсозии воқеӣ (матн ё расм) — дар Firestore
/// `statuses/{uid}/items/{id}` бо мӯҳлати 24-соата сабт мешавад.
class CreateStatusScreen extends StatefulWidget {
  /// Расми аллакай гирифташуда (масалан аз тугмаи камера дар сарлавҳа) —
  /// экран фавран бо ҳамон расм кушода мешавад.
  final XFile? initialImage;
  const CreateStatusScreen({super.key, this.initialImage});

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> {
  final TextEditingController _textController = TextEditingController();
  XFile? _pickedImage;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _pickedImage = widget.initialImage;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pick(bool fromCamera) async {
    final file = fromCamera ? await MediaService.pickFromCamera() : await MediaService.pickFromGallery();
    if (file != null) setState(() => _pickedImage = file);
  }

  Future<void> _post() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final text = _textController.text.trim();
    if (text.isEmpty && _pickedImage == null) return;

    setState(() => _isPosting = true);
    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await MediaService.uploadImage(_pickedImage!, 'statuses/$uid');
      }
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final myName = (userDoc.data()?['name'] as String?) ?? tr('k015');

      final status = AppStatus(id: '', ownerId: uid, ownerName: myName, text: text.isEmpty ? null : text, imageUrl: imageUrl);
      await FirebaseFirestore.instance.collection('statuses').doc(uid).collection('items').add(status.toMap());
      await FirebaseFirestore.instance.collection('statuses').doc(uid).set({
        'ownerId': uid,
        'ownerName': myName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeUploadError(e))));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.x, color: AppColors.textPrimary, size: 22),
                    ),
                    Text(
                      tr('k106'),
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (_pickedImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(File(_pickedImage!.path), height: 300, width: double.infinity, fit: BoxFit.cover),
                        )
                      else
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: AppColors.neonGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          child: Text(
                            _textController.text.isEmpty ? tr('k107') : _textController.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.background, fontWeight: FontWeight.w800, fontSize: 22),
                          ),
                        ),
                      const SizedBox(height: 16),
                      GlassContainer(
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          controller: _textController,
                          maxLines: 3,
                          minLines: 1,
                          style: TextStyle(color: AppColors.textPrimary),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: tr('k108'),
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pick(false),
                              icon: Icon(LucideIcons.image, size: 18, color: AppColors.neonCyan),
                              label: Text(tr('k109'), style: TextStyle(color: AppColors.textPrimary)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.glassBorder),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pick(true),
                              icon: Icon(LucideIcons.camera, size: 18, color: AppColors.neonCyan),
                              label: Text(tr('k043'), style: TextStyle(color: AppColors.textPrimary)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.glassBorder),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonEmerald,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isPosting ? null : _post,
                    child: _isPosting
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
                        : Text(tr('k110'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
