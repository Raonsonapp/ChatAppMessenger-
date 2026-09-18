import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_conversation.dart';

/// Кӣ метавонад навсозиҳои маро бубинад.
enum StatusVisibility {
  /// Ҳама корбарони ChatApp.
  everyone('everyone'),

  /// Танҳо онҳое, ки бо ман сӯҳбат доранд.
  contacts('contacts'),

  /// Ҳељ кас.
  nobody('nobody');

  final String code;
  const StatusVisibility(this.code);

  static StatusVisibility fromCode(String? code) {
    return StatusVisibility.values.firstWhere(
      (v) => v.code == code,
      orElse: () => StatusVisibility.everyone,
    );
  }
}

/// Оё корбари ҷорӣ навсозиҳои соҳибро дида метавонад.
///
/// Барои ҳолати `contacts` мавҷудияти сӯҳбати шахсӣ тафтиш мешавад — id-и он
/// аз ду uid ҳисоб мешавад, бинобар ин як дархости ҳуҷҷат кифоя аст.
class StatusPrivacy {
  static final Map<String, bool> _conversationCache = {};

  static Future<bool> canView({
    required String ownerId,
    required String viewerId,
    required StatusVisibility visibility,
  }) async {
    if (ownerId == viewerId) return true;
    switch (visibility) {
      case StatusVisibility.everyone:
        return true;
      case StatusVisibility.nobody:
        return false;
      case StatusVisibility.contacts:
        final id = AppConversation.idFor(ownerId, viewerId);
        final cached = _conversationCache[id];
        if (cached != null) return cached;
        try {
          final doc = await FirebaseFirestore.instance.collection('conversations').doc(id).get();
          final exists = doc.exists;
          _conversationCache[id] = exists;
          return exists;
        } catch (_) {
          return false;
        }
    }
  }
}
