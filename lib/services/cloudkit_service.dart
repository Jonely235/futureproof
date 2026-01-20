import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import '../utils/app_logger.dart';

/// CloudKit service for iOS iCloud sync
///
/// Provides Flutter interface to native CloudKit operations.
/// Only available on iOS platform.
class CloudKitService {
  static const _channel = MethodChannel('com.yourcompany.futureproof/cloudkit');
  static final _log = Logger('CloudKitService');

  static CloudKitService? _instance;
  bool? _isAvailableCache;

  CloudKitService._();

  /// Get singleton instance
  factory CloudKitService() {
    _instance ??= CloudKitService._();
    return _instance!;
  }

  /// Check if CloudKit is available (iOS only)
  ///
  /// Returns false on non-iOS platforms.
  Future<bool> isAvailable() async {
    if (kIsWeb || !Platform.isIOS) {
      return false;
    }

    if (_isAvailableCache != null) {
      return _isAvailableCache!;
    }

    try {
      final result = await _channel.invokeMethod('isAvailable');
      _isAvailableCache = result as bool? ?? false;
      AppLogger.vaults.info('☁️ CloudKit available: $_isAvailableCache');
      return _isAvailableCache!;
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error checking CloudKit availability', e, st);
      _isAvailableCache = false;
      return false;
    }
  }

  /// Fetch vault index from CloudKit
  ///
  /// Returns a map containing vaults list and active vault ID.
  /// Returns null on non-iOS platforms or on error.
  Future<Map<String, dynamic>?> fetchVaultIndex() async {
    if (!await isAvailable()) {
      _log.warning('CloudKit not available, cannot fetch vault index');
      return null;
    }

    try {
      final result = await _channel.invokeMethod('fetchVaultIndex');
      if (result == null) return null;

      final indexData = result as Map<String, dynamic>;
      AppLogger.vaults.info('📥 Fetched vault index from CloudKit');
      return indexData;
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error fetching vault index', e, st);
      return null;
    }
  }

  /// Upload vault metadata to CloudKit
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> uploadVaultMetadata({
    required String vaultId,
    required Map<String, dynamic> metadata,
  }) async {
    if (!await isAvailable()) {
      _log.warning('CloudKit not available, cannot upload vault metadata');
      return false;
    }

    try {
      await _channel.invokeMethod('uploadVaultMetadata', {
        'vaultId': vaultId,
        'metadata': metadata,
      });
      AppLogger.vaults.info('☁️ Uploaded vault metadata: $vaultId');
      return true;
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error uploading vault metadata', e, st);
      return false;
    }
  }

  /// Delete vault metadata from CloudKit
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> deleteVaultMetadata(String vaultId) async {
    if (!await isAvailable()) {
      _log.warning('CloudKit not available, cannot delete vault metadata');
      return false;
    }

    try {
      await _channel.invokeMethod('deleteVaultMetadata', {
        'vaultId': vaultId,
      });
      AppLogger.vaults.info('🗑️ Deleted vault metadata from CloudKit: $vaultId');
      return true;
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error deleting vault metadata', e, st);
      return false;
    }
  }

  /// Reset availability cache
  ///
  /// Call this after iCloud account status changes.
  void resetAvailabilityCache() {
    _isAvailableCache = null;
  }
}
