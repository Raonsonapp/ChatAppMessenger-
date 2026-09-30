import 'package:cloud_firestore/cloud_firestore.dart';

/// Натиҷаи санҷиши номи корбар.
enum UsernameStatus {
  ok,

  /// Шакл нодуруст: дарозӣ ё ҳарфҳои иҷозатнашуда.
  invalid,

  /// Каси дигар аллакай онро гирифтааст.
  taken,
}

class UsernameResult {
  const UsernameResult(this.status);

  final UsernameStatus status;

  bool get isOk => status == UsernameStatus.ok;
}

/// Номи корбари ягона (`@username`).
///
/// Ягонагӣ дар Firestore бо коллексияи алоҳидаи `usernames` таъмин мешавад:
/// ҳуҷҷат бо ID-и номи хурдҳарф соҳибашро нигоҳ медорад. Азбаски ду навиштан
/// ба як ҳуҷҷат имконнопазир аст, ду корбар ҳамон номро гирифта наметавонанд —
/// ин ягонагии воқеӣ аст, на санҷиши зоҳирӣ.
class UsernameService {
  UsernameService._();

  static const int minLength = 5;
  static const int maxLength = 32;

  /// Ҳарфи аввал бояд ҳарф бошад — то `@12345` ба рақами телефон монанд нашавад.
  static final RegExp _pattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{4,31}$');

  /// Матни воридшударо тоза мекунад: `@` ва фосилаҳо бароварда мешаванд.
  static String normalize(String raw) {
    var value = raw.trim();
    while (value.startsWith('@')) {
      value = value.substring(1);
    }
    return value.trim();
  }

  /// Калиди ҳуҷҷат — ҳамеша хурдҳарф, то `Shahron` ва `shahron` як ном бошанд.
  static String key(String raw) => normalize(raw).toLowerCase();

  static bool isValid(String raw) => _pattern.hasMatch(normalize(raw));

  static DocumentReference<Map<String, dynamic>> _nameRef(String raw) =>
      FirebaseFirestore.instance.collection('usernames').doc(key(raw));

  /// Номро барои корбар мегирад. Номи кӯҳна (агар бошад) озод мешавад.
  static Future<UsernameResult> claim({
    required String uid,
    required String raw,
    String? previous,
  }) async {
    if (!isValid(raw)) return const UsernameResult(UsernameStatus.invalid);

    final db = FirebaseFirestore.instance;
    final desired = key(raw);
    final oldKey = previous == null ? null : key(previous);

    try {
      await db.runTransaction((tx) async {
        final ref = _nameRef(desired);
        final snap = await tx.get(ref);
        if (snap.exists && snap.data()?['uid'] != uid) {
          throw const _Taken();
        }

        // Номи кӯҳна фақат вақте озод мешавад, ки воқеан дигар шуда бошад.
        if (oldKey != null && oldKey.isNotEmpty && oldKey != desired) {
          tx.delete(db.collection('usernames').doc(oldKey));
        }

        tx.set(ref, {'uid': uid});
        tx.set(
          db.collection('users').doc(uid),
          {'username': normalize(raw)},
          SetOptions(merge: true),
        );
      });
    } on _Taken {
      return const UsernameResult(UsernameStatus.taken);
    }
    return const UsernameResult(UsernameStatus.ok);
  }

  /// Номро озод мекунад — корбар қарор дод, ки бе `@username` бошад.
  static Future<void> release({required String uid, required String previous}) async {
    final oldKey = key(previous);
    if (oldKey.isEmpty) return;
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    batch.delete(db.collection('usernames').doc(oldKey));
    batch.set(
      db.collection('users').doc(uid),
      {'username': FieldValue.delete()},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  /// uid-и соҳиби ном, ё `null` агар ном озод бошад.
  static Future<String?> ownerOf(String raw) async {
    if (!isValid(raw)) return null;
    final snap = await _nameRef(raw).get();
    return snap.data()?['uid'] as String?;
  }
}

class _Taken implements Exception {
  const _Taken();
}
