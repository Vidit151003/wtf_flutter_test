import 'dart:async';

import 'package:hive/hive.dart';

import '../models/call_request_model.dart';
import '../models/room_meta_model.dart';
import '../utils/app_logger.dart';

// ─── Abstract interface ───────────────────────────────────────────────────────

abstract class CallService {
  /// Persists a new call [request].
  Future<void> createCallRequest(CallRequestModel request);

  /// Returns a stream of call requests for the given [trainerId].
  Stream<List<CallRequestModel>> watchRequests(String trainerId);

  /// Approves the request identified by [requestId] and saves [roomMeta].
  Future<void> approveRequest(String requestId, RoomMetaModel roomMeta);

  /// Declines the request identified by [requestId] with an optional [reason].
  Future<void> declineRequest(String requestId, String reason);

  /// Returns true if the given [slot] is already taken for [trainerId]
  /// (i.e. an approved request exists within ±30 minutes of [slot]).
  Future<bool> isSlotTaken(String trainerId, DateTime slot);
}

// ─── Mock implementation ──────────────────────────────────────────────────────

class MockCallService implements CallService {
  static const String _requestsBox = 'call_requests_box';
  static const String _roomsBox = 'rooms_box';

  final Map<String, StreamController<List<CallRequestModel>>>
      _controllers = {};

  // ─── createCallRequest ────────────────────────────────────────────────────

  @override
  Future<void> createCallRequest(CallRequestModel request) async {
    AppLogger.write(
        LogTag.schedule, 'createCallRequest: id=${request.id}');
    try {
      final box = Hive.box<CallRequestModel>(_requestsBox);
      await box.put(request.id, request);
    } catch (e) {
      AppLogger.write(LogTag.schedule, 'createCallRequest error: $e');
    }
    _emit(request.trainerId);
  }

  // ─── watchRequests ────────────────────────────────────────────────────────

  @override
  Stream<List<CallRequestModel>> watchRequests(String trainerId) {
    AppLogger.write(LogTag.schedule, 'watchRequests: trainerId=$trainerId');
    final controller = _controllers.putIfAbsent(
      trainerId,
      () => StreamController<List<CallRequestModel>>.broadcast(),
    );
    _emit(trainerId, controller: controller);
    return controller.stream;
  }

  // ─── approveRequest ───────────────────────────────────────────────────────

  @override
  Future<void> approveRequest(
      String requestId, RoomMetaModel roomMeta) async {
    AppLogger.write(
        LogTag.schedule, 'approveRequest: requestId=$requestId');
    try {
      final reqBox = Hive.box<CallRequestModel>(_requestsBox);
      final existing = reqBox.get(requestId);
      if (existing != null) {
        final updated =
            existing.copyWith(status: CallStatus.approved);
        await reqBox.put(requestId, updated);
        _emit(existing.trainerId);
      }
      final roomBox = Hive.box<RoomMetaModel>(_roomsBox);
      await roomBox.put(roomMeta.id, roomMeta);
    } catch (e) {
      AppLogger.write(LogTag.schedule, 'approveRequest error: $e');
    }
  }

  // ─── declineRequest ───────────────────────────────────────────────────────

  @override
  Future<void> declineRequest(String requestId, String reason) async {
    AppLogger.write(
        LogTag.schedule,
        'declineRequest: requestId=$requestId reason=$reason');
    try {
      final box = Hive.box<CallRequestModel>(_requestsBox);
      final existing = box.get(requestId);
      if (existing != null) {
        await box.put(
            requestId, existing.copyWith(status: CallStatus.declined));
        _emit(existing.trainerId);
      }
    } catch (e) {
      AppLogger.write(LogTag.schedule, 'declineRequest error: $e');
    }
  }

  // ─── isSlotTaken ──────────────────────────────────────────────────────────

  @override
  Future<bool> isSlotTaken(String trainerId, DateTime slot) async {
    AppLogger.write(
        LogTag.schedule, 'isSlotTaken: trainerId=$trainerId slot=$slot');
    try {
      final box = Hive.box<CallRequestModel>(_requestsBox);
      const window = Duration(minutes: 30);
      return box.values.any((r) =>
          r.trainerId == trainerId &&
          r.status == CallStatus.approved &&
          r.scheduledFor.difference(slot).abs() < window);
    } catch (e) {
      AppLogger.write(LogTag.schedule, 'isSlotTaken error: $e');
      return false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _emit(
    String trainerId, {
    StreamController<List<CallRequestModel>>? controller,
  }) {
    final ctrl = controller ?? _controllers[trainerId];
    if (ctrl == null || ctrl.isClosed) return;
    try {
      final box = Hive.box<CallRequestModel>(_requestsBox);
      final requests = box.values
          .where((r) => r.trainerId == trainerId)
          .toList()
        ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      ctrl.add(requests);
    } catch (_) {
      ctrl.add([]);
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
