import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import 'post_call_sheet.dart';

class InCallScreen extends StatefulWidget {
  const InCallScreen({super.key});

  @override
  State<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<InCallScreen> {
  bool _isMicOn = true;
  bool _isCameraOn = true;

  void _toggleMic() {
    Provider.of<TrainerCallProvider>(context, listen: false).toggleMute();
  }

  void _toggleCamera() {
    Provider.of<TrainerCallProvider>(context, listen: false).toggleCamera();
  }

  void _flipCamera() {
    Provider.of<TrainerCallProvider>(context, listen: false).hmsManager.switchCamera();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera flipped')),
    );
  }

  void _endCall() async {
    final callProvider = Provider.of<TrainerCallProvider>(context, listen: false);
    await callProvider.endCall(memberId: 'member_001', trainerId: 'trainer_001');
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const PostCallSheet(sessionId: 'stub_session'),
    );
    
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _endRoomForAll() async {
    final callProvider = Provider.of<TrainerCallProvider>(context, listen: false);
    await callProvider.endRoomForAll();
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const PostCallSheet(sessionId: 'stub_session'),
    );
    
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<TrainerCallProvider>(context);
    final userProvider = Provider.of<TrainerAuthProvider>(context);
    
    final trainerName = userProvider.currentUser?.name ?? 'Trainer';
    final trainerInitials = trainerName.isNotEmpty ? trainerName[0].toUpperCase() : 'T';
    
    final memberName = 'Member';
    final memberInitials = memberName.isNotEmpty ? memberName[0].toUpperCase() : 'M';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
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
                          backgroundColor: Colors.grey[800],
                          child: Text(
                            peer.name.isNotEmpty ? peer.name[0].toUpperCase() : 'M',
                            style: const TextStyle(fontSize: 48, color: Colors.white),
                          ),
                        ),
                      );
                    })
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[800],
                          child: Text(
                            memberInitials,
                            style: const TextStyle(fontSize: 48, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          memberName,
                          style: const TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            Positioned(
              right: 16,
              bottom: 100,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (callProvider.isCameraOff || callProvider.hmsManager.localPeer?.videoTrack == null)
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[800],
                        child: Text(
                          trainerInitials,
                          style: const TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      )
                    else
                      HMSVideoView(
                        track: callProvider.hmsManager.localPeer!.videoTrack!,
                        matchParent: true,
                      ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (false)
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFE50914)),
                      SizedBox(height: 16),
                      Text(
                        'Reconnecting...',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),

            Positioned(
              top: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: _endRoomForAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                ),
                child: const Text('End for All'),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                color: Colors.black87,
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: _toggleMic,
                        icon: Icon(callProvider.isMuted ? Icons.mic_off : Icons.mic),
                        color: callProvider.isMuted ? Colors.red : Colors.white,
                        iconSize: 28,
                      ),
                      IconButton(
                        onPressed: _toggleCamera,
                        icon: Icon(callProvider.isCameraOff ? Icons.videocam_off : Icons.videocam),
                        color: callProvider.isCameraOff ? Colors.red : Colors.white,
                        iconSize: 28,
                      ),
                      IconButton(
                        onPressed: _flipCamera,
                        icon: const Icon(Icons.flip_camera_ios),
                        color: Colors.white,
                        iconSize: 28,
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFE50914),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _endCall,
                          icon: const Icon(Icons.call_end),
                          color: Colors.white,
                          iconSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
