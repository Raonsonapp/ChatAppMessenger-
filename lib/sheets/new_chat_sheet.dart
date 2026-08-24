import 'package:flutter/material.dart';

import 'contact_picker_screen.dart';

/// Compatibility wrapper барои кодҳои кӯҳна, ки ҳанӯз NewChatSheet-ро мекушоянд.
/// Он sheet-и рақами телефонро дигар нишон намедиҳад ва фавран ContactPickerScreen-ро мекушояд.
class NewChatSheet extends StatefulWidget {
  const NewChatSheet({super.key});

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ContactPickerScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
