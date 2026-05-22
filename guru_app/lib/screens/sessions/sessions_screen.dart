import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import '../../providers/session_provider.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sessions'),
      ),
      body: Consumer<SessionProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildFilters(context, provider),
              Expanded(
                child: provider.isLoading
                    ? const SkeletonLoader(count: 5)
                    : provider.filteredLogs.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.video_library,
                            title: 'No sessions yet',
                            subtitle: 'Schedule your first call',
                          )
                        : ListView.builder(
                            itemCount: provider.filteredLogs.length,
                            itemBuilder: (context, index) {
                              final log = provider.filteredLogs[index];
                              return SessionLogTile(log: log);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(BuildContext context, SessionProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: provider.filter == SessionFilter.all,
            onSelected: (_) => provider.setFilter(SessionFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Last 7 Days',
            selected: provider.filter == SessionFilter.last7Days,
            onSelected: (_) => provider.setFilter(SessionFilter.last7Days),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'This Month',
            selected: provider.filter == SessionFilter.thisMonth,
            onSelected: (_) => provider.setFilter(SessionFilter.thisMonth),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
    );
  }
}
