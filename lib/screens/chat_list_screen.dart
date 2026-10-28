import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import '../services/media_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/neon_fab.dart';
import '../sheets/new_chat_sheet.dart';
import '../sheets/profile_sheet.dart';
import '../sheets/new_call_sheet.dart';
import 'chat_search_screen.dart';
import 'create_status_screen.dart';
import 'create_community_screen.dart';
import 'create_group_screen.dart';
import 'favorites_screen.dart';
import 'settings/linked_devices_screen.dart';
import 'broadcast_screen.dart';
import 'tabs/marketplace_tab.dart';
import 'marketplace/create_listing_screen.dart';
import 'chat_detail_screen.dart';
import '../models/listing.dart';
import '../models/chat_conversation.dart';
import 'settings/settings_home_screen.dart';
import 'create_channel_screen.dart';
import 'settings/privacy_settings_screen.dart';
import '../services/conversation_actions.dart';
import 'tabs/chats_tab.dart';
import 'tabs/status_tab.dart';
import 'tabs/communities_tab.dart';
import 'tabs/calls_tab.dart';
import '../l10n/l10n.dart';
import '../theme/app_scope.dart';
import '../widgets/connection_banner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notes_screen.dart';
import 'bot_studio_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  /// Барои донистани он ки дар Бозор кадом навъ интихоб шудааст — тугмаи «+»
  /// бояд ҳамон навъро созад.
  final GlobalKey<MarketplaceTabState> _marketplaceKey = GlobalKey<MarketplaceTabState>();

  int _currentIndex = 0;

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

  void _openNewGroup() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
  }

  void _openFavorites() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
  }

  void _openLinkedDevices() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkedDevicesScreen()));
  }

  /// Паёми умумӣ воқеан кор мекунад: матн ба ҳар чати шахсӣ ҷудогона меравад
  /// (мисли WhatsApp). Бинобар ин ин ҷо экрани «ба зудӣ» лозим нест.
  void _openNewBroadcast() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BroadcastScreen()),
    );
  }

  void _openSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsHomeScreen()));
  }

  Future<void> _markAllRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final messenger = ScaffoldMessenger.of(context);
    await ConversationActions.markAllRead(uid);
    if (mounted) messenger.showSnackBar(SnackBar(content: Text(tr('k437'))));
  }

  void _openCreateChannel() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateChannelScreen()));
  }

  void _openStatusPrivacy() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()));
  }

  /// Менюи 3-нуқта: танзимоти вобаста ба таби фаъол.
  void _openMainMenu() {
    final size = MediaQuery.of(context).size;
    final position = RelativeRect.fromLTRB(size.width - 220, 70, 12, 0);
    final items = _currentIndex == 1
        ? [
            _menuItem(LucideIcons.hash, tr('k093'), _openCreateChannel),
            _menuItem(LucideIcons.lock, tr('k441'), _openStatusPrivacy),
            _menuItem(LucideIcons.star, tr('k412'), _openFavorites),
            _menuItem(LucideIcons.settings, tr('k181'), _openSettings),
          ]
        : [
            _menuItem(LucideIcons.users, tr('k438'), _openNewGroup),
            _menuItem(Icons.campaign_outlined, tr('k410'), _openNewBroadcast),
            _menuItem(Icons.devices_other_outlined, tr('k411'), _openLinkedDevices),
            _menuItem(LucideIcons.star, tr('k412'), _openFavorites),
            _menuItem(LucideIcons.notebook_pen, 'Заметка', _openNotes),
            _menuItem(LucideIcons.check_check, tr('k413'), _markAllRead),
            _menuItem(LucideIcons.settings, tr('k181'), _openSettings),
          ];
    showMenu<void>(
      context: context,
      position: position,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.glassBorder)),
      items: items,
    );
  }

  /// Менюи зуди "+" — танзимоти зудро аз 3-нуқта ҷудо нигоҳ медорад.
  Widget _buildHeaderPlusButton() {
    return PopupMenuButton<String>(
      tooltip: 'Амали нав',
      icon: Icon(LucideIcons.plus, color: AppColors.textPrimary, size: 22),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.glassBorder),
      ),
      onSelected: (value) {
        switch (value) {
          case 'new_chat': _openNewChatSheet(); break;
          case 'ai': _openAi(); break;
          case 'telegram': Navigator.push(context, MaterialPageRoute(builder: (_) => const BotStudioScreen())); break;
          case 'group': _openNewGroup(); break;
          case 'broadcast': _openNewBroadcast(); break;
          case 'linked': _openLinkedDevices(); break;
          case 'community': _openCreateCommunity(); break;
          case 'channel': _openCreateChannel(); break;
          case 'status': _openCreateStatus(); break;
          case 'call': _openNewCallSheet(); break;
          case 'settings': _openSettings(); break;
        }
      },
      itemBuilder: (_) => [
        _headerAction('new_chat', LucideIcons.message_circle, 'Чати нав'),
        _headerAction('telegram', LucideIcons.bot, 'Ботҳо / Telegram'),
        const PopupMenuDivider(),
        _headerAction('group', LucideIcons.users, 'Гурӯҳи нав'),
        _headerAction('broadcast', Icons.campaign_outlined, 'Паёми умумӣ'),
        _headerAction('linked', Icons.devices_other_outlined, 'Дастгоҳҳои пайвастшуда'),
        _headerAction('community', LucideIcons.users_round, 'Ҷамъияти нав'),
        _headerAction('channel', LucideIcons.hash, 'Канали нав'),
        _headerAction('status', LucideIcons.circle_plus, 'Статуси нав'),
        _headerAction('call', LucideIcons.phone_call, 'Занги нав'),
        const PopupMenuDivider(),
        _headerAction('settings', LucideIcons.settings, 'Танзимот'),
      ],
    );
  }

  PopupMenuItem<String> _headerAction(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      height: 48,
      child: Row(
        children: [
          SizedBox(width: 28, child: Icon(icon, size: 19, color: AppColors.neonCyan)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14))),
        ],
      ),
    );
  }

  /// Сатри «Ҳамаро ҷустуҷӯ кунед» — чатҳо, гурӯҳҳо ва эълонҳои Бозор.
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
              Text(tr('k557'), style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<void> _menuItem(IconData icon, String label, VoidCallback onTap) {
    return PopupMenuItem<void>(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
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
        _quickToolsShortcut(),
        const SizedBox(height: 10),
        const SizedBox(height: 10),
        fab,
      ],
    );
  }

  /// Quick actions launcher placed above ChatAI and the primary plus button.
  /// This is deliberately separate from the header overflow menu.
  /// Standalone ChatAI button: it is intentionally not hidden under overflow/ellipsis.
  Widget _quickToolsShortcut() {
    return Semantics(
      button: true,
      label: 'ChatAI',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _openAi,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 54,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.72), width: 1.2),
              boxShadow: [
                BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.16), blurRadius: 12),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.zap, color: AppColors.neonCyan, size: 18),
                const SizedBox(height: 1),
                Text('ChatAI', style: TextStyle(color: AppColors.neonCyan, fontSize: 9, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openNotes() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
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

  /// Дар таби "Чатҳо" бренди "ChatApp" нишон дода мешавад; дар дигар
  /// табҳо — номи ҳамон таб (мисли WhatsApp, ки сарлавҳа вобаста ба
  /// экрани фаъол иваз мешавад).
  String? get _tabTitle {
    switch (_currentIndex) {
      case 1:
        return tr('k045');
      case 2:
        return tr('k556');
      case 3:
        return tr('k046');
      case 4:
        return tr('k047');
      default:
        return null;
    }
  }

  Widget _buildAppBar() {
    final title = _tabTitle;
    final compact = MediaQuery.sizeOf(context).width < 400;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _openProfileSheet,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  if (title == null) ...[
                    const AppLogo(size: 34),
                    const SizedBox(width: 10),
                    Flexible(
                      child: ShaderMask(
                        shaderCallback: (bounds) => AppColors.neonGradient.createShader(bounds),
                        child: const Text(
                          'ChatApp',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 23, letterSpacing: 0.1),
                        ),
                      ),
                    ),
                  ] else
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 0.1),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (_currentIndex == 0 && !compact) ...[
            _iconButton(LucideIcons.camera, onTap: _openCameraStatus),
            const SizedBox(width: 6),
          ],
          if (_currentIndex != 0 && _currentIndex != 2) ...[
            _iconButton(LucideIcons.search, onTap: _openSearch),
            const SizedBox(width: 6),
          ],
          if (!compact) ...[
            _iconButton(LucideIcons.phone_call, onTap: _openNewCallSheet),
            const SizedBox(width: 6),
          ],
          SizedBox(width: 44, height: 44, child: _buildHeaderPlusButton()),
          const SizedBox(width: 2),
          _iconButton(LucideIcons.ellipsis_vertical, onTap: _openMainMenu),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, {required VoidCallback onTap}) {
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: AppColors.textPrimary, size: 19),
          ),
        ),
      ),
    );
  }

  /// Навигатсияи поёнӣ — услуби WhatsApp/Material 3: зери иконаи интихобшуда
  /// "дона"-и кабуди мудаввар пайдо мешавад, дигарҳо хокистарӣ мемонанд.
  Widget _buildBottomNav() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary.withValues(alpha: 0.96),
            border: Border(top: BorderSide(color: AppColors.glassBorder, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  indicatorColor: AppColors.accent,
                  indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return TextStyle(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      color: selected ? AppColors.background : AppColors.textSecondary,
                      size: 22,
                    );
                  }),
                ),
              ),
              child: NavigationBar(
                height: 60,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) => setState(() => _currentIndex = i),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  NavigationDestination(icon: const Icon(LucideIcons.message_circle), label: tr('k044')),
                  NavigationDestination(icon: const Icon(LucideIcons.circle), label: tr('k045')),
                  NavigationDestination(icon: const Icon(LucideIcons.store), label: tr('k556')),
                  NavigationDestination(icon: const Icon(LucideIcons.users), label: tr('k046')),
                  NavigationDestination(icon: const Icon(LucideIcons.phone), label: tr('k047')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
