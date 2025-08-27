import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_we_have_for_lunch/presentation/providers/meal_providers.dart';
import 'package:what_we_have_for_lunch/presentation/providers/simple_providers.dart';
import 'package:what_we_have_for_lunch/presentation/providers/user_preferences_provider.dart';
import 'package:what_we_have_for_lunch/domain/entities/meal.dart';
import 'package:what_we_have_for_lunch/domain/entities/user_preferences.dart';
import 'package:what_we_have_for_lunch/domain/repositories/user_repository.dart';
import 'package:what_we_have_for_lunch/domain/entities/user.dart';

class MockUserRepository implements UserRepository {
  @override
  Future<int> createUser(UserEntity user) async => 1;
  
  @override
  Future<UserEntity?> getUserById(int id) async => null;
  
  @override
  Future<bool> updateUser(UserEntity user) async => true;
  
  @override
  Future<bool> deleteUser(int id) async => true;
  
  @override
  Future<List<UserEntity>> getAllUsers() async => [];
}

void main() {
  group('MealFormNotifier', () {
    late ProviderContainer container;
    late MealFormNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(mealFormProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default values', () {
      final state = container.read(mealFormProvider);
      
      expect(state.restaurantName, isEmpty);
      expect(state.cost, isNull);
      expect(state.notes, isEmpty);
      expect(state.mealType, equals('dining_out'));
      expect(state.isLoading, isFalse);
      expect(state.isDraft, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.isValid, isFalse);
    });

    test('should update restaurant name and mark as draft', () {
      const testName = 'Test Restaurant';
      
      notifier.updateRestaurantName(testName);
      
      final state = container.read(mealFormProvider);
      expect(state.restaurantName, equals(testName));
      expect(state.isDraft, isTrue);
      expect(state.errorMessage, isNull);
    });

    test('should update cost and mark as draft', () {
      const testCost = 25.50;
      
      notifier.updateCost(testCost);
      
      final state = container.read(mealFormProvider);
      expect(state.cost, equals(testCost));
      expect(state.isDraft, isTrue);
      expect(state.errorMessage, isNull);
    });

    test('should update meal type', () {
      const testType = 'lunch';
      
      notifier.updateMealType(testType);
      
      final state = container.read(mealFormProvider);
      expect(state.mealType, equals(testType));
      expect(state.isDraft, isTrue);
    });

    test('should update notes', () {
      const testNotes = 'Great experience!';
      
      notifier.updateNotes(testNotes);
      
      final state = container.read(mealFormProvider);
      expect(state.notes, equals(testNotes));
      expect(state.isDraft, isTrue);
    });

    test('should apply smart defaults based on time', () {
      notifier.applySmartDefaults();
      
      final state = container.read(mealFormProvider);
      expect(state.mealType, isIn(['breakfast', 'lunch', 'snack', 'dinner']));
      expect(state.date.day, equals(DateTime.now().day));
    });

    test('should validate form correctly', () {
      // Initially invalid
      expect(container.read(mealFormProvider).isValid, isFalse);
      
      // Add restaurant name only - still invalid
      notifier.updateRestaurantName('Test Restaurant');
      expect(container.read(mealFormProvider).isValid, isFalse);
      
      // Add cost - now valid
      notifier.updateCost(20.0);
      expect(container.read(mealFormProvider).isValid, isTrue);
      
      // Set cost to 0 - invalid again
      notifier.updateCost(0.0);
      expect(container.read(mealFormProvider).isValid, isFalse);
    });

    test('should clear form', () {
      // Set some values
      notifier.updateRestaurantName('Test Restaurant');
      notifier.updateCost(25.0);
      notifier.updateNotes('Test notes');
      
      // Clear form
      notifier.clearForm();
      
      final state = container.read(mealFormProvider);
      expect(state.restaurantName, isEmpty);
      expect(state.cost, isNull);
      expect(state.notes, isEmpty);
      expect(state.isDraft, isFalse);
    });

    test('should convert to meal entity', () {
      const userId = 1;
      const restaurantName = 'Test Restaurant';
      const cost = 25.50;
      const notes = 'Great meal';
      const mealType = 'lunch';
      
      notifier.updateRestaurantName(restaurantName);
      notifier.updateCost(cost);
      notifier.updateNotes(notes);
      notifier.updateMealType(mealType);
      
      final state = container.read(mealFormProvider);
      final meal = state.toMeal(userId);
      
      expect(meal.userId, equals(userId));
      expect(meal.cost, equals(cost));
      expect(meal.notes, equals(notes));
      expect(meal.mealType, equals(mealType));
      expect(meal.restaurantId, isNull);
    });

    test('should handle error state', () {
      const errorMessage = 'Test error';
      
      notifier.setError(errorMessage);
      
      final state = container.read(mealFormProvider);
      expect(state.errorMessage, equals(errorMessage));
      expect(state.isLoading, isFalse);
    });

    test('should handle loading state', () {
      notifier.setLoading(true);
      
      final state = container.read(mealFormProvider);
      expect(state.isLoading, isTrue);
      
      notifier.setLoading(false);
      final updatedState = container.read(mealFormProvider);
      expect(updatedState.isLoading, isFalse);
    });
  });

  group('MealCategory', () {
    test('should provide correct meal categories', () {
      final container = ProviderContainer();
      final categories = container.read(mealCategoriesProvider);
      
      expect(categories, isNotEmpty);
      expect(categories.length, equals(5));
      
      // Check that all expected categories are present
      final categoryIds = categories.map((c) => c.id).toList();
      expect(categoryIds, contains('dining_out'));
      expect(categoryIds, contains('delivery'));
      expect(categoryIds, contains('takeout'));
      expect(categoryIds, contains('groceries'));
      expect(categoryIds, contains('snack'));
      
      // Check that categories have required fields
      for (final category in categories) {
        expect(category.id, isNotEmpty);
        expect(category.name, isNotEmpty);
        expect(category.description, isNotEmpty);
        expect(category.icon, isNotEmpty);
        expect(category.suggestedBudget, greaterThan(0));
      }
      
      container.dispose();
    });
  });

  group('BudgetImpact', () {
    test('should calculate low impact correctly', () {
      final container = ProviderContainer(
        overrides: [
          userPreferencesProvider.overrideWith((ref) {
            final notifier = UserPreferencesNotifier(MockUserRepository());
            notifier.state = const UserPreferences(weeklyBudget: 200.0);
            return notifier;
          }),
        ],
      );
      
      container.read(mealFormProvider.notifier).updateCost(8.0); // $8 out of $200 budget = 4%
      
      final budgetImpact = container.read(budgetImpactProvider);
      
      expect(budgetImpact.impactLevel, equals('low'));
      expect(budgetImpact.percentageOfWeeklyBudget, lessThan(5));
      expect(budgetImpact.message, contains('Great choice'));
      
      container.dispose();
    });

    test('should calculate moderate impact correctly', () {
      final container = ProviderContainer(
        overrides: [
          userPreferencesProvider.overrideWith((ref) {
            final notifier = UserPreferencesNotifier(MockUserRepository());
            notifier.state = const UserPreferences(weeklyBudget: 200.0);
            return notifier;
          }),
        ],
      );
      
      container.read(mealFormProvider.notifier).updateCost(20.0); // $20 out of $200 budget = 10%
      
      final budgetImpact = container.read(budgetImpactProvider);
      
      expect(budgetImpact.impactLevel, equals('moderate'));
      expect(budgetImpact.percentageOfWeeklyBudget, greaterThanOrEqualTo(5));
      expect(budgetImpact.percentageOfWeeklyBudget, lessThan(15));
      expect(budgetImpact.message, contains('Nice balance'));
      
      container.dispose();
    });

    test('should calculate high impact correctly', () {
      final container = ProviderContainer(
        overrides: [
          userPreferencesProvider.overrideWith((ref) {
            final notifier = UserPreferencesNotifier(MockUserRepository());
            notifier.state = const UserPreferences(weeklyBudget: 200.0);
            return notifier;
          }),
        ],
      );
      
      container.read(mealFormProvider.notifier).updateCost(40.0); // $40 out of $200 budget
      
      final budgetImpact = container.read(budgetImpactProvider);
      
      expect(budgetImpact.impactLevel, equals('high'));
      expect(budgetImpact.percentageOfWeeklyBudget, greaterThanOrEqualTo(15));
      expect(budgetImpact.percentageOfWeeklyBudget, lessThan(25));
      expect(budgetImpact.message, contains('special experience'));
      
      container.dispose();
    });

    test('should calculate very high impact correctly', () {
      final container = ProviderContainer(
        overrides: [
          userPreferencesProvider.overrideWith((ref) {
            final notifier = UserPreferencesNotifier(MockUserRepository());
            notifier.state = const UserPreferences(weeklyBudget: 200.0);
            return notifier;
          }),
        ],
      );
      
      container.read(mealFormProvider.notifier).updateCost(100.0); // $100 out of $200 budget
      
      final budgetImpact = container.read(budgetImpactProvider);
      
      expect(budgetImpact.impactLevel, equals('very_high'));
      expect(budgetImpact.percentageOfWeeklyBudget, greaterThanOrEqualTo(25));
      expect(budgetImpact.message, contains('significant investment'));
      
      container.dispose();
    });
  });
}