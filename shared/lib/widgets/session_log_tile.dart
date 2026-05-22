import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session_log_model.dart';
import '../utils/extensions.dart';

/// Compact list tile for a [SessionLogModel] with a date badge, duration badge,
/// and star rating. Tapping opens a detail bottom sheet.
class SessionLogTile extends StatelessWidget {
  final SessionLogModel log;

  const SessionLogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showDetailSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Date badge ─────────────────────────────────────────────────
            _DateBadge(date: log.startedAt, colorScheme: colorScheme),
            const SizedBox(width: 12),

            // ── Duration ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.durationSec.toFormattedDuration(),
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    log.startedAt.toSlotLabel(),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),

            // ── Star rating ────────────────────────────────────────────────
            _StarRating(rating: log.rating, size: 16),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SessionDetailSheet(log: log),
    );
  }
}

// ─── Date badge ──────────────────────────────────────────────────────────────

class _DateBadge extends StatelessWidget {
  final DateTime date;
  final ColorScheme colorScheme;

  const _DateBadge({required this.date, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('dd').format(date),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colorScheme.onPrimaryContainer,
              height: 1,
            ),
          ),
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Star rating row ─────────────────────────────────────────────────────────

class _StarRating extends StatelessWidget {
  final int? rating;
  final double size;

  const _StarRating({this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    const maxStars = 5;
    final filled = (rating ?? 0).clamp(0, maxStars);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (i) {
        return Icon(
          i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: i < filled ? const Color(0xFFFACC15) : Colors.grey.shade300,
        );
      }),
    );
  }
}

// ─── Detail bottom sheet ─────────────────────────────────────────────────────

class _SessionDetailSheet extends StatelessWidget {
  final SessionLogModel log;

  const _SessionDetailSheet({required this.log});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Session Details',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              _DetailRow(
                label: 'Date',
                value: DateFormat('EEE, dd MMM yyyy').format(log.startedAt),
              ),
              _DetailRow(
                label: 'Time',
                value:
                    '${log.startedAt.toSlotLabel()} – ${log.endedAt.toSlotLabel()}',
              ),
              _DetailRow(
                label: 'Duration',
                value: log.durationSec.toFormattedDuration(),
              ),
              const SizedBox(height: 16),

              Text('Rating', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              _StarRating(rating: log.rating, size: 28),
              const SizedBox(height: 20),

              if (log.trainerNotes != null &&
                  log.trainerNotes!.isNotEmpty) ...[
                Text('Trainer Notes', style: textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(log.trainerNotes!, style: textTheme.bodyMedium),
                const SizedBox(height: 16),
              ],
              if (log.memberNotes != null &&
                  log.memberNotes!.isNotEmpty) ...[
                Text('My Notes', style: textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(log.memberNotes!, style: textTheme.bodyMedium),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
