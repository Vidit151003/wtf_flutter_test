import 'dart:async';

import 'package:hive/hive.dart';

import '../models/session_log_model.dart';
import '../models/user_model.dart';
import '../utils/app_logger.dart';

// ─── Abstract interface ───────────────────────────────────────────────────────

abstract class LogService {
  /// Saves a new [log] entry.
  Future<void> saveLog(SessionLogModel log);

  /// Returns a stream of session logs filtered by [userId] and [role].
  /// For trainers, filters by trainerId; for members, filters by memberId.
  Stream<List<SessionLogModel>> watchLogs(String userId, UserRole role);

  /// Updates fields of the log with [logId].
  Future<void> updateLog(
    String logId, {
    int? rating,
    String? memberNotes,
    String? trainerNotes,
  });
}

// ─── Mock implementation ──────────────────────────────────────────────────────

class MockLogService implements LogService {
  static const String _boxName = 'session_logs_box';

  /// Key: userId, value: stream controller for that user's logs.
  final Map<String, StreamController<List<SessionLogModel>>> _controllers =
      {};

  // ─── saveLog ──────────────────────────────────────────────────────────────

  @override
  Future<void> saveLog(SessionLogModel log) async {
    AppLogger.write(LogTag.rtc, 'saveLog: id=${log.id}');
    try {
      final box = Hive.box<SessionLogModel>(_boxName);
      await box.put(log.id, log);
    } catch (e) {
      AppLogger.write(LogTag.rtc, 'saveLog error: $e');
    }
    _emitForLog(log);
  }

  // ─── watchLogs ────────────────────────────────────────────────────────────

  @override
  Stream<List<SessionLogModel>> watchLogs(
      String userId, UserRole role) {
    AppLogger.write(LogTag.rtc, 'watchLogs: userId=$userId role=${role.name}');
    final controller = _controllers.putIfAbsent(
      userId,
      () => StreamController<List<SessionLogModel>>.broadcast(),
    );
    _emit(userId, role, controller);
    return controller.stream;
  }

  // ─── updateLog ────────────────────────────────────────────────────────────

  @override
  Future<void> updateLog(
    String logId, {
    int? rating,
    String? memberNotes,
    String? trainerNotes,
  }) async {
    AppLogger.write(LogTag.rtc, 'updateLog: logId=$logId');
    try {
      final box = Hive.box<SessionLogModel>(_boxName);
      final existing = box.get(logId);
      if (existing == null) return;
      final updated = existing.copyWith(
        rating: rating,
        memberNotes: memberNotes,
        trainerNotes: trainerNotes,
      );
      await box.put(logId, updated);
      _emitForLog(updated);
    } catch (e) {
      AppLogger.write(LogTag.rtc, 'updateLog error: $e');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _emit(
    String userId,
    UserRole role,
    StreamController<List<SessionLogModel>> controller,
  ) {
    if (controller.isClosed) return;
    try {
      final box = Hive.box<SessionLogModel>(_boxName);
      final logs = box.values.where((l) {
        return role == UserRole.trainer
            ? l.trainerId == userId
            : l.memberId == userId;
      }).toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      controller.add(logs);
    } catch (_) {
      controller.add([]);
    }
  }

  void _emitForLog(SessionLogModel log) {
    // Emit for both trainer and member controllers if they exist.
    final trainerCtrl = _controllers[log.trainerId];
    if (trainerCtrl != null && !trainerCtrl.isClosed) {
      _emit(log.trainerId, UserRole.trainer, trainerCtrl);
    }
    final memberCtrl = _controllers[log.memberId];
    if (memberCtrl != null && !memberCtrl.isClosed) {
      _emit(log.memberId, UserRole.member, memberCtrl);
    }
  }

  /// Dispose stream controllers.
  Future<void> dispose() async {
    for (final c in _controllers.values) {
      await c.close();
    }
    _controllers.clear();
  }
}
