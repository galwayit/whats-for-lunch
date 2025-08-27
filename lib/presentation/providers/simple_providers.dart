import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart' as domain;
import '../../domain/entities/user_preferences.dart';
import '../../domain/entities/restaurant.dart';
import 'database_provider.dart';
import 'discovery_providers.dart';

// Simple in-memory state management for Stage 1
final currentUserIdProvider = StateProvider<int?>((ref) {
  // Auto-set demo user for Stage 1 demo - will be validated by ensureDemoUserProvider
  return 1;
});

// Provider that ensures demo user exists in database
final ensureDemoUserProvider = FutureProvider<void>((ref) async {
  final userRepository = ref.read(userRepositoryProvider);
  final currentUserId = ref.read(currentUserIdProvider);
  
  if (currentUserId != null) {
    // Check if the current user exists in database
    final existingUser = await userRepository.getUserById(currentUserId);
    
    if (existingUser == null) {
      // Create demo user if it doesn't exist
      final demoUser = domain.UserEntity(
        name: 'Demo User',
        preferences: {},
        createdAt: DateTime.now(),
      );
      
      await userRepository.createUser(demoUser);
    }
  }
});

final simpleUserPreferencesProvider = StateNotifierProvider<SimpleUserPreferencesNotifier, UserPreferences?>((ref) {
  final notifier = SimpleUserPreferencesNotifier();
  // Auto-initialize with default preferences for Stage 1
  notifier.loadUserPreferences(1);
  return notifier;
});

class SimpleUserPreferencesNotifier extends StateNotifier<UserPreferences?> {
  SimpleUserPreferencesNotifier() : super(null);

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
    final userRepository = ref.read(userRepositoryProvider);
    
    // Check if user ID 1 already exists
    final existingUser = await userRepository.getUserById(1);
    
    int userId;
    if (existingUser == null) {
      // Create the user in the database
      final newUser = domain.UserEntity(
        name: name,
        preferences: {},
        createdAt: DateTime.now(),
      );
      
      userId = await userRepository.createUser(newUser);
    } else {
      // User already exists, use existing ID
      userId = existingUser.id!;
    }
    
    // Set as current user
    ref.read(currentUserIdProvider.notifier).state = userId;
    
    // Load default preferences
    ref.read(simpleUserPreferencesProvider.notifier).loadUserPreferences(userId);
    
    return userId;
  };
});

/// Home page search state
class HomeSearchState {
  final bool isSearching;
  final bool hasSearched;
  final Restaurant? recommendedRestaurant;
  final String? error;

  const HomeSearchState({
    this.isSearching = false,
    this.hasSearched = false,
    this.recommendedRestaurant,
    this.error,
  });

  HomeSearchState copyWith({
    bool? isSearching,
    bool? hasSearched,
    Restaurant? recommendedRestaurant,
    String? error,
  }) {
    return HomeSearchState(
      isSearching: isSearching ?? this.isSearching,
      hasSearched: hasSearched ?? this.hasSearched,
      recommendedRestaurant: recommendedRestaurant ?? this.recommendedRestaurant,
      error: error ?? this.error,
    );
  }
}

/// Home search state notifier
class HomeSearchNotifier extends StateNotifier<HomeSearchState> {
  final Ref _ref;

  HomeSearchNotifier(this._ref) : super(const HomeSearchState());

  /// Start restaurant search
  Future<void> searchForRestaurant() async {
    try {
      state = state.copyWith(
        isSearching: true,
        hasSearched: false,
        recommendedRestaurant: null,
        error: null,
      );

      // Ensure minimum loading time for better UX (at least 1.5 seconds)
      final searchFuture = _performSearch();
      final delayFuture = Future.delayed(const Duration(milliseconds: 1500));

      await Future.wait([searchFuture, delayFuture]);

      state = state.copyWith(
        isSearching: false,
        hasSearched: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        hasSearched: true,
        recommendedRestaurant: null,
        error: e.toString(),
      );
    }
  }

  /// Perform the actual search and update state
  Future<void> _performSearch() async {
    // Trigger restaurant discovery with force refresh to ensure it runs
    await _ref.read(discoveryProvider.notifier).searchRestaurants(forceRefresh: true);

    // Get discovered restaurants and user preferences
    final discoveryState = _ref.read(discoveryProvider);
    final preferences = _ref.read(simpleUserPreferencesProvider);

    if (discoveryState.restaurants.isEmpty) {
      state = state.copyWith(recommendedRestaurant: null);
      return;
    }

    // Find the best matching restaurant based on user preferences
    Restaurant? bestMatch;
    double bestScore = -1;

    for (final restaurant in discoveryState.restaurants) {
      double score = _calculateCompatibilityScore(restaurant, preferences);

      if (score > bestScore) {
        bestScore = score;
        bestMatch = restaurant;
      }
    }

    // Only recommend if we found a reasonably good match
    if (bestMatch != null && bestScore > 0.1) {
      state = state.copyWith(recommendedRestaurant: bestMatch);
    } else {
      state = state.copyWith(recommendedRestaurant: null);
    }
  }

