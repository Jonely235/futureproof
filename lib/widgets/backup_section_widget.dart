import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';
import '../services/backup_service.dart';
import '../utils/app_logger.dart';

/// Backup Section Widget
///
/// Displays backup status and provides export/import functionality.
/// Extracted from SettingsScreen for better modularity and testability.
class BackupSectionWidget extends StatelessWidget {
  const BackupSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.widgets.info('BackupSectionWidget: Building widget');
    final backupService = BackupService();

    return FutureBuilder<DateTime?>(
      future: backupService.getLastBackupDate(),
      builder: (context, snapshot) {
        final lastBackup = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.cloud_upload,
                  color: AppColors.black,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Backup',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      if (lastBackup != null)
                        Text(
                          'Last backup: ${_formatDate(lastBackup)}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: AppColors.gray700,
                          ),
                        )
                      else
                        Text(
                          'No backups yet',
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
                    onPressed: () => _exportData(context, backupService),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(
                      'Export',
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
                    onPressed: () => _importData(context, backupService),
                    icon: const Icon(Icons.upload, size: 18),
                    label: Text(
                      'Import',
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
      },
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

  Future<void> _exportData(
      BuildContext context, BackupService backupService) async {
    AppLogger.widgets.info('BackupSectionWidget: Export data requested');
    HapticFeedback.lightImpact();

    try {
      // Export data
      final jsonData = await backupService.exportData();
      final filename = backupService.getExportFilename();

      AppLogger.widgets
          .info('BackupSectionWidget: Export successful, filename: $filename');

      // Show success dialog with data
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your data has been exported successfully.'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jsonData,
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Copy this data and save it to a file:'),
                const SizedBox(height: 8),
                Text(
                  filename,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonData));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data copied to clipboard!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Copy to Clipboard'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }

      // Save last backup timestamp
      await backupService.saveLastBackupDate();
    } catch (e) {
      AppLogger.widgets.info('BackupSectionWidget: Export failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData(
      BuildContext context, BackupService backupService) async {
    AppLogger.widgets.info('BackupSectionWidget: Import data requested');
    HapticFeedback.lightImpact();

    // Show text input dialog
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your backup JSON data below:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Paste JSON data here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        // Import data
        AppLogger.widgets.info('BackupSectionWidget: Importing data...');
        final importResult = await backupService.importData(result);

        if (context.mounted) {
          if (importResult.success) {
            AppLogger.widgets.info(
                'BackupSectionWidget: Import successful - ${importResult.importedCount} transactions imported');
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Import Successful'),
                content: Text(
                  'Imported ${importResult.importedCount} transactions\n'
                  '${importResult.skippedCount > 0 ? 'Skipped ${importResult.skippedCount} duplicates' : ''}',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            AppLogger.widgets.info(
                'BackupSectionWidget: Import failed - ${importResult.errorMessage}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Import failed: ${importResult.errorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        AppLogger.widgets.info('BackupSectionWidget: Import error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
