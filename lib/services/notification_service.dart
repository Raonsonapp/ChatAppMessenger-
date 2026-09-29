import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../firebase_options.dart';
import '../models/app_call.dart';
import '../screens/call_screen.dart';
import '../screens/group_call_screen.dart';
import '../screens/chat_detail_screen.dart';
import '../models/chat_conversation.dart';
import '../screens/user_chat_screen.dart';
import '../screens/group_chat_screen.dart';
import '../screens/community_chat_screen.dart';
import '../l10n/l10n.dart';
import 'notification_prefs.dart';
import '../models/app_conversation.dart';

/// Калиди Navigator-и глобалӣ — барои кушодани чат/занг аз push-огоҳинома,
/// новобаста аз он ки корбар дар кадом экран аст.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const String _messagesChannelId = 'messages_channel';
const String _callsChannelId = 'calls_channel';

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

/// ID-и 32-бита барои огоҳинома — бар асоси мавзӯъ (call/thread), то
/// огоҳиномаҳои ҳамон сӯҳбат/занг якдигарро иваз кунанд, на ки анбошта шаванд.
int _notificationId(Map<String, dynamic> data) {
  final key = (data['callId'] ?? data['threadId'] ?? DateTime.now().millisecondsSinceEpoch).toString();
  return key.hashCode & 0x7FFFFFFF;
}

/// Огоҳиномаи паём вақте ки барнома дар пешзамина/паснамо кушода аст ё
/// пурра баста аст — дар ҳарду ҳолат тавассути ин функсия намоён мешавад.
Future<void> _showMessageNotification(Map<String, dynamic> data) async {
  // Танзимоти корбар: агар огоҳиномаи паём хомӯш бошад, чизе нишон дода
  // намешавад; садо, ларзиш ва нишон додани матн низ ба он тобеъанд.
  if (!await NotificationPrefs.read('messageNotifications')) return;
  final withSound = await NotificationPrefs.read('notificationSound');
  final withVibration = await NotificationPrefs.read('notificationVibration');
  final withPreview = await NotificationPrefs.read('notificationPreview');

  final senderName = data['senderName'] as String? ?? tr('k217');
  final text = data['text'] as String? ?? '';
  final payload = jsonEncode(data);

  final androidDetails = AndroidNotificationDetails(
    _messagesChannelId,
    tr('k218'),
    channelDescription: tr('k219'),
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.message,
    playSound: withSound,
    enableVibration: withVibration,
    actions: [
      AndroidNotificationAction(
        'reply',
        tr('k220'),
        inputs: [AndroidNotificationActionInput(label: tr('k221'))],
      ),
    ],
  );

  await _localNotifications.show(
    id: _notificationId(data),
    title: senderName,
    // «Нишон додани матн» хомӯш — танҳо «Паёми нав» навишта мешавад.
    body: (!withPreview || text.isEmpty) ? tr('k222') : text,
    notificationDetails: NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentSound: withSound),
    ),
    payload: payload,
  );
}

/// Огоҳиномаи занги воридотӣ — importance/priority максималӣ ва
/// fullScreenIntent, то мисли WhatsApp болои экрани қулф намоён шавад.
Future<void> _showIncomingCallNotification(Map<String, dynamic> data) async {
  final callerName = data['callerName'] as String? ?? tr('k223');
  final isVideo = data['callType'] == 'video';
  final payload = jsonEncode(data);

  final androidDetails = AndroidNotificationDetails(
    _callsChannelId,
    tr('k047'),
    channelDescription: tr('k224'),
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.call,
    fullScreenIntent: true,
    ongoing: true,
    timeoutAfter: 45000,
    actions: [
      AndroidNotificationAction('decline_call', tr('k123'), showsUserInterface: false, cancelNotification: true),
      AndroidNotificationAction('accept_call', tr('k124'), showsUserInterface: true, cancelNotification: true),
    ],
  );

  await _localNotifications.show(
    id: _notificationId(data),
    title: callerName,
    body: isVideo ? tr('k121') : tr('k122'),
    notificationDetails: NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
    payload: payload,
  );
}

/// Огоҳиномаи занги ҷавобнадодашуда.
///
/// Огоҳиномаи «занг зада истодааст» бекор карда мешавад: вагарна ду
/// огоҳинома дар лавҳа мемонад — яке «занг зада истодааст», дигаре
/// «ҷавоб надодед».
Future<void> _showMissedCallNotification(Map<String, dynamic> data) async {
  final callerName = data['callerName'] as String? ?? tr('k223');
  final isVideo = data['callType'] == 'video';

  await _localNotifications.cancel(id: _notificationId(data));

  final androidDetails = AndroidNotificationDetails(
    _callsChannelId,
    tr('k047'),
    channelDescription: tr('k224'),
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.missedCall,
  );

  await _localNotifications.show(
    // Шиносаи дигар, то огоҳиномаи занг ва ҷавобнадодашуда омехта нашаванд.
    id: _notificationId(data) + 1,
    title: callerName,
    body: isVideo ? tr('k401') : tr('k402'),
    notificationDetails: NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    ),
    payload: jsonEncode(data),
  );
}

