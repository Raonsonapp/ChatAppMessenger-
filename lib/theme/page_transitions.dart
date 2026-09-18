import 'package:flutter/material.dart';

/// Гузариши нарм байни экранҳо — фаромадани сабук ва ҳамвор шудан.
///
/// Гузариши пешфарзи Android (zoom) дар барномаи чат сангин менамояд;
/// ин гузариш ба он чизе наздиктар аст, ки дар WhatsApp дида мешавад.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
