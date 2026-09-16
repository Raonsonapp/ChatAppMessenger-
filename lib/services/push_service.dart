import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/otp_server_config.dart';

/// Огоҳиномаҳои push тавассути сервери худамон фиристода мешаванд.
///
/// Триггери Firestore (Cloud Functions) ба нақшаи пулакии Blaze ниёз дорад,
/// бинобар ин пас аз фиристодани паём худи барнома серверро даъво мекунад ва
/// сервер (ки firebase-admin дорад) push мефиристад.
class PushService {
  /// Ба гиранда огоҳинома мефиристад. Хатогӣ фиристодани паёмро вайрон
  /// намекунад — паём аллакай дар Firestore сабт шудааст.
  static Future<void> notify({
    required String toUid,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;

      await http
          .post(
            Uri.parse('${OtpServerConfig.baseUrl}/api/notify'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'toUid': toUid,
              'title': title,
              'body': body,
              if (data != null) 'data': data,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Огоҳинома нарасид — вале паём фиристода шуд, ин ҳалокатовар нест.
    }
  }
}
