import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../../providers/requests_provider.dart';
import 'decline_reason_modal.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestsProvider = context.watch<RequestsProvider>();
    final requests = requestsProvider.allRequests;

    // Sort: instant pending first, then by date desc
    final sorted = [...requests]..sort((a, b) {
        final aFirst = a.isInstant && a.status == CallStatus.pending ? 0 : 1;
        final bFirst = b.isInstant && b.status == CallStatus.pending ? 0 : 1;
        if (aFirst != bFirst) return aFirst - bFirst;
        return b.requestedAt.compareTo(a.requestedAt);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: requestsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : sorted.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.check_circle_outline,
                  title: 'No Pending Requests',
                  subtitle: 'All caught up! No call requests at the moment.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  itemBuilder: (ctx, i) {
                    final request = sorted[i];
                    return request.isInstant
                        ? _InstantRequestTile(request: request, delay: i * 80)
                        : _RequestTile(request: request, delay: i * 80);
                  },
                ),
    );
  }
}

// ─── Instant Request Tile ─────────────────────────────────────────────────────

class _InstantRequestTile extends StatefulWidget {
  final CallRequestModel request;
  final int delay;
  const _InstantRequestTile({required this.request, this.delay = 0});

  @override
  State<_InstantRequestTile> createState() => _InstantRequestTileState();
}

class _InstantRequestTileState extends State<_InstantRequestTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.request.status == CallStatus.pending) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestsProvider = context.read<RequestsProvider>();
    final isPending = widget.request.status == CallStatus.pending;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final glowOpacity = isPending ? 0.25 + _pulseCtrl.value * 0.35 : 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D4D).withOpacity(glowOpacity),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: widget.request.status == CallStatus.pending
                ? const Color(0xFFFF4D4D)
                : kTrainerNeutral100,
            width: widget.request.status == CallStatus.pending ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: INSTANT badge + member + time
              Row(
                children: [
                  // Live badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D4D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        )
                            .animate(
                              onPlay: (ctrl) => ctrl.repeat(reverse: true),
                            )
                            .scaleXY(
                              begin: 0.6,
                              end: 1.0,
                              duration: 600.ms,
                              curve: Curves.easeInOut,
                            ),
                        const SizedBox(width: 5),
                        const Text(
                          'INSTANT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Member: ${widget.request.memberId}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: kTrainerNeutral900,
                          ),
                    ),
                  ),
                  // Status chip
                  _StatusChip(status: widget.request.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Requesting a live call right now',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: kTrainerNeutral500,
                    ),
              ),
              if (widget.request.status == CallStatus.pending) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          showDeclineReasonModal(
                            context,
                            onConfirm: (reason) async {
                              await requestsProvider.decline(
                                  widget.request.id, reason);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Request declined.'),
                                    backgroundColor: kColorError,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kColorError,
                          side: const BorderSide(color: kColorError),
                          minimumSize: const Size(0, 44),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await requestsProvider.approve(widget.request.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Call accepted! Joining…'),
                                backgroundColor: kColorSuccess,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            context.push('/call/pre-join');
                          }
                        },
                        icon: const Icon(Icons.videocam_rounded, size: 18),
                        label: const Text('Accept & Join'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4D4D),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 44),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: widget.delay), duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

// ─── Regular Scheduled Request Tile ──────────────────────────────────────────

class _RequestTile extends StatelessWidget {
  final CallRequestModel request;
  final int delay;
  const _RequestTile({required this.request, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    final requestsProvider = context.read<RequestsProvider>();
    final formattedDate =
        DateFormat('dd MMM yyyy').format(request.scheduledFor);
    final formattedTime = DateFormat('h:mm a').format(request.scheduledFor);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: request.status == CallStatus.pending
              ? kColorWarning.withOpacity(0.4)
              : kTrainerNeutral100,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Member: ${request.memberId}',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: kTrainerNeutral900,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$formattedDate · $formattedTime',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: kTrainerNeutral500,
                                ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: request.status),
              ],
            ),
            if (request.note.isNotEmpty && request.note != 'Instant call request') ...[
              const SizedBox(height: 10),
              Text(
                request.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: kTrainerNeutral700),
              ),
            ],
            if (request.status == CallStatus.pending) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        showDeclineReasonModal(
                          context,
                          onConfirm: (reason) async {
                            await requestsProvider.decline(
                                request.id, reason);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Request declined.'),
                                  backgroundColor: kColorError,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kColorError,
                        side: const BorderSide(color: kColorError),
                        minimumSize: const Size(0, 40),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await requestsProvider.approve(request.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Request approved!'),
                              backgroundColor: kColorSuccess,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kColorSuccess,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        elevation: 0,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

// ─── Status Chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final CallStatus status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case CallStatus.pending:
        return kColorWarning;
      case CallStatus.approved:
        return kColorSuccess;
      case CallStatus.declined:
        return kColorError;
      case CallStatus.cancelled:
        return Colors.grey;
    }
  }

  String get _label {
    switch (status) {
      case CallStatus.pending:
        return 'Pending';
      case CallStatus.approved:
        return 'Approved';
      case CallStatus.declined:
        return 'Declined';
      case CallStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
