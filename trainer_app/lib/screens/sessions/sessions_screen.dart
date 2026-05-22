import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../../providers/session_provider.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<TrainerSessionProvider>();
    final logs = sessionProvider.logs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: sessionProvider.isLoading && logs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : logs.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.history_toggle_off,
                  title: 'No Sessions Yet',
                  subtitle: 'Your completed sessions will appear here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (ctx, i) {
                    final log = logs[i];
                    return _SessionTileWithActions(
                      log: log,
                      delay: i * 80,
                    );
                  },
                ),
    );
  }
}

class _SessionTileWithActions extends StatelessWidget {
  final SessionLogModel log;
  final int delay;

  const _SessionTileWithActions({
    required this.log,
    this.delay = 0,
  });

  Future<void> _showAddNotesDialog(
      BuildContext context, SessionLogModel log) async {
    final notesCtrl =
        TextEditingController(text: log.trainerNotes ?? '');
    final sessionProvider =
        context.read<TrainerSessionProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Session Notes'),
        content: TextField(
          controller: notesCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter trainer notes...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await sessionProvider.addNotes(log.id, notesCtrl.text.trim());
      notesCtrl.dispose();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes saved!'),
            backgroundColor: kColorSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      notesCtrl.dispose();
    }
  }

  Future<void> _markComplete(BuildContext context) async {
    final sessionProvider = context.read<TrainerSessionProvider>();
    await sessionProvider.markComplete(log.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session marked as complete!'),
          backgroundColor: kColorSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kTrainerNeutral100),
        ),
        child: Column(
          children: [
            SessionLogTile(
              log: log,
            ),
            const Divider(height: 1),
            // Action buttons row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _markComplete(context),
                    icon: const Icon(Icons.check_circle_outline,
                        size: 16),
                    label: const Text('Mark Complete'),
                    style: TextButton.styleFrom(
                      foregroundColor: kColorSuccess,
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () =>
                        _showAddNotesDialog(context, log),
                    icon: const Icon(Icons.edit_note, size: 16),
                    label: const Text('Add Notes'),
                    style: TextButton.styleFrom(
                      foregroundColor: kTrainerPrimary,
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(
              delay: Duration(milliseconds: delay), duration: 400.ms)
          .slideY(begin: 0.05, end: 0),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note,
                  color: kTrainerPrimary),
              title: const Text('Add Notes'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddNotesDialog(context, log);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.check_circle, color: kColorSuccess),
              title: const Text('Mark Complete'),
              onTap: () {
                Navigator.pop(ctx);
                _markComplete(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
