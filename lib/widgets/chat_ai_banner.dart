import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';
import '../models/chat_conversation.dart';
import '../screens/chat_detail_screen.dart';
import 'glass_container.dart';

/// Блоки ChatAI (мисли Meta AI) — имконияти сохтани расм, мусиқӣ ва видео.
/// Пахши ҳар чип корбарро ба чати AI Ассистент мебарад бо матни омодашуда
/// дар майдони вуруд (то Gemini API-и воқеӣ пайваст шавад).
class ChatAIBanner extends StatelessWidget {
  const ChatAIBanner({super.key});

  void _openWithPrompt(BuildContext context, String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(conversation: AppChats.aiAssistant, initialText: prompt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 22,
      glow: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
                child: const Icon(LucideIcons.zap, color: AppColors.background, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ChatAI', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Расм, мусиқӣ ё видео эҷод кунед', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AiActionChip(
                  icon: LucideIcons.image,
                  label: 'Расм',
                  onTap: () => _openWithPrompt(context, 'Лутфан барои ман расме эҷод кун: '),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AiActionChip(
                  icon: LucideIcons.music,
                  label: 'Мусиқӣ',
                  onTap: () => _openWithPrompt(context, 'Лутфан барои ман мусиқие эҷод кун: '),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AiActionChip(
                  icon: LucideIcons.video,
                  label: 'Видео',
                  onTap: () => _openWithPrompt(context, 'Лутфан барои ман видеое эҷод кун: '),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AiActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.neonCyan, size: 20),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
