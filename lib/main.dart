import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'theme/app_scope.dart';
import 'theme/theme_controller.dart';
import 'theme/wallpaper_controller.dart';
import 'theme/text_scale_controller.dart';
import 'services/draft_store.dart';
import 'l10n/locale_controller.dart';
import 'screens/auth_gate.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Ҳаҷми кэши Firestore маҳдуд нашавад: дар ҷойҳое ки интернет заиф аст,
  // сӯҳбатҳои кӯҳна бояд бе шабака ҳам кушода шаванд. Ин бояд ПЕШ АЗ
  // аввалин муроҷиат ба Firestore гузошта шавад.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();
  // Пеш аз аввалин кашидан, то мавзӯъ назди чашм наҷаҳад.
  await themeController.load();
  await localeController.load();
  await wallpaperController.load();
  await textScaleController.load();
  await draftStore.load();
  runApp(const ChatApp());
}

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  /// Ҳангоми ҳар тағйири мавзӯъ/забон/андоза зиёд мешавад ва ҳамаи экранҳоро
  /// ба аз нав сохта шудан водор мекунад (ниг. AppScope).
  int _version = 0;

  late final Listenable _settings = Listenable.merge([
    themeController,
    localeController,
    wallpaperController,
    textScaleController,
    draftStore,
  ]);

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() => _version++);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: themeController.isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          // AppScope дар болои Navigator меистад, вале хабари тағйирот ба
          // дохили ҳамаи маршрутҳо мерасад — маҳз ҳамин экранҳои кушодаро
          // бо ранг ва забони нав аз нав месозад.
          builder: (context, child) => AppScope(version: _version, child: child!),
          home: const AuthGate(),
        );
      },
    );
  }
}
