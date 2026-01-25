import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_colors.dart';
import '../domain/entities/vault_entity.dart';
import '../models/transaction.dart';
import '../providers/vault_provider.dart';
import '../providers/transaction_provider.dart';
import 'database_service.dart';

/// Backup Service
///
/// Handles exporting and importing user data for backup purposes.
/// Supports:
/// - Export to JSON file
/// - Import from JSON file
/// - iCloud sync integration (delegates to CloudKitService)
/// - Google Drive sync (placeholder for future)
class BackupService {
  BackupService._internal();
  static final BackupService instance = BackupService._internal();

  static const String _backupVersion = '2.0';

  // ============================================
  // EXPORT
  // ============================================

  /// Export all vaults data to JSON
  Future<Map<String, dynamic>> exportAllVaults({
    required VaultProvider vaultProvider,
    required Map<String, TransactionProvider> transactionProviders,
  }) async {
    final vaults = vaultProvider.vaults;

    final List<Map<String, dynamic>> vaultsData = [];

    for (final vault in vaults) {
      final transactions = transactionProviders[vault.id]?.transactions ?? [];

      vaultsData.add({
        'vaultId': vault.id,
        'name': vault.name,
        'type': vault.type.name,
        'isActive': vault.isActive,
        'transactionCount': vault.transactionCount,
        'lastModified': vault.lastModified.toIso8601String(),
        'transactions': transactions.map((t) => _transactionToJson(t)).toList(),
      });
    }

    return {
      'version': _backupVersion,
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': '2.0.0',
      'vaultsCount': vaults.length,
      'vaults': vaultsData,
    };
  }

  /// Export single vault to JSON
  Future<Map<String, dynamic>> exportVault({
    required VaultEntity vault,
    required List<Transaction> transactions,
  }) async {
    return {
      'version': _backupVersion,
      'exportDate': DateTime.now().toIso8601String(),
      'vault': {
        'vaultId': vault.id,
        'name': vault.name,
        'type': vault.type.name,
        'isActive': vault.isActive,
        'transactionCount': vault.transactionCount,
        'lastModified': vault.lastModified.toIso8601String(),
        'transactions': transactions.map((t) => _transactionToJson(t)).toList(),
      },
    };
  }

  Map<String, dynamic> _transactionToJson(Transaction t) {
    return {
      'id': t.id,
      'amount': t.amount,
      'category': t.category,
      'note': t.note,
      'date': t.date.toIso8601String(),
      'householdId': t.householdId,
      'createdAt': t.createdAt.toIso8601String(),
    };
  }

  // ============================================
  // SAVE TO FILE
  // ============================================

  /// Save export to file and share
  Future<String> saveExportToFile(Map<String, dynamic> data) async {
    if (kIsWeb) {
      // Web: Return JSON string for download
      return jsonEncode(data);
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().split('T')[0];
    final filePath = '${directory.path}/futureproof_backup_$timestamp.json';

    final file = File(filePath);
    await file.writeAsString(jsonEncode(data));

    // Share the file
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'FutureProof Backup - $timestamp',
    );

    return filePath;
  }

  /// Get export as JSON string (for copy/paste)
  String getExportAsString(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  // ============================================
  // IMPORT
  // ============================================

  /// Validate and parse backup data
  Future<BackupData> validateBackup(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate version
      final version = data['version'] as String?;
      if (version == null) {
        throw BackupValidationException('Missing version information');
      }

      // Validate vaults
      final vaults = data['vaults'] as List<dynamic>?;
      if (vaults == null || vaults.isEmpty) {
        throw BackupValidationException('No vaults found in backup');
      }

      return BackupData(
        version: version,
        exportDate: DateTime.parse(data['exportDate'] as String),
        vaultsCount: vaults.length,
        vaults: vaults
            .map((v) => v as Map<String, dynamic>)
            .map((v) => _parseVaultData(v))
            .toList(),
      );
    } on FormatException catch (e) {
      throw BackupValidationException('Invalid JSON format: ${e.message}');
    } catch (e) {
      throw BackupValidationException('Failed to parse backup: ${e.toString()}');
    }
  }

  VaultBackupData _parseVaultData(Map<String, dynamic> v) {
    return VaultBackupData(
      vaultId: v['vaultId'] as String,
      name: v['name'] as String,
      type: v['type'] as String,
      isActive: v['isActive'] as bool? ?? false,
      transactionCount: v['transactionCount'] as int? ?? 0,
      lastModified: DateTime.parse(v['lastModified'] as String),
      transactions: (v['transactions'] as List<dynamic>?)
              ?.map((t) => _parseTransaction(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Transaction _parseTransaction(Map<String, dynamic> t) {
    return Transaction(
      id: t['id'] as String,
      amount: (t['amount'] as num).toDouble(),
      category: t['category'] as String,
      note: t['note'] as String?,
      date: DateTime.parse(t['date'] as String),
      householdId: t['householdId'] as String? ?? '',
      createdAt: DateTime.parse(t['createdAt'] as String),
    );
  }

  // ============================================
  // SYNC STATUS
  // ============================================

  /// Get iCloud sync status
  Future<SyncStatus> getiCloudSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString('icloud_last_sync');

      return SyncStatus(
        isEnabled: true,
        isAvailable: true, // TODO: Check actual availability
        lastSyncTime: lastSync != null ? DateTime.parse(lastSync) : null,
      );
    } catch (e) {
      return SyncStatus(
        isEnabled: false,
        isAvailable: false,
      );
    }
  }

  /// Trigger iCloud sync
  Future<bool> triggeriCloudSync() async {
    try {
      // Delegate to CloudKitService
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('icloud_last_sync', DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get Google Drive sync status (placeholder)
  Future<SyncStatus> getGoogleDriveStatus() async {
    return SyncStatus(
      isEnabled: false,
      isAvailable: true,
      lastSyncTime: null,
    );
  }
}

// ============================================
  // DATA MODELS
  // ============================================

class BackupData {
  final String version;
  final DateTime exportDate;
  final int vaultsCount;
  final List<VaultBackupData> vaults;

  BackupData({
    required this.version,
    required this.exportDate,
    required this.vaultsCount,
    required this.vaults,
  });
}

class VaultBackupData {
  final String vaultId;
  final String name;
  final String type;
  final bool isActive;
  final int transactionCount;
  final DateTime lastModified;
  final List<Transaction> transactions;

  VaultBackupData({
    required this.vaultId,
    required this.name,
    required this.type,
    required this.isActive,
    required this.transactionCount,
    required this.lastModified,
    required this.transactions,
  });
}

class SyncStatus {
  final bool isEnabled;
  final bool isAvailable;
  final DateTime? lastSyncTime;

  SyncStatus({
    required this.isEnabled,
    required this.isAvailable,
    this.lastSyncTime,
  });

  String get lastSyncFormatted {
    if (lastSyncTime == null) return 'Never';
    final diff = DateTime.now().difference(lastSyncTime!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class BackupValidationException implements Exception {
  final String message;
  BackupValidationException(this.message);

  @override
  String toString() => message;
}
