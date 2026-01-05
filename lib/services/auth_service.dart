import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as model;
import '../models/household.dart';

/// Authentication Service
///
/// Handles user authentication, signup, login, and logout.
/// Integrates with Firebase Auth and Firestore.
class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current authenticated user (stream)
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  /// Get current user
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get current user ID
  String? get currentUserId => currentUser?.uid;

  /// Signup with email and password
  ///
  /// Returns the created User object
  /// Throws [Exception] on failure
  Future<model.User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create auth account
      final credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Failed to create user account');
      }

      // Update display name
      await user.updateDisplayName(name);

      // Create user document in Firestore
      final appUser = model.User(
        id: user.uid,
        email: email,
        name: name,
        householdId: null,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(appUser.toMap());

      return appUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to signup: $e');
    }
  }

  /// Login with email and password
  ///
  /// Returns the User object
  /// Throws [Exception] on failure
  Future<model.User> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Failed to login');
      }

      // Fetch user document from Firestore
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final appUser = model.User.fromMap(userDoc.data()!, userDoc.id);

      // Update last login
      await _firestore.collection('users').doc(user.uid).update({
        'lastLogin': DateTime.now().toIso8601String(),
      });

      return appUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  /// Logout current user
  ///
  /// Throws [Exception] on failure
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  /// Get current user from Firestore
  ///
  /// Returns null if not authenticated or user not found
  Future<model.User?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return null;

      return model.User.fromMap(userDoc.data()!, userDoc.id);
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  /// Send password reset email
  ///
  /// Throws [Exception] on failure
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
    }
  }

  /// Create a new household
  ///
  /// Returns the created Household
  /// Throws [Exception] on failure
  Future<Household> createHousehold({
    required String name,
    required String userId,
    double? monthlyIncome,
    double? savingsGoal,
  }) async {
    try {
      // Create household document
      final householdRef = await _firestore.collection('households').add({
        'name': name,
        'members': [userId],
        'createdAt': DateTime.now().toIso8601String(),
        'monthlyIncome': monthlyIncome,
        'savingsGoal': savingsGoal,
      });

      // Update user with household ID
      await _firestore.collection('users').doc(userId).update({
        'householdId': householdRef.id,
      });

      // Fetch and return the household
      final householdDoc = await householdRef.get();
      return Household.fromMap(householdDoc.data()!, householdDoc.id);
    } catch (e) {
      throw Exception('Failed to create household: $e');
    }
  }

  /// Join an existing household by ID
  ///
  /// Returns the joined Household
  /// Throws [Exception] on failure
  Future<Household> joinHousehold({
    required String householdId,
    required String userId,
  }) async {
    try {
      // Fetch household
      final householdDoc =
          await _firestore.collection('households').doc(householdId).get();

      if (!householdDoc.exists) {
        throw Exception('Household not found');
      }

      final household =
          Household.fromMap(householdDoc.data()!, householdDoc.id);

      // Add user to household members
      final updatedMembers = List<String>.from(household.memberIds);
      if (updatedMembers.contains(userId)) {
        throw Exception('User already in household');
      }
      updatedMembers.add(userId);

      await _firestore.collection('households').doc(householdId).update({
        'members': updatedMembers,
      });

      // Update user with household ID
      await _firestore.collection('users').doc(userId).update({
        'householdId': householdId,
      });

      return household.copyWith(memberIds: updatedMembers);
    } catch (e) {
      throw Exception('Failed to join household: $e');
    }
  }

  /// Get household by ID
  ///
  /// Returns null if not found
  Future<Household?> getHousehold(String householdId) async {
    try {
      final householdDoc =
          await _firestore.collection('households').doc(householdId).get();

      if (!householdDoc.exists) return null;

      return Household.fromMap(householdDoc.data()!, householdDoc.id);
    } catch (e) {
      print('Error fetching household: $e');
      return null;
    }
  }

  /// Convert Firebase Auth exception to user-friendly message
  String _getAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak (min 6 characters)';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}
