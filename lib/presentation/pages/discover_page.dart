import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/restaurant.dart';
import '../../domain/entities/user_preferences.dart';
import '../providers/discovery_providers.dart';
import '../providers/simple_providers.dart' as simple;

/// Simplified restaurant discovery page with clear recommendations and reasons
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

enum SortOption { relevance, price, distance, rating }
enum FilterType { price, distance, rating }

class _DiscoverPageState extends ConsumerState<DiscoverPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  // Sorting and filtering state
  SortOption _currentSort = SortOption.relevance;
  Map<FilterType, dynamic> _activeFilters = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendations();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    await ref.read(discoveryProvider.notifier).refresh();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(discoveryProvider);
    final preferences = ref.watch(simple.simpleUserPreferencesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7), // Warm, appetizing cream
      appBar: AppBar(
        title: Text(
          'Perfect For You',
          style: TextStyle(
            color: const Color(0xFF2E7D3E), // Fresh green
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildRecommendations(discoveryState, preferences),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: const Color(0xFFFF6B35), // Appetizing orange
              strokeWidth: 6,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Finding perfect restaurants...',
            style: TextStyle(
              fontSize: 18,
              color: const Color(0xFF6B4E3D), // Warm brown
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your diet, budget & distance',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF8B6F47), // Warm brown variant
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(DiscoveryState discoveryState, UserPreferences? preferences) {
    if (discoveryState.isLoading) {
      return _buildLoadingState();
    }
    
    if (discoveryState.error != null) {
      return _buildErrorState(discoveryState.error!);
    }

    if (discoveryState.restaurants.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Header with recommendation count and sort/filter controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: const Color(0xFFFF6B35),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_getFilteredAndSortedRestaurants(discoveryState.restaurants, preferences).length} great options for you',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D3E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Sort and Filter controls
              Row(
                children: [
                  Expanded(
                    child: _buildSortButton(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterButton(),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Restaurant list
        Expanded(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final sortedAndFilteredRestaurants = _getFilteredAndSortedRestaurants(discoveryState.restaurants, preferences);
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sortedAndFilteredRestaurants.length,
                itemBuilder: (context, index) {
                  final restaurant = sortedAndFilteredRestaurants[index];
                  final animationOffset = (index * 0.1).clamp(0.0, 0.8);
                  final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(animationOffset, 1.0, curve: Curves.easeOutCubic),
                    ),
                  );

                  return Transform.translate(
                    offset: Offset(30 * (1 - animation.value), 0),
                    child: Opacity(
                      opacity: animation.value,
                      child: _buildSimpleRestaurantCard(restaurant, preferences),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleRestaurantCard(Restaurant restaurant, UserPreferences? preferences) {
    final reasons = _getRecommendationReasons(restaurant, preferences);
    final violations = _getPreferenceViolations(restaurant, preferences);
    final hasViolations = violations.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: hasViolations 
            ? BorderSide(color: Colors.red.shade300, width: 2)
            : BorderSide.none,
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showRestaurantDetails(restaurant, reasons, preferences);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant header
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.restaurant,
                        color: const Color(0xFFFF6B35),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2E7D3E),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (restaurant.cuisineType != null)
                            Text(
                              restaurant.cuisineType!,
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF6B4E3D),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Rating badge
                    if (restaurant.rating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              restaurant.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Why we recommend this
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D3E).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2E7D3E).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 18,
                            color: const Color(0xFF2E7D3E),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Why this is perfect for you:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E7D3E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...reasons.map((reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: const Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFF6B4E3D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
                
                // Preference violations warning (if any)
                if (hasViolations) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_outlined,
                              size: 18,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Doesn\'t match your preferences:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...violations.map((violation) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.red.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  violation,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Quick info row
                Row(
                  children: [
                    if (restaurant.priceLevel != null) ...[
                      _buildInfoChip(
                        '\$' * restaurant.priceLevel!,
                        Icons.attach_money,
                        (preferences != null && restaurant.priceLevel! > preferences.budgetLevel)
                          ? Colors.red.shade600
                          : const Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (restaurant.distanceFromUser != null) ...[
                      _buildInfoChip(
                        '${restaurant.distanceFromUser!.toStringAsFixed(1)}km',
                        Icons.location_on,
                        (preferences != null && restaurant.distanceFromUser! > preferences.maxTravelDistance)
                          ? Colors.red.shade600
                          : const Color(0xFF2196F3),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (restaurant.isOpenNow) ...[
                      _buildInfoChip(
                        'Open now',
                        Icons.access_time,
                        const Color(0xFF4CAF50),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getRecommendationReasons(Restaurant restaurant, UserPreferences? preferences) {
    final reasons = <String>[];

    if (preferences == null) return ['Great choice for a delicious meal!'];

    // Budget match
    if (restaurant.priceLevel != null) {
      if (restaurant.priceLevel! <= preferences.budgetLevel) {
        reasons.add('Fits your ${'\$' * preferences.budgetLevel} budget perfectly');
      }
    }

    // Distance
    if (restaurant.distanceFromUser != null) {
      if (restaurant.distanceFromUser! <= preferences.maxTravelDistance) {
        reasons.add('Only ${restaurant.distanceFromUser!.toStringAsFixed(1)}km away - perfect distance');
      }
    }

    // Rating
    if (restaurant.rating != null && restaurant.rating! >= 4.0) {
      reasons.add('Highly rated (${restaurant.rating!.toStringAsFixed(1)}⭐) by other diners');
    }

    // Open now
    if (restaurant.isOpenNow) {
      reasons.add('Open right now - ready when you are');
    }

    // Cuisine match (simplified)
    if (restaurant.cuisineType != null) {
      reasons.add('Delicious ${restaurant.cuisineType!.toLowerCase()} cuisine');
    }

    // Chains preference
    if (preferences.includeChains || !_isChainRestaurant(restaurant)) {
      if (!_isChainRestaurant(restaurant)) {
        reasons.add('Local favorite - unique dining experience');
      }
    }

    // Default reason if no specific matches
    if (reasons.isEmpty) {
      reasons.add('Great choice for a satisfying meal');
    }

    return reasons.take(3).toList(); // Limit to 3 reasons for simplicity
  }

  bool _isChainRestaurant(Restaurant restaurant) {
    final chainKeywords = ['mcdonalds', 'subway', 'kfc', 'burger king', 'pizza hut', 'dominos'];
    final name = restaurant.name.toLowerCase();
    return chainKeywords.any((keyword) => name.contains(keyword));
  }

  /// Get preference violations for showing red indicators
  List<String> _getPreferenceViolations(Restaurant restaurant, UserPreferences? preferences) {
    final violations = <String>[];
    
    if (preferences == null) return violations;

    // Budget violation
    if (restaurant.priceLevel != null && restaurant.priceLevel! > preferences.budgetLevel) {
      final budgetSymbols = '\$' * preferences.budgetLevel;
      violations.add('Above your $budgetSymbols budget level');
    }

    // Distance violation
    if (restaurant.distanceFromUser != null && restaurant.distanceFromUser! > preferences.maxTravelDistance) {
      violations.add('${restaurant.distanceFromUser!.toStringAsFixed(1)}km away - beyond your ${preferences.maxTravelDistance.toStringAsFixed(1)}km range');
    }

    // Chain preference violation
    if (!preferences.includeChains && _isChainRestaurant(restaurant)) {
      violations.add('Chain restaurant - you prefer local places');
    }

    return violations;
  }

  /// Check if restaurant has any preference violations
  bool _hasPreferenceViolations(Restaurant restaurant, UserPreferences? preferences) {
    return _getPreferenceViolations(restaurant, preferences).isNotEmpty;
  }

  /// Build sort button
  Widget _buildSortButton() {
    String sortText = '';
    IconData sortIcon = Icons.sort;
    
    switch (_currentSort) {
      case SortOption.relevance:
        sortText = 'Relevance';
        sortIcon = Icons.recommend;
        break;
      case SortOption.price:
        sortText = 'Price';
        sortIcon = Icons.attach_money;
        break;
      case SortOption.distance:
        sortText = 'Distance';
        sortIcon = Icons.location_on;
        break;
      case SortOption.rating:
        sortText = 'Rating';
        sortIcon = Icons.star;
        break;
    }
    
    return Container(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: _showSortOptions,
        icon: Icon(sortIcon, size: 18),
        label: Text(
          sortText,
          style: TextStyle(fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2E7D3E),
          side: BorderSide(color: const Color(0xFF2E7D3E).withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  /// Build filter button
  Widget _buildFilterButton() {
    final hasActiveFilters = _activeFilters.isNotEmpty;
    
    return Container(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: _showFilterOptions,
        icon: Icon(
          hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
          size: 18,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter',
              style: TextStyle(fontSize: 14),
            ),
            if (hasActiveFilters) ...[ 
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_activeFilters.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: hasActiveFilters 
              ? const Color(0xFFFF6B35)
              : const Color(0xFF2E7D3E),
          side: BorderSide(
            color: hasActiveFilters 
                ? const Color(0xFFFF6B35).withOpacity(0.5)
                : const Color(0xFF2E7D3E).withOpacity(0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  /// Get filtered and sorted restaurants with non-matching ones at bottom
  List<Restaurant> _getFilteredAndSortedRestaurants(List<Restaurant> restaurants, UserPreferences? preferences) {
    // First, apply filters
    List<Restaurant> filteredRestaurants = restaurants.where((restaurant) {
      // Apply price filter
      if (_activeFilters.containsKey(FilterType.price)) {
        final maxPrice = _activeFilters[FilterType.price] as int;
        if (restaurant.priceLevel != null && restaurant.priceLevel! > maxPrice) {
          return false;
        }
      }
      
      // Apply distance filter
      if (_activeFilters.containsKey(FilterType.distance)) {
        final maxDistance = _activeFilters[FilterType.distance] as double;
        if (restaurant.distanceFromUser != null && restaurant.distanceFromUser! > maxDistance) {
          return false;
        }
      }
      
      // Apply rating filter
      if (_activeFilters.containsKey(FilterType.rating)) {
        final minRating = _activeFilters[FilterType.rating] as double;
        if (restaurant.rating != null && restaurant.rating! < minRating) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // Separate matching and non-matching restaurants
    final matching = <Restaurant>[];
    final nonMatching = <Restaurant>[];
    
    for (final restaurant in filteredRestaurants) {
      if (_hasPreferenceViolations(restaurant, preferences)) {
        nonMatching.add(restaurant);
      } else {
        matching.add(restaurant);
      }
    }
    
    // Sort each group separately
    _sortRestaurants(matching, preferences);
    _sortRestaurants(nonMatching, preferences);
    
    // Return matching restaurants first, then non-matching ones
    return [...matching, ...nonMatching];
  }

  /// Sort restaurants by current sort option
  void _sortRestaurants(List<Restaurant> restaurants, UserPreferences? preferences) {
    switch (_currentSort) {
      case SortOption.relevance:
        restaurants.sort((a, b) {
          // Sort by relevance score (more reasons = more relevant)
          final reasonsA = _getRecommendationReasons(a, preferences).length;
          final reasonsB = _getRecommendationReasons(b, preferences).length;
          int result = reasonsB.compareTo(reasonsA);
          if (result == 0) {
            // Secondary sort by rating
            final ratingA = a.rating ?? 0.0;
            final ratingB = b.rating ?? 0.0;
            result = ratingB.compareTo(ratingA);
          }
          return result;
        });
        break;
        
      case SortOption.price:
        restaurants.sort((a, b) {
          final priceA = a.priceLevel ?? 0;
          final priceB = b.priceLevel ?? 0;
          return priceA.compareTo(priceB); // Low to high
        });
        break;
        
      case SortOption.distance:
        restaurants.sort((a, b) {
          final distanceA = a.distanceFromUser ?? double.infinity;
          final distanceB = b.distanceFromUser ?? double.infinity;
          return distanceA.compareTo(distanceB); // Near to far
        });
        break;
        
      case SortOption.rating:
        restaurants.sort((a, b) {
          final ratingA = a.rating ?? 0.0;
          final ratingB = b.rating ?? 0.0;
          return ratingB.compareTo(ratingA); // High to low
        });
        break;
    }
  }

  /// Show sort options dialog
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort by',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D3E),
              ),
            ),
            const SizedBox(height: 16),
            ...SortOption.values.map((option) => _buildSortOption(option)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(SortOption option) {
    String title = '';
    String description = '';
    IconData icon = Icons.sort;
    
    switch (option) {
      case SortOption.relevance:
        title = 'Relevance';
        description = 'Best matches for your preferences';
        icon = Icons.recommend;
        break;
      case SortOption.price:
        title = 'Price';
        description = 'From lowest to highest price';
        icon = Icons.attach_money;
        break;
      case SortOption.distance:
        title = 'Distance';
        description = 'Closest restaurants first';
        icon = Icons.location_on;
        break;
      case SortOption.rating:
        title = 'Rating';
        description = 'Highest rated restaurants first';
        icon = Icons.star;
        break;
    }
    
    final isSelected = _currentSort == option;
    
    return InkWell(
      onTap: () {
        setState(() {
          _currentSort = option;
        });
        Navigator.of(context).pop();
        HapticFeedback.lightImpact();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
              ? const Color(0xFF2E7D3E).withOpacity(0.1)
              : null,
          border: isSelected 
              ? Border.all(color: const Color(0xFF2E7D3E), width: 2)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? const Color(0xFF2E7D3E)
                  : const Color(0xFF6B4E3D),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected 
                          ? const Color(0xFF2E7D3E)
                          : const Color(0xFF2E2E2E),
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF6B4E3D),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF2E7D3E),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  /// Show filter options dialog
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filter options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D3E),
                  ),
                ),
                const Spacer(),
                if (_activeFilters.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _activeFilters.clear();
                      });
                      Navigator.of(context).pop();
                      HapticFeedback.lightImpact();
                    },
                    child: Text(
                      'Clear all',
                      style: TextStyle(
                        color: const Color(0xFFFF6B35),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildPriceFilter(),
                  const SizedBox(height: 20),
                  _buildDistanceFilter(),
                  const SizedBox(height: 20),
                  _buildRatingFilter(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceFilter() {
    final currentPriceFilter = _activeFilters[FilterType.price] as int? ?? 4;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maximum Price Level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E7D3E),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(4, (index) {
            final level = index + 1;
            final symbols = '\$' * level;
            final isSelected = level <= currentPriceFilter;
            
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (level == 4 && _activeFilters[FilterType.price] == 4) {
                      // If max is selected and clicked again, remove filter
                      _activeFilters.remove(FilterType.price);
                    } else {
                      _activeFilters[FilterType.price] = level;
                    }
                  });
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF2E7D3E).withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF2E7D3E)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    symbols,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? const Color(0xFF2E7D3E)
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    final currentDistanceFilter = _activeFilters[FilterType.distance] as double? ?? 20.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Maximum Distance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D3E),
              ),
            ),
            const Spacer(),
            Text(
              '${currentDistanceFilter.toStringAsFixed(1)} km',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: currentDistanceFilter,
          min: 1.0,
          max: 20.0,
          divisions: 19,
          activeColor: const Color(0xFFFF6B35),
          inactiveColor: const Color(0xFFFF6B35).withOpacity(0.3),
          onChanged: (value) {
            setState(() {
              _activeFilters[FilterType.distance] = value;
            });
          },
        ),
        Row(
          children: [
            TextButton(
              onPressed: _activeFilters.containsKey(FilterType.distance)
                  ? () {
                      setState(() {
                        _activeFilters.remove(FilterType.distance);
                      });
                      HapticFeedback.lightImpact();
                    }
                  : null,
              child: Text(
                'Remove filter',
                style: TextStyle(
                  color: _activeFilters.containsKey(FilterType.distance)
                      ? const Color(0xFFFF6B35)
                      : Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    final currentRatingFilter = _activeFilters[FilterType.rating] as double? ?? 1.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Minimum Rating',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D3E),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  currentRatingFilter.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF6B35),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.star,
                  size: 16,
                  color: const Color(0xFFFFC107),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: currentRatingFilter,
          min: 1.0,
          max: 5.0,
          divisions: 8,
          activeColor: const Color(0xFFFF6B35),
          inactiveColor: const Color(0xFFFF6B35).withOpacity(0.3),
          onChanged: (value) {
            setState(() {
              _activeFilters[FilterType.rating] = value;
            });
          },
        ),
        Row(
          children: [
            TextButton(
              onPressed: _activeFilters.containsKey(FilterType.rating)
                  ? () {
                      setState(() {
                        _activeFilters.remove(FilterType.rating);
                      });
                      HapticFeedback.lightImpact();
                    }
                  : null,
              child: Text(
                'Remove filter',
                style: TextStyle(
                  color: _activeFilters.containsKey(FilterType.rating)
                      ? const Color(0xFFFF6B35)
                      : Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showRestaurantDetails(Restaurant restaurant, List<String> reasons, UserPreferences? preferences) async {
    final violations = _getPreferenceViolations(restaurant, preferences);
    final hasViolations = violations.isNotEmpty;
    
    // Fetch reviews in the background for AI analysis
    _fetchRestaurantReviews(restaurant.placeId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B6F47).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Restaurant header
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.restaurant,
                                color: const Color(0xFFFF6B35),
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    restaurant.name,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E7D3E),
                                    ),
                                  ),
                                  if (restaurant.cuisineType != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      restaurant.cuisineType!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: const Color(0xFF6B4E3D),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Why we recommend
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D3E).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF2E7D3E).withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.recommend,
                                    color: const Color(0xFF2E7D3E),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Why this is perfect:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E7D3E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...reasons.map((reason) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: const Color(0xFF4CAF50),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        reason,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: const Color(0xFF6B4E3D),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ],
                          ),
                        ),
                        
                        // Preference violations warning (if any)
                        if (hasViolations) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: Colors.red.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Doesn\'t match your preferences:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...violations.map((violation) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.red.shade600,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          violation,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.red.shade700,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Restaurant details
                        if (restaurant.rating != null || 
                            restaurant.priceLevel != null || 
                            restaurant.distanceFromUser != null) ...[
                          _buildDetailSection('Restaurant Info', [
                            if (restaurant.rating != null)
                              _buildDetailRow(
                                Icons.star,
                                'Rating',
                                '${restaurant.rating!.toStringAsFixed(1)} stars',
                                const Color(0xFFFFC107),
                              ),
                            if (restaurant.priceLevel != null)
                              _buildDetailRow(
                                Icons.attach_money,
                                'Price Level',
                                '\$' * restaurant.priceLevel!,
                                (preferences != null && restaurant.priceLevel! > preferences.budgetLevel)
                                  ? Colors.red.shade600
                                  : const Color(0xFF4CAF50),
                              ),
                            if (restaurant.distanceFromUser != null)
                              _buildDetailRow(
                                Icons.location_on,
                                'Distance',
                                '${restaurant.distanceFromUser!.toStringAsFixed(1)} km away',
                                (preferences != null && restaurant.distanceFromUser! > preferences.maxTravelDistance)
                                  ? Colors.red.shade600
                                  : const Color(0xFF2196F3),
                              ),
                            if (restaurant.isOpenNow)
                              _buildDetailRow(
                                Icons.access_time,
                                'Status',
                                'Open now',
                                const Color(0xFF4CAF50),
                              ),
                          ]),
                          
                          const SizedBox(height: 24),
                        ],
                        
                        // Recent Reviews Section (if available)
                        if (restaurant.recentReviews.isNotEmpty) ...[ 
                          _buildReviewsSection(restaurant),
                          const SizedBox(height: 24),
                        ],
                        
                        // Action button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                              // Navigate to directions or call restaurant
                              _handleRestaurantSelection(restaurant);
                            },
                            icon: Icon(Icons.navigation, size: 24),
                            label: Text(
                              'Get Directions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsSection(Restaurant restaurant) {
    final reviews = restaurant.recentReviews.take(3).toList(); // Show max 3 reviews
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.reviews,
              color: const Color(0xFF2E7D3E),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Recent Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D3E),
              ),
            ),
            const Spacer(),
            if (restaurant.aiSentimentSummary != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D3E),
                  ),
                ),
              ),
          ],
        ),
        
        // AI Sentiment Summary
        if (restaurant.aiSentimentSummary != null) ...[ 
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D3E).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2E7D3E).withOpacity(0.2),
              ),
            ),
            child: Text(
              restaurant.aiSentimentSummary!,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6B4E3D),
                height: 1.4,
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        // Individual Reviews
        ...reviews.map((review) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF8B6F47).withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    review.authorName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D3E),
                    ),
                  ),
                  const Spacer(),
                  ...List.generate(5, (index) => Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: const Color(0xFFFFC107),
                  )),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                review.relativeTimeDescription,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF8B6F47),
                ),
              ),
              if (review.text != null && review.text!.isNotEmpty) ...[ 
                const SizedBox(height: 8),
                Text(
                  review.text!.length > 150 
                      ? '${review.text!.substring(0, 150)}...'
                      : review.text!,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF6B4E3D),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        )).toList(),
        
        // Show more reviews indicator
        if (restaurant.recentReviews.length > 3)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '+ ${restaurant.recentReviews.length - 3} more reviews available',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF8B6F47),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2E7D3E),
          ),
        ),
        const SizedBox(height: 12),
        ...details,
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF8B6F47),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B4E3D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRestaurantSelection(Restaurant restaurant) async {
    try {
      await _openMapDirections(restaurant);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open directions: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Fetch restaurant reviews for AI analysis
  Future<void> _fetchRestaurantReviews(String placeId) async {
    try {
      final restaurantRepo = ref.read(restaurantRepositoryProvider);
      final updatedRestaurant = await restaurantRepo.updateRestaurantWithReviews(placeId);
      
      if (updatedRestaurant != null && updatedRestaurant.recentReviews.isNotEmpty) {
        if (kDebugMode) {
          print('=== RESTAURANT REVIEWS FOR AI ===');
          print('Restaurant: ${updatedRestaurant.name}');
          print('Reviews Count: ${updatedRestaurant.recentReviews.length}');
          print('AI Sentiment Summary: ${updatedRestaurant.aiSentimentSummary}');
          print('Review Summary for AI: ${updatedRestaurant.getReviewSummaryForAI()}');
          print('=== END REVIEWS FOR AI ===');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching restaurant reviews: $e');
      }
    }
  }

  /// Open directions to restaurant in the default Maps app
  Future<void> _openMapDirections(Restaurant restaurant) async {
    if (restaurant.latitude == null || restaurant.longitude == null) {
      // Fallback to address-based search if coordinates are not available
      await _openMapDirectionsByAddress(restaurant);
      return;
    }

    final lat = restaurant.latitude!;
    final lng = restaurant.longitude!;
    final name = Uri.encodeComponent(restaurant.name);

    // Try different map apps in order of preference
    final mapUrls = [
      // Apple Maps (iOS) / Google Maps (Android) - Universal
      'maps://?daddr=$lat,$lng&daddr_name=$name',
      
      // Google Maps (universal fallback)
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_name=$name',
      
      // Alternative Google Maps URL
      'https://maps.google.com/maps?daddr=$lat,$lng',
    ];

    bool launched = false;
    
    for (final urlString in mapUrls) {
      try {
        final uri = Uri.parse(urlString);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          launched = true;
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening directions to ${restaurant.name}'),
                backgroundColor: const Color(0xFF2E7D3E),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          break;
        }
      } catch (e) {
        // Try next URL
        continue;
      }
    }

    if (!launched) {
      throw Exception('No map application available');
    }
  }

  /// Fallback method when coordinates are not available
  Future<void> _openMapDirectionsByAddress(Restaurant restaurant) async {
    final query = Uri.encodeComponent('${restaurant.name} ${restaurant.location}');
    
    final mapUrls = [
      // Apple Maps (iOS) - address search
      'maps://?q=$query',
      
      // Google Maps - address search
      'https://www.google.com/maps/search/?api=1&query=$query',
      
      // Alternative Google Maps search
      'https://maps.google.com/maps?q=$query',
    ];

    bool launched = false;
    
    for (final urlString in mapUrls) {
      try {
        final uri = Uri.parse(urlString);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          launched = true;
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening search for ${restaurant.name}'),
                backgroundColor: const Color(0xFF2E7D3E),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          break;
        }
      } catch (e) {
        continue;
      }
    }

    if (!launched) {
      throw Exception('No map application available');
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 80,
              color: const Color(0xFF8B6F47).withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Trouble finding restaurants',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B4E3D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Let me try again to find great places for you',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF8B6F47),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadRecommendations,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: const Color(0xFF8B6F47).withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No restaurants found nearby',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B4E3D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your preferences or search in a different area',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF8B6F47),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadRecommendations,
              icon: Icon(Icons.refresh),
              label: Text('Search Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}