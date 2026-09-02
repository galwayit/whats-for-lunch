// Non-preferences providers for home search, recommendations, and meal entry.
// User-preferences state has been unified into user_preferences_provider.dart;
// the symbols are re-exported here so that existing `import ... as simple`
// references continue to compile.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/restaurant.dart';
import '../../domain/entities/user_preferences.dart';
import 'discovery_providers.dart';

// ---------------------------------------------------------------------------
// Re-export unified preferences symbols so files importing this module
// as `simple` can still use `simple.userPreferencesProvider`, etc.
// ---------------------------------------------------------------------------
export 'user_preferences_provider.dart'
    show
        userPreferencesProvider,
        UserPreferencesNotifier,
        currentUserIdProvider,
        currentUserProvider,
        createUserProvider,
        ensureDemoUserProvider;

// Re-import locally so we can reference them inside this file
import 'user_preferences_provider.dart'
    show userPreferencesProvider;

/// Home page search state
class HomeSearchState {
  final bool isSearching;
  final bool hasSearched;
  final Restaurant? recommendedRestaurant;
  final String? error;
  final Set<String> rejectedPlaceIds;

  const HomeSearchState({
    this.isSearching = false,
    this.hasSearched = false,
    this.recommendedRestaurant,
    this.error,
    this.rejectedPlaceIds = const {},
  });

  HomeSearchState copyWith({
    bool? isSearching,
    bool? hasSearched,
    Restaurant? recommendedRestaurant,
    String? error,
    Set<String>? rejectedPlaceIds,
  }) {
    return HomeSearchState(
      isSearching: isSearching ?? this.isSearching,
      hasSearched: hasSearched ?? this.hasSearched,
      recommendedRestaurant: recommendedRestaurant ?? this.recommendedRestaurant,
      error: error ?? this.error,
      rejectedPlaceIds: rejectedPlaceIds ?? this.rejectedPlaceIds,
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
    // Ensure location is available before searching
    final discoveryNotifier = _ref.read(discoveryProvider.notifier);
    final currentDiscoveryState = _ref.read(discoveryProvider);
    if (currentDiscoveryState.userLocation == null) {
      await discoveryNotifier.getCurrentLocation();
    }

    // Trigger restaurant discovery with force refresh to ensure it runs
    await discoveryNotifier.searchRestaurants(forceRefresh: true);

    // Get discovered restaurants and user preferences
    final discoveryState = _ref.read(discoveryProvider);
    final preferences = _ref.read(userPreferencesProvider);

    if (discoveryState.restaurants.isEmpty) {
      state = state.copyWith(recommendedRestaurant: null);
      return;
    }

    // Filter out rejected restaurants from this session
    final candidates = discoveryState.restaurants
        .where((r) => !state.rejectedPlaceIds.contains(r.placeId))
        .toList();

    if (candidates.isEmpty) {
      // All restaurants rejected — clear rejections and show "no more options"
      state = state.copyWith(
        recommendedRestaurant: null,
        rejectedPlaceIds: {},
      );
      return;
    }

    // Find the best matching restaurant based on user preferences
    Restaurant? bestMatch;
    double bestScore = -1;

    for (final restaurant in candidates) {
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
      final userBudgetLevel = preferences.budgetLevel;
      if (restaurant.priceLevel != null) {
        final priceDiff = (restaurant.priceLevel! - userBudgetLevel).abs();
        score += (4 - priceDiff) * 0.4; // Higher score for closer price match
      } else {
        score += 2.0 * 0.4; // Neutral score if price level unknown
      }

      // Distance preference (weight: 30%)
      final maxDistance = preferences.maxTravelDistance;
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

  /// Reject current recommendation and find the next best match
  Future<void> rejectAndSearchAgain() async {
    final rejected = state.recommendedRestaurant;
    if (rejected == null) return;

    final updatedRejections = {...state.rejectedPlaceIds, rejected.placeId};

    state = state.copyWith(
      isSearching: true,
      hasSearched: false,
      recommendedRestaurant: null,
      rejectedPlaceIds: updatedRejections,
    );

    try {
      final searchFuture = _performSearch();
      final delayFuture = Future.delayed(const Duration(milliseconds: 800));
      await Future.wait([searchFuture, delayFuture]);

      state = state.copyWith(
        isSearching: false,
        hasSearched: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        hasSearched: true,
        error: e.toString(),
      );
    }
  }

  /// Reset search state (clears rejections too)
  void resetSearch() {
    state = const HomeSearchState();
  }

  /// Get recommendation reasons for display
  List<String> getRecommendationReasons(Restaurant restaurant, UserPreferences? preferences) {
    List<String> reasons = [];

    if (preferences != null) {
      // Budget match reason
      final userBudgetLevel = preferences.budgetLevel;
      if (restaurant.priceLevel != null) {
        if (restaurant.priceLevel == userBudgetLevel) {
          final dollarSigns = '\$' * userBudgetLevel;
          reasons.add('Perfect budget match ($dollarSigns)');
        } else if ((restaurant.priceLevel! - userBudgetLevel).abs() <= 1) {
          reasons.add('Close to your budget range');
        }
      }

      // Distance reason
      final maxDistance = preferences.maxTravelDistance;
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
