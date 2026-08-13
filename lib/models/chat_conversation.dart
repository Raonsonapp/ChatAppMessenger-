import 'package:flutter/material.dart';

/// Суҳбатҳои дастрас — метавонанд AI Ассистент ё чати оддии Firestore бошанд
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

/// Рӯйхати суҳбатҳое, ки барнома айни замон дастгирӣ мекунад
class AppChats {
  static const aiAssistant = ChatConversation(
    id: 'ai_assistant',
    name: 'AI Ассистент',
    avatarIcon: Icons.auto_awesome_rounded,
    isAIChat: true,
  );
  static const general = ChatConversation(
    id: 'general',
    name: 'Чати умумӣ',
    avatarIcon: Icons.groups_rounded,
    isAIChat: false,
  );
  static const List<ChatConversation> all = [aiAssistant, general];
}
