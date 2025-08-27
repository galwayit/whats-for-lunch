import 'package:drift/drift.dart';

import 'database_connection_stub.dart'
    if (dart.library.io) 'database_connection_native.dart'
    if (dart.library.js) 'database_connection_web.dart';

/// Creates a database connection appropriate for the current platform.
/// Uses IndexedDB for web and SQLite for mobile platforms.
DatabaseConnection createDatabaseConnection() {
  return createPlatformDatabaseConnection();
}

/// Creates a database connection for testing.
/// Uses in-memory databases for both platforms.
DatabaseConnection createTestDatabaseConnection() {
  return createPlatformTestDatabaseConnection();
}