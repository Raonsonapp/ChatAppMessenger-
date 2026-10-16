import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../theme/app_theme.dart';
import '../models/app_status.dart';
import '../models/status_style.dart';
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
  String? _pickedMusicUrl;
  String? _pickedMusicName;
  String? _selectedSticker;
  bool _drawingEnabled = false;
  final List<List<Offset>> _drawingStrokes = [];
  List<Offset>? _activeStroke;
  bool _isPosting = false;

  /// Шакли статуси матнӣ. Ҳангоми интихоби акс истифода намешавад.
  StatusStyle _style = const StatusStyle();

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

  Offset _normalizedPoint(Offset point, Size size) => Offset(
        (point.dx / size.width).clamp(0.0, 1.0).toDouble(),
        (point.dy / size.height).clamp(0.0, 1.0).toDouble(),
      );

  void _beginStroke(Offset point, Size size) {
    final stroke = <Offset>[_normalizedPoint(point, size)];
    setState(() { _activeStroke = stroke; _drawingStrokes.add(stroke); });
  }

  void _extendStroke(Offset point, Size size) {
    final stroke = _activeStroke;
    if (stroke != null) setState(() => stroke.add(_normalizedPoint(point, size)));
  }

  void _finishStroke() => _activeStroke = null;

  void _undoStroke() {
    if (_drawingStrokes.isEmpty) return;
    setState(() { _drawingStrokes.removeLast(); _activeStroke = null; });
  }

  void _clearStrokes() {
    setState(() { _drawingStrokes.clear(); _activeStroke = null; });
  }

  Future<void> _pick(bool fromCamera) async {
    final file = fromCamera ? await MediaService.pickFromCamera() : await MediaService.pickFromGallery();
    if (!mounted) return;
    if (file != null) setState(() => _pickedImage = file);
  }

  Future<void> _pickMusic() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final files = await FilePicker.pickFiles(type: FileType.audio);
      final file = files.isEmpty ? null : files.first;
      if (file == null || file.path == null || !mounted) return;
      setState(() => _isPosting = true);
      final url = await MediaService.uploadFile(
        File(file.path!),
        file.name,
        'statuses/$uid/music',
      );
      if (!mounted) return;
      setState(() {
        _pickedMusicUrl = url;
        _pickedMusicName = file.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describeUploadError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Widget _mediaStyleEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _editorLabel('Чорчӯбаи акс'),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < 4; i++)
              _chip(
                selected: _style.frame == i,
                onTap: () => setState(() => _style = _style.copyWith(frame: i)),
                child: Text(
                  const ['Не', 'Сафед', 'Сабз', 'Гулобӣ'][i],
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _editorLabel('Эффекти акс'),
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < 4; i++)
              _chip(
                selected: _style.effect == i,
                onTap: () => setState(() => _style = _style.copyWith(effect: i)),
                child: Text(
                  const ['Аслӣ', 'Сиёҳу сафед', 'Гарм', 'Кабуд'][i],
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                ),
              ),
          ],
        ),
      ],
    );
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

      final status = AppStatus(
        id: '',
        ownerId: uid,
        ownerName: myName,
        text: text.isEmpty ? null : text,
        imageUrl: imageUrl,
        musicUrl: _pickedMusicUrl,
        musicName: _pickedMusicName,
        stickerEmoji: _selectedSticker,
        drawingStrokes: _drawingStrokes.map((stroke) => List<Offset>.from(stroke)).toList(),
        style: _style,
      );
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

  /// Палитраи замина, услуби ҳарф ва ҷойгиршавӣ.
  Widget _styleEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _editorLabel(tr('k546')),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: StatusStyle.backgrounds.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final selected = _style.background == index;
              return GestureDetector(
                onTap: () => setState(() => _style = _style.copyWith(background: index)),
                child: Container(
                  width: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: StatusStyle.backgrounds[index],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.textPrimary : AppColors.glassBorder,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _editorLabel(tr('k547')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < StatusStyle.fonts.length; index++)
              _chip(
                selected: _style.font == index,
                onTap: () => setState(() => _style = _style.copyWith(font: index)),
                child: Text(
                  StatusStyle.fontNames[index],
                  style: StatusStyle.fonts[index].copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _editorLabel(tr('k548')),
        Row(
          children: [
            for (final entry in <(int, IconData)>[
              (0, LucideIcons.text_align_start),
              (1, LucideIcons.text_align_center),
              (2, LucideIcons.text_align_end),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(
                  selected: _style.align == entry.$1,
                  onTap: () => setState(() => _style = _style.copyWith(align: entry.$1)),
                  child: Icon(entry.$2, size: 17, color: AppColors.textPrimary),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _editorLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.75),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _chip({required bool selected, required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.neonEmerald.withValues(alpha: 0.18) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.neonEmerald : AppColors.glassBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: child,
      ),
    );
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
                        Container(
                          padding: EdgeInsets.all(_style.frame == 0 ? 0 : 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: _style.frame == 0
                                ? null
                                : Border.all(color: _style.frameColor!, width: 4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ColorFiltered(
                                  colorFilter: _style.imageFilter ?? const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.dst,
                                  ),
                                  child: Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                                ),
                                if (_drawingStrokes.isNotEmpty)
                                  Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _StoryDrawingPainter(_drawingStrokes)))),
                                if (_drawingEnabled)
                                  Positioned.fill(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                                        return GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onPanStart: (d) => _beginStroke(d.localPosition, size),
                                          onPanUpdate: (d) => _extendStroke(d.localPosition, size),
                                          onPanEnd: (_) => _finishStroke(),
                                          child: CustomPaint(
                                            painter: _StoryDrawingPainter(_drawingStrokes),
                                            child: const SizedBox.expand(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                if (_selectedSticker != null)
                                  Positioned(right: 14, bottom: 14, child: Text(_selectedSticker!, style: const TextStyle(fontSize: 58))),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: _style.gradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          child: Text(
                            _textController.text.isEmpty ? tr('k107') : _textController.text,
                            textAlign: _style.textAlign,
                            style: _style.textStyleFor(_textController.text, base: 22),
                          ),
                        ),
                      if (_pickedImage == null) ...[
                        const SizedBox(height: 16),
                        _styleEditor(),
                      ] else ...[
                        const SizedBox(height: 16),
                        _mediaStyleEditor(),
                      ],
                      const SizedBox(height: 12),
                      if (_pickedImage != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => setState(() => _drawingEnabled = !_drawingEnabled),
                                icon: Icon(_drawingEnabled ? Icons.edit_off : Icons.draw),
                                label: Text(_drawingEnabled ? 'Қалам: фаъол' : 'Қалам'),
                              ),
                            ),
                            IconButton(tooltip: 'Як қадам бекор кардан', onPressed: _drawingStrokes.isEmpty ? null : _undoStroke, icon: const Icon(Icons.undo)),
                            IconButton(tooltip: 'Тоза кардан', onPressed: _drawingStrokes.isEmpty ? null : _clearStrokes, icon: const Icon(Icons.delete_outline)),
                          ],
                        ),
                        Align(alignment: Alignment.centerLeft, child: _editorLabel('Стикер / эмодзи')),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final emoji in const ['❤️','😂','🔥','🥳','😍','✨','🌸','😎','🐼'])
                              ChoiceChip(
                                label: Text(emoji, style: const TextStyle(fontSize: 20)),
                                selected: _selectedSticker == emoji,
                                onSelected: (selected) => setState(() => _selectedSticker = selected ? emoji : null),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      OutlinedButton.icon(
                        onPressed: _isPosting ? null : _pickMusic,
                        icon: const Icon(Icons.music_note),
                        label: Text(
                          _pickedMusicName == null
                              ? 'Илова кардани мусиқӣ'
                              : 'Мусиқӣ: $_pickedMusicName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_pickedMusicName != null)
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _pickedMusicUrl = null;
                            _pickedMusicName = null;
                          }),
                          icon: const Icon(Icons.close),
                          label: const Text('Хориҷ кардани мусиқӣ'),
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


class _StoryDrawingPainter extends CustomPainter {
  const _StoryDrawingPainter(this.strokes);
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(Offset(stroke.first.dx * size.width, stroke.first.dy * size.height), 2.2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx * size.width, stroke.first.dy * size.height);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StoryDrawingPainter oldDelegate) => true;
}
