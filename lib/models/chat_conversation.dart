import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// ChatAI — суҳбати ягонаи собит бо ID-и статикӣ
class ChatConversation {
  final String id;
  final String name;
  final IconData avatarIcon;
  final bool isAIChat;

  const ChatConversation({
    required this.id,
    required this.name,
    required this.avatarIcon,
    this.isAIChat = false,
  });
}

class AppChats {
  static const aiAssistant = ChatConversation(
    id: 'ai_assistant',
    name: 'ChatAI',
    avatarIcon: LucideIcons.zap,
    isAIChat: true,
  );
}
