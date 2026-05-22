import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../../providers/auth_provider.dart';
import '../../providers/members_provider.dart';
import '../../providers/requests_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<TrainerAuthProvider>();
    final membersProvider = context.watch<MembersProvider>();
    final requestsProvider = context.watch<RequestsProvider>();

    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: kTrainerBackground,
      appBar: AppBar(
        backgroundColor: kTrainerBackground,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Trainer Portal'),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kTrainerPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Trainer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showProfileMenu(context, authProvider),
              child: AppAvatar(
                name: user?.name ?? 'Aarav',
                url: user?.avatarUrl,
                size: 38,
                borderColor: kTrainerPrimary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'Hello, ${user?.name ?? 'Aarav'} 👋',
                style:
                    Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: kTrainerNeutral900,
                        ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 4),
              Text(
                'Your coaching dashboard',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: kTrainerNeutral500),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 32),
              // Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _FeatureTile(
                      icon: Icons.group,
                      label: 'Members',
                      badge: membersProvider.memberCount,
                      badgeColor: kTrainerPrimary,
                      onTap: () => context.push('/members'),
                      delay: 0,
                    ),
                    _FeatureTile(
                      icon: Icons.chat_bubble_outline,
                      label: 'Chats',
                      onTap: () => context.push('/chat/chat_dk_aarav'),
                      delay: 100,
                    ),
                    _FeatureTile(
                      icon: Icons.notifications_outlined,
                      label: 'Requests',
                      badge: requestsProvider.pendingCount,
                      badgeColor: requestsProvider.hasInstantPending
                          ? kColorError
                          : kColorWarning,
                      onTap: () => context.push('/requests'),
                      delay: 200,
                    ),
                    _FeatureTile(
                      icon: Icons.history,
                      label: 'Sessions',
                      onTap: () => context.push('/sessions'),
                      delay: 300,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileMenu(
      BuildContext context, TrainerAuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAvatar(
              name: authProvider.currentUser?.name ?? 'Aarav',
              size: 64,
              borderColor: kTrainerPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              authProvider.currentUser?.name ?? 'Aarav',
              style: Theme.of(ctx)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              authProvider.currentUser?.email ?? 'aarav@wtf.com',
              style: Theme.of(ctx)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: kTrainerNeutral500),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await authProvider.logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kColorError,
                side: const BorderSide(color: kColorError),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? badge;
  final Color? badgeColor;
  final VoidCallback onTap;
  final int delay;

  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: kTrainerNeutral100),
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: kTrainerPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: kTrainerPrimary,
                      size: 26,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: kTrainerNeutral900,
                            ),
                  ),
                ],
              ),
            ),
            // Badge
            if (badge != null && badge! > 0)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor ?? kTrainerPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
          .slideY(begin: 0.1, end: 0),
    );
  }
}
