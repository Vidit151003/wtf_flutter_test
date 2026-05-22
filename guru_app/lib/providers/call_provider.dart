import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

// TODO: Integrate hmssdk_flutter when 100ms credentials are available
// This provider is fully wired but uses stub call state

class CallProvider extends ChangeNotifier {
  final LogService _logService;
  final AuthService _authService;

  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isInCall = false;
  bool _isReconnecting = false;
  String? _roomId;
  DateTime? _callStartTime;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;

  bool get isMuted => _isMuted;
  bool get isVideoOff => _isVideoOff;
  bool get isInCall => _isInCall;
  bool get isReconnecting => _isReconnecting;
  String? get roomId => _roomId;

  CallProvider(this._logService, this._authService);

  // TODO(100ms): Future<void> joinCall(String roomId, String token, String role)
  Future<void> joinCall(String roomId, String token, String role) async {
    AppLogger.write(
        LogTag.rtc, 'joinCall: roomId=$roomId role=$role (STUB)');
    _roomId = roomId;
    _callStartTime = DateTime.now();
    _isInCall = true;
    _reconnectAttempts = 0;
    notifyListeners();
  }

  Future<void> leaveCall() async {
    AppLogger.write(LogTag.rtc, 'leaveCall called');
    if (_callStartTime != null) {
      final endedAt = DateTime.now();
      final durationSec = endedAt.difference(_callStartTime!).inSeconds;
      final user = _authService.currentUser;
      if (user != null) {
        final log = SessionLogModel(
          id: 'log_${DateTime.now().millisecondsSinceEpoch}',
          memberId: user.role == UserRole.member ? user.id : 'unknown',
          trainerId: user.role == UserRole.trainer
              ? user.id
              : (user.assignedTrainerId ?? 'trainer_001'),
          startedAt: _callStartTime!,
          endedAt: endedAt,
          durationSec: durationSec,
        );
        await _logService.saveLog(log);
        AppLogger.write(LogTag.rtc,
            'Session log saved: durationSec=$durationSec');
      }
    }
    _isInCall = false;
    _roomId = null;
    _callStartTime = null;
    notifyListeners();
  }

  void toggleMic() {
    _isMuted = !_isMuted;
    AppLogger.write(LogTag.rtc, 'toggleMic: isMuted=$_isMuted');
    // TODO(100ms): hmsSDK.toggleMicMuteState()
    notifyListeners();
  }

  void toggleVideo() {
    _isVideoOff = !_isVideoOff;
    AppLogger.write(LogTag.rtc, 'toggleVideo: isVideoOff=$_isVideoOff');
    // TODO(100ms): hmsSDK.toggleCameraMuteState()
    notifyListeners();
  }

  void flipCamera() {
    AppLogger.write(LogTag.rtc, 'flipCamera called');
    // TODO(100ms): hmsSDK.switchCamera()
  }

  // TODO(100ms): Reconnect logic
  Future<void> attemptReconnect(
      String roomId, String token, String role) async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      AppLogger.write(LogTag.rtc, 'Max reconnect attempts reached');
      return;
    }
    _isReconnecting = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _reconnectAttempts++;
    AppLogger.write(
        LogTag.rtc, 'Reconnect attempt #$_reconnectAttempts');
    await joinCall(roomId, token, role);
    _isReconnecting = false;
    notifyListeners();
  }
}
