import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';

enum CallState { idle, preJoin, inCall, postCall }

class TrainerCallProvider extends ChangeNotifier {
  final LogService _logService;

  final _uuid = const Uuid();

  CallState _callState = CallState.idle;
  RoomMetaModel? _roomMeta;
  bool _isMuted = false;
  bool _isCameraOff = false;
  DateTime? _callStartedAt;
  String? _error;

  TrainerCallProvider(this._logService);

  CallState get callState => _callState;
  RoomMetaModel? get roomMeta => _roomMeta;
  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  DateTime? get callStartedAt => _callStartedAt;
  String? get error => _error;
  bool get isInCall => _callState == CallState.inCall;

  /// Pre-join: set room metadata and transition to preJoin state.
  void prepareCall(RoomMetaModel meta) {
    _roomMeta = meta;
    _callState = CallState.preJoin;
    AppLogger.write(LogTag.rtc, 'Trainer prepareCall: room=${meta.hmsRoomId}');
    notifyListeners();
  }

  /// Join the call (stub — 100ms not integrated).
  Future<void> joinCall() async {
    AppLogger.write(
        LogTag.rtc, 'RTC: joinCall (STUB, requires 100ms credentials)');
    _callState = CallState.inCall;
    _callStartedAt = DateTime.now();
    notifyListeners();
  }

  /// Toggle microphone mute state.
  void toggleMute() {
    _isMuted = !_isMuted;
    AppLogger.write(LogTag.rtc, 'Trainer toggleMute: muted=$_isMuted');
    notifyListeners();
  }

  /// Toggle camera off state.
  void toggleCamera() {
    _isCameraOff = !_isCameraOff;
    AppLogger.write(LogTag.rtc, 'Trainer toggleCamera: off=$_isCameraOff');
    notifyListeners();
  }

  /// End call for this participant and save session log.
  Future<void> endCall({
    required String memberId,
    required String trainerId,
  }) async {
    AppLogger.write(LogTag.rtc, 'Trainer endCall');
    _callState = CallState.postCall;
    final now = DateTime.now();
    final started = _callStartedAt ?? now.subtract(const Duration(minutes: 1));
    final durationSec = now.difference(started).inSeconds;

    final log = SessionLogModel(
      id: _uuid.v4(),
      memberId: memberId,
      trainerId: trainerId,
      startedAt: started,
      endedAt: now,
      durationSec: durationSec,
    );

    try {
      await _logService.saveLog(log);
      AppLogger.write(LogTag.rtc, 'Session log saved: ${log.id}');
    } catch (e) {
      _error = e.toString();
      AppLogger.write(LogTag.rtc, 'endCall saveLog error: $e');
    }
    notifyListeners();
  }

  /// End the room for all participants (stub — requires 100ms server credentials).
  Future<void> endRoomForAll() async {
    AppLogger.write(
        LogTag.rtc, 'RTC: endRoomForAll (STUB, requires 100ms credentials)');
    _callState = CallState.postCall;
    notifyListeners();
  }

  /// Reset call state back to idle.
  void resetCall() {
    _callState = CallState.idle;
    _roomMeta = null;
    _isMuted = false;
    _isCameraOff = false;
    _callStartedAt = null;
    _error = null;
    notifyListeners();
  }

  int get callDurationSeconds {
    if (_callStartedAt == null) return 0;
    return DateTime.now().difference(_callStartedAt!).inSeconds;
  }
}
