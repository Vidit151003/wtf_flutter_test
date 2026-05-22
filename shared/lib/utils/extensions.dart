import 'package:intl/intl.dart';

// ─── DateTime Extensions ──────────────────────────────────────────────────────

extension DateTimeRelative on DateTime {
  /// Returns a human-readable relative string:
  /// - '5m ago', '2h ago' for recent times
  /// - 'Yesterday' for times within the previous calendar day
  /// - A formatted date string ('dd MMM yyyy') for older dates
  String toRelative() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      // Check if the date falls on "yesterday" relative to today.
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final thisDay = DateTime(year, month, day);
      if (thisDay == yesterday) {
        return 'Yesterday';
      }
      return DateFormat('dd MMM yyyy').format(this);
    }
  }

  /// Returns a time-slot label, e.g. '6:00 PM'.
  String toSlotLabel() => DateFormat('h:mm a').format(this);
}

// ─── String Extensions ────────────────────────────────────────────────────────

extension StringInitials on String {
  /// Converts a full name to its initials: 'Dhruv Kumar' → 'DK'.
  /// Falls back to the first character of the string if only one word exists.
  String toInitials() {
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || trim().isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.isNotEmpty
          ? parts.first[0].toUpperCase()
          : '';
    }
    final first = parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '';
    final last = parts.last.isNotEmpty ? parts.last[0].toUpperCase() : '';
    return '$first$last';
  }
}

// ─── int Extensions ───────────────────────────────────────────────────────────

extension IntDuration on int {
  /// Formats seconds into MM:SS notation: 2700 → '45:00', 0 → '00:00'.
  String toFormattedDuration() {
    if (this <= 0) return '00:00';
    final minutes = this ~/ 60;
    final seconds = this % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
