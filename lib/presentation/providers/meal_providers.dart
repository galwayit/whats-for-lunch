import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/meal_repository_impl.dart';
import '../../domain/entities/meal.dart';
import '../../domain/repositories/meal_repository.dart';
import '../providers/database_provider.dart';
import '../providers/simple_providers.dart';
import '../providers/user_preferences_provider.dart';

// Provider for meal repository
final mealRepositoryProvider = Provider<MealRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return MealRepositoryImpl(database);
});

// Meal form state for auto-save and draft management
class MealFormState {
  final String restaurantName;
  final double? cost;
  final DateTime date;
  final String notes;
  final String mealType;
  final bool isLoading;
  final bool isDraft;
  final String? errorMessage;
  final DateTime lastSaved;

  const MealFormState({
    this.restaurantName = '',
    this.cost,
    required this.date,
    this.notes = '',
    this.mealType = 'dining_out',
    this.isLoading = false,
    this.isDraft = false,
    this.errorMessage,
    required this.lastSaved,
  });

  MealFormState copyWith({
    String? restaurantName,
    double? cost,
    DateTime? date,
    String? notes,
    String? mealType,
    bool? isLoading,
    bool? isDraft,
    String? errorMessage,
    DateTime? lastSaved,
  }) {
    return MealFormState(
      restaurantName: restaurantName ?? this.restaurantName,
      cost: cost ?? this.cost,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      mealType: mealType ?? this.mealType,
      isLoading: isLoading ?? this.isLoading,
      isDraft: isDraft ?? this.isDraft,
      errorMessage: errorMessage,
      lastSaved: lastSaved ?? this.lastSaved,
    );
  }

  bool get isValid => 
    restaurantName.trim().isNotEmpty && 
    cost != null && 
    cost! > 0;

  Meal toMeal(int userId) {
    return Meal(
      userId: userId,
      restaurantId: null, // Will be populated by restaurant lookup later
      mealType: mealType,
      cost: cost!,
      date: date,
      notes: notes.trim().isEmpty ? null : notes.trim(),
    );
  }
}

// Meal form state provider with auto-save functionality
class MealFormNotifier extends StateNotifier<MealFormState> {
  MealFormNotifier() : super(MealFormState(
    date: DateTime.now(),
    lastSaved: DateTime.now(),
  )) {
    _startAutoSave();
  }

