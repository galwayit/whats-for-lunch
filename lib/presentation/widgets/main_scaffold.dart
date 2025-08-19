import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import 'enhanced_navigation.dart';
import 'ux_components.dart';

/// Enhanced main scaffold with contextual navigation and micro-interactions
/// Follows UX advisor requirements for thumb-friendly navigation and engagement
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildEnhancedBottomNavigation(context),
    );
  }

  Widget _buildEnhancedBottomNavigation(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    int currentIndex = 0;
    switch (currentLocation) {
      case AppRoutes.home:
        currentIndex = 0;
        break;
      case AppRoutes.discover:
        currentIndex = 1;
        break;
      case AppRoutes.track:
        currentIndex = 2;
        break;
      case AppRoutes.profile:
        currentIndex = 3;
        break;
      default:
        // Handle nested routes
        if (currentLocation.startsWith('/ai-recommendations') ||
            currentLocation.startsWith('/hungry')) {
          currentIndex = 0; // Home section
        } else if (currentLocation.startsWith('/discover') ||
                   currentLocation.startsWith('/restaurant')) {
          currentIndex = 1; // Discover section
        } else if (currentLocation.startsWith('/track') ||
                   currentLocation.startsWith('/meal') ||
                   currentLocation.startsWith('/budget')) {
          currentIndex = 2; // Track section
        } else if (currentLocation.startsWith('/profile') ||
                   currentLocation.startsWith('/preferences') ||
                   currentLocation.startsWith('/settings')) {
          currentIndex = 3; // Profile section
        } else {
          currentIndex = 0; // Default to home
        }
    }

    return EnhancedBottomNavigation(
      currentIndex: currentIndex,
      onTap: (index) {
        // Navigation is handled internally by EnhancedBottomNavigation
        // This callback is here for future extensibility
      },
    );
  }
}