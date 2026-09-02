// @file discover_page.dart
// @description Restaurant discovery page with template-matching design: custom
//   sticky header with search bar, horizontal filter chips, and card-based
//   restaurant list with image placeholders, ratings, and action badges.
// @modified 2026-03-11

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/restaurant.dart';
import '../../domain/entities/user_preferences.dart';
import '../providers/discovery_providers.dart';
import '../providers/simple_providers.dart' as simple;

// ---------------------------------------------------------------------------
// Design tokens (matching template)
// ---------------------------------------------------------------------------

const _creamBg = Color(0xFFFDFAF3);
const _primaryGreen = Color(0xFF2F7F3F);
const _brownText = Color(0xFF6B4E3D);
const _brownLight = Color(0xFF8B6F47);

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum SortOption { relevance, price, distance, rating }

enum FilterType { price, distance, rating }

// ---------------------------------------------------------------------------
// DiscoverPage
// ---------------------------------------------------------------------------

/// Restaurant discovery page with clear recommendations and reasons.
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Sorting and filtering state
  SortOption _currentSort = SortOption.relevance;
  final Map<FilterType, dynamic> _activeFilters = {};

  // Search state
  final TextEditingController _searchController = TextEditingController();

  // Favorite state (local set for heart toggle)
  final Set<String> _localFavorites = {};

  // Active filter chip (for visual styling)
  String? _activeFilterChip;

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    await ref.read(discoveryProvider.notifier).refresh();
    _animationController.forward();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(discoveryProvider);
    final preferences = ref.watch(simple.userPreferencesProvider);

    return Scaffold(
      backgroundColor: _creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky header (search, count, sort)
            _buildStickyHeader(discoveryState, preferences),

            // Filter bar
            _buildFilterBar(),

            // Main content
            Expanded(
              child: _buildContent(discoveryState, preferences),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Sticky Header
  // -------------------------------------------------------------------------

  Widget _buildStickyHeader(
    DiscoveryState discoveryState,
    UserPreferences? preferences,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _creamBg,
        border: Border(
          bottom: BorderSide(
            color: _primaryGreen.withValues(alpha: 0.1),
          ),
        ),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + title + notification bell
          Row(
            children: [
              const Icon(
                Icons.restaurant_menu,
                color: _primaryGreen,
                size: 30,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lunch Explorer',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              Material(
                color: _primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () {
                    HapticFeedback.lightImpact();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: _primaryGreen,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(discoveryProvider.notifier).updateSearchQuery(value);
              },
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Search for bowls, salads, or sushi...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Count + Sort row
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_getFilteredAndSortedRestaurants(discoveryState.restaurants, preferences).length} Restaurants Found',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              _buildSortChip(),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Sort Chip (top-right of count row)
  // -------------------------------------------------------------------------

  Widget _buildSortChip() {
    String sortLabel;
    switch (_currentSort) {
      case SortOption.relevance:
        sortLabel = 'Relevance';
        break;
      case SortOption.price:
        sortLabel = 'Price';
        break;
      case SortOption.distance:
        sortLabel = 'Distance';
        break;
      case SortOption.rating:
        sortLabel = 'Rating';
        break;
    }

    return GestureDetector(
      onTap: _showSortOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort: $sortLabel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _primaryGreen,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.expand_more,
              size: 16,
              color: _primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Filter Bar (horizontal scrollable chips)
  // -------------------------------------------------------------------------

  Widget _buildFilterBar() {
    return Container(
      decoration: BoxDecoration(
        color: _creamBg,
        border: Border(
          bottom: BorderSide(
            color: _primaryGreen.withValues(alpha: 0.05),
          ),
        ),
      ),
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _buildFilterChip(
            label: 'Dietary',
            icon: Icons.filter_list,
            isActive: _activeFilterChip == 'Dietary',
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _activeFilterChip =
                    _activeFilterChip == 'Dietary' ? null : 'Dietary';
              });
              _showDietaryFilterOptions();
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Price',
            isActive: _activeFilters.containsKey(FilterType.price),
            onTap: () {
              HapticFeedback.lightImpact();
              _showPriceFilterSheet();
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Distance',
            isActive: _activeFilters.containsKey(FilterType.distance),
            onTap: () {
              HapticFeedback.lightImpact();
              _showDistanceFilterSheet();
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Rating',
            isActive: _activeFilters.containsKey(FilterType.rating),
            onTap: () {
              HapticFeedback.lightImpact();
              _showRatingFilterSheet();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: isActive
              ? null
              : Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isActive ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.black87,
              ),
            ),
            if (!isActive && icon == null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Main Content
  // -------------------------------------------------------------------------

  Widget _buildContent(
    DiscoveryState discoveryState,
    UserPreferences? preferences,
  ) {
    if (discoveryState.isLoading) {
      return _buildLoadingState();
    }

    if (discoveryState.error != null) {
      return _buildErrorState(discoveryState.error!);
    }

    if (discoveryState.restaurants.isEmpty) {
      return _buildEmptyState();
    }

    final sortedAndFilteredRestaurants =
        _getFilteredAndSortedRestaurants(discoveryState.restaurants, preferences);

    if (sortedAndFilteredRestaurants.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
              .copyWith(bottom: 96),
          itemCount: sortedAndFilteredRestaurants.length,
          itemBuilder: (context, index) {
            final restaurant = sortedAndFilteredRestaurants[index];
            final animationOffset = (index * 0.1).clamp(0.0, 0.8);
            final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(animationOffset, 1.0,
                    curve: Curves.easeOutCubic),
              ),
            );

            return Transform.translate(
              offset: Offset(0, 20 * (1 - animation.value)),
              child: Opacity(
                opacity: animation.value,
                child: _buildRestaurantCard(restaurant, preferences),
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Restaurant Card (template design)
  // -------------------------------------------------------------------------

  Widget _buildRestaurantCard(
    Restaurant restaurant,
    UserPreferences? preferences,
  ) {
    final reasons = _getRecommendationReasons(restaurant, preferences);
    final isFavorited = _localFavorites.contains(restaurant.placeId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showRestaurantDetails(restaurant, reasons, preferences);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with favorite button
            _buildCardImage(restaurant, isFavorited),

            // Content area
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row: name + rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (restaurant.rating != null) ...[
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: _primaryGreen,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              restaurant.rating!.toStringAsFixed(1),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Cuisine tags
                  _buildCuisineTags(restaurant),

                  const SizedBox(height: 12),

                  // Bottom row: price, distance, badge
                  _buildCardBottomRow(restaurant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Image placeholder with favourite heart overlay.
  Widget _buildCardImage(Restaurant restaurant, bool isFavorited) {
    return Stack(
      children: [
        // Image or placeholder
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: _buildRestaurantImage(restaurant),
          ),
        ),

        // Favorite heart button
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                if (_localFavorites.contains(restaurant.placeId)) {
                  _localFavorites.remove(restaurant.placeId);
                } else {
                  _localFavorites.add(restaurant.placeId);
                }
              });
              // Also update the provider
              ref
                  .read(favoriteRestaurantsProvider.notifier)
                  .toggleFavorite(restaurant.placeId);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color: isFavorited ? _primaryGreen : Colors.grey.shade400,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Attempt to load a photo from the restaurant's photoReference via the
  /// Google Places Photo API. Falls back to a styled placeholder on error.
  Widget _buildRestaurantImage(Restaurant restaurant) {
    // Use the first available photo reference
    final photoRef = restaurant.photoReference ??
        (restaurant.photoReferences.isNotEmpty
            ? restaurant.photoReferences.first
            : null);

    if (photoRef != null) {
      // Build Google Places Photo URL
      // The actual API key is handled elsewhere; use a generic placeholder
      // for now as the photo URL construction depends on backend config.
      return Image.network(
        'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=400&photo_reference=$photoRef'
        '&key=', // Key will be empty -- network will fail gracefully
        fit: BoxFit.cover,
        width: double.infinity,
        height: 160,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(restaurant),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImagePlaceholder(restaurant);
        },
      );
    }

    return _buildImagePlaceholder(restaurant);
  }

  /// Styled placeholder when no image is available.
  Widget _buildImagePlaceholder(Restaurant restaurant) {
    return Container(
      color: Colors.grey.shade200,
      width: double.infinity,
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              restaurant.cuisineType ?? 'Restaurant',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cuisine tags with bullet separators (e.g. "Salads . Healthy . Vegan").
  Widget _buildCuisineTags(Restaurant restaurant) {
    final tags = <String>[];

    // Use cuisineTypes list if available, otherwise fall back to single type
    if (restaurant.cuisineTypes.isNotEmpty) {
      tags.addAll(restaurant.cuisineTypes.take(3));
    } else if (restaurant.cuisineType != null) {
      tags.add(restaurant.cuisineType!);
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Text(
      tags.join(' \u2022 '),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: Colors.grey.shade500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Bottom row: price + distance on left, badge on right.
  Widget _buildCardBottomRow(Restaurant restaurant) {
    return Row(
      children: [
        // Price and distance group
        Expanded(
          child: Row(
            children: [
              if (restaurant.priceLevel != null) ...[
                Icon(
                  Icons.payments_outlined,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '\$' * restaurant.priceLevel!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (restaurant.distanceFromUser != null) ...[
                Icon(
                  Icons.near_me_outlined,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDistance(restaurant.distanceFromUser!),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Badge
        _buildCardBadge(restaurant),
      ],
    );
  }

  /// Format distance value for display.
  String _formatDistance(double distanceKm) {
    final miles = distanceKm * 0.621371;
    if (miles < 0.1) return '< 0.1 miles';
    return '${miles.toStringAsFixed(1)} miles';
  }

  /// Badge shown on the card (delivery, time estimate, or award).
  Widget _buildCardBadge(Restaurant restaurant) {
    // Determine badge based on restaurant attributes
    String badgeText;
    Color badgeBg;
    Color badgeTextColor;

    if (restaurant.rating != null && restaurant.rating! >= 4.8) {
      badgeText = 'AWARD WINNER';
      badgeBg = _primaryGreen.withValues(alpha: 0.1);
      badgeTextColor = _primaryGreen;
    } else if (restaurant.features.contains('delivery')) {
      badgeText = 'FAST DELIVERY';
      badgeBg = _primaryGreen.withValues(alpha: 0.1);
      badgeTextColor = _primaryGreen;
    } else if (restaurant.isOpenNow) {
      badgeText = 'OPEN NOW';
      badgeBg = _primaryGreen.withValues(alpha: 0.1);
      badgeTextColor = _primaryGreen;
    } else {
      // Default badge with estimated time
      badgeText = '25-35 MIN';
      badgeBg = Colors.grey.shade100;
      badgeTextColor = Colors.grey.shade500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        badgeText,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: badgeTextColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Loading / Error / Empty States
  // -------------------------------------------------------------------------

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              color: _primaryGreen,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Finding perfect restaurants...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              color: _brownText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your diet, budget & distance',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: _brownLight,
            ),
          ),
        ],
      ),
    );
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
              size: 72,
              color: _brownLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Trouble finding restaurants',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _brownText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Let me try again to find great places for you',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: _brownLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
              size: 72,
              color: _brownLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No restaurants found nearby',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _brownText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your preferences or search in a different area',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: _brownLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('Search Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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

  // -------------------------------------------------------------------------
  // Sorting & Filtering Business Logic
  // -------------------------------------------------------------------------

  /// Get recommendation reasons for a restaurant.
  List<String> _getRecommendationReasons(
    Restaurant restaurant,
    UserPreferences? preferences,
  ) {
    final reasons = <String>[];

    if (preferences == null) return ['Great choice for a delicious meal!'];

    // Budget match
    if (restaurant.priceLevel != null) {
      if (restaurant.priceLevel! <= preferences.budgetLevel) {
        reasons.add(
            'Fits your ${'\$' * preferences.budgetLevel} budget perfectly');
      }
    }

    // Distance
    if (restaurant.distanceFromUser != null) {
      if (restaurant.distanceFromUser! <= preferences.maxTravelDistance) {
        reasons.add(
            'Only ${restaurant.distanceFromUser!.toStringAsFixed(1)}km away - perfect distance');
      }
    }

    // Rating
    if (restaurant.rating != null && restaurant.rating! >= 4.0) {
      reasons.add(
          'Highly rated (${restaurant.rating!.toStringAsFixed(1)}) by other diners');
    }

    // Open now
    if (restaurant.isOpenNow) {
      reasons.add('Open right now - ready when you are');
    }

    // Cuisine match
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

    return reasons.take(3).toList();
  }

  bool _isChainRestaurant(Restaurant restaurant) {
    final chainKeywords = [
      'mcdonalds',
      'subway',
      'kfc',
      'burger king',
      'pizza hut',
      'dominos'
    ];
    final name = restaurant.name.toLowerCase();
    return chainKeywords.any((keyword) => name.contains(keyword));
  }

  /// Get preference violations for showing red indicators.
  List<String> _getPreferenceViolations(
    Restaurant restaurant,
    UserPreferences? preferences,
  ) {
    final violations = <String>[];

    if (preferences == null) return violations;

    // Budget violation
    if (restaurant.priceLevel != null &&
        restaurant.priceLevel! > preferences.budgetLevel) {
      final budgetSymbols = '\$' * preferences.budgetLevel;
      violations.add('Above your $budgetSymbols budget level');
    }

    // Distance violation
    if (restaurant.distanceFromUser != null &&
        restaurant.distanceFromUser! > preferences.maxTravelDistance) {
      violations.add(
          '${restaurant.distanceFromUser!.toStringAsFixed(1)}km away - beyond your ${preferences.maxTravelDistance.toStringAsFixed(1)}km range');
    }

    // Chain preference violation
    if (!preferences.includeChains && _isChainRestaurant(restaurant)) {
      violations.add('Chain restaurant - you prefer local places');
    }

    return violations;
  }

  /// Check if restaurant has any preference violations.
  bool _hasPreferenceViolations(
    Restaurant restaurant,
    UserPreferences? preferences,
  ) {
    return _getPreferenceViolations(restaurant, preferences).isNotEmpty;
  }

  /// Get filtered and sorted restaurants with non-matching ones at bottom.
  List<Restaurant> _getFilteredAndSortedRestaurants(
    List<Restaurant> restaurants,
    UserPreferences? preferences,
  ) {
    // Apply filters
    List<Restaurant> filteredRestaurants = restaurants.where((restaurant) {
      // Apply price filter
      if (_activeFilters.containsKey(FilterType.price)) {
        final maxPrice = _activeFilters[FilterType.price] as int;
        if (restaurant.priceLevel != null &&
            restaurant.priceLevel! > maxPrice) {
          return false;
        }
      }

      // Apply distance filter
      if (_activeFilters.containsKey(FilterType.distance)) {
        final maxDistance = _activeFilters[FilterType.distance] as double;
        if (restaurant.distanceFromUser != null &&
            restaurant.distanceFromUser! > maxDistance) {
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

  /// Sort restaurants by current sort option.
  void _sortRestaurants(
    List<Restaurant> restaurants,
    UserPreferences? preferences,
  ) {
    switch (_currentSort) {
      case SortOption.relevance:
        restaurants.sort((a, b) {
          final reasonsA = _getRecommendationReasons(a, preferences).length;
          final reasonsB = _getRecommendationReasons(b, preferences).length;
          int result = reasonsB.compareTo(reasonsA);
          if (result == 0) {
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
          return priceA.compareTo(priceB);
        });
        break;

      case SortOption.distance:
        restaurants.sort((a, b) {
          final distanceA = a.distanceFromUser ?? double.infinity;
          final distanceB = b.distanceFromUser ?? double.infinity;
          return distanceA.compareTo(distanceB);
        });
        break;

      case SortOption.rating:
        restaurants.sort((a, b) {
          final ratingA = a.rating ?? 0.0;
          final ratingB = b.rating ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
    }
  }

  // -------------------------------------------------------------------------
  // Sort Options Bottom Sheet
  // -------------------------------------------------------------------------

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _creamBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sort by',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _primaryGreen,
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
          color: isSelected ? _primaryGreen.withValues(alpha: 0.1) : null,
          border: isSelected
              ? Border.all(color: _primaryGreen, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? _primaryGreen : _brownText,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color:
                          isSelected ? _primaryGreen : const Color(0xFF2E2E2E),
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: _brownText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: _primaryGreen,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Filter Bottom Sheets
  // -------------------------------------------------------------------------

  /// Dietary filter quick options
  void _showDietaryFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _creamBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Dietary Preferences',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            _buildDietaryOption('Vegetarian', Icons.eco),
            _buildDietaryOption('Vegan', Icons.grass),
            _buildDietaryOption('Gluten-Free', Icons.no_food),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  ref.read(discoveryProvider.notifier).clearAllFilters();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Clear Dietary Filters',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDietaryOption(String label, IconData icon) {
    return InkWell(
      onTap: () {
        ref
            .read(discoveryProvider.notifier)
            .applyQuickFilter(label.toLowerCase());
        Navigator.of(context).pop();
        HapticFeedback.lightImpact();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: _primaryGreen, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Price filter bottom sheet.
  void _showPriceFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentPriceFilter =
                _activeFilters[FilterType.price] as int? ?? 4;

            return Container(
              decoration: const BoxDecoration(
                color: _creamBg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Maximum Price Level',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(4, (index) {
                      final level = index + 1;
                      final symbols = '\$' * level;
                      final isSelected = level <= currentPriceFilter;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setSheetState(() {});
                            setState(() {
                              if (level == 4 &&
                                  _activeFilters[FilterType.price] == 4) {
                                _activeFilters.remove(FilterType.price);
                              } else {
                                _activeFilters[FilterType.price] = level;
                              }
                            });
                            HapticFeedback.lightImpact();
                          },
                          child: Container(
                            margin:
                                EdgeInsets.only(right: index < 3 ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryGreen.withValues(alpha: 0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? _primaryGreen
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              symbols,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? _primaryGreen
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Apply',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Distance filter bottom sheet.
  void _showDistanceFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentDistance =
                _activeFilters[FilterType.distance] as double? ?? 20.0;

            return Container(
              decoration: const BoxDecoration(
                color: _creamBg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Maximum Distance',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _primaryGreen,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${currentDistance.toStringAsFixed(1)} km',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: currentDistance,
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    activeColor: _primaryGreen,
                    inactiveColor: _primaryGreen.withValues(alpha: 0.3),
                    onChanged: (value) {
                      setSheetState(() {});
                      setState(() {
                        _activeFilters[FilterType.distance] = value;
                      });
                    },
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed:
                            _activeFilters.containsKey(FilterType.distance)
                                ? () {
                                    setSheetState(() {});
                                    setState(() {
                                      _activeFilters
                                          .remove(FilterType.distance);
                                    });
                                    HapticFeedback.lightImpact();
                                  }
                                : null,
                        child: Text(
                          'Remove filter',
                          style: GoogleFonts.plusJakartaSans(
                            color: _activeFilters
                                    .containsKey(FilterType.distance)
                                ? Colors.red.shade400
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Apply',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Rating filter bottom sheet.
  void _showRatingFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentRating =
                _activeFilters[FilterType.rating] as double? ?? 1.0;

            return Container(
              decoration: const BoxDecoration(
                color: _creamBg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Minimum Rating',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _primaryGreen,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            currentRating.toStringAsFixed(1),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Color(0xFFFFC107),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: currentRating,
                    min: 1.0,
                    max: 5.0,
                    divisions: 8,
                    activeColor: _primaryGreen,
                    inactiveColor: _primaryGreen.withValues(alpha: 0.3),
                    onChanged: (value) {
                      setSheetState(() {});
                      setState(() {
                        _activeFilters[FilterType.rating] = value;
                      });
                    },
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed:
                            _activeFilters.containsKey(FilterType.rating)
                                ? () {
                                    setSheetState(() {});
                                    setState(() {
                                      _activeFilters
                                          .remove(FilterType.rating);
                                    });
                                    HapticFeedback.lightImpact();
                                  }
                                : null,
                        child: Text(
                          'Remove filter',
                          style: GoogleFonts.plusJakartaSans(
                            color:
                                _activeFilters.containsKey(FilterType.rating)
                                    ? Colors.red.shade400
                                    : Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Apply',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Restaurant Details Bottom Sheet
  // -------------------------------------------------------------------------

  void _showRestaurantDetails(
    Restaurant restaurant,
    List<String> reasons,
    UserPreferences? preferences,
  ) async {
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
            decoration: const BoxDecoration(
              color: _creamBg,
              borderRadius: BorderRadius.only(
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
                    color: _brownLight.withValues(alpha: 0.3),
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
                                color:
                                    _primaryGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _primaryGreen
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: _primaryGreen,
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    restaurant.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: _primaryGreen,
                                    ),
                                  ),
                                  if (restaurant.cuisineType !=
                                      null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      restaurant.cuisineType!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        color: _brownText,
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
                            color:
                                _primaryGreen.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _primaryGreen
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.recommend,
                                    color: _primaryGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Why this is perfect:',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...reasons.map(
                                (reason) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: Color(0xFF4CAF50),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          reason,
                                          style:
                                              GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            color: _brownText,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Preference violations warning
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
                                      style:
                                          GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...violations.map(
                                  (violation) => Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            style: GoogleFonts
                                                .plusJakartaSans(
                                              fontSize: 15,
                                              color:
                                                  Colors.red.shade700,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
                                (preferences != null &&
                                        restaurant.priceLevel! >
                                            preferences.budgetLevel)
                                    ? Colors.red.shade600
                                    : const Color(0xFF4CAF50),
                              ),
                            if (restaurant.distanceFromUser != null)
                              _buildDetailRow(
                                Icons.location_on,
                                'Distance',
                                '${restaurant.distanceFromUser!.toStringAsFixed(1)} km away',
                                (preferences != null &&
                                        restaurant.distanceFromUser! >
                                            preferences
                                                .maxTravelDistance)
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

                        // Recent Reviews Section
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
                              _handleRestaurantSelection(restaurant);
                            },
                            icon: const Icon(Icons.navigation, size: 24),
                            label: Text(
                              'Get Directions',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryGreen,
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

  // -------------------------------------------------------------------------
  // Detail Section helpers
  // -------------------------------------------------------------------------

  Widget _buildDetailSection(String title, List<Widget> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        ...details,
      ],
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _brownLight,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _brownText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Reviews Section
  // -------------------------------------------------------------------------

  Widget _buildReviewsSection(Restaurant restaurant) {
    final reviews = restaurant.recentReviews.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.reviews, color: _primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              'Recent Reviews',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _primaryGreen,
              ),
            ),
            const Spacer(),
            if (restaurant.aiSentimentSummary != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primaryGreen,
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
              color: _primaryGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _primaryGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              restaurant.aiSentimentSummary!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: _brownText,
                height: 1.4,
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Individual Reviews
        ...reviews.map(
          (review) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _brownLight.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      review.authorName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryGreen,
                      ),
                    ),
                    const Spacer(),
                    ...List.generate(
                      5,
                      (index) => Icon(
                        index < review.rating
                            ? Icons.star
                            : Icons.star_border,
                        size: 16,
                        color: const Color(0xFFFFC107),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  review.relativeTimeDescription,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: _brownLight,
                  ),
                ),
                if (review.text != null &&
                    review.text!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    review.text!.length > 150
                        ? '${review.text!.substring(0, 150)}...'
                        : review.text!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: _brownText,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Show more reviews indicator
        if (restaurant.recentReviews.length > 3)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '+ ${restaurant.recentReviews.length - 3} more reviews available',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: _brownLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Navigation / External Actions
  // -------------------------------------------------------------------------

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

  /// Fetch restaurant reviews for AI analysis.
  Future<void> _fetchRestaurantReviews(String placeId) async {
    try {
      final restaurantRepo = ref.read(restaurantRepositoryProvider);
      final updatedRestaurant =
          await restaurantRepo.updateRestaurantWithReviews(placeId);

      if (updatedRestaurant != null &&
          updatedRestaurant.recentReviews.isNotEmpty) {
        if (kDebugMode) {
          print('=== RESTAURANT REVIEWS FOR AI ===');
          print('Restaurant: ${updatedRestaurant.name}');
          print('Reviews Count: ${updatedRestaurant.recentReviews.length}');
          print(
              'AI Sentiment Summary: ${updatedRestaurant.aiSentimentSummary}');
          print(
              'Review Summary for AI: ${updatedRestaurant.getReviewSummaryForAI()}');
          print('=== END REVIEWS FOR AI ===');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching restaurant reviews: $e');
      }
    }
  }

  /// Open directions to restaurant in the default Maps app.
  Future<void> _openMapDirections(Restaurant restaurant) async {
    if (restaurant.latitude == null || restaurant.longitude == null) {
      await _openMapDirectionsByAddress(restaurant);
      return;
    }

    final lat = restaurant.latitude!;
    final lng = restaurant.longitude!;
    final name = Uri.encodeComponent(restaurant.name);

    final mapUrls = [
      'maps://?daddr=$lat,$lng&daddr_name=$name',
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_name=$name',
      'https://maps.google.com/maps?daddr=$lat,$lng',
    ];

    bool launched = false;

    for (final urlString in mapUrls) {
      try {
        final uri = Uri.parse(urlString);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening directions to ${restaurant.name}'),
                backgroundColor: _primaryGreen,
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

  /// Fallback method when coordinates are not available.
  Future<void> _openMapDirectionsByAddress(Restaurant restaurant) async {
    final query =
        Uri.encodeComponent('${restaurant.name} ${restaurant.location}');

    final mapUrls = [
      'maps://?q=$query',
      'https://www.google.com/maps/search/?api=1&query=$query',
      'https://maps.google.com/maps?q=$query',
    ];

    bool launched = false;

    for (final urlString in mapUrls) {
      try {
        final uri = Uri.parse(urlString);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening search for ${restaurant.name}'),
                backgroundColor: _primaryGreen,
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

}
