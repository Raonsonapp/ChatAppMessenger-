import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_call.dart';
import '../screens/incoming_call_screen.dart';

/// Дар паси саҳна занги воридотиро назорат мекунад (то барнома кушода
/// бошад) ва IncomingCallScreen-ро худкор мекушояд. Огоҳии push (FCM)
/// дар ин лоиҳа пайваст нашудааст — занг танҳо вақте ки барнома дар
/// пешзамина кушода аст ошкор мешавад.
class IncomingCallListener extends StatefulWidget {
  final Widget child;
  const IncomingCallListener({super.key, required this.child});

  @override
  State<IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<IncomingCallListener> {
  final Set<String> _handledCallIds = {};
  bool _showing = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _subscription = FirebaseFirestore.instance
          .collection('calls')
          .where('calleeId', isEqualTo: uid)
          .where('outcome', isEqualTo: 'ringing')
          .snapshots()
          .listen(_handleSnapshot, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _handleSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (_showing || !mounted) return;
    for (final doc in snapshot.docs) {
      if (_handledCallIds.contains(doc.id)) continue;
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      _handledCallIds.add(doc.id);
      if (createdAt != null && DateTime.now().difference(createdAt).inSeconds > 40) {
        continue;
      }
      _showing = true;
      final call = AppCall.fromDoc(doc);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _showing = false;
          return;
        }
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => IncomingCallScreen(
              callId: call.id,
              callerId: call.callerId,
              callerName: call.callerName,
              type: call.type,
            ),
          ),
        );
        _showing = false;
      });
      break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
