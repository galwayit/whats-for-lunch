import 'package:drift/drift.dart';

import '../../domain/entities/budget_tracking.dart' as entity;
import '../../domain/repositories/budget_repository.dart';
import '../database/database.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final AppDatabase _database;

  BudgetRepositoryImpl(this._database);

  @override
  Future<int> createBudgetEntry(entity.BudgetTracking budgetTracking) async {
    final companion = _database.budgetTrackingToCompanion(budgetTracking);
    return await _database.insertBudgetTracking(companion);
  }

  @override
  Future<List<entity.BudgetTracking>> getBudgetTrackingByUserId(int userId) async {
    final budgetEntries = await _database.getBudgetTrackingByUserId(userId);
    return budgetEntries.map((entry) => _database.budgetTrackingFromTable(entry)).toList();
  }

  @override
  Future<List<entity.BudgetTracking>> getBudgetTrackingByDateRange(int userId, DateTime start, DateTime end) async {
    final budgetEntries = await (_database.select(_database.budgetTrackings)
          ..where((tbl) => tbl.userId.equals(userId))
          ..where((tbl) => tbl.date.isBiggerOrEqual(Variable(start)) & tbl.date.isSmallerOrEqual(Variable(end))))
        .get();
    return budgetEntries.map((entry) => _database.budgetTrackingFromTable(entry)).toList();
  }

  @override
  Future<bool> updateBudgetEntry(entity.BudgetTracking budgetTracking) async {
    if (budgetTracking.id == null) return false;
    final companion = _database.budgetTrackingToCompanion(budgetTracking);
    final updatedRows = await (_database.update(_database.budgetTrackings)
          ..where((tbl) => tbl.id.equals(budgetTracking.id!)))
        .replace(companion);
    return updatedRows;
  }

  @override
  Future<bool> deleteBudgetEntry(int id) async {
    final deletedRows = await (_database.delete(_database.budgetTrackings)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
    return deletedRows > 0;
  }
}