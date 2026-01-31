import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/vault_entity.dart';
import '../models/transaction.dart';
import '../utils/app_logger.dart';

/// Firebase Sync Service
///
/// Manages Firebase Firestore sync for vaults and transactions.
/// Provides cross-platform sync (iOS + Android) with client-side encryption.
///
/// **NOTE:** This is a simplified version for initial compilation.
/// Full sync functionality will be implemented after Firebase Console setup.
class FirebaseSyncService {
  FirebaseSyncService._internal();
  static final FirebaseSyncService instance = FirebaseSyncService._internal();

  final _log = Logger('FirebaseSyncService');
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  // Encryption key (derived from user's password/hardware)
  String? _encryptionKey;

  // Stream controllers
  final _statusController = StreamController<SyncStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<String> get errorStream => _errorController.stream;

  SyncStatus _currentStatus = SyncStatus.idle;
  SyncStatus get currentStatus => _currentStatus;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase
  Future<bool> initialize() async {
    try {
      _log.info('🔥 Initializing Firebase...');

      // Initialize Firebase Core
      await Firebase.initializeApp();

      // Initialize Firestore
      _firestore = FirebaseFirestore.instance;

      // Initialize Auth
      _auth = FirebaseAuth.instance;

      // Set Firestore settings
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 10485760,
      );

      // Generate or load encryption key
      await _initializeEncryption();

      _isInitialized = true;
      _updateStatus(SyncStatus.idle);
      _log.info('✅ Firebase initialized successfully');
      return true;
    } catch (e, stack) {
      _log.severe('❌ Failed to initialize Firebase: $e');
      _log.severe('Stack: $stack');
      _errorController.add('Firebase initialization failed: $e');
      return false;
    }
  }

  /// Initialize encryption key
  Future<void> _initializeEncryption() async {
    final prefs = await SharedPreferences.getInstance();

    String? key = prefs.getString('firebase_encryption_key');

    if (key == null) {
      _log.info('🔐 Generating new encryption key...');
      final uuid = const Uuid().v4();
      final bytes = utf8.encode(uuid + DateTime.now().toIso8601String());
      final hash = sha256.convert(bytes);
      key = hash.toString();
      await prefs.setString('firebase_encryption_key', key);
      _log.info('✅ Encryption key generated and stored');
    }

    _encryptionKey = key;
    _log.fine('🔐 Encryption key loaded');
  }

  /// Encrypt data using XOR (simple for now - upgrade to AES in production)
  String _encrypt(String data) {
    if (_encryptionKey == null) {
      throw StateError('Encryption key not initialized');
    }

    try {
      final key = utf8.encode(_encryptionKey!);
      final bytes = utf8.encode(data);

      final encrypted = List<int>.generate(
        bytes.length,
        (i) => bytes[i] ^ key[i % key.length],
      );

      return base64Encode(encrypted);
    } catch (e) {
      _log.severe('❌ Encryption failed: $e');
      rethrow;
    }
  }

  /// Decrypt data
  String _decrypt(String encryptedData) {
    if (_encryptionKey == null) {
      throw StateError('Encryption key not initialized');
    }

    try {
      final key = utf8.encode(_encryptionKey!);
      final encrypted = base64Decode(encryptedData);

      final decrypted = List<int>.generate(
        encrypted.length,
        (i) => encrypted[i] ^ key[i % key.length],
      );

      return utf8.decode(decrypted);
    } catch (e) {
      _log.severe('❌ Decryption failed: $e');
      rethrow;
    }
  }

  /// Sign in anonymously
  Future<bool> signInAnonymously() async {
    if (_auth == null) return false;

    try {
      _log.info('🔑 Signing in anonymously...');
      final userCredential = await _auth!.signInAnonymously();
      _log.info('✅ Signed in as: ${userCredential.user?.uid}');
      return true;
    } catch (e) {
      _log.severe('❌ Sign in failed: $e');
      _errorController.add('Sign in failed: $e');
      return false;
    }
  }

  /// Get current user ID
  String? get currentUserId => _auth?.currentUser?.uid;

  /// Check if user is signed in
  bool get isSignedIn => _auth?.currentUser != null;

  /// Sync vault to Firebase
  Future<bool> syncVault(VaultEntity vault) async {
    if (!_isInitialized || _firestore == null) return false;
    if (!isSignedIn) {
      final signedIn = await signInAnonymously();
      if (!signedIn) return false;
    }

    try {
      _updateStatus(SyncStatus.syncing);
      _log.info('☁️ Syncing vault: ${vault.id}');

      final userId = currentUserId!;
      final vaultRef = _firestore!
          .collection('users')
          .doc(userId)
          .collection('vaults')
          .doc(vault.id);

      final vaultJson = jsonEncode({
        'id': vault.id,
        'name': vault.name,
        'type': vault.type.toString(),
        'createdAt': vault.createdAt.toIso8601String(),
        'lastModified': vault.lastModified.toIso8601String(),
        'transactionCount': vault.transactionCount,
        'isActive': vault.isActive,
      });

      final encryptedData = _encrypt(vaultJson);

      await vaultRef.set({
        'encryptedData': encryptedData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _updateStatus(SyncStatus.success);
      _log.info('✅ Vault synced successfully');
      return true;
    } catch (e, stack) {
      _log.severe('❌ Vault sync failed: $e');
      _updateStatus(SyncStatus.error);
      _errorController.add('Vault sync failed: $e');
      return false;
    }
  }

  /// Sync transaction to Firebase
  Future<bool> syncTransaction(Transaction transaction) async {
    if (!_isInitialized || _firestore == null) return false;
    if (!isSignedIn) {
      final signedIn = await signInAnonymously();
      if (!signedIn) return false;
    }

    try {
      _updateStatus(SyncStatus.syncing);
      _log.info('☁️ Syncing transaction: ${transaction.id}');

      final userId = currentUserId!;
      final txRef = _firestore!
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transaction.id);

      final txJson = jsonEncode({
        'id': transaction.id,
        'amount': transaction.amount,
        'category': transaction.category,
        'note': transaction.note,
        'date': transaction.date.toIso8601String(),
        'householdId': transaction.householdId,
        'createdAt': transaction.createdAt.toIso8601String(),
      });

      final encryptedData = _encrypt(txJson);

      await txRef.set({
        'encryptedData': encryptedData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _updateStatus(SyncStatus.success);
      _log.info('✅ Transaction synced successfully');
      return true;
    } catch (e, stack) {
      _log.severe('❌ Transaction sync failed: $e');
      _updateStatus(SyncStatus.error);
      _errorController.add('Transaction sync failed: $e');
      return false;
    }
  }

  /// Listen to vault updates from Firebase
  Stream<List<VaultEntity>> watchVaults() {
    if (!_isInitialized || _firestore == null || !isSignedIn) {
      return Stream.value([]);
    }

    final userId = currentUserId!;

    return _firestore!
        .collection('users')
        .doc(userId)
        .collection('vaults')
        .snapshots()
        .map((snapshot) {
      _log.info('📥 Received vault updates: ${snapshot.docs.length} vaults');

      final vaults = <VaultEntity>[];

      for (var doc in snapshot.docs) {
        try {
          final encryptedData = doc.data()['encryptedData'] as String;
          final decryptedJson = _decrypt(encryptedData);
          final json = jsonDecode(decryptedJson) as Map<String, dynamic>;

          vaults.add(VaultEntity(
            id: json['id'] as String,
            name: json['name'] as String,
            type: _parseVaultType(json['type'] as String?),
            createdAt: DateTime.parse(json['createdAt'] as String),
            lastModified: DateTime.parse(json['lastModified'] as String),
            transactionCount: json['transactionCount'] as int? ?? 0,
            isActive: json['isActive'] as bool? ?? false,
          ));
        } catch (e) {
          _log.severe('❌ Failed to decrypt vault: $e');
        }
      }

      return vaults;
    });
  }

  /// Listen to transaction updates from Firebase
  Stream<List<Transaction>> watchTransactions() {
    if (!_isInitialized || _firestore == null || !isSignedIn) {
      return Stream.value([]);
    }

    final userId = currentUserId!;

    return _firestore!
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .snapshots()
        .map((snapshot) {
      _log.info('📥 Received transaction updates: ${snapshot.docs.length} transactions');

      final transactions = <Transaction>[];

      for (var doc in snapshot.docs) {
        try {
          final encryptedData = doc.data()['encryptedData'] as String;
          final decryptedJson = _decrypt(encryptedData);
          final json = jsonDecode(decryptedJson) as Map<String, dynamic>;

          transactions.add(Transaction(
            id: json['id'] as String,
            amount: (json['amount'] as num).toDouble(),
            category: json['category'] as String,
            note: json['note'] as String?,
            date: DateTime.parse(json['date'] as String),
            householdId: json['householdId'] as String? ?? '',
            createdAt: DateTime.parse(json['createdAt'] as String),
          ));
        } catch (e) {
          _log.severe('❌ Failed to decrypt transaction: $e');
        }
      }

      return transactions;
    });
  }

  /// Parse VaultType from string
  VaultType _parseVaultType(String? typeString) {
    if (typeString == null) return VaultType.personal;

    return VaultType.values.firstWhere(
      (e) => e.toString() == typeString,
      orElse: () => VaultType.personal,
    );
  }

  /// Delete vault from Firebase
  Future<bool> deleteVault(String vaultId) async {
    if (!_isInitialized || _firestore == null || !isSignedIn) return false;

    try {
      final userId = currentUserId!;
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('vaults')
          .doc(vaultId)
          .delete();

      _log.info('✅ Vault deleted from Firebase: $vaultId');
      return true;
    } catch (e) {
      _log.severe('❌ Failed to delete vault: $e');
      return false;
    }
  }

  /// Delete transaction from Firebase
  Future<bool> deleteTransaction(String transactionId) async {
    if (!_isInitialized || _firestore == null || !isSignedIn) return false;

    try {
      final userId = currentUserId!;
      await _firestore!
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .delete();

      _log.info('✅ Transaction deleted from Firebase: $transactionId');
      return true;
    } catch (e) {
      _log.severe('❌ Failed to delete transaction: $e');
      return false;
    }
  }

  /// Update sync status
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
    _errorController.close();
  }
}

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}
