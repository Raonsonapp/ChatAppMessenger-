import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../models/app_call.dart';
import '../screens/call_screen.dart';
import '../screens/chat_detail_screen.dart';
import '../models/chat_conversation.dart';
import '../screens/user_chat_screen.dart';
import '../screens/group_chat_screen.dart';
import '../screens/community_chat_screen.dart';

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
  final senderName = data['senderName'] as String? ?? 'Паёми нав';
  final text = data['text'] as String? ?? '';
  final payload = jsonEncode(data);

  const androidDetails = AndroidNotificationDetails(
    _messagesChannelId,
    'Паёмҳо',
    channelDescription: 'Огоҳиномаи паёмҳои нав',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.message,
    actions: [
      AndroidNotificationAction(
        'reply',
        'Ҷавоб',
        inputs: [AndroidNotificationActionInput(label: 'Паём нависед...')],
      ),
    ],
  );

  await _localNotifications.show(
    _notificationId(data),
    senderName,
    text.isEmpty ? '📷 Расм' : text,
    const NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails()),
    payload: payload,
  );
}

/// Огоҳиномаи занги воридотӣ — importance/priority максималӣ ва
/// fullScreenIntent, то мисли WhatsApp болои экрани қулф намоён шавад.
Future<void> _showIncomingCallNotification(Map<String, dynamic> data) async {
  final callerName = data['callerName'] as String? ?? 'Занги воридотӣ';
  final isVideo = data['callType'] == 'video';
  final payload = jsonEncode(data);

  final androidDetails = AndroidNotificationDetails(
    _callsChannelId,
    'Зангҳо',
    channelDescription: 'Огоҳиномаи занги воридотӣ',
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.call,
    fullScreenIntent: true,
    ongoing: true,
    timeoutAfter: 45000,
    actions: [
      const AndroidNotificationAction('decline_call', 'Рад кардан', showsUserInterface: false, cancelNotification: true),
      AndroidNotificationAction('accept_call', 'Қабул', showsUserInterface: true, cancelNotification: true),
    ],
  );

  await _localNotifications.show(
    _notificationId(data),
    callerName,
    isVideo ? 'Занги видеоии воридотӣ...' : 'Занги воридотӣ...',
    NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails()),
    payload: payload,
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
    final callerName = data['callerName'] as String? ?? 'Корбар';
    final callType = data['callType'] == 'video' ? CallType.video : CallType.audio;
    if (callId == null || callerId == null) return;
    navigator.push(MaterialPageRoute(
      builder: (_) => CallScreen(otherUserId: callerId, otherUserName: callerName, type: callType, existingCallId: callId),
    ));
    return;
  }

  if (type == 'chat_message') {
    final kind = data['kind'] as String?;
    final threadId = data['threadId'] as String?;
    final senderName = data['senderName'] as String? ?? 'Корбар';
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
  } else if (data['type'] == 'chat_message') {
    await _showMessageNotification(data);
  }
}

class NotificationService {
  static Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _messagesChannelId,
      'Паёмҳо',
      description: 'Огоҳиномаи паёмҳои нав',
      importance: Importance.high,
    ));
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _callsChannelId,
      'Зангҳо',
      description: 'Огоҳиномаи занги воридотӣ',
      importance: Importance.max,
    ));

    FirebaseMessaging.onMessage.listen((message) async {
      final data = message.data;
      if (data['type'] == 'incoming_call') {
        await _showIncomingCallNotification(data);
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

  /// Пас аз воридшавӣ даъват шавад — токени FCM-ро дар ҳуҷҷати корбар
  /// сабт мекунад, то Cloud Function тавонад ба ӯ push фиристад.
  static Future<void> registerTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
    }
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance.collection('users').doc(uid).set({'fcmToken': newToken}, SetOptions(merge: true));
    });
  }
}
