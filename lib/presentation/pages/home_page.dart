import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_routes.dart';
import '../../domain/entities/restaurant.dart';
import '../providers/discovery_providers.dart';
import '../providers/simple_providers.dart' as simple;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Start gentle pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure demo user exists in database
    ref.watch(simple.ensureDemoUserProvider);

    final currentUser = ref.watch(simple.currentUserProvider);
    final preferences = ref.watch(simple.simpleUserPreferencesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7), // Warm, appetizing cream color
      appBar: AppBar(
        title: Text(
          'What We Have For Lunch',
          style: TextStyle(
            color: const Color(0xFF2E7D3E), // Fresh green
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: currentUser != null
          ? _buildSimpleContent(context, currentUser['name'] ?? 'User')
          : _buildLoadingState(),
    );
  }

  Widget _buildSimpleContent(BuildContext context, String userName) {
    final searchState = ref.watch(simple.homeSearchProvider);

    // Show search results if search completed with a recommendation
    if (searchState.hasSearched && !searchState.isSearching && searchState.recommendedRestaurant != null) {
      return _buildRecommendationResult(context, userName, searchState.recommendedRestaurant!);
    }

    // Show no results if search completed without a recommendation
    if (searchState.hasSearched && !searchState.isSearching && searchState.recommendedRestaurant == null) {
      return _buildNoRecommendationResult(context, userName);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Warm greeting
            Text(
              'Hello, $userName! 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2E7D3E), // Fresh green
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              'Ready for a delicious meal?',
              style: TextStyle(
                fontSize: 18,
                color: const Color(0xFF6B4E3D), // Warm brown
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 60),

            // Progress indicator or main button
            if (searchState.isSearching) _buildSearchingState() else _buildHungryButton(),

            const SizedBox(height: 40),

            if (!searchState.isSearching)
              Text(
                'Tap to find the perfect meal for you',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF8B6F47), // Warm brown variant
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHungryButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.05),
          child: Container(
            width: 200,
            height: 200,
            child: ElevatedButton(
              onPressed: () => ref.read(simple.homeSearchProvider.notifier).searchForRestaurant(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35), // Appetizing orange
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 8,
                shadowColor: const Color(0xFFFF6B35).withOpacity(0.4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'I am\nhungry',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchingState() {
    return Container(
      width: 200,
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: const Color(0xFFFF6B35),
              strokeWidth: 6,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Finding your\nperfect meal...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E7D3E),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your preferences',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF6B4E3D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationResult(BuildContext context, String userName, Restaurant restaurant) {
    final preferences = ref.watch(simple.simpleUserPreferencesProvider);
    final reasons = ref.read(simple.homeSearchProvider.notifier).getRecommendationReasons(restaurant, preferences);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success message
            Text(
              'Perfect match found! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D3E),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Restaurant card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Restaurant icon and name
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

                      const SizedBox(height: 16),

                      Text(
                        restaurant.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D3E),
                        ),
                        textAlign: TextAlign.center,
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

                      const SizedBox(height: 16),

                      // Why this restaurant
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D3E).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Why this is perfect for you:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E7D3E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...reasons.take(2).map((reason) => Padding(
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
                                )),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quick info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (restaurant.rating != null)
                            _buildQuickInfo(
                              Icons.star,
                              '${restaurant.rating!.toStringAsFixed(1)}',
                              const Color(0xFFFFC107),
                            ),
                          if (restaurant.priceLevel != null)
                            _buildQuickInfo(
                              Icons.attach_money,
                              '\$' * restaurant.priceLevel!,
                              const Color(0xFF4CAF50),
                            ),
                          if (restaurant.distanceFromUser != null)
                            _buildQuickInfo(
                              Icons.location_on,
                              '${restaurant.distanceFromUser!.toStringAsFixed(1)}km',
                              const Color(0xFF2196F3),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Meh meme face button for "Search Again"
                Container(
                  width: 140,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () => ref.read(simple.homeSearchProvider.notifier).resetSearch(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35).withOpacity(0.5),
                      foregroundColor: const Color(0xFFFF6B35),
                      shape: const CircleBorder(),
                      elevation: 2,
                      padding: EdgeInsets.zero,
                    ),
                    child: Icon(
                      Icons.sentiment_dissatisfied,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Green round "GO" button for directions
                Container(
                  width: 140,
                  height: 90,
                  child: ElevatedButton(
                    onPressed: () => _openMapDirections(restaurant),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 6,
                      shadowColor: const Color(0xFF4CAF50).withOpacity(0.4),
                    ),
                    child: Text(
                      'GO',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRecommendationResult(BuildContext context, String userName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Sorry, $userName',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D3E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The restaurants are not available\nfor your current preferences',
              style: TextStyle(
                fontSize: 18,
                color: const Color(0xFF6B4E3D),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.go(AppRoutes.discover);
              },
              icon: Icon(Icons.explore),
              label: Text('Try Discover'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.read(simple.homeSearchProvider.notifier).resetSearch(),
              child: Text(
                'Search Again',
                style: TextStyle(
                  color: const Color(0xFF6B4E3D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: const Color(0xFFFF6B35),
          ),
          const SizedBox(height: 16),
          Text(
            'Getting ready...',
            style: TextStyle(
              color: const Color(0xFF6B4E3D),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _openMapDirections(Restaurant restaurant) async {
    try {
      HapticFeedback.mediumImpact();

      String url;

      if (restaurant.latitude != null && restaurant.longitude != null) {
        // Use coordinates if available for more accurate directions
        url =
            'https://maps.apple.com/?daddr=${restaurant.latitude},${restaurant.longitude}&dirflg=d';
      } else {
        // Fallback to address-based search
        final encodedAddress =
            Uri.encodeComponent('${restaurant.name}, ${restaurant.location}');
        url = 'https://maps.apple.com/?q=$encodedAddress&dirflg=d';
      }

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to Google Maps if Apple Maps is not available
        final googleMapsUrl = restaurant.latitude != null &&
                restaurant.longitude != null
            ? 'https://www.google.com/maps/dir/?api=1&destination=${restaurant.latitude},${restaurant.longitude}'
            : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${restaurant.name}, ${restaurant.location}')}';

        final googleUri = Uri.parse(googleMapsUrl);

        if (await canLaunchUrl(googleUri)) {
          await launchUrl(googleUri, mode: LaunchMode.externalApplication);
        } else {
          // Show error if no map app is available
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No map application available'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open map application'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}
