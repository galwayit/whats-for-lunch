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

/// Simple Maps component without clustering for compatibility
class SimpleMapsView extends StatefulWidget {
  final List<Restaurant> restaurants;
  final UserPreferences userPreferences;
  final Position? userLocation;
  final Function(Restaurant)? onRestaurantSelected;
  final Function(LatLng)? onMapTap;
  final Function(double)? onRadiusChanged;
  final Function(Restaurant)? onRestaurantFavorited;
  final Function(Restaurant)? onDirectionsRequested;

  const SimpleMapsView({
    super.key,
    required this.restaurants,
    required this.userPreferences,
    this.userLocation,
    this.onRestaurantSelected,
    this.onMapTap,
    this.onRadiusChanged,
    this.onRestaurantFavorited,
    this.onDirectionsRequested,
  });

  @override
  State<SimpleMapsView> createState() => _SimpleMapsViewState();
}

class _SimpleMapsViewState extends State<SimpleMapsView>
    with TickerProviderStateMixin {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  
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
  void dispose() {
    _isDisposed = true;
    _locationSubscription?.cancel();
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
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
          _errorMessage = 'Failed to load marker icons: $e';
        });
      }
    }
  }

  /// Create custom marker bitmap
  Future<BitmapDescriptor> _createCustomMarker(Color color, IconData icon, {int size = 40}) async {
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    // Draw circle background
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    
    // Draw white border
    paint
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 1, paint);
    
    // Draw icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * 0.6,
          fontFamily: icon.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
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

  /// Initialize markers for restaurants and user location
  void _initializeMarkers() {
    if (_isDisposed) return;

    _markers.clear();
    
    // Add user location marker
    if (widget.userLocation != null && _userMarkerIcon != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(widget.userLocation!.latitude, widget.userLocation!.longitude),
          icon: _userMarkerIcon!,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Add restaurant markers
    for (final restaurant in widget.restaurants) {
      if (restaurant.latitude != null && restaurant.longitude != null) {
        final safetyLevel = _getDietarySafetyLevel(restaurant);
        final isFavorite = _favoriteRestaurantIds.contains(restaurant.placeId);
        final markerIcon = isFavorite 
            ? (_customMarkerIcons['favorite'] ?? BitmapDescriptor.defaultMarker)
            : (_customMarkerIcons[safetyLevel] ?? BitmapDescriptor.defaultMarker);

        _markers.add(
          Marker(
            markerId: MarkerId(restaurant.placeId),
            position: LatLng(restaurant.latitude!, restaurant.longitude!),
            icon: markerIcon,
            infoWindow: InfoWindow(
              title: restaurant.name,
              snippet: '${restaurant.priceLevel ?? 'Price not available'} • ${restaurant.rating?.toStringAsFixed(1) ?? 'No rating'}★',
            ),
            onTap: () => _onRestaurantMarkerTapped(restaurant),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  /// Determine dietary safety level for restaurant marker
  String _getDietarySafetyLevel(Restaurant restaurant) {
    // Check dietary compatibility based on user preferences
    final userDietaryRestrictions = widget.userPreferences.dietaryRestrictions;
    
    if (userDietaryRestrictions.isEmpty) return 'verified';
    
    // Simple compatibility check - in production this would be more sophisticated
    final cuisineType = restaurant.cuisineType?.toLowerCase() ?? '';
    
    if (userDietaryRestrictions.contains('vegetarian') && 
        !cuisineType.contains('vegetarian') && 
        !cuisineType.contains('vegan')) {
      return 'caution';
    }
    
    if (userDietaryRestrictions.contains('vegan') && 
        !cuisineType.contains('vegan')) {
      return 'warning';
    }
    
    return 'safe';
  }

  /// Handle restaurant marker tap
  void _onRestaurantMarkerTapped(Restaurant restaurant) {
    setState(() {
      _selectedRestaurant = restaurant;
    });
    
    widget.onRestaurantSelected?.call(restaurant);
    
    // Show restaurant details bottom sheet
    _showRestaurantBottomSheet(restaurant);
  }

  /// Show restaurant details in bottom sheet
  void _showRestaurantBottomSheet(Restaurant restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Restaurant info
              Text(
                restaurant.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text('${restaurant.rating?.toStringAsFixed(1) ?? 'No rating'}'),
                  const SizedBox(width: 16),
                  Text('${restaurant.priceLevel ?? 'Price not available'}'),
                ],
              ),
              
              if (restaurant.address != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 4),
                    Expanded(child: Text(restaurant.address!)),
                  ],
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleFavorite(restaurant),
                      icon: Icon(_favoriteRestaurantIds.contains(restaurant.placeId) 
                          ? Icons.favorite 
                          : Icons.favorite_border),
                      label: Text(_favoriteRestaurantIds.contains(restaurant.placeId) 
                          ? 'Favorited' 
                          : 'Favorite'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _favoriteRestaurantIds.contains(restaurant.placeId)
                            ? Colors.pink
                            : Colors.grey[200],
                        foregroundColor: _favoriteRestaurantIds.contains(restaurant.placeId)
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _getDirections(restaurant),
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    _initializeMarkers(); // Refresh markers
  }

  /// Get directions to restaurant
  void _getDirections(Restaurant restaurant) async {
    if (restaurant.latitude != null && restaurant.longitude != null) {
      final url = 'https://www.google.com/maps/dir/?api=1&destination=${restaurant.latitude},${restaurant.longitude}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
    
    widget.onDirectionsRequested?.call(restaurant);
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _loadCustomMarkerIcons();
                _initializeMarkers();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: widget.userLocation != null
            ? LatLng(widget.userLocation!.latitude, widget.userLocation!.longitude)
            : const LatLng(37.7749, -122.4194), // Default to SF
        zoom: 14.0,
      ),
      markers: _markers,
      circles: _circles,
      onMapCreated: (GoogleMapController controller) {
        _controller = controller;
      },
      onTap: (LatLng position) {
        widget.onMapTap?.call(position);
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: false,
    );
  }
}