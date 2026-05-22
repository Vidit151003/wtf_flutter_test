import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';

class PreJoinScreen extends StatefulWidget {
  const PreJoinScreen({super.key});

  @override
  State<PreJoinScreen> createState() => _PreJoinScreenState();
}

class _PreJoinScreenState extends State<PreJoinScreen> {
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

  void _joinCall() async {
    final callProvider = Provider.of<TrainerCallProvider>(context, listen: false);
    try {
      await callProvider.joinCall();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/call/in-call',
        arguments: {'sessionId': 'stub_session'},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join call: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<TrainerAuthProvider>(context);
    final trainerName = userProvider.currentUser?.name ?? 'Trainer';
    final initials = trainerName.isNotEmpty ? trainerName[0].toUpperCase() : 'T';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ready to join?'),
        backgroundColor: const Color(0xFFE50914),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!_isCameraOn)
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[800],
                        child: Text(
                          initials,
                          style: const TextStyle(fontSize: 40, color: Colors.white),
                        ),
                      )
                    else
                      const Text(
                        'Camera preview',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 18,
                        ),
                      ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          trainerName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Joining as Trainer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You can end this room for all participants',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _toggleMic,
                    icon: Icon(_isMicOn ? Icons.mic : Icons.mic_off),
                    iconSize: 32,
                    color: _isMicOn ? Colors.black : Colors.red,
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    onPressed: _toggleCamera,
                    icon: Icon(_isCameraOn ? Icons.videocam : Icons.videocam_off),
                    iconSize: 32,
                    color: _isCameraOn ? Colors.black : Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Ready to join? Check mic and camera.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _joinCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Join Call',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
