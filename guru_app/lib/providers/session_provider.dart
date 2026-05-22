import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

enum SessionFilter { all, last7Days, thisMonth }

class SessionProvider extends ChangeNotifier {
  final LogService _logService;
  final AuthService _authService;

  List<SessionLogModel> _logs = [];
  SessionFilter _filter = SessionFilter.all;
  bool _isLoading = true;

  StreamSubscription<List<SessionLogModel>>? _logsSub;

  List<SessionLogModel> get logs => List.unmodifiable(_logs);
  SessionFilter get filter => _filter;
  bool get isLoading => _isLoading;

  List<SessionLogModel> get filteredLogs {
    final now = DateTime.now();
    switch (_filter) {
      case SessionFilter.all:
        return _logs;
      case SessionFilter.last7Days:
        final cutoff = now.subtract(const Duration(days: 7));
        return _logs.where((l) => l.startedAt.isAfter(cutoff)).toList();
      case SessionFilter.thisMonth:
        return _logs
            .where((l) =>
                l.startedAt.year == now.year &&
                l.startedAt.month == now.month)
            .toList();
    }
  }

  SessionProvider(this._logService, this._authService) {
    _init();
  }

  void _init() {
    final user = _authService.currentUser;
    if (user == null) {
      _isLoading = false;
      return;
    }
    _logsSub = _logService.watchLogs(user.id, user.role).listen((logs) {
      _logs = logs;
      _isLoading = false;
      notifyListeners();
    });
    AppLogger.write(LogTag.rtc, 'SessionProvider init: watching ${user.id}');
  }

  void setFilter(SessionFilter f) {
    _filter = f;
    notifyListeners();
    AppLogger.write(LogTag.rtc, 'setFilter: ${f.name}');
  }

  Future<void> submitRating(
      String logId, int rating, String? note) async {
    AppLogger.write(LogTag.rtc,
        'submitRating: logId=$logId rating=$rating');
    await _logService.updateLog(
      logId,
      rating: rating,
      memberNotes: note,
    );
  }

  @override
  void dispose() {
    _logsSub?.cancel();
    super.dispose();
  }
}
