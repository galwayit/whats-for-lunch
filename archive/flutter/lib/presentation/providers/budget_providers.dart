import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/budget_repository_impl.dart';
import '../../data/repositories/meal_repository_impl.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/meal_repository.dart';
import 'database_provider.dart';
import 'user_preferences_provider.dart' as user_prefs;
import 'simple_providers.dart' as simple;

// Budget repository provider
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return BudgetRepositoryImpl(database);
});

// Current week's investment capacity state
class WeeklyInvestmentState {
  final double weeklyCapacity;
  final double currentSpent;
  final double remainingCapacity;
  final int experiencesLogged;
  final int targetExperiences;
  final List<Meal> weeklyMeals;
  final DateTime weekStartDate;
  final bool isLoading;
  final String? errorMessage;

  const WeeklyInvestmentState({
    this.weeklyCapacity = 200.0,
    this.currentSpent = 0.0,
    this.remainingCapacity = 200.0,
    this.experiencesLogged = 0,
    this.targetExperiences = 10,
    this.weeklyMeals = const [],
    required this.weekStartDate,
    this.isLoading = false,
    this.errorMessage,
  });

  WeeklyInvestmentState copyWith({
    double? weeklyCapacity,
    double? currentSpent,
    double? remainingCapacity,
    int? experiencesLogged,
    int? targetExperiences,
    List<Meal>? weeklyMeals,
    DateTime? weekStartDate,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WeeklyInvestmentState(
      weeklyCapacity: weeklyCapacity ?? this.weeklyCapacity,
      currentSpent: currentSpent ?? this.currentSpent,
      remainingCapacity: remainingCapacity ?? this.remainingCapacity,
      experiencesLogged: experiencesLogged ?? this.experiencesLogged,
      targetExperiences: targetExperiences ?? this.targetExperiences,
      weeklyMeals: weeklyMeals ?? this.weeklyMeals,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  double get capacityProgress => weeklyCapacity > 0 ? currentSpent / weeklyCapacity : 0.0;
  double get experienceProgress => targetExperiences > 0 ? experiencesLogged / targetExperiences : 0.0;
  
  String get capacityUsageLevel {
    final progress = capacityProgress;
    if (progress < 0.3) return 'low';
    if (progress < 0.7) return 'moderate';
    if (progress < 0.9) return 'high';
    return 'very_high';
  }

  String get investmentGuidanceLevel {
    final progress = capacityProgress;
    if (progress < 0.5) return 'excellent';
    if (progress < 0.8) return 'good';
    if (progress < 0.95) return 'moderate';
    return 'high';
  }
}

// Weekly investment state notifier with real-time calculations
class WeeklyInvestmentNotifier extends StateNotifier<WeeklyInvestmentState> {
  final Ref _ref;
  
  WeeklyInvestmentNotifier(this._mealRepository, this._userPreferences, this._ref) 
    : super(WeeklyInvestmentState(weekStartDate: _getWeekStartDate(DateTime.now()))) {
    _initialize();
    _startPeriodicUpdates();
  }

  final MealRepository _mealRepository;
  final UserPreferences? _userPreferences;
  
  Timer? _updateTimer;
  static const Duration _updateInterval = Duration(minutes: 5);

  void _startPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(_updateInterval, (_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _refreshData();
  }

  Future<void> _refreshData() async {
    if (mounted) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final preferences = _userPreferences;
      if (preferences == null) {
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'User preferences not available',
          );
        }
        return;
      }

      final weekStart = _getWeekStartDate(DateTime.now());
      final weekEnd = weekStart.add(const Duration(days: 7));

      // Get current week's meals with proper error handling
      List<Meal> weeklyMeals = [];
      try {
        final currentUserId = _ref.read(simple.currentUserIdProvider);
        if (currentUserId != null) {
          weeklyMeals = await _mealRepository.getMealsByDateRange(currentUserId, weekStart, weekEnd);
        } else {
          // No user logged in, return empty list
          weeklyMeals = [];
        }
      } catch (e) {
        // Handle meal retrieval error gracefully
        weeklyMeals = [];
      }

      final currentSpent = weeklyMeals.fold<double>(0.0, (sum, meal) => sum + meal.cost);
      final remainingCapacity = (preferences.weeklyBudget - currentSpent).clamp(0.0, double.infinity);

      if (mounted) {
        state = state.copyWith(
          weeklyCapacity: preferences.weeklyBudget,
          currentSpent: currentSpent,
          remainingCapacity: remainingCapacity,
          experiencesLogged: weeklyMeals.length,
          targetExperiences: _calculateTargetExperiences(preferences),
          weeklyMeals: weeklyMeals,
          weekStartDate: weekStart,
          isLoading: false,
          errorMessage: null,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load investment data: ${e.toString()}',
        );
      }
    }
  }

  int _calculateTargetExperiences(UserPreferences preferences) {
    // Calculate target based on meal frequency and budget level
    final baseTarget = preferences.mealFrequencyPerDay * 7;
    final budgetMultiplier = preferences.budgetLevel / 4.0; // Scale by budget level
    return (baseTarget * budgetMultiplier).round().clamp(5, 21); // 5-21 experiences per week
  }

  static DateTime _getWeekStartDate(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  // Real-time investment impact calculation for meal entry
  InvestmentImpact calculateMealImpact(double mealCost) {
    final totalAfterMeal = state.currentSpent + mealCost;
    final capacityAfterMeal = totalAfterMeal / state.weeklyCapacity;
    
    String impactLevel;
    String message;
    String guidanceLevel;
    
    if (capacityAfterMeal < 0.3) {
      impactLevel = 'low';
      guidanceLevel = 'excellent';
      message = 'Perfect! This investment keeps you well within your comfort zone.';
    } else if (capacityAfterMeal < 0.7) {
      impactLevel = 'moderate';
      guidanceLevel = 'good';
      message = 'Great balance between enjoyment and your weekly investment goals.';
    } else if (capacityAfterMeal < 0.9) {
      impactLevel = 'high';
      guidanceLevel = 'moderate';
      message = 'This is a significant investment. Make sure it aligns with your priorities.';
    } else {
      impactLevel = 'very_high';
      guidanceLevel = 'high';
      message = 'This investment will exceed your weekly capacity. Consider adjusting the amount.';
    }

    return InvestmentImpact(
      mealCost: mealCost,
      projectedSpent: totalAfterMeal,
      projectedRemaining: (state.weeklyCapacity - totalAfterMeal).clamp(0.0, double.infinity),
      impactLevel: impactLevel,
      guidanceLevel: guidanceLevel,
      message: message,
      exceedsCapacity: totalAfterMeal > state.weeklyCapacity,
    );
  }

  // Manual refresh for pull-to-refresh
  Future<void> refreshData() async {
    await _refreshData();
  }

  // Update weekly capacity
  Future<void> updateWeeklyCapacity(double newCapacity) async {
    if (mounted) {
      state = state.copyWith(
        weeklyCapacity: newCapacity,
        remainingCapacity: (newCapacity - state.currentSpent).clamp(0.0, double.infinity),
      );
    }
  }
}

// Investment impact for real-time meal entry feedback
class InvestmentImpact {
  final double mealCost;
  final double projectedSpent;
  final double projectedRemaining;
  final String impactLevel;
  final String guidanceLevel;
  final String message;
  final bool exceedsCapacity;

  const InvestmentImpact({
    required this.mealCost,
    required this.projectedSpent,
    required this.projectedRemaining,
    required this.impactLevel,
    required this.guidanceLevel,
    required this.message,
    required this.exceedsCapacity,
  });
}

// Provider for weekly investment state
final weeklyInvestmentProvider = StateNotifierProvider<WeeklyInvestmentNotifier, WeeklyInvestmentState>((ref) {
  final mealRepository = ref.watch(Provider<MealRepository>((ref) {
    final database = ref.watch(databaseProvider);
    return MealRepositoryImpl(database);
  }));
  
  final userPreferences = ref.watch(user_prefs.userPreferencesProvider);
  
  return WeeklyInvestmentNotifier(mealRepository, userPreferences, ref);
});

// Real-time investment impact provider for meal entry
final mealInvestmentImpactProvider = Provider.family<InvestmentImpact?, double?>((ref, mealCost) {
  if (mealCost == null || mealCost <= 0) return null;
  
  final weeklyInvestment = ref.watch(weeklyInvestmentProvider.notifier);
  return weeklyInvestment.calculateMealImpact(mealCost);
});

// Achievement system state
class AchievementState {
  final List<Achievement> unlockedAchievements;
  final List<Achievement> availableAchievements;
  final Achievement? latestAchievement;
  final int totalPoints;
  final String currentLevel;

  const AchievementState({
    this.unlockedAchievements = const [],
    this.availableAchievements = const [],
    this.latestAchievement,
    this.totalPoints = 0,
    this.currentLevel = 'Beginner',
  });

  AchievementState copyWith({
    List<Achievement>? unlockedAchievements,
    List<Achievement>? availableAchievements,
    Achievement? latestAchievement,
    int? totalPoints,
    String? currentLevel,
  }) {
    return AchievementState(
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      availableAchievements: availableAchievements ?? this.availableAchievements,
      latestAchievement: latestAchievement,
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevel: currentLevel ?? this.currentLevel,
    );
  }
}

// Achievement entity
class Achievement {
  final String id;
  final String title;
  final String description;
  final String category;
  final int points;
  final String iconName;
  final DateTime? unlockedAt;
  final bool isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.points,
    required this.iconName,
    this.unlockedAt,
    this.isUnlocked = false,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? points,
    String? iconName,
    DateTime? unlockedAt,
    bool? isUnlocked,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      points: points ?? this.points,
      iconName: iconName ?? this.iconName,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

// Achievement system notifier
class AchievementNotifier extends StateNotifier<AchievementState> {
  AchievementNotifier() : super(const AchievementState()) {
    _initializeAchievements();
  }

  void _initializeAchievements() {
    final availableAchievements = [
      const Achievement(
        id: 'first_experience',
        title: 'First Investment',
        description: 'Log your first dining experience',
        category: 'Getting Started',
        points: 10,
        iconName: 'celebration',
      ),
      const Achievement(
        id: 'week_optimizer',
        title: 'Weekly Optimizer',
        description: 'Stay within 80% of weekly capacity for a full week',
        category: 'Budget Management',
        points: 25,
        iconName: 'eco',
      ),
      const Achievement(
        id: 'experience_explorer',
        title: 'Experience Explorer',
        description: 'Try 5 different types of dining experiences',
        category: 'Diversity',
        points: 20,
        iconName: 'explore',
      ),
      const Achievement(
        id: 'consistent_tracker',
        title: 'Consistent Tracker',
        description: 'Log experiences for 7 consecutive days',
        category: 'Consistency',
        points: 30,
        iconName: 'calendar_today',
      ),
      const Achievement(
        id: 'smart_spender',
        title: 'Smart Investor',
        description: 'Complete a month with optimal investment distribution',
        category: 'Budget Management',
        points: 50,
        iconName: 'psychology',
      ),
    ];

    state = state.copyWith(availableAchievements: availableAchievements);
  }

  void checkAchievements(WeeklyInvestmentState weeklyState, List<Meal> allMeals) {
    final newAchievements = <Achievement>[];

    // Check First Investment
    if (!_isAchievementUnlocked('first_experience') && allMeals.isNotEmpty) {
      newAchievements.add(_unlockAchievement('first_experience'));
    }

    // Check Weekly Optimizer
    if (!_isAchievementUnlocked('week_optimizer') && 
        weeklyState.capacityProgress <= 0.8 && 
        weeklyState.experiencesLogged >= 5) {
      newAchievements.add(_unlockAchievement('week_optimizer'));
    }

    // Check Experience Explorer
    if (!_isAchievementUnlocked('experience_explorer')) {
      final uniqueTypes = allMeals.map((m) => m.mealType).toSet();
      if (uniqueTypes.length >= 5) {
        newAchievements.add(_unlockAchievement('experience_explorer'));
      }
    }

    // Check Consistent Tracker
    if (!_isAchievementUnlocked('consistent_tracker')) {
      if (_hasConsecutiveDays(allMeals, 7)) {
        newAchievements.add(_unlockAchievement('consistent_tracker'));
      }
    }

    if (newAchievements.isNotEmpty) {
      final updatedUnlocked = [...state.unlockedAchievements, ...newAchievements];
      final totalPoints = updatedUnlocked.fold<int>(0, (sum, achievement) => sum + achievement.points);
      
      state = state.copyWith(
        unlockedAchievements: updatedUnlocked,
        latestAchievement: newAchievements.last,
        totalPoints: totalPoints,
        currentLevel: _calculateLevel(totalPoints),
      );
    }
  }

  bool _isAchievementUnlocked(String id) {
    return state.unlockedAchievements.any((a) => a.id == id);
  }

  Achievement _unlockAchievement(String id) {
    final achievement = state.availableAchievements.firstWhere((a) => a.id == id);
    return achievement.copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
  }

  bool _hasConsecutiveDays(List<Meal> meals, int days) {
    if (meals.length < days) return false;
    
    final sortedMeals = List<Meal>.from(meals)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    final mealDates = sortedMeals.map((m) => 
      DateTime(m.date.year, m.date.month, m.date.day)
    ).toSet().toList()..sort();
    
    int consecutiveCount = 1;
    for (int i = 1; i < mealDates.length; i++) {
      if (mealDates[i].difference(mealDates[i-1]).inDays == 1) {
        consecutiveCount++;
        if (consecutiveCount >= days) return true;
      } else {
        consecutiveCount = 1;
      }
    }
    
    return false;
  }

  String _calculateLevel(int points) {
    if (points < 50) return 'Beginner';
    if (points < 150) return 'Explorer';
    if (points < 300) return 'Optimizer';
    if (points < 500) return 'Expert';
    return 'Master';
  }

  void dismissLatestAchievement() {
    state = state.copyWith(latestAchievement: null);
  }
}

// Achievement provider
final achievementProvider = StateNotifierProvider<AchievementNotifier, AchievementState>((ref) {
  return AchievementNotifier();
});

// Auto-refresh achievements when weekly data changes
final _achievementWatcherProvider = Provider((ref) {
  final achievementNotifier = ref.watch(achievementProvider.notifier);
  
  // Get all user meals for achievement checking
  ref.listen(weeklyInvestmentProvider, (previous, next) {
    if (!next.isLoading && next.errorMessage == null) {
      // In a real implementation, we'd get all user meals here
      // For now, we'll use the weekly meals as a proxy
      achievementNotifier.checkAchievements(next, next.weeklyMeals);
    }
  });
  
  return null;
});

// Budget setup state for onboarding
class BudgetSetupState {
  final int currentStep;
  final double weeklyCapacity;
  final List<String> experiencePreferences;
  final bool celebrateAchievements;
  final bool isCompleted;
  final DateTime? completedAt;

  const BudgetSetupState({
    this.currentStep = 0,
    this.weeklyCapacity = 200.0,
    this.experiencePreferences = const [],
    this.celebrateAchievements = true,
    this.isCompleted = false,
    this.completedAt,
  });

  BudgetSetupState copyWith({
    int? currentStep,
    double? weeklyCapacity,
    List<String>? experiencePreferences,
    bool? celebrateAchievements,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return BudgetSetupState(
      currentStep: currentStep ?? this.currentStep,
      weeklyCapacity: weeklyCapacity ?? this.weeklyCapacity,
      experiencePreferences: experiencePreferences ?? this.experiencePreferences,
      celebrateAchievements: celebrateAchievements ?? this.celebrateAchievements,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get canProceed {
    switch (currentStep) {
      case 0: return weeklyCapacity > 0;
      case 1: return experiencePreferences.isNotEmpty;
      case 2: return true; // Celebration setup is optional
      default: return false;
    }
  }
}

// Budget setup notifier for 3-step onboarding
class BudgetSetupNotifier extends StateNotifier<BudgetSetupState> {
  BudgetSetupNotifier() : super(const BudgetSetupState());

  void updateWeeklyCapacity(double capacity) {
    state = state.copyWith(weeklyCapacity: capacity);
  }

  void updateExperiencePreferences(List<String> preferences) {
    state = state.copyWith(experiencePreferences: preferences);
  }

  void toggleCelebrations(bool celebrate) {
    state = state.copyWith(celebrateAchievements: celebrate);
  }

  void nextStep() {
    if (state.currentStep < 2 && state.canProceed) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void completeSetup() {
    state = state.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
  }

  void reset() {
    state = const BudgetSetupState();
  }
}

// Budget setup provider
final budgetSetupProvider = StateNotifierProvider<BudgetSetupNotifier, BudgetSetupState>((ref) {
  return BudgetSetupNotifier();
});

// Initialize achievement watcher
final initializeAchievementWatcherProvider = Provider((ref) {
  ref.watch(_achievementWatcherProvider);
  return null;
});

// Weekly investment capacity provider (derived state)
final weeklyInvestmentCapacityProvider = Provider<double>((ref) {
  final weeklyState = ref.watch(weeklyInvestmentProvider);
  return weeklyState.weeklyCapacity;
});

// Weekly spent provider (derived state)
final weeklySpentProvider = Provider<double>((ref) {
  final weeklyState = ref.watch(weeklyInvestmentProvider);
  return weeklyState.currentSpent;
});