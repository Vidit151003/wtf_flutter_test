import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class DevPanelOverlay extends StatefulWidget {
  final Widget child;

  const DevPanelOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<DevPanelOverlay> createState() => _DevPanelOverlayState();
}

class _DevPanelOverlayState extends State<DevPanelOverlay> {
  void _showDevPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            final logs = AppLogger.instance.entries.toList();
            
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE50914),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.developer_mode, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Dev Panel - Logs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: logs.isEmpty
                      ? const Center(child: Text('No logs available'))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[logs.length - 1 - index];
                            return ListTile(
                              title: Text(log.message),
                              subtitle: Text(
                                '${log.timestamp.toIso8601String()} - [${log.tag.name}]',
                                style: TextStyle(
                                  color: log.tag.name == 'ERROR' ? Colors.red : Colors.grey,
                                ),
                              ),
                              isThreeLine: true,
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      AppLogger.instance.clear();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logs cleared')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Clear Logs'),
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'dev_panel_btn',
            mini: true,
            backgroundColor: const Color(0xFFE50914),
            onPressed: () => _showDevPanel(context),
            child: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
