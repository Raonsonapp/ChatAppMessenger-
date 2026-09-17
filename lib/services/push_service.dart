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
  }) {
    return notifyMany(toUids: [toUid], title: title, body: body, data: data);
  }

  /// Ба якчанд гиранда (масалан ҳамаи аъзои гурӯҳ).
  ///
  /// Токен як маротиба гирифта мешавад ва дархостҳо дар як вақт мераванд —
  /// вагарна дар гурӯҳи калон фиристодани паём даҳҳо сония мекашид.
  static Future<void> notifyMany({
    required List<String> toUids,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (toUids.isEmpty) return;
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;

      final url = Uri.parse('${OtpServerConfig.baseUrl}/api/notify');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

      await Future.wait(toUids.map((toUid) {
        return http
            .post(
              url,
              headers: headers,
              body: jsonEncode({
                'toUid': toUid,
                'title': title,
                'body': body,
                if (data != null) 'data': data,
              }),
            )
            .timeout(const Duration(seconds: 10))
            // Як гиранда нарасид — дигарон бояд ба ҳар ҳол хабар гиранд.
            .catchError((_) => http.Response('', 599));
      }));
    } catch (_) {
      // Огоҳинома нарасид — вале паём фиристода шуд, ин ҳалокатовар нест.
    }
  }
}
