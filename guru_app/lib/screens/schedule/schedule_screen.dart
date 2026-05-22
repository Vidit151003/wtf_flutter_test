import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../../providers/auth_provider.dart';
import '../../providers/schedule_provider.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final TextEditingController _noteController = TextEditingController();
  late final List<DateTime> _availableDates;

  static const int _slotsStartHour = 8;
  static const int _slotsEndHour = 20;
  static const int _slotIntervalMinutes = 30;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _availableDates = List.generate(
        3,
        (i) => DateTime(now.year, now.month, now.day)
            .add(Duration(days: i)));

    // Select today by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().selectDate(_availableDates.first);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<DateTime> _slotsForDate(DateTime date) {
    final slots = <DateTime>[];
    var hour = _slotsStartHour;
    var minute = 0;
    while (hour < _slotsEndHour ||
        (hour == _slotsEndHour && minute == 0)) {
      slots.add(DateTime(date.year, date.month, date.day, hour, minute));
      minute += _slotIntervalMinutes;
      if (minute >= 60) {
        minute = 0;
        hour++;
      }
    }
    return slots;
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == tomorrow) return 'Tomorrow';
    return DateFormat('EEE').format(date);
  }

  Future<void> _requestCall() async {
    final scheduleProvider = context.read<ScheduleProvider>();
    final slot = scheduleProvider.selectedSlot;

    if (slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot.')),
      );
      return;
    }

    final note = _noteController.text.trim();

    await scheduleProvider.requestCall(slot: slot, note: note);

    if (!mounted) return;
    if (scheduleProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(scheduleProvider.errorMessage!)),
      );
      scheduleProvider.clearError();
    } else {
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Call requested. Waiting for trainer approval.'),
          backgroundColor: kColorSuccess,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final authProvider = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final selectedDate = scheduleProvider.selectedDate;
    final selectedSlot = scheduleProvider.selectedSlot;

    final slots = selectedDate != null ? _slotsForDate(selectedDate) : <DateTime>[];
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule a Call'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  kSpacing16, kSpacing16, kSpacing16, 0),
              sliver: SliverToBoxAdapter(
                child: Text('Choose a date',
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),

            // Date chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: kSpacing16, vertical: kSpacing8),
                  itemCount: _availableDates.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: kSpacing8),
                  itemBuilder: (_, i) {
                    final date = _availableDates[i];
                    final isSelected = selectedDate != null &&
                        DateTime(selectedDate.year, selectedDate.month,
                                selectedDate.day) ==
                            DateTime(date.year, date.month, date.day);
                    return GestureDetector(
                      onTap: () =>
                          scheduleProvider.selectDate(date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 80,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? kGuruPrimary
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isSelected
                                  ? kGuruPrimary
                                  : kGuruNeutral300),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: kGuruPrimary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              _dateLabel(date),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : kGuruNeutral500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('d').format(date),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : kGuruNeutral900,
                              ),
                            ),
                            Text(
                              DateFormat('MMM').format(date),
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : kGuruNeutral500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Time slots header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  kSpacing16, kSpacing16, kSpacing16, kSpacing8),
              sliver: SliverToBoxAdapter(
                child: Text('Choose a time slot',
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),

            // Slots grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: kSpacing16),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.2,
                  crossAxisSpacing: kSpacing8,
                  mainAxisSpacing: kSpacing8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final slot = slots[i];
                    final isPast = slot.isBefore(now);
                    final isSelected = selectedSlot != null &&
                        selectedSlot.isAtSameMomentAs(slot);
                    return GestureDetector(
                      onTap: isPast
                          ? null
                          : () =>
                              scheduleProvider.selectSlot(slot),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isPast
                              ? kGuruNeutral100
                              : isSelected
                                  ? kGuruPrimary
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isPast
                                ? kGuruNeutral300
                                : isSelected
                                    ? kGuruPrimary
                                    : kGuruNeutral300,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: kGuruPrimary
                                        .withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          slot.toSlotLabel(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isPast
                                ? kGuruNeutral500
                                : isSelected
                                    ? Colors.white
                                    : kGuruNeutral700,
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: slots.length,
                ),
              ),
            ),

            // Note field
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  kSpacing16, kSpacing24, kSpacing16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add a note',
                        style: textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: kSpacing8),
                    TextField(
                      controller: _noteController,
                      maxLength: 140,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'E.g. Focus on legs, need modifications...',
                        counterText: '${_noteController.text.length}/140',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),

            // Request button
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  kSpacing16, kSpacing16, kSpacing16, 0),
              sliver: SliverToBoxAdapter(
                child: ElevatedButton(
                  onPressed:
                      scheduleProvider.isLoading ? null : _requestCall,
                  child: scheduleProvider.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Request Call'),
                ),
              ),
            ),

            // My Requests section
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  kSpacing16, kSpacing24, kSpacing16, kSpacing8),
              sliver: SliverToBoxAdapter(
                child: Text('My Requests',
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),

            if (scheduleProvider.myRequests.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: kSpacing16, vertical: kSpacing16),
                  child: Text(
                    'No requests yet.',
                    style: TextStyle(color: kGuruNeutral500),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final req = scheduleProvider.myRequests[i];
                    return _RequestTile(request: req);
                  },
                  childCount: scheduleProvider.myRequests.length,
                ),
              ),

            const SliverPadding(
                padding: EdgeInsets.only(bottom: kSpacing32)),
          ],
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final CallRequestModel request;

  const _RequestTile({required this.request});

  Color _chipColor(CallStatus status) {
    switch (status) {
      case CallStatus.pending:
        return kColorWarning;
      case CallStatus.approved:
        return kColorSuccess;
      case CallStatus.declined:
        return kColorError;
      case CallStatus.cancelled:
        return kGuruNeutral500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chipColor = _chipColor(request.status);

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: kSpacing16, vertical: kSpacing4),
      padding: const EdgeInsets.all(kSpacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGuruNeutral300.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, dd MMM • h:mm a')
                      .format(request.scheduledFor),
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (request.note.isNotEmpty) ...[
                  const SizedBox(height: kSpacing4),
                  Text(
                    request.note,
                    style: textTheme.bodySmall
                        ?.copyWith(color: kGuruNeutral500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: kSpacing12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: kSpacing8, vertical: kSpacing4),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              request.status.name.toUpperCase(),
              style: TextStyle(
                color: chipColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