  /// Calculate compatibility score for a restaurant
  double _calculateCompatibilityScore(Restaurant restaurant, UserPreferences? preferences) {
    double score = 0.0;

    if (preferences != null) {
      // Budget level matching (weight: 40%)
      final userBudgetLevel = preferences.budgetLevel ?? 2;
      if (restaurant.priceLevel != null) {
        final priceDiff = (restaurant.priceLevel! - userBudgetLevel).abs();
        score += (4 - priceDiff) * 0.4; // Higher score for closer price match
      } else {
        score += 2.0 * 0.4; // Neutral score if price level unknown
      }

      // Distance preference (weight: 30%)
      final maxDistance = preferences.maxTravelDistance ?? 5.0;
      if (restaurant.distanceFromUser != null) {
        if (restaurant.distanceFromUser! <= maxDistance) {
          // Prefer closer restaurants within the max distance
          final distanceScore = 1.0 - (restaurant.distanceFromUser! / maxDistance);
          score += distanceScore * 0.3;
        }
        // No points if beyond max distance
      } else {
        score += 0.5 * 0.3; // Half points if distance unknown
      }

      // Rating (weight: 20%)
      if (restaurant.rating != null && restaurant.rating! > 0) {
        score += (restaurant.rating! / 5.0) * 0.2;
      } else {
        score += 0.5 * 0.2; // Half points if rating unknown
      }

      // Open now bonus (weight: 10%)
      if (restaurant.isOpenNow == true) {
        score += 1.0 * 0.1;
      }
    } else {
      // No preferences available, use basic scoring
      if (restaurant.rating != null) {
        score += restaurant.rating! / 5.0;
      } else {
        score += 0.5;
      }
    }

    return score;
  }

  /// Reset search state
  void resetSearch() {
    state = const HomeSearchState();
  }

  /// Get recommendation reasons for display
  List<String> getRecommendationReasons(Restaurant restaurant, UserPreferences? preferences) {
    List<String> reasons = [];

    if (preferences != null) {
      // Budget match reason
      final userBudgetLevel = preferences.budgetLevel ?? 2;
      if (restaurant.priceLevel != null) {
        if (restaurant.priceLevel == userBudgetLevel) {
          final dollarSigns = '\$' * userBudgetLevel;
          reasons.add('Perfect budget match ($dollarSigns)');
        } else if ((restaurant.priceLevel! - userBudgetLevel).abs() <= 1) {
          reasons.add('Close to your budget range');
        }
      }

      // Distance reason
      final maxDistance = preferences.maxTravelDistance ?? 5.0;
      if (restaurant.distanceFromUser != null) {
        if (restaurant.distanceFromUser! <= maxDistance * 0.5) {
          reasons.add('Very close to you (${restaurant.distanceFromUser!.toStringAsFixed(1)}km)');
        } else if (restaurant.distanceFromUser! <= maxDistance) {
          reasons.add('Within your preferred distance');
        }
      }

      // Rating reason
      if (restaurant.rating != null && restaurant.rating! >= 4.0) {
        reasons.add('Highly rated (${restaurant.rating!.toStringAsFixed(1)}/5)');
      }

      // Open now reason
      if (restaurant.isOpenNow == true) {
        reasons.add('Open right now');
      }

      // Cuisine match (if available)
      if (restaurant.cuisineType != null) {
        reasons.add('Great ${restaurant.cuisineType!.toLowerCase()} cuisine');
      }
    }

    // If no specific reasons, add generic ones
    if (reasons.isEmpty) {
      if (restaurant.rating != null && restaurant.rating! > 0) {
        reasons.add('Good ratings (${restaurant.rating!.toStringAsFixed(1)}/5)');
      }
      if (restaurant.cuisineType != null) {
        reasons.add('${restaurant.cuisineType} cuisine');
      }
      if (reasons.isEmpty) {
        reasons.add('Popular choice in your area');
      }
    }

    return reasons;
  }
}

/// Home search state provider
final homeSearchProvider = StateNotifierProvider<HomeSearchNotifier, HomeSearchState>((ref) {
  return HomeSearchNotifier(ref);
});