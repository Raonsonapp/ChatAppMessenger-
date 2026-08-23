import 'package:flutter/material.dart';

import '../../models/chat_conversation.dart';
import '../../widgets/chat_tile.dart';

/// ЭЗОҲ: Пештар дар ин ҷо блоки калони "ChatAIBanner" низ буд (расм/мусиқӣ/
/// видео). Мутобиқи дархости шумо он бардошта шуд — акнун ChatAI танҳо
/// ҳамчун як қатори оддии феҳристи чат (бо равшании сабук) намоён аст,
/// мисли ҳар чати воқеӣ. Пешниҳодҳои расм/мусиқӣ/видео акнун дар ДОХИЛИ
/// худи чати ChatAI (ҳангоми холӣ будани он) намоён мешаванд.
class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
      children: const [
        ChatTile(conversation: AppChats.aiAssistant, highlighted: true),
        SizedBox(height: 6),
        ChatTile(conversation: AppChats.general),
      ],
    );
  }
}
