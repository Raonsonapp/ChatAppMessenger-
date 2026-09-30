import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../l10n/l10n.dart';
import '../../services/plus_service.dart';
import '../../theme/app_scope.dart';
import '../../theme/app_theme.dart';
import '../../utils/user_search.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_backdrop.dart';
import '../../widgets/user_avatar.dart';

/// Панели соҳиб: ҷустуҷӯи корбар, додан ва бекор кардани Plus.
///
/// Ин экран ҳељ ваколат намедиҳад. Ҳар пахш ба сервер меравад ва сервер
/// uid-и токенро бо `OWNER_UID` муқоиса мекунад. Агар касе ин экранро ба
/// таври дигар кушояд, ҳар амал 403 мегирад.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final snapshot =
        await FirebaseFirestore.instance.collection('users').limit(kUserSearchLimit).get();
    final matches = snapshot.docs.where((doc) => userMatchesQuery(doc.data(), q)).map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'name': (data['name'] ?? tr('k002')) as String,
        'phone': (data['phone'] ?? '') as String,
        'photoUrl': (data['photoUrl'] ?? '') as String,
        'plus': data['plus'],
      };
    }).toList();
    if (!mounted) return;
    setState(() {
      _results = matches;
      _searching = false;
    });
  }

  Future<void> _grant(String uid) async {
    final duration = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    tr('k601'),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              for (final entry in <(String, String)>[
                ('7d', tr('k605')),
                ('30d', tr('k606')),
                ('1y', tr('k607')),
                ('lifetime', tr('k608')),
              ])
                ListTile(
                  leading: Icon(LucideIcons.calendar_clock, color: AppColors.neonCyan, size: 19),
                  title: Text(
                    entry.$2,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  onTap: () => Navigator.pop(sheetContext, entry.$1),
                ),
            ],
          ),
        ),
      ),
    );
    if (duration == null) return;
    await _run(() => PlusService.grant(uid: uid, duration: duration), tr('k603'));
  }

  Future<void> _revoke(String uid) async {
    await _run(() => PlusService.revoke(uid: uid), tr('k604'));
  }

  Future<void> _run(Future<PlusStatus> Function() action, String successMessage) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = successMessage;
        _messageIsError = false;
      });
      // Рӯйхат аз нав хонда мешавад — вагарна ҳолати кӯҳна нишон дода мешавад.
      await _search(_searchController.text);
    } on PlusFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = _describe(failure.code);
        _messageIsError = true;
      });
    }
  }

  static String _describe(String code) => switch (code) {
        'not-owner' => tr('k609'),
        'user-not-found' => tr('k610'),
        'cannot-revoke-owner' => tr('k590'),
        'network' || 'bad-response' => tr('k611'),
        _ => tr('k543'),
      };

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NeonBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                    ),
                    const Text('♛', style: TextStyle(color: Color(0xFFFFC857), fontSize: 17)),
                    const SizedBox(width: 8),
                    Text(
                      tr('k599'),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassContainer(
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: AppColors.textPrimary),
                    onSubmitted: _search,
                    decoration: InputDecoration(
                      hintText: tr('k600'),
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      prefixIcon: Icon(LucideIcons.search, color: AppColors.textSecondary, size: 19),
                      suffixIcon: IconButton(
                        icon: Icon(LucideIcons.arrow_right, color: AppColors.neonEmerald, size: 19),
                        onPressed: () => _search(_searchController.text),
                      ),
                    ),
                  ),
                ),
              ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _messageIsError ? Colors.redAccent : AppColors.neonEmerald,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              Expanded(
                child: _searching
                    ? Center(child: CircularProgressIndicator(color: AppColors.neonEmerald))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _results.length,
                        itemBuilder: (context, index) => _userRow(_results[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _userRow(Map<String, dynamic> user) {
    final uid = user['uid'] as String;
    final name = user['name'] as String;
    final raw = user['plus'];
    final status = PlusStatus.fromUserDoc(raw is Map ? {'plus': raw} : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            UserAvatar(
              name: name,
              photoUrl: (user['photoUrl'] as String).isEmpty ? null : user['photoUrl'] as String,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      if (status.active) const Text('  ✦', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.active ? tr('k588') : tr('k589'),
                    style: TextStyle(
                      color: status.active ? AppColors.neonEmerald : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _busy ? null : () => status.active ? _revoke(uid) : _grant(uid),
              child: Text(
                status.active ? tr('k602') : tr('k601'),
                style: TextStyle(
                  color: status.active ? Colors.redAccent : AppColors.neonEmerald,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
