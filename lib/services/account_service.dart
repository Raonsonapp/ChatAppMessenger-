import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/otp_server_config.dart';

/// Нест кардани ҳисоб.
///
/// Амал дар сервер иҷро мешавад: барнома ҳуқуқи нест кардани ҳуҷҷатҳои
/// шахси дигар ва ҳисоби Firebase Auth-ро надорад ва набояд дошта бошад.
class AccountService {
  /// Ҳисоб ва маълумоти шахсиро нест мекунад, сипас аз барнома мебарояд.
  ///
  /// Бозгашт надорад.
  static Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const AccountFailure(AccountFailureKind.notSignedIn);

    final String idToken;
    try {
      // Токени тоза: сервер токени кӯҳнаро қабул намекунад, зеро ин амал
      // бозгашт надорад.
      idToken = await user.getIdToken(true) ?? '';
    } catch (_) {
      throw const AccountFailure(AccountFailureKind.network);
    }
    if (idToken.isEmpty) throw const AccountFailure(AccountFailureKind.notSignedIn);

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${OtpServerConfig.baseUrl}/api/delete-account'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw const AccountFailure(AccountFailureKind.network);
    }

    if (response.statusCode == 401) {
      throw const AccountFailure(AccountFailureKind.notSignedIn);
    }
    if (response.statusCode != 200) {
      throw const AccountFailure(AccountFailureKind.server);
    }

    final deleted = (jsonDecode(response.body) as Map<String, dynamic>)['deleted'];
    if (deleted != true) throw const AccountFailure(AccountFailureKind.server);

    // Ҳисоб дигар вуҷуд надорад — баромадан танҳо ҳолати маҳаллиро тоза
    // мекунад, бинобар ин хатои он муҳим нест.
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}

enum AccountFailureKind { notSignedIn, network, server }

class AccountFailure implements Exception {
  final AccountFailureKind kind;
  const AccountFailure(this.kind);

  @override
  String toString() => 'AccountFailure(${kind.name})';
}
