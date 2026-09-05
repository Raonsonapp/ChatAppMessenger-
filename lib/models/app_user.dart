import 'package:cloud_firestore/cloud_firestore.dart';

/// Ҳуҷҷати `users/{uid}` дар Firestore — маълумоти профили корбар
/// пас аз тасдиқи рақами телефон (OTP).
class AppUser {
  final String uid;
  final String phone;
  final String name;
  final String nickname;
  final String about;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.phone,
    required this.name,
    required this.nickname,
    this.about = '',
    this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      phone: (data['phone'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      nickname: (data['nickname'] ?? '') as String,
      about: (data['about'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'name': name,
      'nickname': nickname,
      'about': about,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
