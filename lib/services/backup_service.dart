import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_error.dart';
import '../models/transaction.dart';
import '../utils/app_logger.dart';
import '../utils/error_tracker.dart';
import 'database_service.dart';

/// Service for exporting and importing app data
class BackupService {
  final DatabaseService _db = DatabaseService();

  /// Export all transactions to JSON string
  Future<String> exportData() async {
    try {
      final transactions = await _db.getAllTransactions();

      // Create backup data structure
      final backupData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'settings': await _exportSettings(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      AppLogger.backup.info(
          '✅ Exported ${transactions.length} transactions at ${backupData['exportDate']}');
      return jsonString;
    } catch (e, st) {
      AppLogger.backup.severe('Failed to export data', e);
      if (e is AppError) {
        ErrorTracker()
            .trackError(e, 'BackupService.exportData', stackTrace: st);
        rethrow;
      }
      final appError = AppError(
        type: AppErrorType.backup,
        message: 'Failed to export data',
        technicalDetails: 'Export operation failed',
        originalError: e,
        stackTrace: st,
      );
      ErrorTracker()
          .trackError(appError, 'BackupService.exportData', stackTrace: st);
      throw appError;
    }
  }

  /// Export settings to JSON
  Future<Map<String, dynamic>> _exportSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'monthly_income': prefs.getDouble('monthly_income') ?? 5000.0,
        'savings_goal': prefs.getDouble('savings_goal') ?? 1000.0,
        'selected_theme': prefs.getInt('selected_theme') ?? 0,
      };
    } catch (e) {
      AppLogger.backup.severe('Failed to export settings', e);
      // Graceful degradation - return empty map for non-critical settings
      return {};
    }
  }

  /// Import data from JSON string
  /// Returns number of transactions imported
  Future<ImportResult> importData(String jsonString) async {
    try {
      // Parse JSON
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate structure
      if (!jsonData.containsKey('transactions')) {
        throw const AppError(
          type: AppErrorType.validation,
          message: 'Invalid backup file',
          technicalDetails: 'Missing transactions field in backup data',
        );
      }

      final transactionsList = jsonData['transactions'] as List;
      int importedCount = 0;
      int skippedCount = 0;

      // Import transactions
      for (final item in transactionsList) {
        try {
          final transactionMap = item as Map<String, dynamic>;

          // Create transaction from JSON
          final transaction = Transaction(
            id: transactionMap['id'] as String,
            amount: (transactionMap['amount'] as num).toDouble(),
            category: transactionMap['category'] as String,
            date: DateTime.parse(transactionMap['date'] as String),
            note: transactionMap['note'] as String?,
          );

          // Check if transaction already exists by loading all and checking
          final allTransactions = await _db.getAllTransactions();
          final exists = allTransactions.any((t) => t.id == transaction.id);

          if (!exists) {
            await _db.addTransaction(transaction);
            importedCount++;
          } else {
            skippedCount++;
          }
        } catch (e, st) {
          // Log warning for individual transaction failures but continue
          AppLogger.backup
              .warning('Skipping invalid transaction during import', e, st);
          skippedCount++;
          continue;
        }
      }

      // Import settings if present
      if (jsonData.containsKey('settings')) {
        await _importSettings(jsonData['settings'] as Map<String, dynamic>);
      }

      AppLogger.backup.info(
          '✅ Imported $importedCount transactions, skipped $skippedCount');

      return ImportResult(
        success: true,
        importedCount: importedCount,
        skippedCount: skippedCount,
      );
    } catch (e) {
      AppLogger.backup.severe('Failed to import data', e);
      if (e is AppError) rethrow;
      return ImportResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Import settings from JSON
  Future<void> _importSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (settings.containsKey('monthly_income')) {
        await prefs.setDouble(
          'monthly_income',
          (settings['monthly_income'] as num).toDouble(),
        );
      }

      if (settings.containsKey('savings_goal')) {
        await prefs.setDouble(
          'savings_goal',
          (settings['savings_goal'] as num).toDouble(),
        );
      }

      if (settings.containsKey('selected_theme')) {
        await prefs.setInt(
          'selected_theme',
          settings['selected_theme'] as int,
        );
      }
    } catch (e) {
      AppLogger.backup.severe('Failed to import settings', e);
      if (e is AppError) {
        ErrorTracker().trackError(e, 'BackupService._importSettings');
        rethrow;
      }
      final appError = AppError(
        type: AppErrorType.backup,
        message: 'Failed to import settings',
        technicalDetails: 'Settings import failed',
        originalError: e,
      );
      ErrorTracker().trackError(appError, 'BackupService._importSettings');
      throw appError;
    }
  }

  /// Get formatted filename for export
  String getExportFilename() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd_HH-mm');
    return 'futureproof_backup_${formatter.format(now)}.json';
  }

  /// Get last backup timestamp from SharedPreferences
  Future<DateTime?> getLastBackupDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_backup_timestamp');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      AppLogger.backup.severe('Failed to get last backup date', e);
      return null;
    }
  }

  /// Save last backup timestamp
  Future<void> saveLastBackupDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'last_backup_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      AppLogger.backup.severe('Failed to save last backup date', e);
    }
  }
}

/// Result of import operation
class ImportResult {
  final bool success;
  final int importedCount;
  final int skippedCount;
  final String? errorMessage;

  ImportResult({
    required this.success,
    this.importedCount = 0,
    this.skippedCount = 0,
    this.errorMessage,
  });

  @override
  String toString() {
    if (success) {
      return 'Imported $importedCount transactions';
    } else {
      return 'Import failed: $errorMessage';
    }
  }
}
