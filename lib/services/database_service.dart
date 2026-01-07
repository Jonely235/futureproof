import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/transaction.dart' as model;

/// Firebase-based Database service for managing transaction persistence.
///
/// Replaces SQLite with Firestore as the single source of truth.
/// Implements singleton pattern to ensure single database connection.
/// Provides CRUD operations for [Transaction] model.
///
/// Benefits of Firestore over SQLite:
/// - Cross-platform compatibility (no iOS build issues)
/// - Real-time sync across devices
/// - Offline persistence via Firestore cache
/// - Automatic scaling
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Get current user ID or throw if not authenticated
  String _getUserId() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated. Please log in.');
    }
    return userId;
  }

  /// Get reference to transactions collection for current user
  CollectionReference _getTransactionsCollection() {
    final userId = _getUserId();
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  /// Adds a new transaction to Firestore.
  ///
  /// Returns the transaction ID (same as input).
  /// Throws [Exception] if user is not authenticated or operation fails.
  Future<String> addTransaction(model.Transaction transaction) async {
    try {
      final userId = _getUserId();

      // Validate transaction has required fields
      if (transaction.id.isEmpty) {
        throw ArgumentError('Transaction ID cannot be empty');
      }

      final data = _transactionToMap(transaction);
      data['createdBy'] = userId;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _getTransactionsCollection().doc(transaction.id).set(data);

      print('✅ Added transaction ${transaction.id} to Firestore');
      return transaction.id;
    } catch (e) {
      print('❌ Error adding transaction: $e');
      rethrow;
    }
  }

  /// Retrieves all transactions from Firestore.
  ///
  /// Returns transactions sorted by date in descending order (newest first).
  /// Returns empty list if no transactions exist or on error.
  Future<List<model.Transaction>> getAllTransactions() async {
    try {
      final userId = _getUserId();

      final querySnapshot = await _getTransactionsCollection()
          .orderBy('date', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      print('📊 Retrieved ${querySnapshot.docs.length} transactions from Firestore');

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs
          .map((doc) => _transactionFromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error getting transactions: $e');
      return [];
    }
  }

  /// Retrieves all transactions as a real-time stream.
  ///
  /// Returns a Stream that emits updated transaction lists automatically.
  /// Useful for UI components that need real-time updates.
  Stream<List<model.Transaction>> watchAllTransactions() {
    try {
      final userId = _getUserId();

      return _getTransactionsCollection()
          .orderBy('date', descending: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => _transactionFromFirestore(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      print('❌ Error watching transactions: $e');
      return Stream.value([]);
    }
  }

  /// Retrieves a specific transaction by ID.
  ///
  /// Returns null if not found.
  Future<model.Transaction?> getTransactionById(String id) async {
    try {
      final docSnapshot = await _getTransactionsCollection().doc(id).get();

      if (!docSnapshot.exists) {
        print('⚠️ Transaction $id not found');
        return null;
      }

      return _transactionFromFirestore(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      print('❌ Error getting transaction by ID: $e');
      return null;
    }
  }

  /// Updates an existing transaction in Firestore.
  ///
  /// Returns 1 on success, 0 if transaction not found.
  Future<int> updateTransaction(model.Transaction transaction) async {
    try {
      if (transaction.id.isEmpty) {
        throw ArgumentError('Transaction ID is required for update');
      }

      final docRef = _getTransactionsCollection().doc(transaction.id);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        print('⚠️ No transaction found with ID ${transaction.id}');
        return 0;
      }

      final data = _transactionToMap(transaction);
      data['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.update(data);
      print('✅ Updated transaction ${transaction.id} in Firestore');
      return 1;
    } catch (e) {
      print('❌ Error updating transaction: $e');
      return 0;
    }
  }

  /// Deletes a transaction from Firestore by ID.
  ///
  /// Returns 1 on success, 0 if transaction not found.
  Future<int> deleteTransaction(String id) async {
    try {
      final docRef = _getTransactionsCollection().doc(id);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        print('⚠️ No transaction found with ID $id');
        return 0;
      }

      await docRef.delete();
      print('✅ Deleted transaction $id from Firestore');
      return 1;
    } catch (e) {
      print('❌ Error deleting transaction: $e');
      return 0;
    }
  }

  /// Deletes all transactions from Firestore.
  ///
  /// ⚠️ USE WITH CAUTION - This is irreversible!
  /// Returns the number of transactions deleted.
  Future<int> deleteAllTransactions() async {
    try {
      final querySnapshot = await _getTransactionsCollection().get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Deleted ${querySnapshot.docs.length} transactions from Firestore');
      return querySnapshot.docs.length;
    } catch (e) {
      print('❌ Error deleting all transactions: $e');
      return 0;
    }
  }

  /// Convert Transaction model to Firestore map
  Map<String, dynamic> _transactionToMap(model.Transaction transaction) {
    return {
      'id': transaction.id,
      'amount': transaction.amount,
      'category': transaction.category,
      'date': transaction.date.toIso8601String(),
      'note': transaction.note,
      'householdId': transaction.householdId,
    };
  }

  /// Convert Firestore document to Transaction model
  model.Transaction _transactionFromFirestore(
      Map<String, dynamic> data, String documentId) {
    // Handle both Timestamp and String date formats
    DateTime date;
    if (data['date'] is Timestamp) {
      date = (data['date'] as Timestamp).toDate();
    } else {
      date = DateTime.parse(data['date'] as String);
    }

    return model.Transaction(
      id: documentId,
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] as String,
      date: date,
      note: data['note'] as String? ?? '',
      householdId: data['householdId'] as String? ?? '',
    );
  }

  /// Get transactions for a specific household
  ///
  /// Useful when user is part of multiple households
  Future<List<model.Transaction>> getTransactionsByHousehold(
      String householdId) async {
    try {
      final querySnapshot = await _getTransactionsCollection()
          .where('householdId', isEqualTo: householdId)
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => _transactionFromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error getting household transactions: $e');
      return [];
    }
  }

  /// Watch transactions for a specific household as a stream
  Stream<List<model.Transaction>> watchTransactionsByHousehold(
      String householdId) {
    try {
      return _getTransactionsCollection()
          .where('householdId', isEqualTo: householdId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => _transactionFromFirestore(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      print('❌ Error watching household transactions: $e');
      return Stream.value([]);
    }
  }
}
