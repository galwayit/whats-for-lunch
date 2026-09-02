// @file home_page.dart
// @description Main home screen with template-matching design: custom header,
//   greeting section, animated "I AM HUNGRY" button with decorative rings,
//   daily suggestions badge, and recommendation result cards.
// @modified 2026-03-11

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_routes.dart';
import '../../domain/entities/restaurant.dart';
import '../providers/discovery_providers.dart';
import '../providers/simple_providers.dart' as simple;

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------

const _creamBg = Color(0xFFFFF8E7);
const _primaryGreen = Color(0xFF2F7F3F);
const _ctaOrange = Color(0xFFFF6B35);
const _brownText = Color(0xFF6B4E3D);
const _brownLight = Color(0xFF8B6F47);

// ---------------------------------------------------------------------------
// HomePage
// ---------------------------------------------------------------------------

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  /// Whether the main button is currently pressed (for scale-down effect).
  bool _buttonPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Ensure demo user exists in database
    ref.watch(simple.ensureDemoUserProvider);

    // Eagerly initialise discovery provider so location permission is
    // requested on app start, not when the user taps "I am hungry"
    ref.watch(discoveryProvider);

    final currentUser = ref.watch(simple.currentUserProvider);

    return Scaffold(
      backgroundColor: _creamBg,
      body: currentUser != null
          ? _buildBody(context, currentUser['name'] ?? 'User')
          : _buildLoadingState(),
    );
  }

  // -------------------------------------------------------------------------
  // Top-level body (SafeArea + header + content)
  // -------------------------------------------------------------------------

  Widget _buildBody(BuildContext context, String userName) {
    final searchState = ref.watch(simple.homeSearchProvider);

    return SafeArea(
      child: Column(
        children: [
          // Custom header
          _buildHeader(),

          // Scrollable content area
          Expanded(
            child: _buildContent(context, userName, searchState),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Custom header (replaces AppBar)
  // -------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // User avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _primaryGreen.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              color: _primaryGreen,
              size: 24,
            ),
          ),

          const Spacer(),

          // Title
          Text(
            'LUNCH PLANNER',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _primaryGreen,
              letterSpacing: 3,
            ),
          ),

          const Spacer(),

          // Notification bell
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 22),
              color: _brownText,
              onPressed: () {
                // Notification action placeholder
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Content router (default / searching / result / no result)
  // -------------------------------------------------------------------------

  Widget _buildContent(
      BuildContext context, String userName, dynamic searchState) {
    // Show recommendation result
    if (searchState.hasSearched &&
        !searchState.isSearching &&
        searchState.recommendedRestaurant != null) {
      return _buildRecommendationResult(
          context, userName, searchState.recommendedRestaurant!);
    }

    // Show no-results state
    if (searchState.hasSearched &&
        !searchState.isSearching &&
        searchState.recommendedRestaurant == null) {
      return _buildNoRecommendationResult(context, userName);
    }

    // Default state (greeting + button)
    return _buildDefaultContent(context, userName, searchState);
  }

  // -------------------------------------------------------------------------
  // Default content (greeting + rings + button + badge)
  // -------------------------------------------------------------------------

  Widget _buildDefaultContent(
      BuildContext context, String userName, dynamic searchState) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Greeting section
          Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 24),
            child: Column(
              children: [
                Text(
                  'Hi, $userName!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: _brownText,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready for your next meal?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: _brownText.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Rings + button (or searching spinner)
          if (searchState.isSearching)
            _buildSearchingState()
          else
            _buildHungryButtonWithRings(),

          const SizedBox(height: 48),

          // Daily suggestions badge
          if (!searchState.isSearching) _buildDailySuggestionsBadge(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Animated rings + hungry button
  // -------------------------------------------------------------------------

  Widget _buildHungryButtonWithRings() {
    return SizedBox(
      width: 288,
      height: 288,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring (pulsing)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.04);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 288,
                  height: 288,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _ctaOrange.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),

          // Inner ring (pulsing, slightly offset timing)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.025);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 256,
                  height: 256,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _ctaOrange.withValues(alpha: 0.1),
                      width: 4,
                    ),
                  ),
                ),
              );
            },
          ),

          // Main button (no pulse -- only scale on press)
          GestureDetector(
            onTapDown: (_) => setState(() => _buttonPressed = true),
            onTapUp: (_) {
              setState(() => _buttonPressed = false);
              HapticFeedback.mediumImpact();
              ref
                  .read(simple.homeSearchProvider.notifier)
                  .searchForRestaurant();
            },
            onTapCancel: () => setState(() => _buttonPressed = false),
            child: AnimatedScale(
              scale: _buttonPressed ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: 224,
                height: 224,
                decoration: BoxDecoration(
                  color: _ctaOrange,
                  shape: BoxShape.circle,
                  border: Border.all(color: _creamBg, width: 8),
                  boxShadow: [
                    BoxShadow(
                      color: _ctaOrange.withValues(alpha: 0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                    // Subtle inner glow
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.restaurant,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'I AM\nHUNGRY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 2,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Daily suggestions badge
  // -------------------------------------------------------------------------

  Widget _buildDailySuggestionsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: _primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 18,
            color: _primaryGreen,
          ),
          const SizedBox(width: 8),
          Text(
            '3 DAILY SUGGESTIONS READY',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _primaryGreen,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Searching state (spinner)
  // -------------------------------------------------------------------------

  Widget _buildSearchingState() {
    return SizedBox(
      width: 224,
      height: 224,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: _ctaOrange,
              strokeWidth: 6,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Finding your\nperfect meal...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _primaryGreen,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your preferences',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: _brownText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Recommendation result card
  // -------------------------------------------------------------------------

  Widget _buildRecommendationResult(
      BuildContext context, String userName, Restaurant restaurant) {
    final preferences = ref.watch(simple.userPreferencesProvider);
    final reasons = ref
        .read(simple.homeSearchProvider.notifier)
        .getRecommendationReasons(restaurant, preferences);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Success header
          Text(
            'Perfect match found!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Restaurant card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Restaurant icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _ctaOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _ctaOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: _ctaOrange,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 16),

                // Restaurant name
                Text(
                  restaurant.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _primaryGreen,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (restaurant.cuisineType != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    restaurant.cuisineType!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: _brownText,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Why this restaurant
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Why this is perfect for you:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...reasons.take(2).map((reason) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: Color(0xFF4CAF50),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: _brownText,
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

                // Quick info row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (restaurant.rating != null)
                      _buildQuickInfo(
                        Icons.star,
                        restaurant.rating!.toStringAsFixed(1),
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

          const SizedBox(height: 32),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Reject / search again
              SizedBox(
                width: 140,
                height: 80,
                child: ElevatedButton(
                  onPressed: () => ref
                      .read(simple.homeSearchProvider.notifier)
                      .rejectAndSearchAgain(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ctaOrange.withValues(alpha: 0.5),
                    foregroundColor: _ctaOrange,
                    shape: const CircleBorder(),
                    elevation: 2,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(
                    Icons.sentiment_dissatisfied,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),

              // GO button (directions)
              SizedBox(
                width: 140,
                height: 90,
                child: ElevatedButton(
                  onPressed: () => _openMapDirections(restaurant),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 6,
                    shadowColor: _primaryGreen.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    'GO',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // No recommendation result
  // -------------------------------------------------------------------------

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
              color: _brownLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Sorry, $userName',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _primaryGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The restaurants are not available\nfor your current preferences',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                color: _brownText,
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
              icon: const Icon(Icons.explore),
              label: Text(
                'Try Discover',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _ctaOrange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  ref.read(simple.homeSearchProvider.notifier).resetSearch(),
              child: Text(
                'Search Again',
                style: GoogleFonts.plusJakartaSans(
                  color: _brownText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Quick info chip (rating / price / distance)
  // -------------------------------------------------------------------------

  Widget _buildQuickInfo(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Loading state (initial user fetch)
  // -------------------------------------------------------------------------

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _ctaOrange),
          const SizedBox(height: 16),
          Text(
            'Getting ready...',
            style: GoogleFonts.plusJakartaSans(
              color: _brownText,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Map directions launcher
  // -------------------------------------------------------------------------

  Future<void> _openMapDirections(Restaurant restaurant) async {
    try {
      HapticFeedback.mediumImpact();

      String url;

      if (restaurant.latitude != null && restaurant.longitude != null) {
        // Use coordinates for more accurate directions
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
