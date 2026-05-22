import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/call_provider.dart';
import '../../providers/auth_provider.dart';

class PreJoinScreen extends StatefulWidget {
  const PreJoinScreen({super.key});

  @override
  State<PreJoinScreen> createState() => _PreJoinScreenState();
}

class _PreJoinScreenState extends State<PreJoinScreen> {
  bool _micEnabled = true;
  bool _cameraEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final initials = user?.name.isNotEmpty == true
        ? user!.name.substring(0, 1).toUpperCase()
        : '?';
    final roleStr = user?.role.name ?? 'member';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ready to join?'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue.shade800,
                        child: Text(
                          initials,
                          style: const TextStyle(
                              fontSize: 32, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Camera preview',
                        style: TextStyle(
                            color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Joining as ${roleStr[0].toUpperCase()}${roleStr.substring(1)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                      _micEnabled ? Icons.mic : Icons.mic_off,
                      color: _micEnabled ? Colors.blue : Colors.red),
                  iconSize: 32,
                  onPressed: () {
                    setState(() {
                      _micEnabled = !_micEnabled;
                    });
                  },
                ),
                const SizedBox(width: 32),
                IconButton(
                  icon: Icon(
                      _cameraEnabled ? Icons.videocam : Icons.videocam_off,
                      color: _cameraEnabled ? Colors.blue : Colors.red),
                  iconSize: 32,
                  onPressed: () {
                    setState(() {
                      _cameraEnabled = !_cameraEnabled;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Ready to join? Check mic and camera.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final callProvider =
                    Provider.of<CallProvider>(context, listen: false);
                await callProvider.joinCall(
                    'dummy_room', 'dummy_token', roleStr);
                if (context.mounted) {
                  context.go('/call/in-call');
                }
              },
              child: const Text('Join Call', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
