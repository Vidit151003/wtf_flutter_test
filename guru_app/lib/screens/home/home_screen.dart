import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../../providers/auth_provider.dart';
import '../../providers/schedule_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();
    final user = authProvider.currentUser;
    final hasPendingRequest = scheduleProvider.pendingRequests.isNotEmpty;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: kGuruBackground,
      appBar: AppBar(
        title: Text(
          'Hey, ${user?.name ?? 'there'} 👋',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: kGuruNeutral900,
          ),
        ),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(right: kSpacing16),
            child: AppAvatar(
              name: user?.name ?? 'DK',
              size: 36,
              borderColor: kGuruPrimary,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: kSpacing16, vertical: kSpacing8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending call banner
              if (hasPendingRequest) ...[
                _PendingCallBanner(),
                const SizedBox(height: kSpacing16),
              ],

              // Welcome card
              _WelcomeCard(userName: user?.name ?? 'DK'),
              const SizedBox(height: kSpacing24),

              Text(
                'Quick Actions',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: kGuruNeutral900,
                ),
              ),
              const SizedBox(height: kSpacing12),

              // Feature cards
              _FeatureCard(
                icon: Icons.chat_bubble_rounded,
                title: 'Chat with Trainer',
                subtitle: 'Send messages, share updates',
                gradientColors: const [Color(0xFF1769E0), Color(0xFF1257BC)],
                onTap: () => context.go('/chat'),
              ),
              const SizedBox(height: kSpacing12),
              _FeatureCard(
                icon: Icons.calendar_today_rounded,
                title: 'Schedule a Call',
                subtitle: 'Pick a time that works for you',
                gradientColors: const [Color(0xFF6D5E78), Color(0xFF4A3F52)],
                onTap: () => context.go('/schedule'),
              ),
              const SizedBox(height: kSpacing12),
              _FeatureCard(
                icon: Icons.history_rounded,
                title: 'My Sessions',
                subtitle: 'View past sessions and logs',
                gradientColors: const [Color(0xFF12B76A), Color(0xFF0D8A4F)],
                onTap: () => context.go('/sessions'),
              ),
              const SizedBox(height: kSpacing24),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String userName;

  const _WelcomeCard({required this.userName});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSpacing24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1769E0), Color(0xFF0D3B8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kGuruPrimary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $userName!',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: kSpacing8),
          Text(
            "Stay consistent — every session brings you closer to your goal.",
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: kSpacing16),
          Row(
            children: [
              Icon(Icons.fitness_center,
                  color: Colors.white.withValues(alpha: 0.9), size: 16),
              const SizedBox(width: 6),
              Text(
                'Trainer: Aarav',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingCallBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: kSpacing16, vertical: kSpacing12),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGuruPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              color: kGuruPrimary, size: 20),
          const SizedBox(width: kSpacing12),
          const Expanded(
            child: Text(
              'Call requested. Waiting for trainer approval.',
              style: TextStyle(
                color: kGuruPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(kSpacing20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: kSpacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: kSpacing4),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
