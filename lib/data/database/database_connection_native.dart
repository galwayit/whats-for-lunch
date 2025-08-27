import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Creates a SQLite database connection for mobile platforms
DatabaseConnection createPlatformDatabaseConnection() {
  // Use in-memory database for now to resolve build issues
  // This can be switched to persistent storage once build issues are resolved
  return DatabaseConnection(NativeDatabase.memory());
}

/// Creates an in-memory database connection for testing on mobile platforms
DatabaseConnection createPlatformTestDatabaseConnection() {
  return DatabaseConnection(NativeDatabase.memory());
}