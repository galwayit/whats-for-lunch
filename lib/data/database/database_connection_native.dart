import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Creates a persistent SQLite database connection for mobile platforms.
///
/// Uses [LazyDatabase] to handle the async directory lookup required by
/// [getApplicationDocumentsDirectory]. The database file is stored at
/// `<app-documents>/diet_buddy.sqlite` so data survives app restarts.
DatabaseConnection createPlatformDatabaseConnection() {
  return DatabaseConnection(
    LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'diet_buddy.sqlite'));
      return NativeDatabase.createInBackground(file);
    }),
  );
}

/// Creates an in-memory database connection for testing on mobile platforms
DatabaseConnection createPlatformTestDatabaseConnection() {
  return DatabaseConnection(NativeDatabase.memory());
}