import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import '../services/conversation_actions.dart';
import '../services/media_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/neon_fab.dart';
import '../sheets/chat_menu_sheet.dart';
import '../sheets/new_chat_sheet.dart';
import '../sheets/profile_sheet.dart';
import '../sheets/new_call_sheet.dart';
import 'broadcast_screen.dart';
import 'chat_search_screen.dart';
import 'create_group_screen.dart';
import 'starred_messages_screen.dart';
import 'settings/linked_devices_screen.dart';
import 'settings/settings_home_screen.dart';
import 'create_status_screen.dart';
import 'create_community_screen.dart';
import 'tabs/chats_tab.dart';
import 'tabs/status_tab.dart';
import 'tabs/communities_tab.dart';
import 'tabs/calls_tab.dart';
import 'tabs/marketplace_tab.dart';
import 'marketplace/create_listing_screen.dart';
import '../models/listing.dart';
import '../models/chat_conversation.dart';
import 'chat_detail_screen.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';
import '../widgets/connection_banner.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _currentIndex = 0;

  /// Барои донистани он ки дар Бозор кадом навъ интихоб шудааст — тугмаи «+»
  /// бояд ҳамон навъро созад.
  final GlobalKey<MarketplaceTabState> _marketplaceKey = GlobalKey<MarketplaceTabState>();

  /// Лангари менюи сенуқтагӣ — меню бояд зери ҳамин тугма кушода шавад.
  final GlobalKey _menuAnchorKey = GlobalKey();

  void _openNewChatSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const NewChatSheet(),
    );
  }

  void _openProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileSheet(),
    );
  }

  /// Менюи сенуқтагии саҳифаи асосӣ.
  ///
  /// Ҳар банд ба экрани воқеии мавҷуда мебарад; ҳеҷ банди холӣ нест.
  ///
  /// Меню зери ҳамон тугма кушода мешавад, на аз поёни экран: варақаи поёнӣ
  /// барои менюи дохили чат мемонад, вале дар сарлавҳа менюи лангарӣ ба
  /// тугмаи пахшшуда наздиктар аст ва камтар ҷои экранро мепӯшонад.
  Future<void> _openHomeMenu() async {
    final anchor = _menuAnchorKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (anchor == null || overlay == null) return;

    final topRight = anchor.localToGlobal(anchor.size.topRight(Offset.zero), ancestor: overlay);
    final bottomRight = anchor.localToGlobal(anchor.size.bottomRight(Offset.zero), ancestor: overlay);

    final selected = await showMenu<VoidCallback>(
      context: context,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.glassBorder),
      ),
      position: RelativeRect.fromLTRB(
        topRight.dx,
        bottomRight.dy + 6,
        overlay.size.width - topRight.dx,
        0,
      ),
      items: [
        for (final action in _homeMenuActions())
          PopupMenuItem<VoidCallback>(
            value: action.onTap,
            height: 46,
            child: Row(
              children: [
                Icon(action.icon, size: 18, color: AppColors.neonCyan),
                const SizedBox(width: 14),
                Text(
                  action.label,
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
    selected?.call();
  }

  List<ChatMenuAction> _homeMenuActions() {
    return [
        ChatMenuAction(
          icon: LucideIcons.users,
          label: tr('k083'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          ),
        ),
        ChatMenuAction(
          icon: LucideIcons.megaphone,
          label: tr('k493'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BroadcastScreen()),
          ),
        ),
        ChatMenuAction(
          icon: LucideIcons.monitor_smartphone,
          label: tr('k494'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LinkedDevicesScreen()),
          ),
        ),
        ChatMenuAction(
          icon: LucideIcons.star,
          label: tr('k260'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StarredMessagesScreen()),
          ),
        ),
        ChatMenuAction(
          icon: LucideIcons.check_check,
          label: tr('k495'),
          onTap: _markAllRead,
        ),
        ChatMenuAction(
          icon: LucideIcons.settings,
          label: tr('k181'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsHomeScreen()),
          ),
        ),
      ];
  }

  Future<void> _markAllRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await ConversationActions.markAllRead(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k496'))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('k543'))));
    }
  }

  void _openSearch() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatSearchScreen()));
  }

  void _openCreateStatus() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateStatusScreen()));
  }

  /// Тугмаи камера дар сарлавҳа — мисли WhatsApp: сурат мегирем ва фавран
  /// экрани сохтани навсозӣ бо ҳамон сурат кушода мешавад.
  Future<void> _openCameraStatus() async {
    final photo = await MediaService.pickFromCamera();
    if (photo == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateStatusScreen(initialImage: photo)),
    );
  }

  void _openCreateCommunity() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCommunityScreen()));
  }

  void _openNewCallSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const NewCallSheet(),
    );
  }

  /// Тугмаи асосӣ ва — дар ҷадвали чатҳо — гузаргоҳи ChatApp AI дар болои он.
  ///
  /// AI пештар ҳамчун чати мустаҳкамшуда дар болои рӯйхат мешишт ва ҳар рӯз
  /// ҷои як сӯҳбати воқеиро мегирифт. Ҳоло он гузаргоҳи ҷамъушуда аст.
  Widget? _buildFab() {
    final fab = switch (_currentIndex) {
      0 => NeonFab(onPressed: _openNewChatSheet),
      1 => NeonFab(icon: LucideIcons.camera, onPressed: _openCreateStatus),
      2 => NeonFab(onPressed: _openCreateListing),
      3 => NeonFab(onPressed: _openCreateCommunity),
      4 => NeonFab(icon: LucideIcons.phone_call, onPressed: _openNewCallSheet),
      _ => null,
    };
    if (fab == null) return null;
    if (_currentIndex != 0) return fab;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _aiShortcut(),
        const SizedBox(height: 12),
        fab,
      ],
    );
  }

  /// Гузаргоҳи ҷамъушудаи ChatApp AI.
  Widget _aiShortcut() {
    return GestureDetector(
      onTap: _openAi,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.55), width: 1.2),
          boxShadow: [
            BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.22), blurRadius: 14, spreadRadius: 0.5),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkles, color: AppColors.neonCyan, size: 16),
            const SizedBox(width: 7),
            Text(
              'AI',
              style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _openAi() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatDetailScreen(conversation: AppChats.aiAssistant)),
    );
  }

  /// Эълони нав аз ҳамон навъе ки дар Бозор интихоб шудааст.
  void _openCreateListing() {
    final kind = _marketplaceKey.currentState?.kind ?? ListingKind.product;
    Navigator.push(context, MaterialPageRoute(builder: (_) => CreateListingScreen(kind: kind)));
  }

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
      body: NeonBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(),
              // Сатри ҷустуҷӯ танҳо дар он ҷадвалҳое ки чизе барои ҷустуҷӯ
              // доранд. Дар «Статус» ва «Зангҳо» он танҳо ҷой мегирифт.
              if (_currentIndex == 0 || _currentIndex == 2) _buildSearchField(),
              const ConnectionBanner(),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    const ChatsTab(),
                    const StatusTab(),
                    MarketplaceTab(key: _marketplaceKey),
                    const CommunitiesTab(),
                    const CallsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Пахши логотип варақаи профилро мекушояд — роҳи кӯтоҳ ба профил,
          // ситорадорҳо ва танзимот.
          GestureDetector(
            onTap: _openProfileSheet,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const AppLogo(size: 30),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.neonGradient.createShader(bounds),
                  child: const Text(
                    'ChatApp',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 0.2),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _iconButton(LucideIcons.camera, onTap: _openCameraStatus),
              const SizedBox(width: 8),
              // Дар ҷадвалҳое ки сатри ҷустуҷӯ доранд, нишонаи ҷустуҷӯ дар
              // сарлавҳа такрор мешавад — он ҷо пинҳон мешавад.
              if (_currentIndex != 0 && _currentIndex != 2) ...[
                _iconButton(LucideIcons.search, onTap: _openSearch),
                const SizedBox(width: 8),
              ],
              _iconButton(LucideIcons.ellipsis_vertical, onTap: _openHomeMenu, key: _menuAnchorKey),
            ],
          ),
        ],
      ),
    );
  }

  /// Сатри «Ҳамаро ҷустуҷӯ кунед» — чатҳо, паёмҳо, корбарон ва эълонҳои Бозор.
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: _openSearch,
        behavior: HitTestBehavior.opaque,
        child: GlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(LucideIcons.search, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 10),
              Text(
                tr('k557'),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, {required VoidCallback onTap, Key? key}) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 14,
        padding: const EdgeInsets.all(9),
        child: Icon(icon, color: AppColors.textPrimary, size: 19),
      ),
    );
  }

  /// Як банди навбар бо аниматсияи мулоим.
  ///
  /// Ҳангоми интихоб: андоза каме калон, каме боло меравад ва дурахш пайдо
  /// мешавад — 260 мс, ба қадри кофӣ намоён, вале на дилгиркунанда.
  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (_currentIndex == index) return;
            setState(() => _currentIndex = index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSlide(
                  offset: Offset(0, selected ? -0.10 : 0),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  child: AnimatedScale(
                    scale: selected ? 1.16 : 1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.neonEmerald
                                      .withValues(alpha: 0.35),
                                  blurRadius: 14,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        size: 21,
                        color: selected
                            ? AppColors.neonEmerald
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  style: TextStyle(
                    color: selected
                        ? AppColors.neonEmerald
                        : AppColors.textSecondary.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            border: Border(top: BorderSide(color: AppColors.glassBorder, width: 1)),
          ),
          child: SafeArea(
            top: false,
            // Навбари худсохт: `BottomNavigationBar`-и стандартӣ дурахши
            // нишонаи интихобшуда ва ҳаракати амудиро дастгирӣ намекунад.
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  _navItem(0, LucideIcons.message_circle, tr('k044')),
                  _navItem(1, LucideIcons.circle_dashed, tr('k045')),
                  _navItem(2, LucideIcons.store, tr('k556')),
                  _navItem(3, LucideIcons.users, tr('k046')),
                  _navItem(4, LucideIcons.phone, tr('k047')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
