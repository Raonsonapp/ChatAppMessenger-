import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/l10n.dart';
import '../../models/listing.dart';
import '../../services/listing_service.dart';
import '../../services/media_service.dart';
import '../../theme/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../utils/upload_error.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';

/// Сохтани эълон: маҳсулот, хизмат, ҷойи кор ё эълони одӣ.
class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key, required this.kind});

  final ListingKind kind;

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  final List<XFile> _images = [];
  bool _saving = false;
  String? _error;

  /// Беш аз ин расм ба як эълон лозим нест ва боркунӣ хеле дароз мекашад.
  static const int _maxImages = 5;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  String get _screenTitle => switch (widget.kind) {
        ListingKind.product => tr('k582'),
        ListingKind.service => tr('k583'),
        ListingKind.job => tr('k584'),
        ListingKind.ad => tr('k585'),
      };

  String get _priceLabel => widget.kind == ListingKind.job ? tr('k579') : tr('k565');

  Future<void> _addImage() async {
    if (_images.length >= _maxImages) return;
    final file = await MediaService.pickFromGallery();
    if (file == null || !mounted) return;
    setState(() => _images.add(file));
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _error = tr('k581'));
      return;
    }
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = tr('k571'));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final myDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final rawName = (myDoc.data()?['name'] as String?)?.trim();

      // Расмҳо пеш аз сохтани ҳуҷҷат бор мешаванд — эълони бе расм беҳтар аз
      // эълони ба расмҳои нарасида ишоракунанда аст.
      final urls = <String>[];
      for (final image in _images) {
        urls.add(await MediaService.uploadImage(image, 'listings/$uid'));
      }

      final listing = Listing(
        id: '',
        kind: widget.kind,
        ownerId: uid,
        ownerName: (rawName == null || rawName.isEmpty) ? tr('k002') : rawName,
        title: title,
        description: _descriptionController.text.trim(),
        price: _parsePrice(_priceController.text),
        city: _cityController.text.trim(),
        category: _categoryController.text.trim(),
        images: urls,
      );
      await ListingService.create(listing);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k570'))));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = describeUploadError(error);
      });
    }
  }

  /// Нарх бо фосила, вергул ё нуқта навишта мешавад — ҳамаро қабул мекунем.
  ///
  /// Матни холӣ ё нодуруст `null` медиҳад: «нарх нишон дода нашудааст» ҳолати
  /// қобили қабул аст, махсусан барои эълон ва хизмат.
  static num? _parsePrice(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s ]'), '').replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    final value = num.tryParse(cleaned);
    if (value == null || value < 0) return null;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.background,
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
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                    ),
                    Text(
                      _screenTitle,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  children: [
                    _imageRow(),
                    const SizedBox(height: 16),
                    _field(tr('k563'), _titleController),
                    const SizedBox(height: 14),
                    _field(
                      _priceLabel,
                      _priceController,
                      keyboardType: TextInputType.number,
                      // Ҳарф ба майдони нарх намегузарад — вагарна корбар
                      // танҳо баъди пахши «Нашр» хатогиро мебинад.
                      formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 .,]'))],
                      hint: tr('k580'),
                    ),
                    const SizedBox(height: 14),
                    _field(tr('k566'), _cityController),
                    const SizedBox(height: 14),
                    _field(tr('k576'), _categoryController),
                    const SizedBox(height: 14),
                    _field(tr('k564'), _descriptionController, maxLines: 5),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonEmerald,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.background,
                            ),
                          )
                        : Text(
                            tr('k562'),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageRow() {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var index = 0; index < _images.length; index++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(_images[index].path),
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                        child: const Icon(LucideIcons.x, size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_images.length < _maxImages)
            GestureDetector(
              onTap: _addImage,
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.image_plus, color: AppColors.neonEmerald, size: 22),
                    const SizedBox(height: 6),
                    Text(
                      tr('k575'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        GlassContainer(
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
