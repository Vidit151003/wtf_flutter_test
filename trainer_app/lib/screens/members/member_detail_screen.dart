import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../../providers/members_provider.dart';
import '../../providers/session_provider.dart';

class MemberDetailScreen extends StatelessWidget {
  final String memberId;

  const MemberDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    final membersProvider = context.watch<MembersProvider>();
    final sessionProvider = context.watch<TrainerSessionProvider>();
    final member = membersProvider.getMember(memberId);

    if (member == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
        ),
        body: const EmptyStateWidget(
          icon: Icons.person_off,
          title: 'Member Not Found',
          subtitle: 'This member no longer exists.',
        ),
      );
    }

    final memberLogs = sessionProvider.logsForMember(memberId);

    return Scaffold(
      appBar: AppBar(
        title: Text(member.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Member header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: kTrainerNeutral100),
              ),
              child: Column(
                children: [
                  AppAvatar(
                    name: member.name,
                    url: member.avatarUrl,
                    size: 80,
                    borderColor: kTrainerPrimary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    member.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: kTrainerNeutral900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.email,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: kTrainerNeutral500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _InfoChip(
                        icon: Icons.fitness_center,
                        label: '${memberLogs.length} sessions',
                        color: kTrainerPrimary,
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.verified_user,
                        label: 'Active Member',
                        color: kColorSuccess,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Session History Section
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Session History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: kTrainerNeutral900,
                    ),
              ),
            ),
          ),
          // Session logs
          memberLogs.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: EmptyStateWidget(
                      icon: Icons.history_toggle_off,
                      title: 'No Sessions Yet',
                      subtitle:
                          'Sessions with this member will appear here.',
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SessionLogTile(
                          log: memberLogs[i],
                        ),
                      ),
                      childCount: memberLogs.length,
                    ),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
