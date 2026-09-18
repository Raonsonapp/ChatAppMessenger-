import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_theme.dart';

/// Тугмаи «ба поён» — вақте корбар дар чати дароз ба боло варақ задааст.
///
/// Ба [controller] обуна мешавад, бинобар ин ҳангоми варақ задан худаш пайдо
/// ва ғайб мешавад; экрани чат барои ин setState лозим надорад.
class ScrollToBottomButton extends StatelessWidget {
  final ScrollController controller;
  final VoidCallback onTap;
  const ScrollToBottomButton({super.key, required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final visible = controller.hasClients &&
            controller.position.maxScrollExtent - controller.position.pixels > 300;

        return AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: IgnorePointer(
            ignoring: !visible,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.glassBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(LucideIcons.chevron_down, color: AppColors.textSecondary, size: 20),
              ),
            ),
          ),
        );
      },
    );
  }
}