Future<void> _ensureFirebaseReady() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

/// Коркарди амали "Ҷавоб"/"Рад кардан" — дар изоляти паснамо (барнома
/// пурра баста) ё дар изоляти асосӣ (барнома кушода) кор мекунад.
Future<void> _handleActionResponse(NotificationResponse response) async {
  if (response.payload == null) return;
  Map<String, dynamic> data;
  try {
    data = jsonDecode(response.payload!) as Map<String, dynamic>;
  } catch (_) {
    return;
  }

  if (response.actionId == 'reply' && response.input != null && response.input!.trim().isNotEmpty) {
    await _ensureFirebaseReady();
    final threadPath = data['threadPath'] as String?;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (threadPath == null || uid == null) return;
    final threadDoc = FirebaseFirestore.instance.doc(threadPath);
    final text = response.input!.trim();
    await threadDoc.collection('messages').add({
      'text': text,
      'senderId': uid,
      'isAI': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await threadDoc.set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': uid,
    }, SetOptions(merge: true));
  } else if (response.actionId == 'decline_call') {
    await _ensureFirebaseReady();
    final callId = data['callId'] as String?;
    if (callId == null) return;
    await FirebaseFirestore.instance.collection('calls').doc(callId).update({'outcome': 'declined'});
  }
}

/// Кушодани экрани дуруст вақте ки корбар ба худи огоҳинома (на ба амал) зер мекунад.
void _navigateFromPayload(Map<String, dynamic> data) {
  final type = data['type'] as String?;
  final navigator = navigatorKey.currentState;
  if (navigator == null) return;

  if (type == 'incoming_call') {
    final callId = data['callId'] as String?;
    final callerId = data['callerId'] as String?;
    final callerName = data['callerName'] as String? ?? tr('k002');
    final callType = data['callType'] == 'video' ? CallType.video : CallType.audio;
    if (callId == null || callerId == null) return;

    // Занг ҳамчун ҷавобдодашуда қайд мешавад. Бе ин IncomingCallListener
    // ҳуҷҷатро ҳанӯз `ringing` мебинад ва экрани занги воридотиро БОЛОИ
    // экрани зангe ки ҳозир кушода шуд, як бори дигар мебарорад.
    FirebaseFirestore.instance
        .collection('calls')
        .doc(callId)
        .update({'outcome': CallOutcome.completed.name})
        .catchError((_) {});

    // Занги гурӯҳӣ ба канали умумӣ мебарад, на ба сӯҳбати шахсӣ бо
    // зангзананда — вагарна қабулкунанда ба канали дигар меафтад ва ҳељ
    // касро намешунавад.
    final groupId = data['groupId'] as String?;
    final channelId = data['channelId'] as String?;
    if (groupId != null &&
        groupId.isNotEmpty &&
        channelId != null &&
        channelId.isNotEmpty) {
      navigator.push(MaterialPageRoute(
        builder: (_) => GroupCallScreen(
          groupId: groupId,
          groupName: (data['groupName'] as String?) ?? tr('k293'),
          type: callType,
          joinChannelId: channelId,
        ),
      ));
      return;
    }

    navigator.push(MaterialPageRoute(
      builder: (_) => CallScreen(otherUserId: callerId, otherUserName: callerName, type: callType, existingCallId: callId),
    ));
    return;
  }

  if (type == 'missed_call') {
    // Занги ҷавобнадодашуда — ба сӯҳбат бо ҳамон шахс мебарад, то корбар
    // фавран ҷавоб дода тавонад.
    final callerId = data['callerId'] as String?;
    final callerName = data['callerName'] as String? ?? tr('k002');
    if (callerId == null) return;
    navigator.push(MaterialPageRoute(
      builder: (_) => UserChatScreen(
        conversationId: AppConversation.idFor(callerId, FirebaseAuth.instance.currentUser?.uid ?? ''),
        otherUserId: callerId,
        otherUserName: callerName,
      ),
    ));
    return;
  }

  if (type == 'chat_message') {
    final kind = data['kind'] as String?;
    final threadId = data['threadId'] as String?;
    final senderName = data['senderName'] as String? ?? tr('k002');
    final threadName = data['threadName'] as String? ?? senderName;
    final senderId = data['senderId'] as String?;
    if (threadId == null) return;
    switch (kind) {
      case 'direct':
        if (senderId == null) return;
        navigator.push(MaterialPageRoute(
          builder: (_) => UserChatScreen(conversationId: threadId, otherUserName: senderName, otherUserId: senderId),
        ));
        break;
      case 'group':
        navigator.push(MaterialPageRoute(
          builder: (_) => GroupChatScreen(groupId: threadId, groupName: threadName, memberNames: const {}),
        ));
        break;
      case 'community':
        navigator.push(MaterialPageRoute(
          builder: (_) => CommunityChatScreen(communityId: threadId, communityName: threadName, memberNames: const {}),
        ));
        break;
      case 'ai':
        navigator.push(MaterialPageRoute(builder: (_) => ChatDetailScreen(conversation: AppChats.aiAssistant)));
        break;
    }
  }
}

