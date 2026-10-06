import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/app_theme.dart';
import '../../models/app_group.dart';
import '../../models/app_community.dart';
import '../../models/app_channel.dart';
import '../../widgets/group_tile.dart';
import '../../widgets/community_tile.dart';
import '../../widgets/neon_backdrop.dart';
import '../../widgets/empty_state.dart';
import '../../utils/doc_sort.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_scope.dart';
import '../channel_screen.dart';

/// "Рӯйхатҳо" — ҳамаи гурӯҳ, ҳамҷомеъа ва каналҳое, ки корбар воқеан дар
/// онҳост, дар се varaq. Ҳамаш аз Firestore-и воқеӣ (ҳамон коллексияҳое, ки
/// ChatsTab/CommunitiesTab/DiscoverChannelsScreen истифода мебаранд) — ягон
/// рӯйхати нав сохта намешавад.
class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppScope.watch(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NeonBackdrop(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(LucideIcons.arrow_left, color: AppColors.textPrimary, size: 20),
                      ),
                      Text(
                        tr('k444'),
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.accent,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: [
                    Tab(text: tr('k453')),
                    Tab(text: tr('k454')),
                    Tab(text: tr('k455')),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _GroupsList(currentUid: currentUid),
                      _CommunitiesList(currentUid: currentUid),
                      _ChannelsList(currentUid: currentUid),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupsList extends StatelessWidget {
  final String currentUid;
  const _GroupsList({required this.currentUid});

  @override
  Widget build(BuildContext context) {
    if (currentUid.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('groups').where('members', arrayContains: currentUid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        final docs = sortByTimeDesc(snapshot.data!.docs, 'lastMessageTime');
        if (docs.isEmpty) {
          return EmptyState(icon: LucideIcons.users, title: tr('k456'));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          children: docs
              .map((doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: GroupTile(group: AppGroup.fromDoc(doc), currentUid: currentUid),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _CommunitiesList extends StatelessWidget {
  final String currentUid;
  const _CommunitiesList({required this.currentUid});

  @override
  Widget build(BuildContext context) {
    if (currentUid.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('communities').where('members', arrayContains: currentUid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        final docs = sortByTimeDesc(snapshot.data!.docs, 'lastMessageTime');
        if (docs.isEmpty) {
          return EmptyState(icon: LucideIcons.hash, title: tr('k202'), description: tr('k203'));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          children: docs
              .map((doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: CommunityTile(community: AppCommunity.fromDoc(doc), currentUid: currentUid),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _ChannelsList extends StatelessWidget {
  final String currentUid;
  const _ChannelsList({required this.currentUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('channels').where('followers', arrayContains: currentUid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        final channels = snapshot.data!.docs.map(AppChannel.fromDoc).toList();
        if (channels.isEmpty) {
          return EmptyState(icon: LucideIcons.hash, title: tr('k457'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: AppColors.glassBorder)),
                child: Icon(LucideIcons.hash, color: AppColors.textSecondary, size: 19),
              ),
              title: Text(channel.name, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14.5)),
              subtitle: Text(trf('k023', [channel.followers.length]), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChannelScreen(channelId: channel.id))),
            );
          },
        );
      },
    );
  }
}
