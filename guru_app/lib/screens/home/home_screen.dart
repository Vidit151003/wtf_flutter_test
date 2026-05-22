import 'dart:async';

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
            padding: const EdgeInsets.only(right: kSpacing16),
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
              const SizedBox(height: kSpacing20),

              // ── Instant Call Button ──────────────────────────────────────
              _InstantCallButton(),
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
                onTap: () => context.push('/chat'),
              ),
              const SizedBox(height: kSpacing12),
              _FeatureCard(
                icon: Icons.calendar_today_rounded,
                title: 'Schedule a Call',
                subtitle: 'Pick a time that works for you',
                gradientColors: const [Color(0xFF6D5E78), Color(0xFF4A3F52)],
                onTap: () => context.push('/schedule'),
              ),
              const SizedBox(height: kSpacing12),
              _FeatureCard(
                icon: Icons.history_rounded,
                title: 'My Sessions',
                subtitle: 'View past sessions and logs',
                gradientColors: const [Color(0xFF12B76A), Color(0xFF0D8A4F)],
                onTap: () => context.push('/sessions'),
              ),
              const SizedBox(height: kSpacing24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Instant Call Button ──────────────────────────────────────────────────────

class _InstantCallButton extends StatefulWidget {
  @override
  State<_InstantCallButton> createState() => _InstantCallButtonState();
}

class _InstantCallButtonState extends State<_InstantCallButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTap(BuildContext context) async {
    final scheduleProvider =
        context.read<ScheduleProvider>();

    final requestId = await scheduleProvider.instantCall();
    if (!context.mounted) return;

    if (requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scheduleProvider.errorMessage ?? 'Failed to start call'),
          backgroundColor: kColorError,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show waiting dialog
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InstantCallWaitingDialog(requestId: requestId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) => Transform.scale(
        scale: _pulseAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: scheduleProvider.isLoading ? null : () => _onTap(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4D4D), Color(0xFFD62B2B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D4D).withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: scheduleProvider.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.videocam_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Instant Call',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Request a live session right now',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white70, size: 16),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Waiting Dialog ───────────────────────────────────────────────────────────

class _InstantCallWaitingDialog extends StatefulWidget {
  final String requestId;
  const _InstantCallWaitingDialog({required this.requestId});

  @override
  State<_InstantCallWaitingDialog> createState() =>
      _InstantCallWaitingDialogState();
}

class _InstantCallWaitingDialogState extends State<_InstantCallWaitingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveCtrl;
  StreamSubscription<CallRequestModel?>? _sub;
  String _statusText = 'Waiting for trainer to accept…';
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _watch());
  }

  void _watch() {
    final scheduleProvider =
        context.read<ScheduleProvider>();
    _sub = scheduleProvider.watchRequest(widget.requestId).listen((req) {
      if (req == null || _dismissed) return;

      if (req.status == CallStatus.approved) {
        _dismissed = true;
        _sub?.cancel();
        if (mounted) {
          Navigator.of(context).pop();
          // Navigate to pre-join screen
          context.push('/call/pre-join');
        }
      } else if (req.status == CallStatus.declined) {
        _dismissed = true;
        _sub?.cancel();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trainer declined the call request.'),
              backgroundColor: kColorError,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  Future<void> _cancel() async {
    _dismissed = true;
    _sub?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing rings + icon
            AnimatedBuilder(
              animation: _waveCtrl,
              builder: (context, child) {
                return SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      Opacity(
                        opacity: (1.0 - _waveCtrl.value).clamp(0.0, 0.6),
                        child: Transform.scale(
                          scale: 0.6 + _waveCtrl.value * 0.8,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFF4D4D)
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                      ),
                      // Middle ring
                      Opacity(
                        opacity:
                            (1.0 - ((_waveCtrl.value + 0.4) % 1.0))
                                .clamp(0.0, 0.7),
                        child: Transform.scale(
                          scale: 0.4 +
                              ((_waveCtrl.value + 0.4) % 1.0) * 0.6,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFF4D4D)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                      // Core circle
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF4D4D), Color(0xFFD62B2B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.videocam_rounded,
                            color: Colors.white, size: 34),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Calling Trainer…',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 28),
            TextButton(
              onPressed: _cancel,
              style: TextButton.styleFrom(
                foregroundColor: kColorError,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: kColorError.withValues(alpha: 0.4)),
                ),
              ),
              child: const Text(
                'Cancel Request',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Welcome Card ─────────────────────────────────────────────────────────────

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

// ─── Pending Call Banner ──────────────────────────────────────────────────────

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
          const Icon(Icons.access_time_rounded, color: kGuruPrimary, size: 20),
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

// ─── Feature Card ─────────────────────────────────────────────────────────────

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
