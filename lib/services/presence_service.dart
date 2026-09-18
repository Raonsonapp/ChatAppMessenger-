import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';

/// Ҳолати «дар шабака» ва «вақти охирин дида шуд».
///
/// Танзимоти махфият (`onlineVisible`, `lastSeenVisible`) аллакай вуҷуд дошт,
/// вале ҳељ ҷо сабт намешуд — яъне он тугмаҳо ҳељ кор намекарданд. Ин сервис
/// ҳолатро воқеан менависад ва ҳангоми нишон додан танзимоти соҳибро ба
/// назар мегирад.
class PresenceService with WidgetsBindingObserver {
  static final PresenceService instance = PresenceService._();
  PresenceService._();

  bool _started = false;

  /// Танзимоти махфият дар хотира нигоҳ дошта мешавад, то ҳар бор ба ҷои як
  /// навиштан ду муроҷиат ба Firestore нашавад.
  Map<String, dynamic>? _settingsCache;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _setOnline(true);
  }

  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _setOnline(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline(true);
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _setOnline(false);
    }
  }

  Future<void> _setOnline(bool online) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance.collection('users').doc(uid);

    // Танзимоти махфият пештар ТАНҲО ҳангоми нишон додан ба назар гирифта
    // мешуд: худи `online` ва `lastSeen` ба ҳар ҳол навишта мешуданд ва ҳар
    // корбари воридшуда онҳоро бевосита хонда метавонист. Яъне тугма
    // махфиятро ҳифз намекард, танҳо чашмро мепӯшид.
    //
    // Ҳоло чизе ки пинҳон кардан лозим аст, УМУМАН НАВИШТА НАМЕШАВАД ва
    // қимати кӯҳна тоза мегардад — маълумоте ки нест, ошкор ҳам намешавад.
    var settings = _settingsCache;
    if (settings == null) {
      try {
        final snapshot = await ref.get();
        settings = (snapshot.data()?['settings'] as Map<String, dynamic>?) ?? const {};
        _settingsCache = settings;
      } catch (_) {
        // Танзимот хонда нашуд — эҳтиёткорона рафтор мекунем ва чизе
        // намеnависем, то маълумоти пинҳонӣ тасодуфан ошкор нашавад.
        return;
      }
    }

    final onlineVisible = (settings['onlineVisible'] ?? true) == true;
    final lastSeenVisible = (settings['lastSeenVisible'] ?? true) == true;

    final update = <String, dynamic>{
      'online': onlineVisible ? online : FieldValue.delete(),
      'lastSeen': lastSeenVisible
          ? FieldValue.serverTimestamp()
          : FieldValue.delete(),
    };

    // Хатогиро фурӯ мебарем: ҳолати presence набояд барномаро вайрон кунад.
    await ref.set(update, SetOptions(merge: true)).catchError((_) {});
  }

  /// Пас аз тағйири танзимоти махфият даъват мешавад.
  ///
  /// Бе ин қимати кӯҳна то дафъаи дигар кушодани барнома боқӣ мемонад — яъне
  /// корбар танзимотро хомӯш мекунад, вале «охирин дида шуд»-и ӯ ҳанӯз
  /// намоён аст.
  Future<void> refresh() async {
    _settingsCache = null;
    if (!_started) return;
    await _setOnline(true);
  }

  /// Матни зери номи корбар дар сарлавҳаи чат.
  ///
  /// `null` — агар чизе нишон додан лозим набошад (соҳиб онро пинҳон кардааст
  /// ё маълумот ҳанӯз нест).
  static PresenceLabel? describe(Map<String, dynamic>? userData) {
    if (userData == null) return null;
    final settings = (userData['settings'] as Map<String, dynamic>?) ?? const {};

    final online = userData['online'] == true;
    if (online) {
      final visible = (settings['onlineVisible'] ?? true) == true;
      return visible ? PresenceLabel(tr('k248'), isOnline: true) : null;
    }

    if ((settings['lastSeenVisible'] ?? true) != true) return null;
    final lastSeen = (userData['lastSeen'] as Timestamp?)?.toDate();
    if (lastSeen == null) return null;

    final diff = DateTime.now().difference(lastSeen);
    final String text;
    if (diff.inMinutes < 1) {
      text = tr('k249');
    } else if (diff.inMinutes < 60) {
      text = trf('k250', [diff.inMinutes]);
    } else if (diff.inHours < 24) {
      text = trf('k251', [diff.inHours]);
    } else if (diff.inDays == 1) {
      text = tr('k252');
    } else {
      text = trf('k253', [diff.inDays]);
    }
    return PresenceLabel(text, isOnline: false);
  }
}

/// Матни presence ва он ки корбар ҳозир онлайн аст — то ранги он аз рӯи
/// муқоисаи сатр интихоб нашавад (он бо тарҷума мешиканад).
class PresenceLabel {
  final String text;
  final bool isOnline;
  const PresenceLabel(this.text, {required this.isOnline});
}
