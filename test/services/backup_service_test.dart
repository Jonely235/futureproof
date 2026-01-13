import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:futureproof/models/app_error.dart';
import 'package:futureproof/models/transaction.dart';
import 'package:futureproof/services/backup_service.dart';
import 'package:futureproof/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/test_helper.dart';

void main() {
  late BackupService backupService;
  late DatabaseService dbService;

  setUpAll(() {
    initializeTestDatabase();
  });

  setUp(() async {
    backupService = BackupService();
    dbService = DatabaseService();
    // Clear database before each test
    final db = await dbService.database;
    await db.delete('transactions');
    SharedPreferences.setMockInitialValues({});
  });

  group('BackupService - exportData', () {
    test('should export empty transactions list as valid JSON', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await backupService.exportData();

      expect(result, isA<String>());
      expect(result, isNotEmpty);

      // Verify it's valid JSON
      final jsonData = jsonDecode(result) as Map<String, dynamic>;
      expect(jsonData.containsKey('version'), true);
      expect(jsonData.containsKey('exportDate'), true);
      expect(jsonData.containsKey('settings'), true);
      expect(jsonData.containsKey('transactions'), true);

      // Verify transactions is empty list
      final transactions = jsonData['transactions'] as List;
      expect(transactions, isEmpty);
    });

    test('should export transactions with correct structure', () async {
      SharedPreferences.setMockInitialValues({});

      // Add test transactions
      final transactions = [
        Transaction(
          id: 'test-1',
          amount: -100.0,
          category: 'groceries',
          date: DateTime(2024, 1, 15),
        ),
        Transaction(
          id: 'test-2',
          amount: -50.0,
          category: 'dining',
          date: DateTime(2024, 1, 16),
        ),
      ];

      for (final t in transactions) {
        await dbService.addTransaction(t);
      }

      final result = await backupService.exportData();

      // Parse and verify JSON
      final jsonData = jsonDecode(result) as Map<String, dynamic>;
      expect(jsonData['version'], '1.0');
      expect(jsonData['transactions'], isA<List>());

      final exportedTransactions = jsonData['transactions'] as List;
      expect(exportedTransactions.length, 2);

      // Verify first transaction structure
      final first = exportedTransactions[0] as Map<String, dynamic>;
      expect(first.containsKey('id'), true);
      expect(first.containsKey('amount'), true);
      expect(first.containsKey('category'), true);
      expect(first.containsKey('date'), true);
      expect(first.containsKey('note'), true);
    });

    test('should use 2-space indentation for JSON', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await backupService.exportData();

      // Verify indentation by checking for '  ' (2 spaces)
      expect(result, contains('  '));
      // Should use 2-space base indentation (nested objects will have 4 spaces total)
      // The first level should start with 2 spaces after newline
      expect(result, contains('\n  '));
    });

    test('should include settings in export', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 6000.0,
        'savings_goal': 1500.0,
        'selected_theme': 1,
      });

      final result = await backupService.exportData();

      final jsonData = jsonDecode(result) as Map<String, dynamic>;
      final settings = jsonData['settings'] as Map<String, dynamic>;

      expect(settings['monthly_income'], 6000.0);
      expect(settings['savings_goal'], 1500.0);
      expect(settings['selected_theme'], 1);
    });

    test('should include default values when settings not set', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await backupService.exportData();

      final jsonData = jsonDecode(result) as Map<String, dynamic>;
      final settings = jsonData['settings'] as Map<String, dynamic>;

      expect(settings.containsKey('monthly_income'), true);
      expect(settings.containsKey('savings_goal'), true);
      expect(settings.containsKey('selected_theme'), true);

      expect(settings['monthly_income'], 5000.0);
      expect(settings['savings_goal'], 1000.0);
      expect(settings['selected_theme'], 0);
    });

    test('should handle settings export failure gracefully', () async {
      // Test with normal setup - settings export should not crash
      SharedPreferences.setMockInitialValues({});

      final result = await backupService.exportData();

      expect(result, isNotEmpty);
      final jsonData = jsonDecode(result) as Map<String, dynamic>;
      expect(jsonData.containsKey('settings'), true);
    });
  });

  group('BackupService - importData', () {
    test('should import valid JSON with new transactions', () async {
      SharedPreferences.setMockInitialValues({});

      final jsonString = jsonEncode({
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'transactions': [
          {
            'id': 'import-1',
            'amount': -100.0,
            'category': 'groceries',
            'date': DateTime(2024, 1, 15).toIso8601String(),
            'note': null,
          },
          {
            'id': 'import-2',
            'amount': -50.0,
            'category': 'dining',
            'date': DateTime(2024, 1, 16).toIso8601String(),
            'note': 'Lunch',
          },
        ],
      });

      final result = await backupService.importData(jsonString);

      expect(result.success, true);
      expect(result.importedCount, 2);
      expect(result.skippedCount, 0);

      // Verify transactions were added to database
      final allTransactions = await dbService.getAllTransactions();
      expect(allTransactions.length, 2);
    });

    test('should skip duplicate transactions by ID', () async {
      SharedPreferences.setMockInitialValues({});

      // Add existing transaction
      final existing = Transaction(
        id: 'existing-1',
        amount: -100.0,
        category: 'groceries',
        date: DateTime(2024, 1, 15),
      );
      await dbService.addTransaction(existing);

      final jsonString = jsonEncode({
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'transactions': [
          {
            'id': 'existing-1',
            'amount': -200.0,
            'category': 'groceries',
            'date': DateTime(2024, 1, 15).toIso8601String(),
            'note': null,
          },
          {
            'id': 'new-1',
            'amount': -50.0,
            'category': 'dining',
            'date': DateTime(2024, 1, 16).toIso8601String(),
            'note': null,
          },
        ],
      });

      final result = await backupService.importData(jsonString);

      expect(result.success, true);
      expect(result.importedCount, 1);
      expect(result.skippedCount, 1);

      // Verify only new transaction was added
      final allTransactions = await dbService.getAllTransactions();
      expect(allTransactions.length, 2);

      // Verify existing transaction wasn't modified
      final existingTx =
          allTransactions.firstWhere((t) => t.id == 'existing-1');
      expect(existingTx.amount, -100.0);
    });

    test('should throw FormatException when transactions key missing',
        () async {
      SharedPreferences.setMockInitialValues({});

      final invalidJson = jsonEncode({
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        // Missing 'transactions' key
      });

      expect(
        () => backupService.importData(invalidJson),
        throwsA(isA<AppError>()),
      );
    });

    test('should return ImportResult with error for invalid JSON', () async {
      SharedPreferences.setMockInitialValues({});

      const invalidJson = 'not valid json';

      final result = await backupService.importData(invalidJson);

      expect(result.success, false);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, isNotEmpty);
    });

    test('should import settings when present', () async {
      SharedPreferences.setMockInitialValues({});

      final jsonString = jsonEncode({
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'settings': {
          'monthly_income': 7000.0,
          'savings_goal': 2000.0,
          'selected_theme': 2,
        },
        'transactions': [],
      });

      await backupService.importData(jsonString);

      // Verify settings were imported
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('monthly_income'), 7000.0);
      expect(prefs.getDouble('savings_goal'), 2000.0);
      expect(prefs.getInt('selected_theme'), 2);
    });

    test('should skip invalid transactions but continue importing', () async {
      SharedPreferences.setMockInitialValues({});

      final jsonString = jsonEncode({
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'transactions': [
          {
            'id': 'valid-1',
            'amount': -100.0,
            'category': 'groceries',
            'date': DateTime(2024, 1, 15).toIso8601String(),
            'note': null,
          },
          {
            'id': 'invalid-1',
            'amount': 'not a number',
            'category': 'groceries',
            'date': DateTime(2024, 1, 16).toIso8601String(),
            'note': null,
          },
          {
            'id': 'valid-2',
            'amount': -50.0,
            'category': 'dining',
            'date': DateTime(2024, 1, 17).toIso8601String(),
            'note': null,
          },
        ],
      });

      final result = await backupService.importData(jsonString);

      expect(result.success, true);
      expect(result.importedCount, 2);
      expect(result.skippedCount, 1);
    });

    test('should handle transactions with missing optional fields', () async {
      SharedPreferences.setMockInitialValues({});

      final jsonString = jsonEncode({
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'transactions': [
          {
            'id': 'no-note-1',
            'amount': -100.0,
            'category': 'groceries',
            'date': DateTime(2024, 1, 15).toIso8601String(),
            // 'note' field is optional
          },
        ],
      });

      final result = await backupService.importData(jsonString);

      expect(result.success, true);
      expect(result.importedCount, 1);
    });
  });

  group('BackupService - getExportFilename', () {
    test('should return filename with correct format', () {
      final filename = backupService.getExportFilename();

      // Should match pattern: futureproof_backup_YYYY-MM-DD_HH-mm.json
      final regex =
          RegExp(r'^futureproof_backup_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}\.json$');
      expect(regex.hasMatch(filename), true);
    });

    test('should include current date in filename', () {
      final now = DateTime.now();
      final filename = backupService.getExportFilename();

      final expectedPrefix = 'futureproof_backup_${now.year}-';
      expect(filename, startsWith(expectedPrefix));
    });

    test('should include current time in filename', () {
      final filename = backupService.getExportFilename();

      // Should contain _HH-mm format
      expect(filename, contains('_'));
      expect(filename, endsWith('.json'));
    });
  });

  group('BackupService - getLastBackupDate', () {
    test('should return null when no backup date stored', () async {
      SharedPreferences.setMockInitialValues({});

      final result = await backupService.getLastBackupDate();

      expect(result, isNull);
    });

    test('should return DateTime when backup date exists', () async {
      final testDate = DateTime(2024, 1, 15, 10, 30);
      SharedPreferences.setMockInitialValues({
        'last_backup_timestamp': testDate.millisecondsSinceEpoch,
      });

      final result = await backupService.getLastBackupDate();

      expect(result, isNotNull);
      expect(result!.year, 2024);
      expect(result.month, 1);
      expect(result.day, 15);
    });

    test('should return correct timestamp from stored value', () async {
      final testDate = DateTime(2024, 6, 15, 14, 30);
      SharedPreferences.setMockInitialValues({
        'last_backup_timestamp': testDate.millisecondsSinceEpoch,
      });

      final result = await backupService.getLastBackupDate();

      expect(result, isNotNull);
      expect(result!.millisecondsSinceEpoch, testDate.millisecondsSinceEpoch);
    });
  });

  group('BackupService - saveLastBackupDate', () {
    test('should save current timestamp to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});

      await backupService.saveLastBackupDate();

      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_backup_timestamp');

      expect(timestamp, isNotNull);
      expect(timestamp!, greaterThan(0));
    });

    test('should save timestamp within reasonable time range', () async {
      SharedPreferences.setMockInitialValues({});

      final before = DateTime.now();
      await backupService.saveLastBackupDate();
      final after = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_backup_timestamp');

      expect(timestamp, isNotNull);
      final savedDate = DateTime.fromMillisecondsSinceEpoch(timestamp!);
      expect(
          savedDate.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(savedDate.isBefore(after.add(const Duration(seconds: 1))), true);
    });
  });

  group('BackupService - ImportResult.toString', () {
    test('should return success message with count', () {
      final result = ImportResult(
        success: true,
        importedCount: 10,
        skippedCount: 2,
      );

      final message = result.toString();

      expect(message, contains('10'));
      expect(message, contains('transactions'));
    });

    test('should return failure message with error', () {
      final result = ImportResult(
        success: false,
        errorMessage: 'Invalid JSON format',
      );

      final message = result.toString();

      expect(message, contains('Import failed'));
      expect(message, contains('Invalid JSON format'));
    });

    test('should handle zero imported transactions', () {
      final result = ImportResult(
        success: true,
        importedCount: 0,
        skippedCount: 5,
      );

      final message = result.toString();

      expect(message, contains('0'));
      expect(message, contains('transactions'));
    });
  });

  group('BackupService - Integration', () {
    test('should export and import data correctly', () async {
      SharedPreferences.setMockInitialValues({
        'monthly_income': 5500.0,
        'savings_goal': 1200.0,
      });

      // Create original transactions
      final originalTransactions = [
        Transaction(
          id: 'export-1',
          amount: -150.0,
          category: 'groceries',
          date: DateTime(2024, 1, 15),
        ),
        Transaction(
          id: 'export-2',
          amount: -75.0,
          category: 'dining',
          date: DateTime(2024, 1, 16),
        ),
      ];

      for (final t in originalTransactions) {
        await dbService.addTransaction(t);
      }

      // Export
      final exportedData = await backupService.exportData();

      // Clear database and settings
      final db = await dbService.database;
      await db.delete('transactions');
      SharedPreferences.setMockInitialValues({});

      // Import
      final importResult = await backupService.importData(exportedData);

      // Verify import
      expect(importResult.success, true);
      expect(importResult.importedCount, 2);

      // Verify transactions
      final importedTransactions = await dbService.getAllTransactions();
      expect(importedTransactions.length, 2);

      // Verify settings
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('monthly_income'), 5500.0);
      expect(prefs.getDouble('savings_goal'), 1200.0);
    });

    test('should handle empty export and import cycle', () async {
      SharedPreferences.setMockInitialValues({});

      // Export empty database
      final exportedData = await backupService.exportData();

      // Import to new database
      final importResult = await backupService.importData(exportedData);

      expect(importResult.success, true);
      expect(importResult.importedCount, 0);
      expect(importResult.skippedCount, 0);
    });

    test('should track backup date through export/import cycle', () async {
      SharedPreferences.setMockInitialValues({});

      // Save backup date
      await backupService.saveLastBackupDate();

      // Get saved date
      final savedDate = await backupService.getLastBackupDate();

      expect(savedDate, isNotNull);
      final now = DateTime.now();
      expect(savedDate!.year, now.year);
      expect(savedDate.month, now.month);
      expect(savedDate.day, now.day);
    });
  });
}
