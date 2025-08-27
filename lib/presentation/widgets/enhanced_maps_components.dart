import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/restaurant.dart';
import '../../domain/entities/user_preferences.dart';
import 'ux_components.dart';

/// Enhanced Maps components with custom markers, directions, and advanced features
/// Optimized for restaurant discovery with dietary compatibility indicators
/// Performance target: <3s load time, 60fps navigation

/// Enhanced maps view with advanced features (clustering disabled for compatibility)
class UXEnhancedMapsView extends StatefulWidget {
  final List<Restaurant> restaurants;
  final UserPreferences userPreferences;
  final Position? userLocation;
  final Function(Restaurant)? onRestaurantSelected;
  final Function(LatLng)? onMapTap;
  final Function(double)? onRadiusChanged;
  final Function(Restaurant)? onRestaurantFavorited;
  final Function(Restaurant)? onDirectionsRequested;
  final bool showUserLocation;
  final double initialZoom;
  final bool enableRealTimeTracking;

  const UXEnhancedMapsView({
    super.key,
    required this.restaurants,
    required this.userPreferences,
    this.userLocation,
    this.onRestaurantSelected,
    this.onMapTap,
    this.onRadiusChanged,
    this.onRestaurantFavorited,
    this.onDirectionsRequested,
    this.showUserLocation = true,
    this.initialZoom = 14.0,
    this.enableRealTimeTracking = false,
  });

  @override
  State<UXEnhancedMapsView> createState() => _UXEnhancedMapsViewState();
}

class _UXEnhancedMapsViewState extends State<UXEnhancedMapsView> with TickerProviderStateMixin {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDisposed = false;
  StreamSubscription<Position>? _locationSubscription;
  
  // Custom marker icons
  BitmapDescriptor? _userMarkerIcon;
  Map<String, BitmapDescriptor> _customMarkerIcons = {};
  
  // Animation controller for smooth transitions
  late AnimationController _animationController;
  
