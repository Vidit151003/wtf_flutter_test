import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Watches a single request by [requestId] for real-time status changes.
  Stream<CallRequestModel?> watchRequest(String requestId);
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

  // ─── watchRequest ─────────────────────────────────────────────────────────

  @override
  Stream<CallRequestModel?> watchRequest(String requestId) async* {
    try {
      final box = Hive.box<CallRequestModel>(_requestsBox);
      yield box.get(requestId);
      // Poll every second for mock (no real-time in Hive)
      while (true) {
        await Future.delayed(const Duration(seconds: 1));
        final req = box.get(requestId);
        yield req;
        if (req != null &&
            (req.status == CallStatus.approved ||
                req.status == CallStatus.declined ||
                req.status == CallStatus.cancelled)) {
          break;
        }
      }
    } catch (_) {
      yield null;
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

class FirebaseCallService implements CallService {
  FirebaseCallService({FirebaseFirestore? firestore}) : _firestore = firestore;

  static const String _requestsBox = 'call_requests_box';
  static const String _roomsBox = 'rooms_box';

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createCallRequest(CallRequestModel request) async {
    AppLogger.write(LogTag.schedule, 'createCallRequest(firebase): ${request.id}');
    await _cacheRequest(request);
    try {
      await _db
          .collection('callRequests')
          .doc(request.id)
          .set(request.toJson());
    } catch (e) {
      AppLogger.write(LogTag.schedule, 'createCallRequest(firebase) offline: $e');
    }
  }

  @override
  Stream<List<CallRequestModel>> watchRequests(String trainerId) async* {
    AppLogger.write(
      LogTag.schedule,
      'watchRequests(firebase): trainerId=$trainerId',
    );
    yield _cachedRequests(trainerId);

    try {
      final query = _db
          .collection('callRequests')
          .where('trainerId', isEqualTo: trainerId);

      await for (final snapshot in query.snapshots()) {
        final requests = snapshot.docs
            .map((doc) => CallRequestModel.fromJson(doc.data()))
            .toList()
          ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
        await _cacheRequests(requests);
        yield requests;
      }
    } catch (e) {
      AppLogger.write(
        LogTag.schedule,
        'watchRequests(firebase) error; using cache: $e',
      );
      yield _cachedRequests(trainerId);
    }
  }

  @override
  Future<void> approveRequest(String requestId, RoomMetaModel roomMeta) async {
    AppLogger.write(
      LogTag.schedule,
      'approveRequest(firebase): requestId=$requestId room=${roomMeta.hmsRoomId}',
    );
    final existing = _requestById(requestId);
    if (existing != null) {
      await _cacheRequest(existing.copyWith(status: CallStatus.approved));
    }
    await _cacheRoom(roomMeta);

    try {
      await _db.collection('callRequests').doc(requestId).update({
        'status': CallStatus.approved.name,
      });
      await _db.collection('rooms').doc(roomMeta.id).set(roomMeta.toJson());
    } catch (e) {
      AppLogger.write(LogTag.schedule, 'approveRequest(firebase) offline: $e');
    }
  }

  @override
  Future<void> declineRequest(String requestId, String reason) async {
    AppLogger.write(
      LogTag.schedule,
      'declineRequest(firebase): requestId=$requestId',
    );
    final existing = _requestById(requestId);
    if (existing != null) {
      await _cacheRequest(existing.copyWith(status: CallStatus.declined));
    }

    try {
      await _db.collection('callRequests').doc(requestId).update({
        'status': CallStatus.declined.name,
        'declineReason': reason,
      });
    } catch (e) {
      AppLogger.write(LogTag.schedule, 'declineRequest(firebase) offline: $e');
    }
  }

  @override
  Future<bool> isSlotTaken(String trainerId, DateTime slot) async {
    AppLogger.write(
      LogTag.schedule,
      'isSlotTaken(firebase): trainerId=$trainerId slot=$slot',
    );
    const window = Duration(minutes: 30);
    final cachedTaken = _cachedRequests(trainerId).any((request) =>
        request.status == CallStatus.approved &&
        request.scheduledFor.difference(slot).abs() < window);
    if (cachedTaken) return true;

    try {
      final snapshot = await _db
          .collection('callRequests')
          .where('trainerId', isEqualTo: trainerId)
          .where('status', isEqualTo: CallStatus.approved.name)
          .get();
      return snapshot.docs
          .map((doc) => CallRequestModel.fromJson(doc.data()))
          .any((request) => request.scheduledFor.difference(slot).abs() < window);
    } catch (e) {
      AppLogger.write(LogTag.schedule, 'isSlotTaken(firebase) offline: $e');
      return false;
    }
  }

  @override
  Stream<CallRequestModel?> watchRequest(String requestId) async* {
    yield _requestById(requestId);
    try {
      await for (final snapshot in _db
          .collection('callRequests')
          .doc(requestId)
          .snapshots()) {
        if (!snapshot.exists || snapshot.data() == null) {
          yield null;
        } else {
          final req = CallRequestModel.fromJson(snapshot.data()!);
          await _cacheRequest(req);
          yield req;
        }
      }
    } catch (e) {
      AppLogger.write(LogTag.schedule, 'watchRequest(firebase) error: $e');
      yield _requestById(requestId);
    }
  }

  CallRequestModel? _requestById(String requestId) {
    try {
      return Hive.box<CallRequestModel>(_requestsBox).get(requestId);
    } catch (_) {
      return null;
    }
  }

  List<CallRequestModel> _cachedRequests(String trainerId) {
    try {
      final requests = Hive.box<CallRequestModel>(_requestsBox)
          .values
          .where((request) => request.trainerId == trainerId)
          .toList()
        ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return requests;
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheRequests(List<CallRequestModel> requests) async {
    for (final request in requests) {
      await _cacheRequest(request);
    }
  }

  Future<void> _cacheRequest(CallRequestModel request) async {
    try {
      await Hive.box<CallRequestModel>(_requestsBox).put(request.id, request);
    } catch (_) {}
  }

  Future<void> _cacheRoom(RoomMetaModel roomMeta) async {
    try {
      await Hive.box<RoomMetaModel>(_roomsBox).put(roomMeta.id, roomMeta);
    } catch (_) {}
  }
}
