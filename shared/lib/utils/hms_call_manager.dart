import 'package:flutter/foundation.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'app_logger.dart';

class HmsCallManager implements HMSUpdateListener, HMSActionResultListener {
  late HMSSDK hmsSdk;
  HMSPeer? localPeer;
  List<HMSPeer> remotePeers = [];
  bool isJoined = false;

  final VoidCallback onStateChange;
  final Function(String error)? onErrorCallback;

  HmsCallManager({
    required this.onStateChange,
    this.onErrorCallback,
  }) {
    hmsSdk = HMSSDK();
    hmsSdk.build();
  }

  Future<void> joinWithRoomCode(String roomCode, String userName) async {
    try {
      AppLogger.write(LogTag.rtc, 'Joining with room code: $roomCode');
      final token = await hmsSdk.getAuthTokenByRoomCode(roomCode: roomCode);
      final config = HMSConfig(authToken: token, userName: userName);
      hmsSdk.addUpdateListener(listener: this);
      await hmsSdk.join(config: config);
    } catch (e) {
      AppLogger.write(LogTag.rtc, 'Error joining room: $e');
      onErrorCallback?.call(e.toString());
    }
  }

  Future<void> leaveCall() async {
    AppLogger.write(LogTag.rtc, 'Leaving call...');
    await hmsSdk.leave(hmsActionResultListener: this);
    hmsSdk.removeUpdateListener(listener: this);
    isJoined = false;
    localPeer = null;
    remotePeers.clear();
    onStateChange();
  }

  Future<void> toggleMic(bool isMuted) async {
    hmsSdk.toggleMicMuteState();
  }

  Future<void> toggleCamera(bool isVideoOff) async {
    hmsSdk.toggleCameraMuteState();
  }

  Future<void> switchCamera() async {
    hmsSdk.switchCamera();
  }

  Future<void> endRoom() async {
    await hmsSdk.endRoom(lock: false, reason: 'Call ended by trainer');
  }

  @override
  void onJoin({required HMSRoom room}) {
    AppLogger.write(LogTag.rtc, 'Joined room: ${room.id}');
    isJoined = true;
    if (room.peers != null) {
      try {
        localPeer = room.peers!.firstWhere((p) => p.isLocal);
      } catch (_) {
        localPeer = null;
      }
      remotePeers = room.peers!.where((p) => !p.isLocal).toList();
    }
    onStateChange();
  }

  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    AppLogger.write(LogTag.rtc, 'Peer update: ${peer.name} -> $update');
    if (update == HMSPeerUpdate.peerJoined) {
      if (!peer.isLocal && !remotePeers.contains(peer)) {
        remotePeers.add(peer);
      }
    } else if (update == HMSPeerUpdate.peerLeft) {
      remotePeers.removeWhere((p) => p.peerId == peer.peerId);
    }
    onStateChange();
  }

  @override
  void onTrackUpdate({required HMSTrack track, required HMSTrackUpdate trackUpdate, required HMSPeer peer}) {
    // Usually handled by HMSVideoView automatically, but we can trigger rebuild
    onStateChange();
  }

  @override
  void onHMSError({required HMSException error}) {
    AppLogger.write(LogTag.rtc, 'HMS Error: ${error.message}');
    onErrorCallback?.call(error.message ?? 'Unknown HMS Error');
  }

  @override
  void onMessage({required HMSMessage message}) {}

  @override
  void onRoleChangeRequest({required HMSRoleChangeRequest roleChangeRequest}) {}

  @override
  void onRoomUpdate({required HMSRoom room, required HMSRoomUpdate update}) {}

  @override
  void onUpdateSpeakers({required List<HMSSpeaker> updateSpeakers}) {}

  @override
  void onReconnecting() {
    AppLogger.write(LogTag.rtc, 'Reconnecting to room...');
  }

  @override
  void onReconnected() {
    AppLogger.write(LogTag.rtc, 'Reconnected to room');
  }

  @override
  void onChangeTrackStateRequest({required HMSTrackChangeRequest hmsTrackChangeRequest}) {}

  @override
  void onRemovedFromRoom({required HMSPeerRemovedFromPeer hmsPeerRemovedFromPeer}) {
    isJoined = false;
    onStateChange();
  }

  @override
  void onAudioDeviceChanged({HMSAudioDevice? currentAudioDevice, List<HMSAudioDevice>? availableAudioDevice}) {}

  @override
  void onSessionStoreAvailable({HMSSessionStore? hmsSessionStore}) {}

  @override
  void onException({required HMSActionResultListenerMethod methodType, Map<String, dynamic>? arguments, required HMSException hmsException}) {
    AppLogger.write(LogTag.rtc, 'HMS Action Exception: ${hmsException.message}');
  }

  @override
  void onSuccess({required HMSActionResultListenerMethod methodType, Map<String, dynamic>? arguments}) {}

  @override
  void onPeerListUpdate({required List<HMSPeer> addedPeers, required List<HMSPeer> removedPeers}) {}
}
