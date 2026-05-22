import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared/shared.dart';

class DevPanelOverlay extends StatefulWidget {
  final Widget child;
  const DevPanelOverlay({super.key, required this.child});

  @override
  State<DevPanelOverlay> createState() => _DevPanelOverlayState();
}

class _DevPanelOverlayState extends State<DevPanelOverlay> {
  void _showPanel() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade900,
      builder: (ctx) => _DevPanelSheet(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          bottom: 24,
          right: 24,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: const ShapeDecoration(
                  color: Colors.black54,
                  shape: CircleBorder(),
                ),
                child: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: _showPanel,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DevPanelSheet extends StatefulWidget {
  final PackageInfo info;
  const _DevPanelSheet({required this.info});

  @override
  State<_DevPanelSheet> createState() => _DevPanelSheetState();
}

class _DevPanelSheetState extends State<_DevPanelSheet> {
  @override
  Widget build(BuildContext context) {
    final entries = AppLogger.instance.entries.reversed.toList();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.info.appName} v${widget.info.version} (${widget.info.buildNumber})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Build mode: ${kDebugMode ? 'debug' : 'release'}',
            style: const TextStyle(color: Colors.grey),
          ),
          const Divider(color: Colors.grey),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Logs (Last 20)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  AppLogger.instance.clear();
                  setState(() {});
                },
                child: const Text('Clear Logs'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                Color tagColor;
                switch (entry.tag) {
                  case LogTag.auth: tagColor = Colors.blue; break;
                  case LogTag.chat: tagColor = Colors.green; break;
                  case LogTag.rtc: tagColor = Colors.orange; break;
                  case LogTag.schedule: tagColor = Colors.purple; break;
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: tagColor),
                        ),
                        child: Text(
                          entry.tag.name.toUpperCase(),
                          style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.message,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
