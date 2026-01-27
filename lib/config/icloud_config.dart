/// iCloud Configuration
///
/// Central configuration for iCloud sync functionality.
/// These values must match the iOS-side configuration in CloudKitConfig.swift.
library;

/// iCloud configuration constants
class ICloudConfig {
  ICloudConfig._();

  /// Method channel name for CloudKit communication
  /// MUST match: CloudKitConfig.methodChannelName in CloudKitPlugin.swift
  static const String methodChannelName = 'com.yourcompany.futureproof/cloudkit';

  /// Maximum data size for iCloud Drive files (10 MB)
  /// iCloud Drive has limits on file sizes
  static const int maxDataSize = 10 * 1024 * 1024;

  /// File names for iCloud Drive storage
  static const String vaultsFileName = 'vaults';
  static const String settingsFileName = 'settings';

  /// SharedPreferences keys for iCloud settings
  static const String lastSyncKey = 'icloud_last_sync';
  static const String isEnabledKey = 'icloud_enabled';

  /// Debounce delay before triggering sync after changes
  static const Duration syncDebounceDelay = Duration(seconds: 2);

  /// Maximum time between forced syncs
  static const Duration maxSyncInterval = Duration(minutes: 5);

  /// Number of retry attempts for failed syncs
  static const int maxSyncRetries = 3;

  /// Base delay for exponential backoff (in milliseconds)
  static const Duration baseRetryDelay = Duration(seconds: 1);

  /// Status reset delay after successful sync
  static const Duration successStatusResetDelay = Duration(seconds: 2);

  /// Status reset delay after failed sync
  static const Duration errorStatusResetDelay = Duration(seconds: 5);
}
