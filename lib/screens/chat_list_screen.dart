import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/app_logo.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_backdrop.dart';
import '../widgets/neon_fab.dart';
import '../sheets/new_chat_sheet.dart';
import '../sheets/profile_sheet.dart';
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

  // Тугмаи "+" — дар ҳар бахш вазифаи мувофиқ дорад, айнан мисли WhatsApp
  Widget? _buildFab() {
    switch (_currentIndex) {
      case 0:
        return NeonFab(onPressed: _openNewChatSheet);
      case 1:
        return NeonFab(icon: Icons.camera_alt_rounded, onPressed: () => showComingSoonSnack(context, 'Статуси нав'));
      case 2:
        return NeonFab(onPressed: () => showComingSoonSnack(context, 'Ҷамъияти нав'));
      case 3:
        return NeonFab(onPressed: () => showComingSoonSnack(context, 'Занги нав'));
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

  // Сарлавҳаи боло — номи калони "ChatApp" + камера + ҷустуҷӯ + менюи се нуқта
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
              _iconButton(Icons.camera_alt_rounded, onTap: () => showComingSoonSnack(context, 'Камера')),
              const SizedBox(width: 8),
              _iconButton(Icons.search_rounded, onTap: () => showComingSoonSnack(context, 'Ҷустуҷӯ')),
              const SizedBox(width: 8),
              _iconButton(Icons.more_vert_rounded, onTap: _openProfileSheet),
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

  // Bottom Navigation Bar — Чатҳо / Статусҳо / Ҷамъиятҳо / Зангҳо (пайдарпаии дақиқ)
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
                BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Чатҳо'),
                BottomNavigationBarItem(icon: Icon(Icons.donut_large), label: 'Статусҳо'),
                BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Ҷамъиятҳо'),
                BottomNavigationBarItem(icon: Icon(Icons.call_rounded), label: 'Зангҳо'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
