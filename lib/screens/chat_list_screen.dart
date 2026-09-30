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

  /// Менюи сенуқтагии саҳифаи асосӣ — мисли WhatsApp.
  ///
  /// Ҳар банд ба экрани воқеии мавҷуда мебарад; ҳеҷ банди холӣ нест.
  void _openHomeMenu() {
    ChatMenuSheet.show(
      context,
      title: 'ChatApp',
      actions: [
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
      ],
    );
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
              _iconButton(LucideIcons.search, onTap: _openSearch),
              const SizedBox(width: 8),
              _iconButton(LucideIcons.ellipsis_vertical, onTap: _openHomeMenu),
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
                  _navItem(2, LucideIcons.users, tr('k046')),
                  _navItem(3, LucideIcons.phone, tr('k047')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
