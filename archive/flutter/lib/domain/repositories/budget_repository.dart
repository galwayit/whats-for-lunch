import '../entities/budget_tracking.dart';

abstract class BudgetRepository {
  Future<int> createBudgetEntry(BudgetTracking budgetTracking);
  Future<List<BudgetTracking>> getBudgetTrackingByUserId(int userId);
  Future<List<BudgetTracking>> getBudgetTrackingByDateRange(int userId, DateTime start, DateTime end);
  Future<bool> updateBudgetEntry(BudgetTracking budgetTracking);
  Future<bool> deleteBudgetEntry(int id);
}