/// Огоҳинома вақте ки корбар роят ба амал (аз ҷумла "Қабул") зер мекунад,
/// ва барнома ҳанӯз кушода/дар паснамо аст (на пурра баста).
@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) {
  _handleActionResponse(response);
  if (response.actionId == null || response.actionId == 'accept_call') {
    if (response.payload != null) {
      try {
        _navigateFromPayload(jsonDecode(response.payload!) as Map<String, dynamic>);
      } catch (_) {}
    }
  }
}

/// Ҳамон коркард, вале дар изоляти алоҳидаи паснамо (барнома пурра баста).
/// Танҳо амалҳои showsUserInterface:false (масалан "Ҷавоб", "Рад кардан")
/// ба ин ҷо мерасанд.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  _handleActionResponse(response);
}

/// Огоҳиномаи FCM-и маълумотӣ вақте ки барнома пурра баста аст.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _ensureFirebaseReady();
  final data = message.data;
  if (data['type'] == 'incoming_call') {
    await _showIncomingCallNotification(data);
  } else if (data['type'] == 'missed_call') {
    await _showMissedCallNotification(data);
  } else if (data['type'] == 'chat_message') {
    await _showMessageNotification(data);
  }
}

class NotificationService {
  static Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    // Дар Android 13+ огоҳинома иҷозати ҷудогонаи система талаб мекунад.
    // Бе он огоҳиномаҳо ХОМӮШОНА намерасанд — на хато ҳаст, на чизе.
    if (Platform.isAndroid) {
      try {
        final status = await Permission.notification.status;
        if (!status.isGranted) await Permission.notification.request();
      } catch (_) {
        // Дар версияҳои кӯҳна ин иҷозат вуҷуд надорад — ин хато нест.
      }
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(AndroidNotificationChannel(
      _messagesChannelId,
      tr('k218'),
      description: tr('k219'),
      importance: Importance.high,
    ));
    await androidPlugin?.createNotificationChannel(AndroidNotificationChannel(
      _callsChannelId,
      tr('k047'),
      description: tr('k224'),
      importance: Importance.max,
    ));

    FirebaseMessaging.onMessage.listen((message) async {
      final data = message.data;
      if (data['type'] == 'incoming_call') {
        await _showIncomingCallNotification(data);
      } else if (data['type'] == 'missed_call') {
        await _showMissedCallNotification(data);
      } else if (data['type'] == 'chat_message') {
        await _showMessageNotification(data);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateFromPayload(message.data);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateFromPayload(initialMessage.data));
    }
  }

  /// Пас аз воридшавӣ даъват шавад — токени FCM-и ҲАМИН дастгоҳро сабт
  /// мекунад, то сервер тавонад ба ӯ push фиристад.
  ///
  /// Токен ба РӮЙХАТ илова мешавад, на ба як майдон. Пештар як майдон буд ва
  /// вақте корбар аз дастгоҳи дуюм ворид мешуд, токени аввал иваз мегардид —
  /// дастгоҳи якум хомӯшона огоҳинома гирифтанро бас мекард.
  static Future<void> registerTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(uid, token);
    } catch (_) {
      // Дар дастгоҳҳои бе Google Play токен нест — ин барномаро набояд
      // вайрон кунад.
    }

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) => _saveToken(uid, newToken),
      onError: (_) {},
    );
  }

  static StreamSubscription<String>? _tokenRefreshSub;

  static Future<void> _saveToken(String uid, String token) async {
    _currentToken = token;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        // Майдони кӯҳна нигоҳ дошта мешавад, то сервери нусхаи кӯҳна низ
        // кор кунад.
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  static String? _currentToken;

  /// Пеш аз баромадан даъват шавад.
  ///
  /// Бе ин дастгоҳи бароммада ҳанӯз огоҳиномаҳои паёмҳои шахсиро мегирад —
  /// яъне касе ки телефонро мегирад, паёмҳои моро мебинад.
  static Future<void> unregisterTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final token = _currentToken ?? await _safeToken();
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    if (uid == null || token == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
        'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
    } catch (_) {}
    _currentToken = null;
  }

  static Future<String?> _safeToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }
}
