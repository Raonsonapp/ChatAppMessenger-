import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Рамзи даъват ба гурӯҳ.
///
/// Рамз дар коллексияи ҷудогонаи `groupInvites` нигоҳ дошта мешавад, на дар
/// худи гурӯҳ: корбари ҳанӯз ғайриузв ҳуҷҷати гурӯҳро хонда наметавонад, вале
/// барои ҳамроҳ шудан бояд рамзро тафтиш кунад.
class GroupInviteService {
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String _newCode() {
    final random = Random.secure();
    return List.generate(8, (_) => _alphabet[random.nextInt(_alphabet.length)]).join();
  }

  /// Рамзи мавҷударо бармегардонад ё рамзи нав месозад.
  static Future<String?> ensureCode(String groupId, String groupName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final db = FirebaseFirestore.instance;
    final groupRef = db.collection('groups').doc(groupId);

    final group = await groupRef.get();
    final existing = group.data()?['inviteCode'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;

    final code = _newCode();
    await db.collection('groupInvites').doc(code).set({
      'groupId': groupId,
      'groupName': groupName,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await groupRef.set({'inviteCode': code}, SetOptions(merge: true));
    return code;
  }

  /// Рамзи кӯҳнаро бекор мекунад — ҳаволаи пешина дигар кор намекунад.
  static Future<void> revokeCode(String groupId) async {
    final db = FirebaseFirestore.instance;
    final groupRef = db.collection('groups').doc(groupId);
    final group = await groupRef.get();
    final existing = group.data()?['inviteCode'] as String?;
    if (existing != null && existing.isNotEmpty) {
      await db.collection('groupInvites').doc(existing).delete().catchError((_) {});
    }
    await groupRef.set({'inviteCode': FieldValue.delete()}, SetOptions(merge: true));
  }

  /// Натиҷаи кӯшиши ҳамроҳ шудан.
  static Future<GroupJoinResult> joinByCode(String rawCode, String myName) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return GroupJoinResult.failed;

    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return GroupJoinResult.notFound;

    final db = FirebaseFirestore.instance;
    try {
      final invite = await db.collection('groupInvites').doc(code).get();
      final groupId = invite.data()?['groupId'] as String?;
      final groupName = (invite.data()?['groupName'] as String?) ?? '';
      if (groupId == null) return GroupJoinResult.notFound;

      await db.collection('groups').doc(groupId).set({
        'members': FieldValue.arrayUnion([uid]),
        'memberNames': {uid: myName},
      }, SetOptions(merge: true));

      return GroupJoinResult.joined(groupId, groupName);
    } catch (_) {
      return GroupJoinResult.failed;
    }
  }
}

/// Натиҷаи ҳамроҳ шудан ба гурӯҳ бо рамз.
class GroupJoinResult {
  final String? groupId;
  final String groupName;
  final bool success;
  final bool codeUnknown;

  const GroupJoinResult._(this.groupId, this.groupName, this.success, this.codeUnknown);

  factory GroupJoinResult.joined(String groupId, String groupName) =>
      GroupJoinResult._(groupId, groupName, true, false);

  static const GroupJoinResult notFound = GroupJoinResult._(null, '', false, true);
  static const GroupJoinResult failed = GroupJoinResult._(null, '', false, false);
}
