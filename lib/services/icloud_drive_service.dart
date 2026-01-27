import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_error.dart';

/// iCloud Drive Service
///
/// Handles iCloud Drive file operations for vault backup.
/// Only available on iOS platform.
class ICloudDriveService {
  ICloudDriveService._internal();
  static final ICloudDriveService instance = ICloudDriveService._internal();

  static const MethodChannel _channel = MethodChannel('com.yourcompany.futureproof/cloudkit');

  static const String _vaultsFileName = 'vaults';
  static const String _settingsFileName = 'settings';

  // Keys for SharedPreferences
  static const String _lastSyncKey = 'icloud_last_sync';
  static const String _isEnabledKey = 'icloud_enabled';

  // Maximum data size (10 MB)
  static const int _maxDataSize = 10 * 1024 * 1024;

  /// Check if iCloud Drive is available (iOS only)
  static bool get isAvailable => !kIsWeb && Platform.isIOS;

  /// Validate file name (defense in depth)
  static bool _isValidFileName(String fileName) {
    if (fileName.isEmpty || fileName.length > 255) return false;

    // Only allow alphanumeric, underscore, and hyphen
    final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    return validPattern.hasMatch(fileName);
  }

  /// Check if iCloud sync is enabled
  Future<bool> isEnabled() async {
    if (!isAvailable) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isEnabledKey) ?? false;
  }

  /// Enable or disable iCloud sync
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isEnabledKey, enabled);
  }

  /// Get the last sync time
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);
    if (lastSync == null) return null;
    // Use tryParse for safe parsing
    return DateTime.tryParse(lastSync);
  }

  /// Update the last sync time
  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // MARK: - Helper Methods

  /// Save data to iCloud Drive (internal helper)
  Future<ICloudResult<void>> _saveToFile(
    String fileName,
    Map<String, dynamic> data, {
    bool updateSyncTime = true,
  }) async {
    if (!isAvailable) {
      return ICloudResult.failure('iCloud Drive is only available on iOS');
    }

    // Validate file name
    if (!_isValidFileName(fileName)) {
      return ICloudResult.failure('Invalid file name');
    }

    // Validate data
    if (data.isEmpty) {
      return ICloudResult.failure('Cannot save empty data');
    }

    try {
      final jsonString = jsonEncode(data);

      // Check data size limit
      if (jsonString.length > _maxDataSize) {
        return ICloudResult.failure('Data exceeds maximum size limit');
      }

      final result = await _channel.invokeMethod('saveToiCloudDrive', {
        'fileName': fileName,
        'jsonData': jsonString,
      });

      if (result is Map && result['success'] == true) {
        if (updateSyncTime) {
          await _updateLastSyncTime();
        }
        return ICloudResult.success(null);
      } else {
        return ICloudResult.failure('Failed to save to iCloud Drive');
      }
    } on PlatformException catch (e) {
      // Log full error for debugging
      AppLogger.service.warning('iCloud PlatformException: ${e.message}');
      // Return user-friendly message
      return ICloudResult.failure('iCloud service is unavailable');
    } catch (e) {
      // Log full error for debugging
      AppLogger.service.severe('iCloud unexpected error during save', e);
      // Return user-friendly message
      return ICloudResult.failure('Failed to complete iCloud operation');
    }
  }

  /// Load data from iCloud Drive (internal helper)
  Future<ICloudResult<Map<String, dynamic>>> _loadFromFile(
    String fileName, {
    bool updateSyncTime = true,
  }) async {
    if (!isAvailable) {
      return ICloudResult.failure('iCloud Drive is only available on iOS');
    }

    // Validate file name
    if (!_isValidFileName(fileName)) {
      return ICloudResult.failure('Invalid file name');
    }

    try {
      final result = await _channel.invokeMethod('readFromiCloudDrive', {
        'fileName': fileName,
      });

      if (result is Map && result['success'] == true) {
        final jsonString = result['data'] as String?;
        if (jsonString != null) {
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          if (updateSyncTime) {
            await _updateLastSyncTime();
          }
          return ICloudResult.success(data);
        }
      }

      return ICloudResult.failure('No data found in iCloud Drive');
    } on PlatformException catch (e) {
      // Log full error for debugging
      AppLogger.service.warning('iCloud PlatformException: ${e.message}');
      // Return user-friendly message
      return ICloudResult.failure('iCloud service is unavailable');
    } catch (e) {
      // Log full error for debugging
      AppLogger.service.severe('iCloud unexpected error during load', e);
      // Return user-friendly message
      return ICloudResult.failure('Failed to complete iCloud operation');
    }
  }

  // MARK: - Public API

  /// Save vaults data to iCloud Drive
  Future<ICloudResult<void>> saveVaults(Map<String, dynamic> data) async {
    return _saveToFile(_vaultsFileName, data);
  }

  /// Load vaults data from iCloud Drive
  Future<ICloudResult<Map<String, dynamic>>> loadVaults() async {
    return _loadFromFile(_vaultsFileName);
  }

  /// Check if vaults data exists in iCloud Drive
  Future<bool> vaultsExist() async {
    if (!isAvailable) return false;

    try {
      final result = await _channel.invokeMethod('fileExistsInICloudDrive', {
        'fileName': _vaultsFileName,
      });

      if (result is Map && result['success'] == true) {
        return result['exists'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      // Return false on any error - file doesn't exist or iCloud unavailable
      return false;
    }
  }

  /// Delete vaults data from iCloud Drive
  Future<ICloudResult<void>> deleteVaults() async {
    if (!isAvailable) {
      return ICloudResult.failure('iCloud Drive is only available on iOS');
    }

    try {
      final result = await _channel.invokeMethod('deleteFromICloudDrive', {
        'fileName': _vaultsFileName,
      });

      if (result is Map && result['success'] == true) {
        return ICloudResult.success(null);
      }

      return ICloudResult.failure('Failed to delete from iCloud Drive');
    } on PlatformException catch (e) {
      AppLogger.service.warning('iCloud PlatformException: ${e.message}');
      return ICloudResult.failure('iCloud service is unavailable');
    } catch (e) {
      AppLogger.service.severe('iCloud unexpected error during delete', e);
      return ICloudResult.failure('Failed to complete iCloud operation');
    }
  }

  /// List all files in iCloud Drive
  Future<ICloudResult<List<String>>> listFiles() async {
    if (!isAvailable) {
      return ICloudResult.failure('iCloud Drive is only available on iOS');
    }

    try {
      final result = await _channel.invokeMethod('listICloudDriveFiles');

      if (result is Map && result['success'] == true) {
        final files = result['files'] as List<dynamic>?;
        return ICloudResult.success(
          files?.map((e) => e.toString()).toList() ?? [],
        );
      }

      return ICloudResult.failure('Failed to list iCloud Drive files');
    } on PlatformException catch (e) {
      AppLogger.service.warning('iCloud PlatformException: ${e.message}');
      return ICloudResult.failure('iCloud service is unavailable');
    } catch (e) {
      AppLogger.service.severe('iCloud unexpected error during list', e);
      return ICloudResult.failure('Failed to complete iCloud operation');
    }
  }

  /// Save settings to iCloud Drive
  Future<ICloudResult<void>> saveSettings(Map<String, dynamic> data) async {
    return _saveToFile(_settingsFileName, data, updateSyncTime: false);
  }

  /// Load settings from iCloud Drive
  Future<ICloudResult<Map<String, dynamic>>> loadSettings() async {
    return _loadFromFile(_settingsFileName, updateSyncTime: false);
  }

  /// Diagnostic: Check if native iCloud methods are available
  static Future<Map<String, dynamic>> diagnose() async {
    final result = <String, dynamic>{
      'platform': Platform.operatingSystem,
      'isIOS': Platform.isIOS,
      'isWeb': kIsWeb,
      'isAvailable': isAvailable,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (!isAvailable) {
      result['error'] = 'iCloud Drive is only available on iOS';
      return result;
    }

    // Test 1: Method channel response
    try {
      final testResult = await _channel.invokeMethod('isAvailable');
      result['nativeMethodAvailable'] = testResult == true;
      result['nativeMethodResult'] = testResult;
    } catch (e) {
      result['nativeMethodAvailable'] = false;
      result['nativeMethodError'] = e.toString();
    }

    // Test 2: Check if enabled
    try {
      result['enabled'] = await isEnabled();
    } catch (e) {
      result['enabled'] = false;
      result['enabledError'] = e.toString();
    }

    // Test 3: Get detailed diagnostics from Swift
    try {
      final diagResult = await _channel.invokeMethod('getDiagnostics');
      if (diagResult is Map && diagResult['success'] == true) {
        result['swiftDiagnostics'] = diagResult['diagnostics'];
      }
    } catch (e) {
      result['swiftDiagnosticsError'] = e.toString();
    }

    // Test 4: Try to list files
    try {
      final listResult = await instance.listFiles();
      result['listFilesSuccess'] = listResult.isSuccess;
      if (listResult.isSuccess) {
        result['files'] = listResult.data ?? [];
        result['fileCount'] = listResult.data?.length ?? 0;
      } else {
        result['listFilesError'] = listResult.error;
      }
    } catch (e) {
      result['listFilesException'] = e.toString();
    }

    // Test 5: Check if vaults file exists
    try {
      final exists = await instance.vaultsExist();
      result['vaultsFileExists'] = exists;
    } catch (e) {
      result['vaultsFileExistsError'] = e.toString();
    }

    return result;
  }
}

/// Result wrapper for iCloud Drive operations
class ICloudResult<T> {
  final T? data;
  final String? error;

  ICloudResult.success(this.data)
      : error = null,
        _success = true;

  ICloudResult.failure(this.error)
      : data = null,
        _success = false;

  final bool _success;

  bool get isSuccess => _success;
  bool get isFailure => !_success;

  /// Get the data, throws if operation failed
  T get dataOrThrow {
    if (isFailure) {
      throw AppError(
        type: AppErrorType.icloud,
        message: error ?? 'Unknown iCloud error',
      );
    }
    return data as T;
  }
}
