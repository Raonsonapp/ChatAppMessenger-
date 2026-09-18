import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/wallpaper_controller.dart';
import 'theme/text_scale_controller.dart';
import 'l10n/locale_controller.dart';
import 'screens/auth_gate.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();
  // Пеш аз аввалин кашидан, то мавзӯъ назди чашм наҷаҳад.
  await themeController.load();
  await localeController.load();
  await wallpaperController.load();
  await textScaleController.load();
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([themeController, localeController, wallpaperController, textScaleController]),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: themeController.isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: const AuthGate(),
        );
      },
    );
  }
}
