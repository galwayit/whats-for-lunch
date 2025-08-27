import 'package:flutter_test/flutter_test.dart';
import 'package:what_we_have_for_lunch/domain/entities/meal.dart';
import 'package:what_we_have_for_lunch/presentation/providers/budget_providers.dart';

void main() {
  group('Investment Calculation Tests', () {
    test('should calculate weekly investment state correctly', () {
      // Arrange
      final weekStart = DateTime(2024, 1, 1); // Monday
      
      final state = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 75.50,
        remainingCapacity: 124.50,
        experiencesLogged: 3,
        targetExperiences: 10,
        weekStartDate: weekStart,
      );

      // Assert
      expect(state.capacityProgress, closeTo(0.3775, 0.001)); // 75.50 / 200.0
      expect(state.experienceProgress, closeTo(0.3, 0.001)); // 3 / 10
      expect(state.capacityUsageLevel, 'moderate'); // Between 0.3 and 0.7
      expect(state.investmentGuidanceLevel, 'excellent'); // Less than 0.5
    });

    test('should determine correct capacity usage levels', () {
      final weekStart = DateTime.now();

      // Low usage (< 30%)
      final lowUsage = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 50.0,
        weekStartDate: weekStart,
      );
      expect(lowUsage.capacityUsageLevel, 'low');
      expect(lowUsage.investmentGuidanceLevel, 'excellent');

      // Moderate usage (30-70%)
      final moderateUsage = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 100.0,
        weekStartDate: weekStart,
      );
      expect(moderateUsage.capacityUsageLevel, 'moderate');
      expect(moderateUsage.investmentGuidanceLevel, 'good');

      // High usage (70-90%)
      final highUsage = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 160.0, // 160/200 = 0.8
        remainingCapacity: 40.0,
        weekStartDate: weekStart,
      );
      expect(highUsage.capacityProgress, 0.8); // Debug: check actual progress
      expect(highUsage.capacityUsageLevel, 'high');
      expect(highUsage.investmentGuidanceLevel, 'moderate'); // 0.8 >= 0.8 and < 0.95

      // Very high usage (> 90%)
      final veryHighUsage = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 185.0, // 185/200 = 0.925 which is > 0.9
        weekStartDate: weekStart,
      );
      expect(veryHighUsage.capacityUsageLevel, 'very_high'); // Should be very_high since 0.925 > 0.9
      expect(veryHighUsage.investmentGuidanceLevel, 'moderate'); // 0.925 >= 0.8 and < 0.95
    });

    test('should create correct InvestmentImpact for low impact meal', () {
      // Arrange
      const mealCost = 15.0;
      const currentSpent = 30.0;
      const weeklyCapacity = 200.0;
      
      const projectedSpent = currentSpent + mealCost; // 45.0
      const projectedRemaining = weeklyCapacity - projectedSpent; // 155.0
      const capacityAfterMeal = projectedSpent / weeklyCapacity; // 0.225

      // Act
      const impact = InvestmentImpact(
        mealCost: mealCost,
        projectedSpent: projectedSpent,
        projectedRemaining: projectedRemaining,
        impactLevel: 'low', // < 0.3
        guidanceLevel: 'excellent',
        message: 'Perfect! This investment keeps you well within your comfort zone.',
        exceedsCapacity: false,
      );

      // Assert
      expect(impact.mealCost, mealCost);
      expect(impact.projectedSpent, projectedSpent);
      expect(impact.projectedRemaining, projectedRemaining);
      expect(impact.impactLevel, 'low');
      expect(impact.guidanceLevel, 'excellent');
      expect(impact.exceedsCapacity, false);
    });

    test('should create correct InvestmentImpact for high impact meal', () {
      // Arrange
      const mealCost = 60.0;
      const currentSpent = 150.0;
      const weeklyCapacity = 200.0;
      
      const projectedSpent = currentSpent + mealCost; // 210.0
      const projectedRemaining = 0.0; // Clamped to 0
      const capacityAfterMeal = projectedSpent / weeklyCapacity; // 1.05

      // Act
      const impact = InvestmentImpact(
        mealCost: mealCost,
        projectedSpent: projectedSpent,
        projectedRemaining: projectedRemaining,
        impactLevel: 'very_high', // > 0.9
        guidanceLevel: 'high',
        message: 'This investment will exceed your weekly capacity. Consider adjusting the amount.',
        exceedsCapacity: true,
      );

      // Assert
      expect(impact.mealCost, mealCost);
      expect(impact.projectedSpent, projectedSpent);
      expect(impact.projectedRemaining, projectedRemaining);
      expect(impact.impactLevel, 'very_high');
      expect(impact.guidanceLevel, 'high');
      expect(impact.exceedsCapacity, true);
    });

    test('should handle copyWith correctly for WeeklyInvestmentState', () {
      // Arrange
      final originalState = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 75.0,
        remainingCapacity: 125.0,
        experiencesLogged: 3,
        targetExperiences: 10,
        weekStartDate: DateTime.now(),
        isLoading: false,
      );

      // Act
      final updatedState = originalState.copyWith(
        currentSpent: 100.0,
        remainingCapacity: 100.0,
        experiencesLogged: 4,
        isLoading: true,
      );

      // Assert
      expect(updatedState.weeklyCapacity, 200.0); // Unchanged
      expect(updatedState.currentSpent, 100.0); // Changed
      expect(updatedState.remainingCapacity, 100.0); // Changed
      expect(updatedState.experiencesLogged, 4); // Changed
      expect(updatedState.targetExperiences, 10); // Unchanged
      expect(updatedState.isLoading, true); // Changed
    });
  });

  group('Achievement System Tests', () {
    test('should initialize Achievement correctly', () {
      // Arrange & Act
      const achievement = Achievement(
        id: 'test_achievement',
        title: 'Test Achievement',
        description: 'This is a test achievement',
        category: 'Testing',
        points: 25,
        iconName: 'celebration',
        isUnlocked: false,
      );

      // Assert
      expect(achievement.id, 'test_achievement');
      expect(achievement.title, 'Test Achievement');
      expect(achievement.description, 'This is a test achievement');
      expect(achievement.category, 'Testing');
      expect(achievement.points, 25);
      expect(achievement.iconName, 'celebration');
      expect(achievement.isUnlocked, false);
      expect(achievement.unlockedAt, null);
    });

    test('should create unlocked achievement correctly', () {
      // Arrange
      final unlockedAt = DateTime.now();
      const baseAchievement = Achievement(
        id: 'test_achievement',
        title: 'Test Achievement',
        description: 'This is a test achievement',
        category: 'Testing',
        points: 25,
        iconName: 'celebration',
      );

      // Act
      final unlockedAchievement = baseAchievement.copyWith(
        isUnlocked: true,
        unlockedAt: unlockedAt,
      );

      // Assert
      expect(unlockedAchievement.isUnlocked, true);
      expect(unlockedAchievement.unlockedAt, unlockedAt);
      expect(unlockedAchievement.id, baseAchievement.id);
      expect(unlockedAchievement.points, baseAchievement.points);
    });

    test('should handle AchievementState copyWith correctly', () {
      // Arrange
      const achievement1 = Achievement(
        id: 'achievement1',
        title: 'Achievement 1',
        description: 'First achievement',
        category: 'Category 1',
        points: 10,
        iconName: 'celebration',
      );

      const achievement2 = Achievement(
        id: 'achievement2',
        title: 'Achievement 2',
        description: 'Second achievement',
        category: 'Category 2',
        points: 20,
        iconName: 'eco',
      );

      const originalState = AchievementState(
        unlockedAchievements: [achievement1],
        availableAchievements: [achievement1, achievement2],
        totalPoints: 10,
        currentLevel: 'Beginner',
      );

      // Act
      final updatedState = originalState.copyWith(
        unlockedAchievements: [achievement1, achievement2],
        totalPoints: 30,
        currentLevel: 'Explorer',
        latestAchievement: achievement2,
      );

      // Assert
      expect(updatedState.unlockedAchievements.length, 2);
      expect(updatedState.totalPoints, 30);
      expect(updatedState.currentLevel, 'Explorer');
      expect(updatedState.latestAchievement, achievement2);
      expect(updatedState.availableAchievements.length, 2); // Unchanged
    });
  });

  group('Budget Setup Tests', () {
    test('should initialize BudgetSetupState with correct defaults', () {
      // Act
      const state = BudgetSetupState();

      // Assert
      expect(state.currentStep, 0);
      expect(state.weeklyCapacity, 200.0);
      expect(state.experiencePreferences, isEmpty);
      expect(state.celebrateAchievements, true);
      expect(state.isCompleted, false);
      expect(state.completedAt, null);
    });

    test('should validate canProceed correctly for each step', () {
      // Step 0: Weekly capacity validation
      const step0Valid = BudgetSetupState(currentStep: 0, weeklyCapacity: 250.0);
      expect(step0Valid.canProceed, true);

      const step0Invalid = BudgetSetupState(currentStep: 0, weeklyCapacity: 0.0);
      expect(step0Invalid.canProceed, false);

      // Step 1: Experience preferences validation
      const step1Valid = BudgetSetupState(
        currentStep: 1,
        experiencePreferences: ['Fine Dining', 'Casual Dining'],
      );
      expect(step1Valid.canProceed, true);

      const step1Invalid = BudgetSetupState(
        currentStep: 1,
        experiencePreferences: [],
      );
      expect(step1Invalid.canProceed, false);

      // Step 2: Always valid
      const step2 = BudgetSetupState(currentStep: 2);
      expect(step2.canProceed, true);
    });

    test('should handle BudgetSetupState copyWith correctly', () {
      // Arrange
      const originalState = BudgetSetupState(
        currentStep: 0,
        weeklyCapacity: 200.0,
        experiencePreferences: [],
        celebrateAchievements: true,
      );

      // Act
      final updatedState = originalState.copyWith(
        currentStep: 1,
        weeklyCapacity: 300.0,
        experiencePreferences: ['Fine Dining'],
        celebrateAchievements: false,
      );

      // Assert
      expect(updatedState.currentStep, 1);
      expect(updatedState.weeklyCapacity, 300.0);
      expect(updatedState.experiencePreferences, ['Fine Dining']);
      expect(updatedState.celebrateAchievements, false);
      expect(updatedState.isCompleted, false); // Unchanged
    });

    test('should complete setup correctly', () {
      // Arrange
      final completedAt = DateTime.now();
      const originalState = BudgetSetupState(
        currentStep: 2,
        weeklyCapacity: 300.0,
        experiencePreferences: ['Fine Dining', 'Casual Dining'],
      );

      // Act
      final completedState = originalState.copyWith(
        isCompleted: true,
        completedAt: completedAt,
      );

      // Assert
      expect(completedState.isCompleted, true);
      expect(completedState.completedAt, completedAt);
    });
  });

  group('Performance Tests', () {
    test('should handle large meal lists efficiently', () {
      // Arrange
      final largeMealList = List.generate(1000, (index) => 
        Meal(
          id: index,
          userId: 1,
          mealType: ['breakfast', 'lunch', 'dinner', 'snack'][index % 4],
          cost: 10.0 + (index % 50),
          date: DateTime.now().subtract(Duration(days: index % 365)),
        ),
      );

      // Act - Measure calculation performance
      final stopwatch = Stopwatch()..start();
      
      double totalCost = 0.0;
      for (final meal in largeMealList) {
        totalCost += meal.cost;
      }
      
      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(totalCost, greaterThan(0));
      print('1000 meal cost calculations took: ${stopwatch.elapsedMilliseconds}ms');
    });

    test('should perform investment impact calculations quickly', () {
      // Arrange
      final baseState = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 100.0,
        remainingCapacity: 100.0,
        weekStartDate: DateTime.now(),
      );

      // Act - Measure calculation performance
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 1000; i++) {
        final mealCost = 5.0 + (i % 50);
        final projectedSpent = baseState.currentSpent + mealCost;
        final capacityProgress = projectedSpent / baseState.weeklyCapacity;
        
        // Simulate impact level calculation
        String impactLevel;
        if (capacityProgress < 0.3) {
          impactLevel = 'low';
        } else if (capacityProgress < 0.7) {
          impactLevel = 'moderate';
        } else if (capacityProgress < 0.9) {
          impactLevel = 'high';
        } else {
          impactLevel = 'very_high';
        }
        
        // Use the result to prevent optimization
        expect(impactLevel, isNotNull);
      }
      
      stopwatch.stop();

      // Assert - Should complete 1000 calculations in well under 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      print('1000 impact level calculations took: ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}