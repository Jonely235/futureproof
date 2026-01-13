import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/app_error.dart';
import '../../utils/error_display.dart';
import '../../utils/error_tracker.dart';

/// Developer-only screen for viewing error history.
///
/// Provides a list of recent errors with full details, filtering by type,
/// and capabilities to clear history or export logs.
class ErrorHistoryScreen extends StatefulWidget {
  const ErrorHistoryScreen({super.key});

  @override
  State<ErrorHistoryScreen> createState() => _ErrorHistoryScreenState();
}

class _ErrorHistoryScreenState extends State<ErrorHistoryScreen> {
  final _tracker = ErrorTracker();
  AppErrorType? _filterType;

  List<TrackedError> get _errors {
    if (_filterType == null) {
      return _tracker.getRecentErrors(count: 100);
    } else {
      return _tracker.getErrorsByType(_filterType!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety check - though this screen shouldn't be accessible in release
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Debug mode only')),
      );
    }

    final errors = _errors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Error History (Debug)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportLogs,
            tooltip: 'Export Logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _confirmClear,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: errors.isEmpty
                ? const Center(child: Text('No errors tracked yet'))
                : ListView.builder(
                    itemCount: errors.length,
                    itemBuilder: (context, index) {
                      final error = errors[index];
                      return _ErrorListItem(trackedError: error);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _filterType == null,
            onSelected: (selected) {
              setState(() => _filterType = null);
            },
          ),
          const SizedBox(width: 8),
          ...AppErrorType.values.map((type) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type.name.toUpperCase()),
                selected: _filterType == type,
                onSelected: (selected) {
                  setState(() => _filterType = selected ? type : null);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text('This will remove all tracked errors from memory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _tracker.clearHistory());
              Navigator.pop(context);
              ErrorDisplay.showSuccessSnackBar(
                  context, 'Error history cleared');
            },
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportLogs() async {
    final log = _tracker.exportErrorLog();
    await Clipboard.setData(ClipboardData(text: log));
    if (mounted) {
      ErrorDisplay.showSuccessSnackBar(
          context, 'Error log copied to clipboard');
    }
  }
}

class _ErrorListItem extends StatelessWidget {
  final TrackedError trackedError;

  const _ErrorListItem({required this.trackedError});

  IconData _getIcon() {
    switch (trackedError.error.type) {
      case AppErrorType.database:
        return Icons.storage;
      case AppErrorType.network:
        return Icons.wifi_off;
      case AppErrorType.validation:
        return Icons.error_outline;
      case AppErrorType.backup:
        return Icons.backup;
      case AppErrorType.unknown:
        return Icons.warning;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';

    return DateFormat('MMM d, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(_getIcon(), color: Colors.red),
        title: Text(
          trackedError.error.message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_formatTimestamp(trackedError.timestamp)} • ${trackedError.context}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Type', trackedError.error.type.name),
                _buildInfoRow('Timestamp', trackedError.timestamp.toString()),
                _buildInfoRow('Context', trackedError.context),
                if (trackedError.error.technicalDetails != null)
                  _buildInfoRow('Technical Details',
                      trackedError.error.technicalDetails!),
                if (trackedError.stackTrace != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Stack Trace:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    width: double.infinity,
                    child: SingleChildScrollView(
                      child: Text(
                        trackedError.stackTrace.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
