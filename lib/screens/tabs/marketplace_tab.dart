import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../l10n/l10n.dart';
import '../../models/listing.dart';
import '../../services/listing_service.dart';
import '../../theme/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/listing_card.dart';
import '../marketplace/listing_detail_screen.dart';

/// Бозор: маҳсулот, хизматҳо, ҷойи кор ва эълонҳо.
///
/// Харита ва расонидан (Delivery) ҳанӯз нестанд — онҳо коди нақшавӣ ва
/// системаи фармоиш талаб мекунанд. Бахши холӣ гузоштан аз он бадтар мебуд,
/// бинобар ин ин ҷо танҳо он чизе ҳаст, ки воқеан кор мекунад.
class MarketplaceTab extends StatefulWidget {
  const MarketplaceTab({super.key});

  @override
  State<MarketplaceTab> createState() => MarketplaceTabState();
}

class MarketplaceTabState extends State<MarketplaceTab> {
  ListingKind _kind = ListingKind.product;

  /// Навъи ҷории интихобшуда — экрани асосӣ онро барои тугмаи «+» мехонад.
  ListingKind get kind => _kind;

  /// Танҳо эълонҳои худи корбар.
  bool _mineOnly = false;

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        _kindBar(),
        if (uid != null) _mineToggle(),
        Expanded(
          child: StreamBuilder<List<Listing>>(
            stream: _mineOnly && uid != null
                ? ListingService.watchMine(uid)
                : ListingService.watchKind(_kind),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      tr('k543'),
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                );
              }
              // Дар ҳолати «Эълонҳои ман» ҳама навъҳо меоянд — филтри навъ
              // ин ҷо татбиқ намешавад, вагарна корбар эълонҳои худашро
              // намебинад ва фикр мекунад ки онҳо гум шудаанд.
              final items = snapshot.data ?? const <Listing>[];
              if (items.isEmpty) {
                return EmptyState(
                  icon: ListingCard.iconFor(_kind),
                  title: tr('k568'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                itemCount: items.length,
                itemBuilder: (context, index) => ListingCard(
                  listing: items[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ListingDetailScreen(listing: items[index]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _kindBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final entry in <(ListingKind, String)>[
              (ListingKind.product, tr('k558')),
              (ListingKind.service, tr('k559')),
              (ListingKind.job, tr('k560')),
              (ListingKind.ad, tr('k561')),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _chip(
                  label: entry.$2,
                  icon: ListingCard.iconFor(entry.$1),
                  selected: !_mineOnly && _kind == entry.$1,
                  onTap: () => setState(() {
                    _kind = entry.$1;
                    _mineOnly = false;
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mineToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _chip(
          label: tr('k569'),
          icon: LucideIcons.user,
          selected: _mineOnly,
          onTap: () => setState(() => _mineOnly = !_mineOnly),
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.neonEmerald.withValues(alpha: 0.18) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.neonEmerald : AppColors.glassBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? AppColors.neonEmerald : AppColors.textSecondary),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.neonEmerald : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
