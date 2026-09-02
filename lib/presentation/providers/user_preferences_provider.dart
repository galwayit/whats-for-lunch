// Single source of truth for user preferences state management.
// Provides a synchronous StateNotifierProvider that all screens can watch,
// while persisting changes to the database asynchronously.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart' as domain;
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/user_repository.dart';
import 'database_provider.dart';

// ---------------------------------------------------------------------------
// Current user ID -- simple synchronous state used across the app
// ---------------------------------------------------------------------------
final currentUserIdProvider = StateProvider<int?>((ref) {
  // Auto-set demo user for Stage 1 demo
  return 1;
});

// ---------------------------------------------------------------------------
// Ensure demo user exists in the database on first access
// ---------------------------------------------------------------------------
final ensureDemoUserProvider = FutureProvider<void>((ref) async {
  final userRepository = ref.read(userRepositoryProvider);
  final currentUserId = ref.read(currentUserIdProvider);

  if (currentUserId != null) {
    final existingUser = await userRepository.getUserById(currentUserId);

    if (existingUser == null) {
      final demoUser = domain.UserEntity(
        name: 'Demo User',
        preferences: {},
        createdAt: DateTime.now(),
      );
      await userRepository.createUser(demoUser);
    }
  }
});

// ---------------------------------------------------------------------------
// Synchronous user lookup for basic profile display
// ---------------------------------------------------------------------------
final currentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  return {
    'id': userId,
    'name': 'Demo User',
    'createdAt': DateTime.now().toIso8601String(),
  };
});

// ---------------------------------------------------------------------------
// User Preferences Notifier -- the single source of truth
// ---------------------------------------------------------------------------

class UserPreferencesNotifier extends StateNotifier<UserPreferences?> {
  final UserRepository _userRepository;
  int? _currentUserId;

  UserPreferencesNotifier(this._userRepository) : super(null);

  /// Load preferences from the database for [userId].
  /// Sets state synchronously once the async DB call completes.
  Future<void> loadUserPreferences(int userId) async {
    _currentUserId = userId;
    final user = await _userRepository.getUserById(userId);
    if (user != null) {
      state = UserPreferences.fromJson(user.preferences);
    } else {
      // Provide sensible defaults for a new / unknown user
      state = const UserPreferences(
        budgetLevel: 2,
        maxTravelDistance: 5.0,
        includeChains: true,
      );
    }
  }

  /// Replace the entire preferences object.
  /// State is updated synchronously first, then persisted to the database.
  Future<void> updatePreferences(UserPreferences preferences) async {
    final previousState = state;

    // Update in-memory state immediately so watchers react right away
    state = preferences;

    if (_currentUserId == null) return;

    try {
      final user = await _userRepository.getUserById(_currentUserId!);
      if (user != null) {
        final updatedUser =
            user.copyWith(preferences: preferences.toJson());
        await _userRepository.updateUser(updatedUser);
      }
    } catch (e) {
      // Revert to previous state on DB failure and propagate the error
      state = previousState;
      rethrow;
    }
  }

  /// Convenience: update dietary restrictions only.
  Future<void> updateDietaryRestrictions(List<String> restrictions) async {
    if (state != null) {
      await updatePreferences(
          state!.copyWith(dietaryRestrictions: restrictions));
    }
  }

  /// Convenience: update cuisine preferences only.
  Future<void> updateCuisinePreferences(List<String> cuisines) async {
    if (state != null) {
      await updatePreferences(
          state!.copyWith(cuisinePreferences: cuisines));
    }
  }

  /// Convenience: update budget level only.
  Future<void> updateBudgetLevel(int budgetLevel) async {
    if (state != null) {
      await updatePreferences(state!.copyWith(budgetLevel: budgetLevel));
    }
  }

  /// Convenience: update max travel distance only.
  Future<void> updateMaxTravelDistance(double distance) async {
    if (state != null) {
      await updatePreferences(state!.copyWith(maxTravelDistance: distance));
    }
  }

  /// Convenience: update weekly budget only.
  Future<void> updateWeeklyBudget(double budget) async {
    if (state != null) {
      await updatePreferences(state!.copyWith(weeklyBudget: budget));
    }
  }

  /// Convenience: toggle the include-chains flag.
  Future<void> toggleIncludeChains() async {
    if (state != null) {
      await updatePreferences(
          state!.copyWith(includeChains: !state!.includeChains));
    }
  }
}

// ---------------------------------------------------------------------------
// The provider definition -- synchronous StateNotifierProvider
// ---------------------------------------------------------------------------
final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences?>((ref) {
  final userRepository = ref.read(userRepositoryProvider);
  final notifier = UserPreferencesNotifier(userRepository);
  // Auto-initialise with default preferences so screens never start with null
  notifier.loadUserPreferences(ref.read(currentUserIdProvider) ?? 1);
  return notifier;
});

// ---------------------------------------------------------------------------
// Create user helper -- persists to DB and sets current user
// ---------------------------------------------------------------------------
final createUserProvider =
    Provider<Future<int> Function(String name)>((ref) {
  return (String name) async {
    final userRepository = ref.read(userRepositoryProvider);

    // Check if user ID 1 already exists
    final existingUser = await userRepository.getUserById(1);

    int userId;
    if (existingUser == null) {
      final newUser = domain.UserEntity(
        name: name,
        preferences: {},
        createdAt: DateTime.now(),
      );
      userId = await userRepository.createUser(newUser);
    } else {
      userId = existingUser.id!;
    }

    // Set as current user
    ref.read(currentUserIdProvider.notifier).state = userId;

    // Load preferences from DB (creates defaults if needed)
    await ref.read(userPreferencesProvider.notifier).loadUserPreferences(userId);

    return userId;
  };
});
