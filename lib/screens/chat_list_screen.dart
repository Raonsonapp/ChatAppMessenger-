import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';
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
import 'tabs/chats_tab.dart';
import 'tabs/status_tab.dart';
import 'tabs/communities_tab.dart';
import 'tabs/calls_tab.dart';

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
          Row(
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
          Row(
            children: [
              _iconButton(LucideIcons.camera, onTap: () => showComingSoonSnack(context, 'Камера')),
              const SizedBox(width: 8),
              _iconButton(LucideIcons.search, onTap: _openSearch),
              const SizedBox(width: 8),
              _iconButton(LucideIcons.ellipsis_vertical, onTap: _openProfileSheet),
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

  Widget _buildBottomNav() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.glassFill,
            border: Border(top: BorderSide(color: AppColors.glassBorder, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.neonEmerald,
              unselectedItemColor: AppColors.textSecondary,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11.5),
              items: const [
                BottomNavigationBarItem(icon: Icon(LucideIcons.message_circle), label: 'Чатҳо'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.circle), label: 'Статусҳо'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.users), label: 'Ҷамъиятҳо'),
                BottomNavigationBarItem(icon: Icon(LucideIcons.phone), label: 'Зангҳо'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
