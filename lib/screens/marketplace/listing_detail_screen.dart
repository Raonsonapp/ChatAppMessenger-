import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../l10n/l10n.dart';
import '../../models/app_conversation.dart';
import '../../models/listing.dart';
import '../../services/listing_service.dart';
import '../../theme/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/neon_backdrop.dart';
import '../../widgets/net_image.dart';
import '../../widgets/user_avatar.dart';
import '../image_viewer_screen.dart';
import '../user_chat_screen.dart';

/// Тафсилоти эълон. Тугмаи асосӣ — сӯҳбат бо соҳиб.
///
/// Ин ҳамон принсипи ChatApp аст: «ҳама чиз аз сӯҳбат сар мешавад». Ҳеҷ гуна
/// системаи алоҳидаи паём насохта мешавад — ҳамон `conversations` истифода
/// мешавад, бинобар ин сӯҳбат дар рӯйхати чатҳо пайдо мешавад.
class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final Listing listing;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  bool _busy = false;

  Listing get _listing => widget.listing;

  bool get _isMine => FirebaseAuth.instance.currentUser?.uid == _listing.ownerId;

  /// Матни тугмаи сӯҳбат аз навъи эълон вобаста аст — «фурӯшанда» барои
  /// ҷойи кор маъно надорад.
  String get _chatLabel => switch (_listing.kind) {
        ListingKind.product => tr('k567'),
        ListingKind.service => tr('k578'),
        ListingKind.job => tr('k577'),
        ListingKind.ad => tr('k567'),
      };

  Future<void> _chatWithOwner() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k581'))));
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final db = FirebaseFirestore.instance;
      final conversationId = AppConversation.idFor(uid, _listing.ownerId);
      final myDoc = await db.collection('users').doc(uid).get();
      final myName = (myDoc.data()?['name'] as String?)?.trim();

      await db.collection('conversations').doc(conversationId).set({
        'participants': [uid, _listing.ownerId],
        'participantNames': {
          uid: (myName == null || myName.isEmpty) ? tr('k002') : myName,
          _listing.ownerId: _listing.ownerName.isEmpty ? tr('k002') : _listing.ownerName,
        },
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserChatScreen(
            conversationId: conversationId,
            otherUserName: _listing.ownerName.isEmpty ? tr('k002') : _listing.ownerName,
            otherUserId: _listing.ownerId,
            // Матни омода дар майдони вуруд мемонад — корбар онро дида ва
            // тағйир дода метавонад. Паём худкор фиристода намешавад.
            initialText: _listing.title,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k543'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _takeDown() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(tr('k572'), style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
        content: Text(_listing.title, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('k277'), style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('k572'), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      // Эълон пинҳон мешавад, на нест — сӯҳбатҳои бо харидорон боқӣ мемонанд.
      await ListingService.deactivate(_listing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k573'))));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k543'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final price = _listing.price;
    final priceLabel = _listing.kind == ListingKind.job ? tr('k579') : tr('k565');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 14, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                    ),
                    Expanded(
                      child: Text(
                        tr('k556'),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (_isMine)
                      IconButton(
                        onPressed: _takeDown,
                        icon: const Icon(LucideIcons.trash, color: Colors.redAccent, size: 19),
                        tooltip: tr('k572'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  children: [
                    if (_listing.images.isNotEmpty) _gallery(),
                    const SizedBox(height: 14),
                    Text(
                      _listing.title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          price == null ? tr('k580') : ListingCard.formatPrice(price),
                          style: TextStyle(
                            color: price == null ? AppColors.textSecondary : AppColors.neonEmerald,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                          ),
                        ),
                        if (price != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            priceLabel.toLowerCase(),
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _metaCard(),
                    if (_listing.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _listing.description.trim(),
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 14.5, height: 1.45),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: _isMine
                      // Ба худаш нависондан маъно надорад — ба ҷои тугма
                      // танҳо эзоҳ нишон дода мешавад.
                      ? Text(
                          tr('k586'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonEmerald,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _busy ? null : _chatWithOwner,
                          icon: _busy
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.background,
                                  ),
                                )
                              : const Icon(LucideIcons.message_circle, size: 18),
                          label: Text(
                            _chatLabel,
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

  Widget _gallery() {
    if (_listing.images.length == 1) {
      return GestureDetector(
        onTap: () => _openImage(_listing.images.first),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: NetImage(url: _listing.images.first, height: 240, fit: BoxFit.cover),
        ),
      );
    }
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _listing.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => _openImage(_listing.images[index]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: NetImage(url: _listing.images[index], width: 280, height: 240, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  void _openImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ImageViewerScreen(url: url, title: _listing.title)),
    );
  }

  Widget _metaCard() {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(
                name: _listing.ownerName.isEmpty ? tr('k002') : _listing.ownerName,
                uid: _listing.ownerId,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _listing.ownerName.isEmpty ? tr('k002') : _listing.ownerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          if (_listing.city.isNotEmpty || _listing.category.isNotEmpty) ...[
            Divider(color: AppColors.glassBorder, height: 18),
            Row(
              children: [
                if (_listing.city.isNotEmpty) ...[
                  Icon(LucideIcons.map_pin, size: 15, color: AppColors.neonCyan),
                  const SizedBox(width: 6),
                  Text(
                    _listing.city,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
                if (_listing.city.isNotEmpty && _listing.category.isNotEmpty)
                  const SizedBox(width: 16),
                if (_listing.category.isNotEmpty) ...[
                  Icon(ListingCard.iconFor(_listing.kind), size: 15, color: AppColors.neonCyan),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _listing.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