  // Favorites and directions
  Set<String> _favoriteRestaurantIds = {};
  Restaurant? _selectedRestaurant;
  bool _showDirections = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadCustomMarkerIcons();
    _initializeMarkers();
  }

  @override
  void didUpdateWidget(UXEnhancedMapsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurants != widget.restaurants ||
        oldWidget.userLocation != widget.userLocation) {
      _initializeMarkers();
    }
  }

  /// Load custom marker icons for dietary compatibility
  Future<void> _loadCustomMarkerIcons() async {
    if (_isDisposed) return;

    try {
      // Create custom markers for different dietary compatibility levels
      _customMarkerIcons['safe'] = await _createCustomMarker(Colors.green, Icons.check_circle);
      _customMarkerIcons['verified'] = await _createCustomMarker(Colors.blue, Icons.verified);
      _customMarkerIcons['caution'] = await _createCustomMarker(Colors.orange, Icons.warning);
      _customMarkerIcons['warning'] = await _createCustomMarker(Colors.red, Icons.dangerous);
      _customMarkerIcons['favorite'] = await _createCustomMarker(Colors.pink, Icons.favorite);
      
      // User location marker
      _userMarkerIcon = await _createCustomMarker(Colors.blue, Icons.person_pin_circle, size: 50);
    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          _errorMessage = 'Failed to load custom markers: $e';
        });
      }
    }
  }

  /// Create custom bitmap descriptor for markers
  Future<BitmapDescriptor> _createCustomMarker(Color color, IconData icon, {int size = 40}) async {
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;
    
    // Draw circle background
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    
    // Draw white border
    paint
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    
    // Draw icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _initializeMarkers() {
    // Don't proceed if widget is disposed
    if (_isDisposed || !mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _updateUserLocationMarker();
      _updateRadiusCircle();
      _createIndividualMarkers();
    } catch (e) {
      // Only update state if still mounted and not disposed
      if (mounted && !_isDisposed) {
        setState(() {
          _errorMessage = 'Failed to load map markers: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Update user location marker with custom icon
  void _updateUserLocationMarker() {
    if (!widget.showUserLocation || 
        widget.userLocation == null || 
        _isDisposed || 
        !mounted) return;

    final markers = Set<Marker>.from(_markers);
    
    // Remove existing user location marker
    markers.removeWhere((marker) => marker.markerId.value == 'user_location');
    
    // Add new user location marker with custom icon
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(
          widget.userLocation!.latitude,
          widget.userLocation!.longitude,
        ),
        icon: _userMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Current position',
        ),
        zIndex: 1000, // Ensure user marker is always on top
      ),
    );

    setState(() {
      _markers = markers;
    });
  }

  /// Update search radius circle
  void _updateRadiusCircle() {
    if (!widget.showUserLocation || 
        widget.userLocation == null || 
        _isDisposed || 
        !mounted) return;

    final circles = Set<Circle>.from(_circles);
    
    // Remove existing radius circle
    circles.removeWhere((circle) => circle.circleId.value == 'search_radius');
    
    // Add updated radius circle
    circles.add(
      Circle(
        circleId: const CircleId('search_radius'),
        center: LatLng(
          widget.userLocation!.latitude,
          widget.userLocation!.longitude,
        ),
        radius: widget.userPreferences.maxTravelDistance * 1000, // Convert to meters
        fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        strokeColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        strokeWidth: 2,
      ),
    );

    setState(() {
      _circles = circles;
    });
  }

  /// Create individual restaurant markers
  void _createIndividualMarkers() {
    final markers = Set<Marker>.from(_markers);
    
    // Remove existing restaurant markers
    markers.removeWhere((marker) => 
      marker.markerId.value != 'user_location' && 
      !marker.markerId.value.startsWith('cluster_'));

    // Add restaurant markers with custom icons
    for (final restaurant in widget.restaurants) {
      if (restaurant.latitude != null && restaurant.longitude != null) {
        final safetyLevel = restaurant.getSafetyLevel(widget.userPreferences.allergens);
        final dietaryScore = restaurant.calculateDietaryCompatibility(
          widget.userPreferences.dietaryRestrictions,
          widget.userPreferences.allergens,
        );

        final isFavorite = _favoriteRestaurantIds.contains(restaurant.placeId);
        final customIcon = _getCustomMarkerIcon(safetyLevel, dietaryScore, isFavorite);

        markers.add(
          Marker(
            markerId: MarkerId(restaurant.placeId),
            position: LatLng(restaurant.latitude!, restaurant.longitude!),
            icon: customIcon,
            infoWindow: InfoWindow(
              title: restaurant.name,
              snippet: _getEnhancedMarkerSnippet(restaurant),
              onTap: () => _showRestaurantBottomSheet(restaurant),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              _selectRestaurant(restaurant);
            },
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _isLoading = false;
    });
  }

  /// Get custom marker icon based on safety and dietary compatibility
  BitmapDescriptor _getCustomMarkerIcon(SafetyLevel safetyLevel, double dietaryScore, bool isFavorite) {
    if (isFavorite && _customMarkerIcons.containsKey('favorite')) {
      return _customMarkerIcons['favorite']!;
    }
    
    // Use custom markers if available
    switch (safetyLevel) {
      case SafetyLevel.verified:
        return _customMarkerIcons['verified'] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case SafetyLevel.safe:
        return _customMarkerIcons['safe'] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case SafetyLevel.caution:
        return _customMarkerIcons['caution'] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case SafetyLevel.warning:
        return _customMarkerIcons['warning'] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  /// Enhanced marker snippet with more information
  String _getEnhancedMarkerSnippet(Restaurant restaurant) {
    final parts = <String>[];
    
    if (restaurant.rating != null) {
      parts.add('⭐ ${restaurant.rating!.toStringAsFixed(1)}');
    }
    
    if (restaurant.priceLevel != null) {
      parts.add(r'$' * restaurant.priceLevel!);
    }
    
    if (restaurant.distanceFromUser != null) {
      parts.add('${restaurant.distanceFromUser!.toStringAsFixed(1)}km');
    }
    
    if (restaurant.isOpenNow) {
      parts.add('Open now');
    }
    
    final dietaryScore = restaurant.calculateDietaryCompatibility(
      widget.userPreferences.dietaryRestrictions,
      widget.userPreferences.allergens,
    );
    
    if (dietaryScore > 0.8) {
      parts.add('Great match!');
    } else if (dietaryScore < 0.5) {
      parts.add('Check dietary info');
    }
    
    return parts.join(' • ');
  }

  /// Select restaurant and show details
  void _selectRestaurant(Restaurant restaurant) {
    setState(() {
      _selectedRestaurant = restaurant;
    });
    
    widget.onRestaurantSelected?.call(restaurant);
    
    // Animate to restaurant with smooth transition
    if (_controller != null) {
      _animationController.forward().then((_) {
        _animationController.reset();
      });
      
      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(restaurant.latitude!, restaurant.longitude!),
            zoom: 17.0,
          ),
        ),
      );
    }
  }

  /// Show restaurant bottom sheet with actions
  void _showRestaurantBottomSheet(Restaurant restaurant) {
    _selectRestaurant(restaurant);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RestaurantBottomSheet(
        restaurant: restaurant,
        userPreferences: widget.userPreferences,
        isFavorite: _favoriteRestaurantIds.contains(restaurant.placeId),
        onFavoriteToggled: () => _toggleFavorite(restaurant),
        onDirectionsRequested: () => _getDirections(restaurant),
        onCallRequested: () => _callRestaurant(restaurant),
      ),
    );
  }

  /// Toggle restaurant favorite status
  void _toggleFavorite(Restaurant restaurant) {
    setState(() {
      if (_favoriteRestaurantIds.contains(restaurant.placeId)) {
        _favoriteRestaurantIds.remove(restaurant.placeId);
      } else {
        _favoriteRestaurantIds.add(restaurant.placeId);
      }
    });
    
    widget.onRestaurantFavorited?.call(restaurant);
    
    // Refresh markers to update favorite icons
    _initializeMarkers();
  }

  /// Get directions to restaurant
  Future<void> _getDirections(Restaurant restaurant) async {
    if (widget.userLocation == null || restaurant.latitude == null || restaurant.longitude == null) return;
    
    setState(() {
      _showDirections = true;
    });
    
    widget.onDirectionsRequested?.call(restaurant);
    
    try {
      // Create a simple straight line for demonstration
      final polyline = Polyline(
        polylineId: PolylineId('directions_${restaurant.placeId}'),
        points: [
          LatLng(widget.userLocation!.latitude, widget.userLocation!.longitude),
          LatLng(restaurant.latitude!, restaurant.longitude!),
        ],
        color: Theme.of(context).colorScheme.primary,
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      );
      
      setState(() {
        _polylines = {polyline};
      });
      
      // Launch external maps app
      final url = 'https://www.google.com/maps/dir/?api=1&destination=${restaurant.latitude},${restaurant.longitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get directions: $e')),
        );
      }
    }
  }

  /// Call restaurant
  Future<void> _callRestaurant(Restaurant restaurant) async {
    if (restaurant.phoneNumber == null) return;
    
    final url = 'tel:${restaurant.phoneNumber}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    // Don't proceed if widget is disposed
    if (_isDisposed || !mounted) {
      controller.dispose();
      return;
    }
    
    _controller = controller;
    
    try {
      // Move camera to user location or first restaurant with safety checks
      if (!_isDisposed && mounted && widget.userLocation != null) {
        await _controller!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                widget.userLocation!.latitude,
                widget.userLocation!.longitude,
              ),
              zoom: widget.initialZoom,
            ),
          ),
        );
      } else if (!_isDisposed && mounted && 
                 widget.restaurants.isNotEmpty && 
                 widget.restaurants.first.latitude != null &&
                 widget.restaurants.first.longitude != null) {
        await _controller!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                widget.restaurants.first.latitude!,
                widget.restaurants.first.longitude!,
              ),
              zoom: widget.initialZoom,
            ),
          ),
        );
      }
      
      // Start real-time location tracking if enabled
      if (widget.enableRealTimeTracking) {
        _startLocationTracking();
      }
    } catch (e) {
      // Handle camera animation errors gracefully
      if (mounted && !_isDisposed) {
        setState(() {
          _errorMessage = 'Failed to initialize map camera: ${e.toString()}';
        });
      }
    }
  }

  /// Start real-time location tracking
  void _startLocationTracking() {
    _locationSubscription?.cancel();
    
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      if (_isDisposed || !mounted) return;
      
      // Update user location marker
      _updateUserLocationMarker();
      
      // Update radius circle
      _updateRadiusCircle();
    });
  }

  /// Handle map tap events
  void _onMapTap(LatLng position) {
    // Clear directions if showing
    if (_showDirections) {
      setState(() {
        _showDirections = false;
        _polylines.clear();
      });
    }
    
    widget.onMapTap?.call(position);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 400,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: 'Restaurant map showing ${widget.restaurants.length} nearby restaurants',
      child: Container(
        height: 400,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _isDisposed ? 
            const Center(child: Text('Map disposed')) :
            GoogleMap(
              onMapCreated: _onMapCreated,
              markers: _markers,
              circles: _circles,
              polylines: _polylines,
              onTap: _isDisposed ? null : _onMapTap,
              initialCameraPosition: CameraPosition(
                target: widget.userLocation != null
                    ? LatLng(
                        widget.userLocation!.latitude,
                        widget.userLocation!.longitude,
                      )
                    : const LatLng(37.7749, -122.4194), // Default to SF
                zoom: widget.initialZoom,
              ),
              myLocationEnabled: false, // Use custom user location marker
              myLocationButtonEnabled: false, // Use custom location button
              compassEnabled: !_isDisposed,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              buildingsEnabled: !_isDisposed,
              trafficEnabled: false,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
              liteModeEnabled: false,
            ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    _locationSubscription?.cancel();
    
    // Safely dispose of the Google Maps controller
    if (_controller != null) {
      try {
        _controller!.dispose();
      } catch (e) {
        // Ignore disposal errors - controller might already be disposed
        print('Warning: Error disposing Google Maps controller: $e');
      }
    }
    
    super.dispose();
  }
}

/// Enhanced restaurant bottom sheet with favorite and directions actions
class _RestaurantBottomSheet extends StatelessWidget {
  final Restaurant restaurant;
  final UserPreferences userPreferences;
  final bool isFavorite;
  final VoidCallback onFavoriteToggled;
  final VoidCallback onDirectionsRequested;
  final VoidCallback onCallRequested;

  const _RestaurantBottomSheet({
    required this.restaurant,
    required this.userPreferences,
    required this.isFavorite,
    required this.onFavoriteToggled,
    required this.onDirectionsRequested,
    required this.onCallRequested,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dietaryScore = restaurant.calculateDietaryCompatibility(
      userPreferences.dietaryRestrictions,
      userPreferences.allergens,
    );
    final safetyLevel = restaurant.getSafetyLevel(userPreferences.allergens);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      maxChildSize: 0.7,
      minChildSize: 0.2,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with favorite button
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  restaurant.name,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  restaurant.cuisineType ?? 'Restaurant',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Favorite button
                          IconButton(
                            onPressed: onFavoriteToggled,
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.pink : null,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Rating and basic info
                      Row(
                        children: [
                          if (restaurant.rating != null) ...[
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              restaurant.rating!.toStringAsFixed(1),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (restaurant.reviewCount != null) ...[
                              Text(
                                ' (${restaurant.reviewCount})',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(width: 16),
                          ],
                          
                          if (restaurant.priceLevel != null) ...[
                            Text(
                              r'$' * restaurant.priceLevel!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          
                          if (restaurant.distanceFromUser != null) ...[
                            Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${restaurant.distanceFromUser!.toStringAsFixed(1)}km',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Dietary compatibility card
                      _buildDietaryCompatibilityCard(
                        context, dietaryScore, safetyLevel
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onDirectionsRequested,
                              icon: const Icon(Icons.directions),
                              label: const Text('Directions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          if (restaurant.phoneNumber != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onCallRequested,
                                icon: const Icon(Icons.phone),
                                label: const Text('Call'),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDietaryCompatibilityCard(
    BuildContext context, 
    double dietaryScore, 
    SafetyLevel safetyLevel
  ) {
    final theme = Theme.of(context);
    final compatibilityPercentage = (dietaryScore * 100).toInt();
    
    Color cardColor;
    String statusText;
    IconData statusIcon;
    
    if (safetyLevel == SafetyLevel.verified) {
      cardColor = Colors.blue;
      statusText = 'Community Verified';
      statusIcon = Icons.verified;
    } else if (compatibilityPercentage >= 80) {
      cardColor = Colors.green;
      statusText = 'Great Match!';
      statusIcon = Icons.check_circle;
    } else if (compatibilityPercentage >= 60) {
      cardColor = Colors.orange;
      statusText = 'Good Match';
      statusIcon = Icons.info;
    } else {
      cardColor = Colors.red;
      statusText = 'Check Dietary Info';
      statusIcon = Icons.warning;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: cardColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Dietary Compatibility',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$compatibilityPercentage%',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          LinearProgressIndicator(
            value: dietaryScore,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(cardColor),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            statusText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cardColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact restaurant marker for list/grid views
class UXRestaurantMarker extends StatelessWidget {
  final Restaurant restaurant;
  final UserPreferences userPreferences;
  final VoidCallback? onTap;
  final bool showDistance;
  final bool showInvestmentImpact;

  const UXRestaurantMarker({
    super.key,
    required this.restaurant,
    required this.userPreferences,
    this.onTap,
    this.showDistance = true,
    this.showInvestmentImpact = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safetyLevel = restaurant.getSafetyLevel(userPreferences.allergens);
    final dietaryScore = restaurant.calculateDietaryCompatibility(
      userPreferences.dietaryRestrictions,
      userPreferences.allergens,
    );

    Color safetyColor;
    IconData safetyIcon;
    
    switch (safetyLevel) {
      case SafetyLevel.verified:
        safetyColor = Colors.green;
        safetyIcon = Icons.verified;
        break;
      case SafetyLevel.safe:
        safetyColor = Colors.blue;
        safetyIcon = Icons.check_circle;
        break;
      case SafetyLevel.caution:
        safetyColor = Colors.orange;
        safetyIcon = Icons.warning;
        break;
      case SafetyLevel.warning:
        safetyColor = Colors.red;
        safetyIcon = Icons.dangerous;
        break;
    }

    return Semantics(
      button: true,
      label: '${restaurant.name}, ${_getSafetyDescription(safetyLevel)}, dietary compatibility ${(dietaryScore * 100).toInt()}%',
      child: Card(
        margin: const EdgeInsets.symmetric(
          vertical: UXComponents.paddingXS,
          horizontal: UXComponents.paddingS,
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(UXComponents.paddingM),
            child: Row(
              children: [
                // Safety indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: safetyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: safetyColor.withOpacity(0.3)),
                  ),
                  child: Icon(safetyIcon, color: safetyColor, size: 20),
                ),
                
                const SizedBox(width: UXComponents.paddingM),
                
                // Restaurant details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (restaurant.rating != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  restaurant.rating!.toStringAsFixed(1),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Row(
                        children: [
                          if (restaurant.cuisineType != null) ...[
                            Text(
                              restaurant.cuisineType!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Text(' • '),
                          ],
                          
                          if (restaurant.priceLevel != null) ...[
                            Text(
                              r'$' * restaurant.priceLevel!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(' • '),
                          ],
                          
                          if (showDistance && restaurant.distanceFromUser != null) ...[
                            Text(
                              '${restaurant.distanceFromUser!.toStringAsFixed(1)}km',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      if (dietaryScore < 1.0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.info,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(dietaryScore * 100).toInt()}% dietary match',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Action indicator
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSafetyDescription(SafetyLevel level) {
    switch (level) {
      case SafetyLevel.verified:
        return 'Community verified safe';
      case SafetyLevel.safe:
        return 'Safe for your dietary needs';
      case SafetyLevel.caution:
        return 'Some dietary considerations';
      case SafetyLevel.warning:
        return 'May contain allergens';
    }
  }
}

/// Compact map controls for mobile-optimized Discovery page
class UXCompactMapControls extends StatelessWidget {
  final double currentRadius;
  final Function(double) onRadiusChanged;
  final bool isMapView;
  final Function(bool) onViewChanged;
  final VoidCallback? onLocationPressed;
  final bool isLocationLoading;

  const UXCompactMapControls({
    super.key,
    required this.currentRadius,
    required this.onRadiusChanged,
    required this.isMapView,
    required this.onViewChanged,
    this.onLocationPressed,
    this.isLocationLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 56, // Fixed compact height
      margin: const EdgeInsets.symmetric(horizontal: UXComponents.paddingS),
      padding: const EdgeInsets.symmetric(horizontal: UXComponents.paddingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // View toggle - compact
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.list, size: 16),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.map, size: 16),
              ),
            ],
            selected: {isMapView},
            onSelectionChanged: (Set<bool> selection) {
              HapticFeedback.lightImpact();
              onViewChanged(selection.first);
            },
            style: SegmentedButton.styleFrom(
              minimumSize: const Size(40, 32),
              maximumSize: const Size(40, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
            ),
          ),
          
          const SizedBox(width: UXComponents.paddingM),
          
          // Radius info and slider combined
          Expanded(
            child: Row(
              children: [
                Text(
                  '${currentRadius.toStringAsFixed(1)}km',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                
                const SizedBox(width: UXComponents.paddingS),
                
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: currentRadius,
                      min: 1.0,
                      max: 20.0,
                      divisions: 19,
                      onChanged: onRadiusChanged,
                      activeColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: UXComponents.paddingS),
          
          // Quick radius buttons - only most common ones
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [2.0, 5.0, 10.0].map((radius) =>
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Semantics(
                  button: true,
                  label: '${radius}km radius',
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onRadiusChanged(radius);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: currentRadius == radius 
                          ? theme.colorScheme.primaryContainer
                          : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: currentRadius == radius 
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${radius.toInt()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: currentRadius == radius 
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ).toList(),
          ),
          
          const SizedBox(width: UXComponents.paddingS),
          
          // Location button - compact
          Semantics(
            button: true,
            label: 'Update location',
            child: GestureDetector(
              onTap: isLocationLoading ? null : onLocationPressed,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: isLocationLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.my_location,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Legend explaining map markers and safety indicators
class UXMapLegend extends StatelessWidget {
  const UXMapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(UXComponents.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Map Legend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: UXComponents.paddingM),
            
            // Safety levels
            ...[
              _LegendItem(
                color: Colors.green,
                icon: Icons.verified,
                title: 'Community Verified',
                description: 'Dietary info verified by community',
              ),
              _LegendItem(
                color: Colors.blue,
                icon: Icons.check_circle,
                title: 'Safe',
                description: 'No known allergens or dietary conflicts',
              ),
              _LegendItem(
                color: Colors.orange,
                icon: Icons.warning,
                title: 'Caution',
                description: 'Some dietary considerations needed',
              ),
              _LegendItem(
                color: Colors.red,
                icon: Icons.dangerous,
                title: 'Warning',
                description: 'May contain your allergens',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String description;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: UXComponents.paddingS),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          
          const SizedBox(width: UXComponents.paddingS),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}