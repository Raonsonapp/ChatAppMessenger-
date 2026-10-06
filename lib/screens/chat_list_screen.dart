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
import 'linked_devices_screen.dart';
import 'coming_soon_screen.dart';
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

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
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

  void _openNewBroadcast() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComingSoonScreen(title: tr('k410'))),
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

  /// Менюи 3-нуқта дар сарлавҳа — мундариҷаи он вобаста ба таб-и фаъол аст:
  /// дар "Чатҳо" мисли WhatsApp (Гурӯҳи нав, Паёми умумӣ, Дастгоҳҳои
  /// пайвастшуда, Интихобшудаҳо, Ҳама хонда шуд, Танзимот), дар "Статусҳо"
  /// бошад мувофиқи ҳамон таб (Канали нав, Махфияти статус, Интихобшудаҳо,
  /// Танзимот).
  ///
  /// Мавқеи дақиқи тугма муҳим нест — менюи торик ҳамеша аз кунҷи болои
  /// рост мекушояд, мисли менюи 3-нуқтаи WhatsApp.
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

  Widget? _buildFab() {
    switch (_currentIndex) {
      case 0:
        return NeonFab(onPressed: _openNewChatSheet);
      case 1:
        return NeonFab(icon: LucideIcons.camera, onPressed: _openCreateStatus);
      case 2:
        return NeonFab(onPressed: _openCreateCommunity);
      case 3:
        return NeonFab(icon: LucideIcons.phone_call, onPressed: _openNewCallSheet);
      default:
        return null;
    }
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
              const ConnectionBanner(),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: const [
                    ChatsTab(),
                    StatusTab(),
                    CommunitiesTab(),
                    CallsTab(),
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
        return tr('k046');
      case 3:
        return tr('k047');
      default:
        return null;
    }
  }

  Widget _buildAppBar() {
    final title = _tabTitle;
    // Таби "Зангҳо" менюи худашро дорад (шортикатҳо + 3-нуқта дар боло),
    // бинобар ин ин қатори сарлавҳа дар он ҳоло танҳо ном нишон медиҳад.
    final isCallsTab = _currentIndex == 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _openProfileSheet,
            child: Row(
              children: [
                if (title == null) ...[
                  const AppLogo(size: 30),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.neonGradient.createShader(bounds),
                    child: const Text(
                      'ChatApp',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 0.2),
                    ),
                  ),
                ] else
                  Text(
                    title,
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: 0.2),
                  ),
              ],
            ),
          ),
          if (!isCallsTab)
            Row(
              children: [
                if (_currentIndex == 0) ...[
                  _iconButton(LucideIcons.camera, onTap: _openCameraStatus),
                  const SizedBox(width: 8),
                ],
                _iconButton(LucideIcons.search, onTap: _openSearch),
                const SizedBox(width: 8),
                _iconButton(LucideIcons.ellipsis_vertical, onTap: _openMainMenu),
              ],
            ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 14,
        padding: const EdgeInsets.all(9),
        child: Icon(icon, color: AppColors.textPrimary, size: 19),
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
