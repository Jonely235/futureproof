import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import '../config/app_colors.dart';
import '../domain/repositories/cloud_backup_repository.dart';
import '../utils/app_logger.dart';
import '../models/app_error.dart';
import 'firebase_setup_wizard.dart';

/// Firebase Configuration Widget
///
/// Handles Firebase setup, sync status, and manual backup/restore.
/// Self-contained widget following existing patterns (FinancialGoalsFormWidget).
class FirebaseConfigWidget extends StatefulWidget {
  final CloudBackupRepository cloudBackupRepo;

  const FirebaseConfigWidget({
    super.key,
    required this.cloudBackupRepo,
  });

  @override
  State<FirebaseConfigWidget> createState() => _FirebaseConfigWidgetState();
}

class _FirebaseConfigWidgetState extends State<FirebaseConfigWidget> {
  bool _isConfigured = false;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  DateTime? _lastBackup;
  DateTime? _lastSync;
  String? _errorMessage;

  StreamSubscription<BackupStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _listenToStatus();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    try {
      final authenticated = await widget.cloudBackupRepo.isAuthenticated();
      final lastBackup = await widget.cloudBackupRepo.getLastBackupTime();

      if (mounted) {
        setState(() {
          _isAuthenticated = authenticated;
          _isConfigured = authenticated; // Simplified: config = auth
          _lastBackup = lastBackup;
        });
      }
    } catch (e) {
      AppLogger.widgets.warning('Failed to check Firebase status: $e');
    }
  }

  void _listenToStatus() {
    _statusSubscription = widget.cloudBackupRepo.backupStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _lastBackup = status.lastBackupTime;
          _errorMessage = status.errorMessage;
          _isLoading = status.isOperationInProgress;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgets.info('FirebaseConfigWidget: Building widget');

    if (!_isConfigured) {
      return _buildSetupButton();
    }

    return _buildSyncStatus();
  }

  Widget _buildSetupButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.cloud_sync_outlined,
              color: AppColors.black,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cloud Sync',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  Text(
                    'Sync your data to Firebase Firestore',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _showConfigDialog,
            icon: const Icon(Icons.cloud_sync, size: 18),
            label: Text(
              'Setup Cloud Sync',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _errorMessage != null
                  ? Icons.cloud_off
                  : Icons.cloud_done,
              color: _errorMessage != null ? AppColors.danger : AppColors.black,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cloud Sync ${_errorMessage != null ? 'Error' : 'Active'}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  if (_lastBackup != null)
                    Text(
                      'Last backup: ${_formatDate(_lastBackup!)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: AppColors.gray700,
                      ),
                    )
                  else if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: AppColors.danger,
                      ),
                    )
                  else
                    Text(
                      'Connected to Firebase',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: AppColors.gray700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _backupToCloud,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup, size: 18),
                label: Text(
                  'Backup Now',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.black),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _restoreFromCloud,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore, size: 18),
                label: Text(
                  'Restore',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.black),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showConfigDialog() async {
    HapticFeedback.lightImpact();
    AppLogger.widgets.info('FirebaseConfigWidget: Showing setup wizard');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FirebaseSetupWizard(
          cloudBackupRepo: widget.cloudBackupRepo,
          onSetupComplete: () {
            setState(() {
              _isConfigured = true;
              _isAuthenticated = true;
            });
            _checkStatus();
          },
        ),
      ),
    );
  }

  Future<void> _showInitialSyncDialog() async {
    HapticFeedback.lightImpact();
    AppLogger.widgets.info('FirebaseConfigWidget: Showing initial sync dialog');

    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Initial Sync'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_sync, size: 48, color: AppColors.black),
            SizedBox(height: 16),
            Text(
              'Choose your initial sync direction:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '• Backup to Cloud: Upload your local data to Firebase\n'
              '• Restore from Cloud: Download data from Firebase (replaces local)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'backup'),
            child: const Text('Backup to Cloud ☁️'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'restore'),
            child: const Text('Restore from Cloud 📥'),
          ),
        ],
      ),
    );

    if (choice == 'backup') {
      await _backupToCloud();
    } else if (choice == 'restore') {
      await _restoreFromCloud();
    }
  }

  Future<void> _backupToCloud() async {
    HapticFeedback.lightImpact();
    AppLogger.widgets.info('FirebaseConfigWidget: Backup to cloud requested');

    try {
      await widget.cloudBackupRepo.backupData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Backup complete!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.widgets.warning('FirebaseConfigWidget: Backup failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreFromCloud() async {
    HapticFeedback.lightImpact();
    AppLogger.widgets.info('FirebaseConfigWidget: Restore from cloud requested');

    try {
      await widget.cloudBackupRepo.restoreData();

      if (mounted) {
        // Show success and suggest refresh
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Complete'),
            content: const Text(
                'Your data has been restored from Firebase.\n\nPlease restart the app to see the changes.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      AppLogger.widgets.warning('FirebaseConfigWidget: Restore failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
