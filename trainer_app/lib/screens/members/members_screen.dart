import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../../providers/members_provider.dart';
import '../../providers/session_provider.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final membersProvider = context.watch<MembersProvider>();
    final sessionProvider = context.watch<TrainerSessionProvider>();
    final members = membersProvider.members;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Members'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: members.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.group_off,
              title: 'No Members Yet',
              subtitle: 'Your assigned members will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              itemBuilder: (ctx, i) {
                final member = members[i];
                final memberLogs = sessionProvider.logsForMember(member.id);
                final lastSession = memberLogs.isNotEmpty
                    ? 'Last session: ${memberLogs.first.startedAt.toRelative()}'
                    : 'No sessions yet';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: kTrainerNeutral100),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: AppAvatar(
                      name: member.name,
                      url: member.avatarUrl,
                      size: 48,
                      borderColor: kTrainerPrimary,
                    ),
                    title: Text(
                      member.name,
                      style:
                          Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: kTrainerNeutral900,
                              ),
                    ),
                    subtitle: Text(
                      lastSession,
                      style: Theme.of(ctx)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: kTrainerNeutral500),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: kTrainerNeutral300,
                    ),
                    onTap: () => context.push('/members/${member.id}'),
                  ),
                )
                    .animate()
                    .fadeIn(
                        delay: Duration(milliseconds: i * 80),
                        duration: 400.ms)
                    .slideX(begin: -0.05, end: 0);
              },
            ),
    );
  }
}
