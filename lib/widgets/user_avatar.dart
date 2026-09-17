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
    final letter = widget.name.trim().isNotEmpty ? widget.name.trim()[0].toUpperCase() : '?';
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: (_url == null || _url!.isEmpty)
          ? Center(
              child: Text(
                letter,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: widget.size * 0.35,
                ),
              ),
            )
          : Image.network(
              _url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: widget.size * 0.35,
                  ),
                ),
              ),
            ),
    );
  }
}