  Timer? _autoSaveTimer;
  static const Duration _autoSaveInterval = Duration(seconds: 10);

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) {
      if (state.isDraft && state.restaurantName.isNotEmpty) {
        _saveDraft();
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void updateRestaurantName(String name) {
    state = state.copyWith(
      restaurantName: name,
      isDraft: true,
      errorMessage: null,
    );
  }

  void updateCost(double? cost) {
    state = state.copyWith(
      cost: cost,
      isDraft: true,
      errorMessage: null,
    );
  }

  void updateDate(DateTime date) {
    state = state.copyWith(
      date: date,
      isDraft: true,
      errorMessage: null,
    );
  }

  void updateNotes(String notes) {
    state = state.copyWith(
      notes: notes,
      isDraft: true,
      errorMessage: null,
    );
  }

  void updateMealType(String mealType) {
    state = state.copyWith(
      mealType: mealType,
      isDraft: true,
      errorMessage: null,
    );
  }

  void _saveDraft() {
    // For now, just update the last saved time
    // In a more complex implementation, this would save to local storage
    state = state.copyWith(lastSaved: DateTime.now());
  }

  void clearForm() {
    state = MealFormState(
      date: DateTime.now(),
      lastSaved: DateTime.now(),
    );
  }

  void setError(String error) {
    state = state.copyWith(
      errorMessage: error,
      isLoading: false,
    );
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  // Smart defaults based on current time
  void applySmartDefaults() {
    final now = DateTime.now();
    final hour = now.hour;
    
    String mealType;
    if (hour < 10) {
      mealType = 'breakfast';
    } else if (hour < 15) {
      mealType = 'lunch';
    } else if (hour < 18) {
      mealType = 'snack';
    } else {
      mealType = 'dinner';
    }

    state = state.copyWith(
      date: now,
      mealType: mealType,
    );
  }
}

final mealFormProvider = StateNotifierProvider<MealFormNotifier, MealFormState>((ref) {
  return MealFormNotifier();
});

// Meal submission provider
final submitMealProvider = Provider<Future<bool> Function(MealFormState)>((ref) {
  final repository = ref.read(mealRepositoryProvider);
  final currentUserId = ref.read(currentUserIdProvider);
  
  return (MealFormState formState) async {
    if (currentUserId == null) {
      throw Exception('No user logged in');
    }

    if (!formState.isValid) {
      throw Exception('Please fill in all required fields');
    }

    try {
      final meal = formState.toMeal(currentUserId);
      await repository.createMeal(meal);
      return true;
    } catch (e) {
      throw Exception('Failed to save meal experience: ${e.toString()}');
    }
  };
});

// Recent meals provider for autocomplete suggestions
final recentMealsProvider = FutureProvider<List<Meal>>((ref) async {
  final repository = ref.read(mealRepositoryProvider);
  final currentUserId = ref.read(currentUserIdProvider);
  
  if (currentUserId == null) {
    return [];
  }

  try {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return await repository.getMealsByDateRange(currentUserId, thirtyDaysAgo, now);
  } catch (e) {
    return [];
  }
});

// Restaurant name suggestions based on recent meals
final restaurantSuggestionsProvider = Provider<List<String>>((ref) {
  final recentMealsAsync = ref.watch(recentMealsProvider);
  
  return recentMealsAsync.when(
    data: (meals) {
      // Extract unique restaurant names from recent meals, prioritizing by frequency
      final Map<String, int> restaurantFrequency = {};
      
      for (final meal in meals) {
        // For now, we'll use meal notes or generate from meal type
        // In future iterations, this will use actual restaurant data
        final restaurantName = _extractRestaurantName(meal);
        if (restaurantName.isNotEmpty) {
          restaurantFrequency[restaurantName] = (restaurantFrequency[restaurantName] ?? 0) + 1;
        }
      }
      
      // Sort by frequency and return top suggestions
      final suggestions = restaurantFrequency.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
      
      return suggestions.take(10).map((e) => e.key).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Helper function to extract restaurant names from meal data
String _extractRestaurantName(Meal meal) {
  // For now, generate common restaurant names based on meal type
  // This will be replaced with actual restaurant lookup in future phases
  switch (meal.mealType) {
    case 'breakfast':
      return 'Local Cafe';
    case 'lunch':
      return 'Downtown Bistro';
    case 'dinner':
      return 'Fine Dining';
    case 'dining_out':
      return 'Popular Restaurant';
    default:
      return 'Local Eatery';
  }
}

// Meal categories for the form
final mealCategoriesProvider = Provider<List<MealCategory>>((ref) {
  return [
    const MealCategory(
      id: 'dining_out',
      name: 'Dining Out',
      description: 'Restaurant, cafe, or food court experience',
      icon: 'restaurant',
      suggestedBudget: 25.0,
    ),
    const MealCategory(
      id: 'delivery',
      name: 'Delivery',
      description: 'Food delivered to your location',
      icon: 'delivery_dining',
      suggestedBudget: 20.0,
    ),
    const MealCategory(
      id: 'takeout',
      name: 'Takeout',
      description: 'Picked up from restaurant',
      icon: 'takeout_dining',
      suggestedBudget: 18.0,
    ),
    const MealCategory(
      id: 'groceries',
      name: 'Groceries',
      description: 'Ingredients for home cooking',
      icon: 'shopping_cart',
      suggestedBudget: 15.0,
    ),
    const MealCategory(
      id: 'snack',
      name: 'Snack',
      description: 'Quick bite or beverage',
      icon: 'local_cafe',
      suggestedBudget: 8.0,
    ),
  ];
});

// Meal category entity
class MealCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final double suggestedBudget;

  const MealCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.suggestedBudget,
  });
}

// Budget impact calculator
final budgetImpactProvider = Provider<BudgetImpact>((ref) {
  final userPreferences = ref.watch(userPreferencesProvider);
  final formState = ref.watch(mealFormProvider);
  
  if (userPreferences == null || formState.cost == null) {
    return const BudgetImpact();
  }

  final weeklyBudget = userPreferences.weeklyBudget;
  final currentCost = formState.cost!;
  final percentageOfBudget = (currentCost / weeklyBudget) * 100;
  
  String impactLevel;
  String message;
  
  if (percentageOfBudget < 5) {
    impactLevel = 'low';
    message = 'Great choice! This experience fits well within your weekly investment plan.';
  } else if (percentageOfBudget < 15) {
    impactLevel = 'moderate';
    message = 'Nice balance between enjoyment and your weekly goals.';
  } else if (percentageOfBudget < 25) {
    impactLevel = 'high';
    message = 'A special experience - make sure it aligns with your priorities.';
  } else {
    impactLevel = 'very_high';
    message = 'This is a significant investment in your dining experience.';
  }

  return BudgetImpact(
    percentageOfWeeklyBudget: percentageOfBudget,
    impactLevel: impactLevel,
    message: message,
    remainingBudget: weeklyBudget - currentCost,
  );
});

// Budget impact entity
class BudgetImpact {
  final double percentageOfWeeklyBudget;
  final String impactLevel;
  final String message;
  final double remainingBudget;

  const BudgetImpact({
    this.percentageOfWeeklyBudget = 0.0,
    this.impactLevel = 'none',
    this.message = '',
    this.remainingBudget = 0.0,
  });
}

// Meal timeline filter provider
final mealTimelineFilterProvider = StateProvider<String>((ref) => 'week');

// Filtered recent meals provider based on timeline filter
final filteredRecentMealsProvider = FutureProvider<List<Meal>>((ref) async {
  final repository = ref.read(mealRepositoryProvider);
  final currentUserId = ref.read(currentUserIdProvider);
  final filter = ref.watch(mealTimelineFilterProvider);
  
  if (currentUserId == null) {
    return [];
  }

  try {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (filter) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'all':
        startDate = DateTime(now.year - 5, 1, 1); // 5 years back as "all"
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }
    
    return await repository.getMealsByDateRange(currentUserId, startDate, now);
  } catch (e) {
    return [];
  }
});

// Override recentMealsProvider to use filtered data
final filteredRecentMealsOverrideProvider = Provider<AsyncValue<List<Meal>>>((ref) {
  final filter = ref.watch(mealTimelineFilterProvider);
  
  if (filter == 'week') {
    return ref.watch(recentMealsProvider);
  } else {
    return ref.watch(filteredRecentMealsProvider);
  }
});