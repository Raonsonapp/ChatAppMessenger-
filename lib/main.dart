import 'dart:async';

import 'package:app_links/app_links.dart';
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
import 'theme/accessibility_controller.dart';
import 'services/draft_store.dart';
import 'l10n/locale_controller.dart';
import 'screens/auth_gate.dart';
import 'screens/marketplace/listing_detail_screen.dart';
import 'models/listing.dart';
import 'services/notification_service.dart';
import 'theme/chat_theme_controller.dart';
import 'services/media_settings_controller.dart';

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

  // Танзимот ПЕШ АЗ огоҳиномаҳо хонда мешавад: номи каналҳои Android аз
  // тарҷума гирифта мешавад ва пас аз сохта шудан дигар иваз намешавад —
  // вагарна корбари русзабон ҳамеша номи тоҷикиро мебинад.
  // Ҳамчунин пеш аз аввалин кашидан, то мавзӯъ назди чашм наҷаҳад.
  await _safely(themeController.load);
  await _safely(localeController.load);
  await _safely(wallpaperController.load);
  await _safely(textScaleController.load);
  await _safely(accessibilityController.load);
  await _safely(draftStore.load);
  await _safely(chatThemeController.load);
  await _safely(mediaSettings.load);
  // Якҷошавии мавзӯи торик/равшан бо контрасти баланд — пеш аз аввалин
  // кашидан, вагарна якеи ин ду танзимот то боздиди экран дида намешавад.
  AppColors.applyFlags(isDark: themeController.isDark, highContrast: accessibilityController.highContrast);

  // Огоҳиномаҳо дар баъзе дастгоҳҳо (масалан бе Google Play) истисно
  // мепартоянд. Пештар ин истисно то `runApp` мерасид ва барнома умуман
  // кушода намешуд — экрани сафед. Акнун барнома ҳатман оғоз мешавад.
  await _safely(NotificationService.initialize);

  runApp(const ChatApp());
}


/// Қадами оғозро иҷро мекунад ва намегузорад, ки хатои он барномаро
/// кушода нашуда монад.
Future<void> _safely(Future<void> Function() step) async {
  try {
    await step();
  } catch (error, stack) {
    debugPrint('Хатои оғоз: $error');
    debugPrintStack(stackTrace: stack);
  }
}

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Ҳангоми ҳар тағйири мавзӯъ/забон/андоза зиёд мешавад ва ҳамаи экранҳоро
  /// ба аз нав сохта шудан водор мекунад (ниг. AppScope).
  int _version = 0;

  late final Listenable _settings = Listenable.merge([
    themeController,
    localeController,
    wallpaperController,
    textScaleController,
    accessibilityController,
    draftStore,
    chatThemeController,
    mediaSettings,
  ]);

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (Object error) => debugPrint('Хатои пайванди воридотӣ: $error'),
    );
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleIncomingLink(uri);
    }).catchError((Object error) {
      debugPrint('Хатои пайванди аввалия: $error');
    });
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    if (uri.scheme != 'chatapp' || uri.host != 'marketplace') return;
    final segments = uri.pathSegments;
    if (segments.length < 2 || segments[0] != 'listing') return;
    final id = segments[1].trim();
    if (id.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('listings').doc(id).get();
      if (!doc.exists || doc.data() == null) return;
      final listing = Listing.fromDoc(doc);
      if (!listing.active || listing.title.isEmpty) return;
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => ListingDetailScreen(listing: listing),
      ));
    } catch (error) {
      debugPrint('Кушодани эълони муштарак ноком шуд: $error');
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _onSettingsChanged() {
    // Ҳар бор, вақте ки мавзӯъ Ё контрасти баланд тағйир меёбад, бояд якҷо
    // дубора ҳисоб карда шавад — вагарна фаъол кардани контрасти баланд дар
    // мавзӯи торик, пас аз иваз кардани мавзӯъ ба равшан (ё баракс), гум
    // мешавад.
    AppColors.applyFlags(isDark: themeController.isDark, highContrast: accessibilityController.highContrast);
    setState(() => _version++);
  }

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
