import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_preferences.dart';

// Simple in-memory state management for Stage 1
final currentUserIdProvider = StateProvider<int?>((ref) => null);

final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences?>((ref) {
  return UserPreferencesNotifier();
});

class UserPreferencesNotifier extends StateNotifier<UserPreferences?> {
  UserPreferencesNotifier() : super(null);

  void loadUserPreferences(int userId) {
    // For Stage 1, just load default preferences
    state = const UserPreferences(
      budgetLevel: 2,
      maxTravelDistance: 5.0,
      includeChains: true,
    );
  }

  void updatePreferences(UserPreferences preferences) {
    state = preferences;
  }

  void updateBudgetLevel(int budgetLevel) {
    if (state != null) {
      state = state!.copyWith(budgetLevel: budgetLevel);
    }
  }

  void updateMaxTravelDistance(double distance) {
    if (state != null) {
      state = state!.copyWith(maxTravelDistance: distance);
    }
  }

  void updateWeeklyBudget(double budget) {
    if (state != null) {
      state = state!.copyWith(weeklyBudget: budget);
    }
  }

  void toggleIncludeChains() {
    if (state != null) {
      state = state!.copyWith(includeChains: !state!.includeChains);
    }
  }
}

// Simple user provider for Stage 1
final currentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  
  return {
    'id': userId,
    'name': 'Demo User',
    'createdAt': DateTime.now().toIso8601String(),
  };
});

// Create user function for Stage 1
final createUserProvider = Provider<Future<int> Function(String name)>((ref) {
  return (String name) async {
    // Simple ID generation for Stage 1
    const userId = 1;
    
    // Set as current user
    ref.read(currentUserIdProvider.notifier).state = userId;
    
    // Load default preferences
    ref.read(userPreferencesProvider.notifier).loadUserPreferences(userId);
    
    return userId;
  };
});