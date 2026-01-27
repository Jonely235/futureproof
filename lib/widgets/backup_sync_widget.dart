import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../design/design_tokens.dart';
import '../providers/vault_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/backup_service.dart';
import '../services/icloud_drive_service.dart';
import '../services/icloud_sync_manager.dart' as sync_mgr;
import '../utils/app_logger.dart';

/// Backup & Sync Widget
///
/// Provides backup and sync options:
/// - iCloud sync status & trigger
/// - Export all vaults to JSON
/// - Import from backup file
/// - Google Drive (placeholder for future)
class BackupSyncWidget extends StatefulWidget {
  const BackupSyncWidget({super.key});

  @override
  State<BackupSyncWidget> createState() => _BackupSyncWidgetState();
}

class _BackupSyncWidgetState extends State<BackupSyncWidget> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isSyncing = false;
  ICloudSyncStatus? _iCloudStatus;
  ICloudSyncStatus? _googleDriveStatus;

  // iCloud sync manager status
  StreamSubscription<sync_mgr.SyncStatus>? _syncStatusSubscription;
  sync_mgr.SyncStatus _icloudManagerStatus = sync_mgr.sync_mgr.SyncStatus.idle;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
    _listenToSyncStatus();
  }

  @override
  void dispose() {
    _syncStatusSubscription?.cancel();
    super.dispose();
  }

  void _listenToSyncStatus() {
    _syncStatusSubscription = sync_mgr.ICloudSyncManager.instance.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _icloudManagerStatus = status;
          _isSyncing = status == sync_mgr.sync_mgr.SyncStatus.syncing;
        });

        // Show toast for terminal states
        if (status == sync_mgr.sync_mgr.SyncStatus.success) {
          _showSyncSnackBar('Synced to iCloud', AppColors.success);
        } else if (status == sync_mgr.sync_mgr.SyncStatus.error) {
          _showSyncSnackBar('Sync failed - check diagnostic', AppColors.danger);
        }
      }
    });
  }

  void _showSyncSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadSyncStatus() async {
    final iCloudStatus = await BackupService.instance.getiCloudSyncStatus();
    final googleDriveStatus = await BackupService.instance.getGoogleDriveStatus();
    if (mounted) {
      setState(() {
        _iCloudStatus = iCloudStatus;
        _googleDriveStatus = googleDriveStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sync status indicator (shows when active)
        if (_icloudManagerStatus != sync_mgr.sync_mgr.SyncStatus.idle)
          _buildSyncStatusIndicator(),

        // iCloud Sync
        _buildSyncTile(
          icon: Icons.cloud,
          title: 'iCloud Sync',
          subtitle: _getSyncSubtitle(),
          isEnabled: _iCloudStatus?.isEnabled ?? false,
          isAvailable: _iCloudStatus?.isAvailable ?? false,
          isLoading: _isSyncing,
          onTap: _iCloudStatus?.isAvailable == true ? _triggeriCloudSync : null,
        ),

        const SizedBox(height: 8),

        // Debug/Diagnose
        _buildActionButton(
          icon: Icons.bug_report,
          title: 'Diagnose iCloud',
          subtitle: 'Check if iCloud is working',
          isLoading: false,
          onTap: _diagnoseICloud,
          color: AppColors.categoryEntertainment,
        ),

        const SizedBox(height: 8),

        // Google Drive Sync (Placeholder)
        _buildSyncTile(
          icon: Icons.drive_file_move_outline,
          title: 'Google Drive',
          subtitle: 'Coming soon',
          isEnabled: false,
          isAvailable: true,
          isLoading: false,
          onTap: null,
        ),

        const SizedBox(height: 8),

        // Divider
        const Divider(height: 24, color: AppColors.border),

        // Export
        _buildActionButton(
          icon: Icons.download,
          title: 'Export Backup',
          subtitle: 'Save all vaults to file',
          isLoading: _isExporting,
          onTap: _exportBackup,
          color: AppColors.fintechTeal,
        ),

        const SizedBox(height: 8),

        // Import
        _buildActionButton(
          icon: Icons.upload,
          title: 'Import Backup',
          subtitle: 'Restore from file',
          isLoading: _isImporting,
          onTap: _importBackup,
          color: AppColors.black,
        ),
      ],
    );
  }

  Widget _buildSyncTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required bool isAvailable,
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ListTile(
        enabled: isAvailable && onTap != null,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isEnabled
                ? AppColors.fintechTeal.withOpacity(0.1)
                : AppColors.gray100,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          ),
          child: Icon(
            icon,
            color: isEnabled ? AppColors.fintechTeal : AppColors.gray500,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: onTap != null ? AppColors.black : AppColors.gray500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: AppColors.gray700,
          ),
        ),
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : onTap != null
                ? const Icon(Icons.sync, size: 20)
                : const Icon(Icons.lock, size: 20, color: AppColors.gray400),
        onTap: onTap,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLoading,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: DesignTokens.borderRadiusLg,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: AppColors.gray700,
          ),
        ),
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right, size: 20),
        onTap: isLoading ? null : onTap,
      ),
    );
  }

  Future<void> _triggeriCloudSync() async {
    final vaultProvider = context.read<VaultProvider>();
    final transactionProviders = {
      for (final vault in vaultProvider.vaults)
        vault.id: context.read<TransactionProvider>()
    };

    // Use ICloudSyncManager for debounced sync (or force sync for manual trigger)
    await sync_mgr.ICloudSyncManager.instance.forceSync(
      vaultProvider: vaultProvider,
      transactionProviders: transactionProviders,
    );

    await _loadSyncStatus();
  }

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);
    try {
      final vaultProvider = context.read<VaultProvider>();

      // Get transactions for all vaults
      final Map<String, TransactionProvider> transactionProviders = {};
      for (final vault in vaultProvider.vaults) {
        // Note: In real implementation, you'd get each vault's transaction provider
        // For now, we'll use the main provider
        transactionProviders[vault.id] = context.read<TransactionProvider>();
      }

      final data = await BackupService.instance.exportAllVaults(
        vaultProvider: vaultProvider,
        transactionProviders: transactionProviders,
      );

      final filePath = await BackupService.instance.saveExportToFile(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup exported successfully',
              style: GoogleFonts.spaceGrotesk(),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Log detailed error for debugging
      AppLogger.ui.severe('Export backup failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Export failed. Please try again.',
              style: GoogleFonts.spaceGrotesk(),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importBackup() async {
    // Show import options dialog
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusLg),
        title: Text(
          'Import Backup',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose import method:',
              style: GoogleFonts.spaceGrotesk(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildImportOption(
              icon: Icons.paste,
              title: 'Paste JSON',
              subtitle: 'Paste backup data from clipboard',
            ),
            const SizedBox(height: 8),
            _buildImportOption(
              icon: Icons.file_open,
              title: 'From File',
              subtitle: 'Select a backup file (coming soon)',
              enabled: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (result == 'paste') {
      await _importFromClipboard();
    }
  }

  Widget _buildImportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? () => Navigator.pop(context, 'paste') : null,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.gray100
              : AppColors.gray200,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? AppColors.fintechTeal : AppColors.gray400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: enabled ? AppColors.black : AppColors.gray500,
                    ),
                  ),
                  Text(
                    subtitle,
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
      ),
    );
  }

  Future<void> _importFromClipboard() async {
    setState(() => _isImporting = true);
    try {
      // In real implementation, you'd get clipboard data
      // For now, show placeholder
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Paste your backup JSON in the next step',
              style: GoogleFonts.spaceGrotesk(),
            ),
            backgroundColor: AppColors.fintechTeal,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: AppColors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _diagnoseICloud() async {
    // Show loading dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusLg),
        title: Text(
          'Diagnosing iCloud...',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking iCloud availability and configuration'),
          ],
        ),
      ),
    );

    try {
      final result = await ICloudDriveService.diagnose();

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show results dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusLg),
          title: Text(
            'iCloud Diagnostic Results',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic info
                _buildDiagnosticSection('Platform Information', [
                  _buildDiagnosticRow('Platform', result['platform']?.toString() ?? 'Unknown'),
                  _buildDiagnosticRow('iOS Available', result['isIOS'] == true ? 'Yes' : 'No'),
                  _buildDiagnosticRow('iCloud Available', result['isAvailable'] == true ? 'Yes' : 'No'),
                ]),

                // Native method check
                _buildDiagnosticSection('Native Code', [
                  _buildDiagnosticRow(
                    'Native Method',
                    result['nativeMethodAvailable'] == true ? 'Working' : 'Not Working',
                    isSuccess: result['nativeMethodAvailable'] == true,
                    isError: result['nativeMethodAvailable'] == false,
                  ),
                  if (result['nativeMethodError'] != null)
                    _buildDiagnosticRow('Error', result['nativeMethodError'].toString(), isError: true),
                ]),

                // Swift diagnostics
                if (result['swiftDiagnostics'] != null) ...[
                  _buildDiagnosticSection('iCloud Container', [
                    _buildDiagnosticRow('Container ID', result['swiftDiagnostics']['containerIdentifier']?.toString() ?? 'Unknown'),
                    _buildDiagnosticRow(
                      'Ubiquity Container',
                      result['swiftDiagnostics']['ubiquityContainerAvailable'] == true ? 'Available' : 'Not Available',
                      isSuccess: result['swiftDiagnostics']['ubiquityContainerAvailable'] == true,
                      isError: result['swiftDiagnostics']['ubiquityContainerAvailable'] == false,
                    ),
                    if (result['swiftDiagnostics']['ubiquityContainerURL'] != null)
                      _buildDiagnosticRow('Container URL', result['swiftDiagnostics']['ubiquityContainerURL'].toString()),
                    _buildDiagnosticRow(
                      'Documents Directory',
                      result['swiftDiagnostics']['documentsExists'] == true ? 'Exists' : 'Not Found',
                      isSuccess: result['swiftDiagnostics']['documentsExists'] == true,
                    ),
                    _buildDiagnosticRow('Account Status', result['swiftDiagnostics']['accountStatus']?.toString() ?? 'Unknown'),
                    if (result['swiftDiagnostics']['fileCount'] != null)
                      _buildDiagnosticRow('Files Found', '${result['swiftDiagnostics']['fileCount']} file(s)'),
                  ]),
                ],

                // File operations
                _buildDiagnosticSection('File Operations', [
                  _buildDiagnosticRow(
                    'List Files',
                    result['listFilesSuccess'] == true ? 'Success' : 'Failed',
                    isSuccess: result['listFilesSuccess'] == true,
                    isError: result['listFilesSuccess'] == false,
                  ),
                  if (result['files'] != null && (result['files'] as List).isNotEmpty)
                    _buildDiagnosticRow('Files', (result['files'] as List).join(', ')),
                  _buildDiagnosticRow(
                    'Vaults File',
                    result['vaultsFileExists'] == true ? 'Exists' : 'Not Found',
                    isSuccess: result['vaultsFileExists'] == true,
                  ),
                  if (result['listFilesError'] != null)
                    _buildDiagnosticRow('List Files Error', result['listFilesError'].toString(), isError: true),
                  if (result['listFilesException'] != null)
                    _buildDiagnosticRow('List Files Exception', result['listFilesException'].toString(), isError: true),
                ]),

                // Errors section
                if (result['error'] != null || result['swiftDiagnosticsError'] != null)
                  _buildDiagnosticSection('Errors', [
                    if (result['error'] != null)
                      _buildDiagnosticRow('General Error', result['error'].toString(), isError: true),
                    if (result['swiftDiagnosticsError'] != null)
                      _buildDiagnosticRow('Swift Diagnostics Error', result['swiftDiagnosticsError'].toString(), isError: true),
                  ]),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog if still open
      Navigator.pop(context);

      // Log detailed error for debugging
      AppLogger.ui.severe('iCloud diagnostic failed', e);

      // Show user-friendly error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusLg),
          title: Text(
            'Diagnostic Failed',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Unable to run iCloud diagnostic. Please check your internet connection and try again.',
            style: GoogleFonts.spaceGrotesk(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDiagnosticSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.gray700,
            ),
          ),
        ),
        ...children,
        const Divider(height: 16),
      ],
    );
  }

  Widget _buildDiagnosticRow(String label, String value, {bool isError = false, bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: isSuccess ? AppColors.success : (isError ? AppColors.danger : AppColors.black),
                fontWeight: isSuccess || isError ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSyncSubtitle() {
    // Show manager status if active
    if (_icloudManagerStatus != sync_mgr.SyncStatus.idle) {
      return _icloudManagerStatus.displayName;
    }
    // Otherwise show last sync time
    return _iCloudStatus?.lastSyncFormatted ?? 'Loading...';
  }

  Widget _buildSyncStatusIndicator() {
    late Color backgroundColor;
    late Color iconColor;
    late IconData icon;
    late String text;

    switch (_icloudManagerStatus) {
      case sync_mgr.SyncStatus.scheduled:
        backgroundColor = AppColors.gray100;
        iconColor = AppColors.gray700;
        icon = Icons.schedule;
        text = 'Sync scheduled...';
        break;
      case sync_mgr.SyncStatus.syncing:
        backgroundColor = AppColors.fintechTeal.withOpacity(0.1);
        iconColor = AppColors.fintechTeal;
        icon = Icons.cloud_sync;
        text = 'Syncing to iCloud...';
        break;
      case sync_mgr.SyncStatus.success:
        backgroundColor = AppColors.success.withOpacity(0.1);
        iconColor = AppColors.success;
        icon = Icons.check_circle;
        text = 'Synced to iCloud';
        break;
      case sync_mgr.SyncStatus.error:
        backgroundColor = AppColors.danger.withOpacity(0.1);
        iconColor = AppColors.danger;
        icon = Icons.error;
        text = 'Sync failed - tap to diagnose';
        break;
      case sync_mgr.SyncStatus.idle:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_icloudManagerStatus == sync_mgr.SyncStatus.syncing)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iconColor,
              ),
            )
          else
            Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: iconColor,
            ),
          ),
          if (_icloudManagerStatus == sync_mgr.SyncStatus.error) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _diagnoseICloud,
              child: Text(
                'Diagnose',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fintechTeal,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
