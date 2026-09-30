import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../l10n/l10n.dart';
import '../../models/ledger_entry.dart';
import '../../models/listing.dart';
import '../../services/ledger_service.dart';
import '../../services/listing_service.dart';
import '../../theme/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/neon_backdrop.dart';
import '../marketplace/listing_detail_screen.dart';

/// Маркази бизнес: эълонҳои фаъол ва дафтари қарз/даромад/хароҷот.
///
/// Фармоиш, расонидан ва омори харидорон ин ҷо нестанд — онҳо системаи фармоиш
/// талаб мекунанд, ки ҳанӯз нест. Ба ҷои банди холӣ ин рӯирост гуфта мешавад.
class BusinessCenterScreen extends StatefulWidget {
  const BusinessCenterScreen({super.key});

  @override
  State<BusinessCenterScreen> createState() => _BusinessCenterScreenState();
}

class _BusinessCenterScreenState extends State<BusinessCenterScreen> {
  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.neonEmerald,
              foregroundColor: AppColors.background,
              onPressed: () => _addEntry(uid),
              child: const Icon(LucideIcons.plus),
            ),
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      tr('k619'),
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
                child: uid == null
                    ? Center(
                        child: Text(tr('k581'), style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : StreamBuilder<List<LedgerEntry>>(
                        stream: LedgerService.watch(uid),
                        builder: (context, snapshot) {
                          final entries = snapshot.data ?? const <LedgerEntry>[];
                          final summary = LedgerSummary.from(entries);
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                            children: [
                              _summaryCard(summary),
                              const SizedBox(height: 16),
                              _listingsCard(uid),
                              const SizedBox(height: 16),
                              _sectionLabel(tr('k620')),
                              if (entries.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      tr('k636'),
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                    ),
                                  ),
                                )
                              else
                                ...entries.map((entry) => _entryRow(uid, entry)),
                              const SizedBox(height: 14),
                              Text(
                                tr('k640'),
                                style: TextStyle(
                                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                                  fontSize: 11.5,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tr('k639'),
                                style: TextStyle(
                                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(LedgerSummary summary) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _figure(tr('k621'), summary.balance, big: true)),
              Expanded(child: _figure(tr('k622'), summary.profit, big: true)),
            ],
          ),
          Divider(color: AppColors.glassBorder, height: 22),
          Row(
            children: [
              Expanded(child: _figure(tr('k623'), summary.owedToMe)),
              Expanded(child: _figure(tr('k624'), -summary.owedByMe)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _figure(tr('k625'), summary.income)),
              Expanded(child: _figure(tr('k626'), -summary.expense)),
            ],
          ),
        ],
      ),
    );
  }

  /// Рақам бо ранг: мусбат — сабз, манфӣ — сурх, сифр — хокистарӣ.
  Widget _figure(String label, num value, {bool big = false}) {
    final color = value == 0
        ? AppColors.textSecondary
        : (value > 0 ? AppColors.neonEmerald : Colors.redAccent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
        const SizedBox(height: 3),
        Text(
          ListingCard.formatPrice(value),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: big ? 17 : 14,
          ),
        ),
      ],
    );
  }

  /// Эълонҳои фаъоли корбар — ҳамон `listings`, филтри навъ нест.
  Widget _listingsCard(String uid) {
    return StreamBuilder<List<Listing>>(
      stream: ListingService.watchMine(uid),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <Listing>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('${tr('k638')} · ${items.length}'),
            if (items.isEmpty)
              Text(
                tr('k568'),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              )
            else
              ...items.take(3).map((listing) => ListingCard(
                    listing: listing,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)),
                    ),
                  )),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
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

  Widget _entryRow(String uid, LedgerEntry entry) {
    final positive = entry.kind.isPositive;
    final muted = entry.settled && (entry.kind == LedgerKind.debt || entry.kind == LedgerKind.credit);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(_iconFor(entry.kind), size: 18, color: muted ? AppColors.textSecondary : (positive ? AppColors.neonEmerald : Colors.redAccent)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted ? AppColors.textSecondary : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      decoration: muted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.note,
                      maxLines: 2,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              ListingCard.formatPrice(positive ? entry.amount : -entry.amount),
              style: TextStyle(
                color: muted ? AppColors.textSecondary : (positive ? AppColors.neonEmerald : Colors.redAccent),
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
            IconButton(
              onPressed: () => _entryMenu(uid, entry),
              icon: Icon(LucideIcons.ellipsis_vertical, size: 17, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(LedgerKind kind) => switch (kind) {
        LedgerKind.debt => LucideIcons.hand_coins,
        LedgerKind.credit => LucideIcons.circle_alert,
        LedgerKind.income => LucideIcons.trending_up,
        LedgerKind.expense => LucideIcons.trending_down,
      };

  Future<void> _entryMenu(String uid, LedgerEntry entry) async {
    final isDebtLike = entry.kind == LedgerKind.debt || entry.kind == LedgerKind.credit;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDebtLike)
                ListTile(
                  leading: Icon(
                    entry.settled ? LucideIcons.rotate_ccw : LucideIcons.check,
                    color: AppColors.neonEmerald,
                    size: 19,
                  ),
                  title: Text(
                    entry.settled ? tr('k634') : tr('k633'),
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.pop(sheetContext, 'toggle'),
                ),
              ListTile(
                leading: const Icon(LucideIcons.trash, color: Colors.redAccent, size: 19),
                title: Text(
                  tr('k258'),
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == 'toggle') {
      await LedgerService.setSettled(uid, entry.id, !entry.settled);
    } else if (action == 'delete') {
      await LedgerService.delete(uid, entry.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k635'))));
    }
  }

  Future<void> _addEntry(String uid) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    var kind = LedgerKind.debt;
    String? error;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('k627'),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in <(LedgerKind, String)>[
                        (LedgerKind.debt, tr('k623')),
                        (LedgerKind.credit, tr('k624')),
                        (LedgerKind.income, tr('k625')),
                        (LedgerKind.expense, tr('k626')),
                      ])
                        GestureDetector(
                          onTap: () => setSheetState(() => kind = entry.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: kind == entry.$1
                                  ? AppColors.neonEmerald.withValues(alpha: 0.18)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: kind == entry.$1 ? AppColors.neonEmerald : AppColors.glassBorder,
                              ),
                            ),
                            child: Text(
                              entry.$2,
                              style: TextStyle(
                                color: kind == entry.$1 ? AppColors.neonEmerald : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _sheetField(tr('k628'), titleController),
                  const SizedBox(height: 10),
                  _sheetField(
                    tr('k629'),
                    amountController,
                    keyboardType: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 .,]'))],
                  ),
                  const SizedBox(height: 10),
                  _sheetField(tr('k630'), noteController),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonEmerald,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final title = titleController.text.trim();
                        final amount = _parseAmount(amountController.text);
                        if (title.isEmpty || amount == null || amount <= 0) {
                          setSheetState(() => error = tr('k637'));
                          return;
                        }
                        Navigator.pop(sheetContext, true);
                      },
                      child: Text(
                        tr('k377'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (saved == true) {
      final amount = _parseAmount(amountController.text) ?? 0;
      await LedgerService.add(
        uid,
        LedgerEntry(
          id: '',
          kind: kind,
          title: titleController.text.trim(),
          amount: amount,
          note: noteController.text.trim(),
        ),
      );
    }

    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
  }

  Widget _sheetField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  static num? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s ]'), '').replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return num.tryParse(cleaned);
  }
}
