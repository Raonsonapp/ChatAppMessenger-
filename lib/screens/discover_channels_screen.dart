import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../models/app_channel.dart';
import '../widgets/neon_backdrop.dart';
import 'channel_screen.dart';
import 'create_channel_screen.dart';

/// Кашфи ҳамаи каналҳои воқеӣ (коллексияи `channels`), бо тугмаи обуна.
class DiscoverChannelsScreen extends StatelessWidget {
  const DiscoverChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                        ),
                        const Text('Кашфи каналҳо', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateChannelScreen())),
                      icon: const Icon(LucideIcons.plus, color: AppColors.neonEmerald, size: 22),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('channels').limit(100).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Хатои Firestore: ${snapshot.error}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.neonEmerald));
                    }
                    final channels = snapshot.data!.docs.map(AppChannel.fromDoc).toList();
                    if (channels.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Ягон канал ҳанӯз сохта нашудааст. Аввалин канали худро созед!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 13),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: channels.length,
                      itemBuilder: (context, index) {
                        final channel = channels[index];
                        final isFollowing = channel.followers.contains(currentUid);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: AppColors.glassBorder)),
                            child: const Icon(LucideIcons.hash, color: AppColors.textSecondary, size: 20),
                          ),
                          title: Text(channel.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                          subtitle: Text('${channel.followers.length} обунашуда', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          trailing: OutlinedButton(
                            onPressed: () => FirebaseFirestore.instance.collection('channels').doc(channel.id).update({
                              'followers': isFollowing ? FieldValue.arrayRemove([currentUid]) : FieldValue.arrayUnion([currentUid]),
                            }),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: isFollowing ? AppColors.glassBorder : AppColors.neonEmerald),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              isFollowing ? 'Обуна' : 'Обуна шудан',
                              style: TextStyle(color: isFollowing ? AppColors.textSecondary : AppColors.neonEmerald, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChannelScreen(channelId: channel.id))),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
