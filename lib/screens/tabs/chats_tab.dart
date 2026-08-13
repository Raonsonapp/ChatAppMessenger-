import 'package:flutter/material.dart';

import '../../models/chat_conversation.dart';
import '../../widgets/chat_ai_banner.dart';
import '../../widgets/chat_tile.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 100),
      children: const [
        ChatAIBanner(),
        SizedBox(height: 4),
        ChatTile(conversation: AppChats.aiAssistant, highlighted: true),
        SizedBox(height: 6),
        ChatTile(conversation: AppChats.general),
      ],
    );
  }
}
