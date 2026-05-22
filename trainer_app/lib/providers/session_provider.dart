import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

class TrainerSessionProvider extends ChangeNotifier {
  final LogService _logService;
  static const String _trainerId = 'trainer_001';

  List<SessionLogModel> _logs = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<SessionLogModel>>? _logsSub;

  TrainerSessionProvider(this._logService) {
    _init();
  }

  List<SessionLogModel> get logs => List.unmodifiable(_logs);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<SessionLogModel> logsForMember(String memberId) =>
      _logs.where((l) => l.memberId == memberId).toList();

  void _init() {
    AppLogger.write(LogTag.rtc, 'TrainerSessionProvider init: trainer=$_trainerId');
    _logsSub = _logService.watchLogs(_trainerId, UserRole.trainer).listen(
      (logs) {
        _logs = logs;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> addNotes(String logId, String notes) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _logService.updateLog(logId, trainerNotes: notes);
      AppLogger.write(LogTag.rtc, 'Notes added for log: $logId');
    } catch (e) {
      _error = e.toString();
      AppLogger.write(LogTag.rtc, 'addNotes error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markComplete(String logId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _logService.updateLog(
        logId,
        trainerNotes: _logs
            .firstWhere((l) => l.id == logId,
                orElse: () => SessionLogModel(
                      id: logId,
                      memberId: '',
                      trainerId: _trainerId,
                      startedAt: DateTime.now(),
                      endedAt: DateTime.now(),
                      durationSec: 0,
                    ))
            .trainerNotes,
      );
      AppLogger.write(LogTag.rtc, 'Session marked complete: $logId');
    } catch (e) {
      _error = e.toString();
      AppLogger.write(LogTag.rtc, 'markComplete error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveLog(SessionLogModel log) async {
    try {
      await _logService.saveLog(log);
      AppLogger.write(LogTag.rtc, 'Trainer saveLog: ${log.id}');
    } catch (e) {
      _error = e.toString();
      AppLogger.write(LogTag.rtc, 'saveLog error: $e');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _logsSub?.cancel();
    super.dispose();
  }
}
