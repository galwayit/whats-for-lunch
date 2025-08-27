import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Creates an IndexedDB database connection for web platform
DatabaseConnection createPlatformDatabaseConnection() {
  return DatabaseConnection(
    WebDatabase.withStorage(
      DriftWebStorage.indexedDb('drift_db'),
    ),
  );
}

/// Creates a volatile database connection for testing on web platform
DatabaseConnection createPlatformTestDatabaseConnection() {
  return DatabaseConnection(
    WebDatabase.withStorage(DriftWebStorage.volatile()),
  );
}