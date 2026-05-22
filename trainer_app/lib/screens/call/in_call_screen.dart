import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
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
    setState(() {
      _isMicOn = !_isMicOn;
    });
  }

  void _toggleCamera() {
    setState(() {
      _isCameraOn = !_isCameraOn;
    });
  }

  void _flipCamera() {
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
              child: Column(
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!_isCameraOn)
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[800],
                        child: Text(
                          trainerInitials,
                          style: const TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      )
                    else
                      const Text(
                        'Camera preview',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
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
                        icon: Icon(_isMicOn ? Icons.mic : Icons.mic_off),
                        color: _isMicOn ? Colors.white : Colors.red,
                        iconSize: 28,
                      ),
                      IconButton(
                        onPressed: _toggleCamera,
                        icon: Icon(_isCameraOn ? Icons.videocam : Icons.videocam_off),
                        color: _isCameraOn ? Colors.white : Colors.red,
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
