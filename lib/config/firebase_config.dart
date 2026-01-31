/// Firebase Configuration
///
/// You need to replace these values with your own Firebase project credentials.
///
/// Setup Instructions:
/// 1. Go to https://console.firebase.google.com/
/// 2. Create a new project (or use existing)
/// 3. Add an iOS app:
///    - Download GoogleService-Info.plist
///    - Place it in ios/Runner/
/// 4. Add an Android app:
///    - Download google-services.json
///    - Place it in android/app/
/// 5. Enable Firestore Database:
///    - Go to Firestore Database → Create Database
///    - Choose production mode or test mode
/// 6. Enable Authentication:
///    - Go to Authentication → Sign-in method
///    - Enable "Anonymous" sign-in
library;

/// Firebase configuration constants
class FirebaseConfig {
  FirebaseConfig._();

  /// Your Firebase project ID
  /// Get this from Firebase Console → Project Settings
  static const String projectId = 'your-project-id';

  /// Firebase API key (auto-configured from GoogleService-Info.plist / google-services.json)
  static const String apiKey = 'your-api-key';

  /// Firestore collection names
  static const String usersCollection = 'users';
  static const String vaultsCollection = 'vaults';
  static const String transactionsCollection = 'transactions';

  /// Encryption enabled (client-side)
  static const bool enableEncryption = true;

  /// Enable debug logging
  static const bool enableDebugLogging = true;
}
