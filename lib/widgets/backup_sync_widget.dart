import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../design/design_tokens.dart';
import '../providers/vault_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/backup_service.dart';

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
  SyncStatus? _iCloudStatus;
  SyncStatus? _googleDriveStatus;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
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
        // iCloud Sync
        _buildSyncTile(
          icon: Icons.cloud,
          title: 'iCloud Sync',
          subtitle: _iCloudStatus?.lastSyncFormatted ?? 'Loading...',
          isEnabled: _iCloudStatus?.isEnabled ?? false,
          isAvailable: _iCloudStatus?.isAvailable ?? false,
          isLoading: _isSyncing,
          onTap: _iCloudStatus?.isAvailable == true ? _triggeriCloudSync : null,
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
    setState(() => _isSyncing = true);
    try {
      final vaultProvider = context.read<VaultProvider>();
      final transactionProviders = {
        for (final vault in vaultProvider.vaults)
          vault.id: context.read<TransactionProvider>()
      };

      await BackupService.instance.triggeriCloudSync(
        vaultProvider: vaultProvider,
        transactionProviders: transactionProviders,
      );
      await _loadSyncStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced to iCloud',
              style: GoogleFonts.spaceGrotesk(),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sync failed: ${e.toString()}',
              style: GoogleFonts.spaceGrotesk(),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Export failed: ${e.toString()}',
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
}
