import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/user_repository.dart';
import 'database_provider.dart';
import 'simple_providers.dart';

class UserPreferencesNotifier extends StateNotifier<UserPreferences?> {
  final UserRepository _userRepository;
  int? _currentUserId;

  UserPreferencesNotifier(this._userRepository) : super(null);

  Future<void> loadUserPreferences(int userId) async {
    _currentUserId = userId;
    final user = await _userRepository.getUserById(userId);
    if (user != null) {
      state = UserPreferences.fromJson(user.preferences);
    } else {
      // Create default preferences for new user
      state = const UserPreferences();
    }
  }

  Future<void> updatePreferences(UserPreferences preferences) async {
    if (_currentUserId == null) return;

    try {
      // Update local state first
      state = preferences;

      // Update in database
      final user = await _userRepository.getUserById(_currentUserId!);
      if (user != null) {
        final updatedUser = user.copyWith(preferences: preferences.toJson());
        await _userRepository.updateUser(updatedUser);
      }
    } catch (e) {
      // If database update fails, revert state and rethrow
      state = null;
      rethrow;
    }
  }

  Future<void> updateDietaryRestrictions(List<String> restrictions) async {
    if (state != null) {
      await updatePreferences(state!.copyWith(dietaryRestrictions: restrictions));
    }
  }

  Future<void> updateCuisinePreferences(List<String> cuisines) async {
    if (state != null) {
      await updatePreferences(state!.copyWith(cuisinePreferences: cuisines));
    }
  }

  Future<void> updateBudgetLevel(int budgetLevel) async {
    if (state != null) {
      await updatePreferences(state!.copyWith(budgetLevel: budgetLevel));
    }
  }

  Future<void> updateMaxTravelDistance(double distance) async {
    if (state != null) {
      await updatePreferences(state!.copyWith(maxTravelDistance: distance));
    }
  }

  Future<void> updateWeeklyBudget(double budget) async {
    if (state != null) {
      await updatePreferences(state!.copyWith(weeklyBudget: budget));
    }
  }

  Future<void> toggleIncludeChains() async {
    if (state != null) {
      await updatePreferences(state!.copyWith(includeChains: !state!.includeChains));
    }
  }
}

// User preferences provider
final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences?>((ref) {
  final userRepository = ref.read(userRepositoryProvider);
  return UserPreferencesNotifier(userRepository);
});

// Convenience provider to get current user
final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final userRepository = ref.read(userRepositoryProvider);
  return userRepository.getUserById(userId);
});

// Convenience provider to create a new user
final createUserProvider = Provider<Future<int> Function(String name)>((ref) {
  return (String name) async {
    final userRepository = ref.read(userRepositoryProvider);
    final defaultPreferences = const UserPreferences();
    
    final newUser = UserEntity(
      name: name,
      preferences: defaultPreferences.toJson(),
      createdAt: DateTime.now(),
    );
    
    final userId = await userRepository.createUser(newUser);
    
    // Set as current user
    ref.read(currentUserIdProvider.notifier).state = userId;
    
    // Load preferences
    await ref.read(userPreferencesProvider.notifier).loadUserPreferences(userId);
    
    return userId;
  };
});