import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/cloud_backup_repository.dart';
import '../../services/backup_service.dart';
import '../../utils/app_logger.dart';
import '../../models/app_error.dart';
import '../services/sync_queue_service.dart';

/// Firebase implementation of CloudBackupRepository
///
/// Pragmatic approach: Reuses BackupService for serialization,
/// uses anonymous auth, last-write-wins conflict resolution.
class FirebaseBackupRepositoryImpl implements CloudBackupRepository {
  // Lazy getters - only access Firebase when actually needed
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  final BackupService _backupService = BackupService();
  final SyncQueueService _syncQueue = SyncQueueService();

  final _statusController = StreamController<BackupStatus>.broadcast();
  String? _anonymousUid;
  String? _deviceId;

  static const String _autoSyncKey = 'firebase_auto_sync';
  static const String _lastBackupKey = 'firebase_last_backup';
  static const String _lastSyncKey = 'firebase_last_sync';
  static const String _deviceIdKey = 'firebase_device_id';

  @override
  Stream<BackupStatus> get backupStatusStream => _statusController.stream;

  /// Authenticate with Firebase using anonymous auth
  @override
  Future<void> authenticate() async {
    try {
      AppLogger.backup.info('🔐 Authenticating with Firebase...');

      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        throw const AppError(
          type: AppErrorType.validation,
          message: 'Firebase not initialized. Please configure Firebase first.',
        );
      }

      // Sign in anonymously
      final userCredential = await _auth.signInAnonymously();
      _anonymousUid = userCredential.user?.uid;

      if (_anonymousUid == null) {
        throw const AppError(
          type: AppErrorType.network,
          message: 'Failed to authenticate with Firebase',
        );
      }

      // Get or create device ID
      _deviceId = await _getOrCreateDeviceId();

      AppLogger.backup.info('✅ Authenticated: uid=$_anonymousUid, deviceId=$_deviceId');
    } on AppError {
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.backup.severe('❌ Authentication failed: $e');
      throw AppError(
        type: AppErrorType.network,
        message: 'Authentication failed',
        technicalDetails: e.toString(),
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sign out from Firebase
  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _anonymousUid = null;
      _statusController.add(const BackupStatus());
      AppLogger.backup.info('👋 Signed out');
    } catch (e) {
      AppLogger.backup.warning('⚠️ Sign out failed: $e');
    }
  }

  /// Check if authenticated
  @override
  Future<bool> isAuthenticated() async {
    // Check if Firebase is initialized first
    if (Firebase.apps.isEmpty) {
      return false;
    }
    return _auth.currentUser != null;
  }

  /// Backup all data to Firebase Firestore
  ///
  /// Reuses BackupService.exportData() for serialization
  @override
  Future<void> backupData() async {
    try {
      _statusController.add(const BackupStatus(isBackingUp: true, progress: 0.0));
      AppLogger.backup.info('☁️ Starting backup...');

      // Reuse existing export logic
      final jsonData = await _backupService.exportData();
      final parsed = jsonDecode(jsonData) as Map<String, dynamic>;

      // Backup transactions collection
      final transactions = parsed['transactions'] as List;
      await _backupCollection('transactions', transactions, progress: (p) {
        _statusController.add(BackupStatus(isBackingUp: true, progress: p * 0.7));
      });

      // Backup settings document
      final settings = parsed['settings'] as Map<String, dynamic>;
      await _backupDocument('settings', settings);
      _statusController.add(const BackupStatus(isBackingUp: true, progress: 0.9));

      // Backup gamification if exists
      if (parsed.containsKey('gamification')) {
        final gamification = parsed['gamification'] as Map<String, dynamic>;
        await _backupDocument('gamification', gamification);
      }

      _statusController.add(BackupStatus(
        isBackingUp: false,
        lastBackupTime: DateTime.now(),
        progress: 1.0,
      ));

      // Save timestamps
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBackupKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      AppLogger.backup.info('✅ Backup complete: ${transactions.length} transactions');
    } catch (e, stackTrace) {
      final error = AppError(
        type: AppErrorType.backup,
        message: 'Backup failed',
        technicalDetails: e.toString(),
        originalError: e,
        stackTrace: stackTrace,
      );

      _syncQueue.enqueue(SyncOperation.backup, error.message);
      _statusController.add(BackupStatus(
        isBackingUp: false,
        errorMessage: error.message,
      ));

      AppLogger.backup.severe('❌ Backup failed: $e');
      throw error;
    }
  }

  /// Restore all data from Firebase Firestore
  ///
  /// Reuses BackupService.importData() for deserialization
  @override
  Future<void> restoreData() async {
    try {
      _statusController.add(const BackupStatus(isRestoring: true, progress: 0.0));
      AppLogger.backup.info('📥 Starting restore...');

      // Fetch all collections
      final transactions = await _fetchCollection('transactions');
      _statusController.add(const BackupStatus(isRestoring: true, progress: 0.3));

      final settings = await _fetchDocument('settings');
      final gamification = await _fetchDocument('gamification');
      _statusController.add(const BackupStatus(isRestoring: true, progress: 0.6));

      // Merge into JSON format for import
      final restoreJson = jsonEncode({
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'transactions': transactions,
        'settings': settings,
        if (gamification != null) 'gamification': gamification,
      });

      // Reuse existing import logic
      await _backupService.importData(restoreJson);

      _statusController.add(BackupStatus(
        isRestoring: false,
        lastBackupTime: DateTime.now(),
        progress: 1.0,
      ));

      // Save timestamps
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      AppLogger.backup.info('✅ Restore complete: ${transactions.length} transactions');
    } catch (e, stackTrace) {
      final error = AppError(
        type: AppErrorType.backup,
        message: 'Restore failed',
        technicalDetails: e.toString(),
        originalError: e,
        stackTrace: stackTrace,
      );

      _syncQueue.enqueue(SyncOperation.restore, error.message);
      _statusController.add(BackupStatus(
        isRestoring: false,
        errorMessage: error.message,
      ));

      AppLogger.backup.severe('❌ Restore failed: $e');
      throw error;
    }
  }

