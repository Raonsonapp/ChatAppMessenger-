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
  Widget _buildAppBar() {
    final title = _tabTitle;
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
          if (_currentIndex == 0) ...[
            _iconButton(LucideIcons.camera, onTap: _openCameraStatus),
            const SizedBox(width: 6),
          ],
          if (_currentIndex != 0 && _currentIndex != 2) ...[
            _iconButton(LucideIcons.search, onTap: _openSearch),
            const SizedBox(width: 6),
          ],
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
