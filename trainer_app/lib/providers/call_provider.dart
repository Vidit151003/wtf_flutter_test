import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';
import '../secrets.dart';

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

  late final HmsCallManager _hmsManager;

  TrainerCallProvider(this._logService) {
    _hmsManager = HmsCallManager(
      onStateChange: notifyListeners,
      onErrorCallback: (e) {
        _error = e;
        notifyListeners();
      },
    );
  }

  CallState get callState => _callState;
  RoomMetaModel? get roomMeta => _roomMeta;
  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  DateTime? get callStartedAt => _callStartedAt;
  String? get error => _error;
  bool get isInCall => _callState == CallState.inCall;
  HmsCallManager get hmsManager => _hmsManager;

  /// Pre-join: set room metadata and transition to preJoin state.
  void prepareCall(RoomMetaModel meta) {
    _roomMeta = meta;
    _callState = CallState.preJoin;
    AppLogger.write(LogTag.rtc, 'Trainer prepareCall: room=${meta.hmsRoomId}');
    notifyListeners();
  }

  /// Join the call via 100ms
  Future<void> joinCall() async {
    AppLogger.write(LogTag.rtc, 'RTC: joinCall 100ms');
    _callState = CallState.inCall;
    _callStartedAt = DateTime.now();
    notifyListeners();
    await _hmsManager.joinWithRoomCode(Secrets.hmsRoomCodeTrainer, 'Trainer');
  }

  /// Toggle microphone mute state.
  void toggleMute() {
    _isMuted = !_isMuted;
    _hmsManager.toggleMic(_isMuted);
    AppLogger.write(LogTag.rtc, 'Trainer toggleMute: muted=$_isMuted');
    notifyListeners();
  }

  /// Toggle camera off state.
  void toggleCamera() {
    _isCameraOff = !_isCameraOff;
    _hmsManager.toggleCamera(_isCameraOff);
    AppLogger.write(LogTag.rtc, 'Trainer toggleCamera: off=$_isCameraOff');
    notifyListeners();
  }

  /// End call for this participant and save session log.
  Future<void> endCall({
    required String memberId,
    required String trainerId,
  }) async {
    AppLogger.write(LogTag.rtc, 'Trainer endCall');
    await _hmsManager.leaveCall();
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

  /// End the room for all participants via 100ms
  Future<void> endRoomForAll() async {
    AppLogger.write(LogTag.rtc, 'RTC: endRoomForAll');
    await _hmsManager.endRoom();
    await _hmsManager.leaveCall();
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
