import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_theme.dart';
import '../../models/app_status.dart';
import '../../models/app_channel.dart';
import '../create_status_screen.dart';
import '../status_viewer_screen.dart';
import '../channel_screen.dart';
import '../discover_channels_screen.dart';

class StatusTab extends StatelessWidget {
  const StatusTab({super.key});

  List<AppStatus> _activeItems(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map(AppStatus.fromDoc).where((s) => !s.isExpired).toList()
      ..sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('statuses')
              .doc(currentUid)
              .collection('items')
              .orderBy('createdAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            final myItems = snapshot.hasData ? _activeItems(snapshot.data!) : <AppStatus>[];
            final hasStatus = myItems.isNotEmpty;
            return GestureDetector(
              onTap: () {
                if (hasStatus) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => StatusViewerScreen(statuses: myItems, isOwn: true)));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateStatusScreen()));
                }
              },
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: hasStatus ? AppColors.neonGradient : null,
                          color: hasStatus ? null : AppColors.surface,
                          border: hasStatus ? null : Border.all(color: AppColors.glassBorder),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.background),
                          child: const Icon(LucideIcons.user, color: AppColors.textSecondary, size: 24),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.neonGradient),
                          child: const Icon(LucideIcons.plus, color: AppColors.background, size: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Тарихи ман', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(
                          hasStatus ? '${myItems.length} навсозӣ · барои дидан зер кунед' : 'Барои иловаи навсозӣ зер кунед',
                          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        Text(
          'НАВСОЗИҲОИ ОХИРИН',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.6),
            fontSize: 11.5,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('statuses').orderBy('updatedAt', descending: true).limit(50).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Хатои боркунӣ: ${snapshot.error}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(color: AppColors.neonEmerald)),
              );
            }
            final owners = snapshot.data!.docs.where((d) => d.id != currentUid).toList();
            if (owners.isEmpty) {
              return Text(
                'Навсозиҳои дӯстони шумо дар ин ҷо намоён мешаванд',
                style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 12.5),
              );
            }
            return Column(
              children: owners.map((doc) => _OtherStatusRow(ownerId: doc.id, currentUid: currentUid)).toList(),
            );
          },
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'КАНАЛҲО',
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 11.5, letterSpacing: 1.2, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscoverChannelsScreen())),
              child: const Text('Кашф кардан', style: TextStyle(color: AppColors.neonEmerald, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('channels').where('followers', arrayContains: currentUid).limit(50).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final channels = snapshot.data!.docs.map(AppChannel.fromDoc).toList();
            if (channels.isEmpty) {
              return Text(
                'Шумо ба ягон канал обуна нашудаед',
                style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 12.5),
              );
            }
            return Column(
              children: channels.map((channel) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChannelScreen(channelId: channel.id))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: AppColors.glassBorder)),
                            child: const Icon(LucideIcons.hash, color: AppColors.textSecondary, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(channel.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                                Text(
                                  channel.lastMessage.isEmpty ? '${channel.followers.length} обунашуда' : channel.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _OtherStatusRow extends StatelessWidget {
  final String ownerId;
  final String currentUid;
  const _OtherStatusRow({required this.ownerId, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('statuses')
          .doc(ownerId)
          .collection('items')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final items = snapshot.data!.docs.map(AppStatus.fromDoc).where((s) => !s.isExpired).toList();
        if (items.isEmpty) return const SizedBox.shrink();
        final ownerName = items.first.ownerName;
        final hasUnseen = items.any((s) => !s.viewedBy.contains(currentUid));
        final latest = items.last;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StatusViewerScreen(statuses: items))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: hasUnseen ? AppColors.neonGradient : null,
                      color: hasUnseen ? null : AppColors.glassBorder,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.background),
                      child: Center(
                        child: Text(
                          ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 17),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ownerName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(
                          '${items.length} навсозӣ',
                          style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    latest.createdAt == null
                        ? ''
                        : '${latest.createdAt!.hour.toString().padLeft(2, '0')}:${latest.createdAt!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
