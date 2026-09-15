import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../l10n/l10n.dart';

void showComingSoonSnack(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(trf('k231', [feature])),
      backgroundColor: AppColors.surface,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
