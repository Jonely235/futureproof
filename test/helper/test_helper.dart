import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test helper for database initialization
///
/// Call this in setUpAll() to initialize the database factory for testing.
void initializeTestDatabase() {
  // Initialize the FFI database factory for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Clean up test database
///
/// Call this in tearDown() or tearDownAll() to clean up test database.
Future<void> cleanupTestDatabase() async {
  // The database is automatically cleaned up between tests
  // Additional cleanup can be added here if needed
}
