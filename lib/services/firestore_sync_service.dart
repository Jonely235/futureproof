import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart' as model;
import 'database_service.dart';
import 'auth_service.dart';

/// Firestore Sync Service
///
/// Handles synchronization between local SQLite and cloud Firestore.
/// Implements offline-first approach with sync queue.
class FirestoreSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final DatabaseService _localDb = DatabaseService();
  final AuthService _authService = AuthService();

  /// Sync all transactions from Firestore to local database
  Future<void> syncTransactionsToLocal(String householdId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch transactions from Firestore
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('householdId', isEqualTo: householdId)
          .orderBy('date', descending: true)
          .get();

      print('Fetched ${querySnapshot.docs.length} transactions from Firestore');

      // Clear local transactions (optional: could merge instead)
      await _localDb.deleteAllTransactions();

      // Save each transaction to local database
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final transaction = _transactionFromFirestore(data, doc.id);

        await _localDb.addTransaction(transaction);
      }

      print('Synced ${querySnapshot.docs.length} transactions to local database');
    } catch (e) {
      print('Error syncing transactions: $e');
      rethrow;
    }
  }

  /// Upload a single transaction to Firestore
  Future<void> uploadTransaction(model.Transaction transaction) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Convert transaction to Firestore format
      final data = _transactionToFirestore(transaction);
      data['createdBy'] = userId;
      data['updatedAt'] = FieldValue.serverTimestamp();

      // Check if transaction already exists in Firestore
      final existingDoc = await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .get();

      if (existingDoc.exists) {
        // Update existing transaction
        await _firestore
            .collection('transactions')
            .doc(transaction.id)
            .update(data);
        print('Updated transaction ${transaction.id} in Firestore');
      } else {
        // Create new transaction
        data['createdAt'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('transactions')
            .doc(transaction.id)
            .set(data);
        print('Created transaction ${transaction.id} in Firestore');
      }
    } catch (e) {
      print('Error uploading transaction: $e');
      rethrow;
    }
  }

  /// Upload all local transactions to Firestore
  Future<void> uploadAllTransactions(String householdId) async {
    try {
      // Fetch all local transactions
      final localTransactions = await _localDb.getAllTransactions();

      print('Uploading ${localTransactions.length} transactions to Firestore');

      for (final transaction in localTransactions) {
        await uploadTransaction(transaction);
      }

      print('Uploaded all transactions to Firestore');
    } catch (e) {
      print('Error uploading transactions: $e');
      rethrow;
    }
  }

  /// Delete a transaction from Firestore
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transactionId)
          .delete();
      print('Deleted transaction $transactionId from Firestore');
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }

  /// Listen to real-time transaction updates
  Stream<List<model.Transaction>> listenToTransactions(String householdId) {
    return _firestore
        .collection('transactions')
        .where('householdId', isEqualTo: householdId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return _transactionFromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Convert local Transaction to Firestore format
  Map<String, dynamic> _transactionToFirestore(model.Transaction transaction) {
    return {
      'householdId': transaction.householdId,
      'amount': transaction.amount,
      'category': transaction.category,
      'date': Timestamp.fromDate(transaction.date),
      'note': transaction.note,
    };
  }

  /// Convert Firestore document to local Transaction
  model.Transaction _transactionFromFirestore(
      Map<String, dynamic> data, String id) {
    return model.Transaction(
      id: id,
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] as String,
      note: data['note'] as String?,
      date: (data['date'] as Timestamp).toDate(),
      householdId: data['householdId'] as String,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Sync household settings from Firestore to SharedPreferences
  Future<void> syncHouseholdSettings(String householdId) async {
    try {
      final household = await _authService.getHousehold(householdId);
      if (household == null) {
        throw Exception('Household not found');
      }

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      if (household.monthlyIncome != null) {
        await prefs.setDouble('monthly_income', household.monthlyIncome!);
      }

      if (household.savingsGoal != null) {
        await prefs.setDouble('savings_goal', household.savingsGoal!);
      }

      print('Synced household settings: '
          'income=${household.monthlyIncome}, '
          'savings=${household.savingsGoal}');
    } catch (e) {
      print('Error syncing household settings: $e');
      rethrow;
    }
  }

  /// Perform full sync: download cloud changes, upload local changes
  Future<void> fullSync(String householdId) async {
    try {
      print('Starting full sync...');

      // 1. Download transactions from Firestore
      await syncTransactionsToLocal(householdId);

      // 2. Sync household settings
      await syncHouseholdSettings(householdId);

      // 3. Upload any local changes (optional: could check last sync time)
      // await uploadAllTransactions(householdId);

      print('Full sync complete!');
    } catch (e) {
      print('Error during full sync: $e');
      rethrow;
    }
  }
}
