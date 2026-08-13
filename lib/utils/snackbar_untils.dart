import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

void showComingSoonSnack(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature ба зудӣ дастрас мешавад'),
      backgroundColor: AppColors.surface,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
