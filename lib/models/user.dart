import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// User model representing app users
class User {
  final String id;
  final String email;
  final String name;
  final String? householdId;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.householdId,
    required this.createdAt,
    this.lastLogin,
  });

  /// Create from Firebase Auth user
  factory User.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? 'User',
      householdId: null,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
  }

  /// Create from Firestore document
  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      email: map['email'] as String,
      name: map['name'] as String,
      householdId: map['householdId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'] as String)
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'householdId': householdId,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  /// Check if user belongs to a household
  bool get hasHousehold => householdId != null && householdId!.isNotEmpty;

  /// Copy with method for updating fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? householdId,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      householdId: householdId ?? this.householdId,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
