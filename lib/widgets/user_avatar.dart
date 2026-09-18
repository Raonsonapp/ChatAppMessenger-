import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Аксиcи профили корбар бо бозгашт ба ҳарфи аввали ном.
///
/// Барнома то ҳол ҳељ ҷо акси профилро нишон намедод. Барои он ки рӯйхати
/// чатҳо барои ҳар сатр як дархости нав насозад, суроғаи акс дар хотира
/// нигоҳ дошта мешавад — як бор хонда мешавад ва баъд аз кэш меояд.
class UserAvatar extends StatefulWidget {
  final String name;

  /// Агар дода шавад, акс аз `users/{uid}.photoUrl` гирифта мешавад.
  final String? uid;

  /// Агар суроға аллакай маълум бошад, дархост тамоман намешавад.
  final String? photoUrl;
  final double size;

  const UserAvatar({
    super.key,
    required this.name,
    this.uid,
    this.photoUrl,
    this.size = 52,
  });

  static final Map<String, String?> _cache = {};

  /// Рангҳои аватар — ҳамон тавре ки дар WhatsApp ва Telegram: ҳар кас ранги
  /// худро дорад ва он ҳамеша як хел мемонад, чун аз номаш ҳисоб мешавад.
  static const List<List<Color>> _gradients = [
    [Color(0xFF00B894), Color(0xFF00CEC9)],
    [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
    [Color(0xFFE17055), Color(0xFFFAB1A0)],
    [Color(0xFF0984E3), Color(0xFF74B9FF)],
    [Color(0xFFD63031), Color(0xFFFF7675)],
    [Color(0xFFE84393), Color(0xFFFD79A8)],
    [Color(0xFF00897B), Color(0xFF4DB6AC)],
    [Color(0xFFF39C12), Color(0xFFFFD08A)],
  ];

  /// Ранг аз рӯи ном (ё uid, агар ном холӣ бошад) интихоб мешавад.
  static List<Color> gradientFor(String seed) {
    if (seed.isEmpty) return _gradients.first;
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return _gradients[hash % _gradients.length];
  }

  /// Пас аз иваз кардани акс кэшро нав мекунем, вагарна акси кӯҳна мемонад.
  static void updateCache(String uid, String? url) => _cache[uid] = url;

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _url;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid || oldWidget.photoUrl != widget.photoUrl) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    if (widget.photoUrl != null) {
      setState(() => _url = widget.photoUrl);
      return;
    }
    final uid = widget.uid;
    if (uid == null || uid.isEmpty) return;
    if (UserAvatar._cache.containsKey(uid)) {
      setState(() => _url = UserAvatar._cache[uid]);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final url = doc.data()?['photoUrl'] as String?;
      UserAvatar._cache[uid] = url;
      if (mounted) setState(() => _url = url);
    } catch (_) {
      UserAvatar._cache[uid] = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.name.trim();
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colors = UserAvatar.gradientFor(name.isNotEmpty ? name : (widget.uid ?? ''));
    final hasPhoto = _url != null && _url!.isNotEmpty;

    final placeholder = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: widget.size * 0.4,
        ),
      ),
    );

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              _url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            )
          : placeholder,
    );
  }
}
