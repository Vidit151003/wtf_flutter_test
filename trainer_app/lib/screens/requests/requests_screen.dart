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
          : requests.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.check_circle_outline,
                  title: 'No Pending Requests',
                  subtitle: 'All caught up! No call requests at the moment.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (ctx, i) {
                    final request = requests[i];
                    return _RequestTile(
                      request: request,
                      delay: i * 80,
                    );
                  },
                ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final CallRequestModel request;
  final int delay;

  const _RequestTile({required this.request, this.delay = 0});

  Color get _statusColor {
    switch (request.status) {
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

  String get _statusLabel {
    switch (request.status) {
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
            // Header row
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
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            // Note preview
            if (request.note.isNotEmpty) ...[
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
            // Action buttons for pending
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
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
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
