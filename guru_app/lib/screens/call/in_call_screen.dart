import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import '../../providers/call_provider.dart';
import '../../providers/auth_provider.dart';
import 'post_call_sheet.dart';

class InCallScreen extends StatefulWidget {
  const InCallScreen({super.key});

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  bool _peerLeft = false;

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final myInitials = user?.name.isNotEmpty == true
        ? user!.name.substring(0, 1).toUpperCase()
        : 'U';
    
    // Simulate trainer info
    final trainerName = 'Trainer';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video tile
            Positioned.fill(
              child: Container(
                color: Colors.grey.shade900,
                child: Stack(
                  children: [
                    if (callProvider.hmsManager.remotePeers.isNotEmpty)
                      ...callProvider.hmsManager.remotePeers.map((peer) {
                        final track = peer.videoTrack;
                        if (track != null && !track.isMute) {
                          return HMSVideoView(track: track, matchParent: true);
                        }
                        return Center(
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blueGrey,
                            child: Text(
                              peer.name.isNotEmpty ? peer.name[0].toUpperCase() : 'T',
                              style: const TextStyle(fontSize: 48, color: Colors.white),
                            ),
                          ),
                        );
                      })
                    else
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.blueGrey,
                              child: Text(
                                trainerName[0],
                                style: const TextStyle(fontSize: 48, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              trainerName,
                              style: const TextStyle(color: Colors.white, fontSize: 24),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Local video tile
            Positioned(
              bottom: 100,
              right: 16,
              child: Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade600, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    if (callProvider.isVideoOff || callProvider.hmsManager.localPeer?.videoTrack == null)
                      Center(
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.shade800,
                          child: Text(
                            myInitials,
                            style: const TextStyle(fontSize: 24, color: Colors.white),
                          ),
                        ),
                      )
                    else
                      HMSVideoView(
                        track: callProvider.hmsManager.localPeer!.videoTrack!,
                        matchParent: true,
                      ),
                    const Positioned(
                      bottom: 8,
                      left: 8,
                      child: Text(
                        'You',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Control bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: Colors.black54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        callProvider.isMuted ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                      ),
                      onPressed: callProvider.toggleMic,
                    ),
                    IconButton(
                      icon: Icon(
                        callProvider.isVideoOff
                            ? Icons.videocam_off
                            : Icons.videocam,
                        color: Colors.white,
                      ),
                      onPressed: callProvider.toggleVideo,
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios,
                          color: Colors.white),
                      onPressed: callProvider.flipCamera,
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 24,
                      child: IconButton(
                        icon: const Icon(Icons.call_end, color: Colors.white),
                        onPressed: () => _endCall(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Reconnecting Overlay
            if (callProvider.isReconnecting)
              Positioned.fill(
                child: Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Text(
                      'Reconnecting...',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
              ),

            // Peer Left Overlay
            if (_peerLeft)
              Positioned.fill(
                child: Container(
                  color: Colors.black87,
                  child: Center(
                    child: Text(
                      '$trainerName has left the call',
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _endCall(BuildContext context) async {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    await callProvider.leaveCall();
    
    if (context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const PostCallSheet(),
      );
    }
    
    if (context.mounted) {
      context.pop();
    }
  }
}
