import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_conversation.dart';
import '../../models/app_group.dart';
import '../../widgets/user_conversation_tile.dart';
import '../../widgets/group_tile.dart';
import '../../theme/app_theme.dart';
import '../../utils/doc_sort.dart';
import '../../l10n/l10n.dart';
import '../archived_chats_screen.dart';
import '../../widgets/empty_state.dart';
import '../../theme/app_scope.dart';
import '../../services/favorites_service.dart';

/// Рӯйхатҳои чат — ҳамон «Lists»-и WhatsApp.
enum ChatFilter { all, unread, groups, favorites }

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  ChatFilter _filter = ChatFilter.all;

  /// Рӯйхати дӯстдоштаҳо — барои филтри «Дӯстдошта».
  List<String> _favorites = const [];

  /// Чанд гурӯҳ дар кашидани ҷорӣ нишон дода шуд.
  ///
  /// Ду бахш (гурӯҳҳо ва чатҳои шахсӣ) ҷараёнҳои алоҳида доранд, вале паёми
  /// «чат нест» бояд як маротиба ва танҳо вақте пайдо шавад, ки ҳеҷ кадоми
  /// онҳо чизе надода бошанд. Бахши гурӯҳҳо дар рӯйхат пеш аз чатҳо меистад,
  /// бинобар ин то навбати чатҳо ин рақам аллакай нав шудааст.
  int _groupsShown = 0;

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return _list(null);

    // Ҷараёни дӯстдоштаҳо тамоми рӯйхатро мепечонад, на танҳо сатри филтрро.
    // Вагарна илова кардани дӯстдошта дар филтри «Дӯстдошта» дида намешуд:
    // сатри филтр аз нав кашида мешуд, вале рӯйхати чатҳо ҳамсоя аст ва
    // нав намешуд.
    return StreamBuilder<List<String>>(
      stream: FavoritesService.watch(currentUid),
      builder: (context, snapshot) {
        _favorites = snapshot.data ?? _favorites;
        return _list(currentUid);
      },
    );
  }

  Widget _list(String? currentUid) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
      children: [
        if (currentUid != null) _filterBar(),
        if (currentUid != null) ...[
          // Гурӯҳҳо
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('groups')
                .where('members', arrayContains: currentUid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    trf('k200', [snapshot.error]),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                );
              }
              if (!snapshot.hasData) return const SizedBox.shrink();
              // Дар рӯйхати «Дӯстдошта» гурӯҳҳо нестанд — дӯстдошта ба одам
              // тааллуқ дорад, на ба гурӯҳ.
              if (_filter == ChatFilter.favorites) {
                _groupsShown = 0;
                return const SizedBox.shrink();
              }
              final groups = sortByTimeDesc(snapshot.data!.docs, 'lastMessageTime')
                  .map(AppGroup.fromDoc)
                  .where((group) =>
                      _filter != ChatFilter.unread || group.unreadFor(currentUid) > 0)
                  .toList();
              _groupsShown = groups.length;
              if (groups.isEmpty) return const SizedBox.shrink();
              return Column(
                children: groups.map((group) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: GroupTile(group: group, currentUid: currentUid),
                  );
                }).toList(),
              );
            },
          ),
          // Сӯҳбатҳои шахсӣ
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('conversations')
                .where('participants', arrayContains: currentUid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    trf('k197', [snapshot.error]),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(color: AppColors.neonEmerald)),
                );
              }
              final all = sortByTimeDesc(snapshot.data!.docs, 'lastMessageTime')
                  .map(AppConversation.fromDoc)
                  .toList();
              // Чатҳои несткардашуда умуман нишон дода намешаванд.
              final visibleAll = all.where((c) => !c.isDeleted(currentUid)).toList();
              final archived = visibleAll.where((c) => c.isArchived(currentUid)).toList();
              // Чатҳои мустаҳкамшуда ҳамеша дар боло — мисли WhatsApp.
              final visible = visibleAll.where((c) => !c.isArchived(currentUid)).toList()
                ..sort((a, b) {
                  final pa = a.isPinned(currentUid) ? 0 : 1;
                  final pb = b.isPinned(currentUid) ? 0 : 1;
                  return pa.compareTo(pb);
                });

              final filtered = _applyFilter(visible, currentUid);

              if (visibleAll.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: EmptyState(
                    icon: LucideIcons.message_circle,
                    title: tr('k335'),
                    description: tr('k336'),
                  ),
                );
              }
              return Column(
                children: [
                  // Сатри бойгонӣ танҳо дар рӯйхати «Ҳама» — дар филтр он
                  // танҳо халал мерасонад.
                  if (archived.isNotEmpty && _filter == ChatFilter.all)
                    _ArchivedRow(
                      count: archived.length,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ArchivedChatsScreen()),
                      ),
                    ),
                  if (filtered.isEmpty && _groupsShown == 0 && _filter != ChatFilter.all)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: EmptyState(
                        icon: LucideIcons.list_filter,
                        title: tr('k554'),
                      ),
                    ),
                  ...filtered.map((convo) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: UserConversationTile(conversation: convo, currentUid: currentUid),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  List<AppConversation> _applyFilter(List<AppConversation> source, String currentUid) {
    return switch (_filter) {
      ChatFilter.all => source,
      ChatFilter.unread => source.where((c) => c.unreadFor(currentUid) > 0).toList(),
      // Дар рӯйхати «Гурӯҳҳо» чати шахсӣ нест.
      ChatFilter.groups => const [],
      ChatFilter.favorites =>
        source.where((c) => _favorites.contains(c.otherUid(currentUid))).toList(),
    };
  }

  /// Сатри рӯйхатҳо.
  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final entry in <(ChatFilter, String)>[
              (ChatFilter.all, tr('k551')),
              (ChatFilter.unread, tr('k552')),
              (ChatFilter.groups, tr('k190')),
              (ChatFilter.favorites, tr('k553')),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _filterChip(entry.$1, entry.$2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(ChatFilter filter, String label) {
    final selected = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.neonEmerald.withValues(alpha: 0.18) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.neonEmerald : AppColors.glassBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.neonEmerald : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Сатри «Чатҳои бойгонӣ» дар болои рӯйхат.
class _ArchivedRow extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _ArchivedRow({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.glassBorder, width: 0.6)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.archive, color: AppColors.textSecondary, size: 19),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  tr('k269'),
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
              ),
              Text('$count', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}