  /// Get last backup timestamp
  @override
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastBackupKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Enable auto-sync
  @override
  Future<void> enableAutoSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, true);
    AppLogger.backup.info('✅ Auto-sync enabled');
  }

  /// Disable auto-sync
  @override
  Future<void> disableAutoSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, false);
    AppLogger.backup.info('⏸️ Auto-sync disabled');
  }

  /// Check if auto-sync is enabled
  @override
  Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSyncKey) ?? false;
  }

  /// Perform bidirectional sync with conflict resolution
  ///
  /// Last-write-wins: Compare timestamps, keep newest
  @override
  Future<SyncResult> performSync() async {
    try {
      AppLogger.backup.info('🔄 Starting sync...');

      final prefs = await SharedPreferences.getInstance();
      final lastLocalSync = prefs.getInt(_lastSyncKey);

      // Fetch cloud metadata
      final metadataDoc = await _firestore
          .collection('users')
          .doc(_anonymousUid)
          .collection('metadata')
          .doc('sync')
          .get();

      final lastCloudSync = metadataDoc.data()?['lastSyncTime'] as int?;

      // First sync - no action, user must choose backup/restore
      if (lastLocalSync == null && lastCloudSync == null) {
        AppLogger.backup.info('⚠️ First sync - user must choose direction');
        return SyncResult(
          success: true,
          type: SyncType.none,
          syncTime: DateTime.now(),
        );
      }

      SyncType syncType;

      // Compare timestamps (last-write-wins)
      if (lastLocalSync == null || (lastCloudSync != null && lastCloudSync > lastLocalSync)) {
        // Cloud is newer - restore
        await restoreData();
        syncType = SyncType.download;
        AppLogger.backup.info('📥 Downloaded from cloud (cloud newer)');
      } else if (lastCloudSync == null || lastLocalSync > lastCloudSync) {
        // Local is newer - backup
        await backupData();
        syncType = SyncType.upload;
        AppLogger.backup.info('☁️ Uploaded to cloud (local newer)');
      } else {
        // Same - no action needed
        AppLogger.backup.info('✅ Already in sync');
        return SyncResult.downloaded(DateTime.now());
      }

      // Update sync metadata
      await _firestore
          .collection('users')
          .doc(_anonymousUid)
          .collection('metadata')
          .doc('sync')
          .set({
        'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
        'deviceId': _deviceId,
      }, SetOptions(merge: true));

      return SyncResult(
        success: true,
        type: syncType,
        syncTime: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.backup.severe('❌ Sync failed: $e');
      return SyncResult.error(e.toString());
    }
  }

  /// Backup a collection (transactions)
  Future<void> _backupCollection(
    String collectionName,
    List items, {
    void Function(double)? progress,
  }) async {
    final collectionRef = _firestore
        .collection('users')
        .doc(_anonymousUid)
        .collection(collectionName);

    // Firestore batch limit is 500 operations
    const batchSize = 500;
    for (int i = 0; i < items.length; i += batchSize) {
      final batch = _firestore.batch();
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;

      for (int j = i; j < end; j++) {
        final item = items[j] as Map<String, dynamic>;
        final doc = item.clone() as Map<String, dynamic>;

        // Add metadata
        doc['deviceId'] = _deviceId;
        doc['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
        doc['createdAt'] = doc['createdAt'] ?? DateTime.now().millisecondsSinceEpoch;

        final docRef = collectionRef.doc(doc['id'] as String);
        batch.set(docRef, doc, SetOptions(merge: true));
      }

      await batch.commit();

      if (progress != null) {
        progress(end / items.length);
      }
    }
  }

  /// Backup a single document (settings, gamification)
  Future<void> _backupDocument(String docName, Map<String, dynamic> data) async {
    final docRef = _firestore
        .collection('users')
        .doc(_anonymousUid)
        .collection(docName)
        .doc('data');

    final doc = data.clone() as Map<String, dynamic>;
    doc['deviceId'] = _deviceId;
    doc['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

    await docRef.set(doc, SetOptions(merge: true));
  }

  /// Fetch a collection from Firestore
  Future<List> _fetchCollection(String collectionName) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_anonymousUid)
        .collection(collectionName)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Fetch a single document from Firestore
  Future<Map<String, dynamic>?> _fetchDocument(String docName) async {
    final docRef = _firestore
        .collection('users')
        .doc(_anonymousUid)
        .collection(docName)
        .doc('data');

    final doc = await docRef.get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    data.remove('deviceId');
    data.remove('updatedAt');
    return data;
  }

  /// Get or create device ID
  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = await _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
      AppLogger.backup.info('📱 Generated new deviceId: $deviceId');
    }

    return deviceId;
  }

  /// Generate unique device ID
  Future<String> _generateDeviceId() async {
    // Check if running on web
    if (kIsWeb) {
      // Web platform - generate browser-unique ID
      final random = DateTime.now().millisecondsSinceEpoch;
      return 'web_$random';
    }

    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'android_${androidInfo.id}_${DateTime.now().millisecondsSinceEpoch}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'ios_${iosInfo.identifierForVendor}_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // Fallback for other platforms
        return 'desktop_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      // Fallback if Platform detection fails
      return 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
    _syncQueue.dispose();
  }
}

/// Extension to clone Map
extension MapClone on Map<String, dynamic> {
  Map<String, dynamic> clone() {
    return Map<String, dynamic>.from(this);
  }
}
