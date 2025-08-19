import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import 'ux_components.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNavigationBar(context),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    int currentIndex = 0;
    switch (currentLocation) {
      case AppRoutes.hungry:
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
        currentIndex = 0;
    }

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: Icons.restaurant_menu,
            selectedIcon: Icons.restaurant_menu,
            label: 'Hungry',
            route: AppRoutes.hungry,
            isSelected: currentIndex == 0,
          ),
          _buildNavItem(
            context,
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: 'Discover',
            route: AppRoutes.discover,
            isSelected: currentIndex == 1,
          ),
          const SizedBox(width: 40), // Space for FAB
          _buildNavItem(
            context,
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart,
            label: 'Track',
            route: AppRoutes.track,
            isSelected: currentIndex == 2,
          ),
          _buildNavItem(
            context,
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            route: AppRoutes.profile,
            isSelected: currentIndex == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String route,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    
    return Semantics(
      button: true,
      label: 'Navigate to $label',
      selected: isSelected,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.go(route);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: UXComponents.minTouchTarget,
            minHeight: UXComponents.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: UXComponents.paddingS,
            horizontal: UXComponents.paddingS,
          ),
          decoration: isSelected
            ? BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  key: ValueKey(isSelected),
                  size: 24,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Quick meal log',
      hint: 'Add a meal entry quickly with voice, photo, or manual input',
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showQuickLogDialog(context);
        },
        tooltip: 'Quick meal log',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _showQuickLogDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          top: UXComponents.paddingL,
          left: UXComponents.paddingL,
          right: UXComponents.paddingL,
          bottom: MediaQuery.of(context).viewInsets.bottom + UXComponents.paddingL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: UXComponents.paddingL),
            
            // Title
            Text(
              'Quick Meal Log',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: UXComponents.paddingS),
            Text(
              'Choose how you\'d like to log your meal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UXComponents.paddingL),
            
            // Options
            _buildQuickLogOption(
              context,
              icon: Icons.mic,
              title: 'Voice Log',
              subtitle: 'Speak what you ate - fastest option',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement voice logging
                _showComingSoonSnackBar(context, 'Voice logging');
              },
            ),
            const SizedBox(height: UXComponents.paddingS),
            
            _buildQuickLogOption(
              context,
              icon: Icons.camera_alt,
              title: 'Photo Log',
              subtitle: 'Snap a picture of your meal',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement photo logging
                _showComingSoonSnackBar(context, 'Photo logging');
              },
            ),
            const SizedBox(height: UXComponents.paddingS),
            
            _buildQuickLogOption(
              context,
              icon: Icons.edit,
              title: 'Manual Entry',
              subtitle: 'Type meal details and cost',
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.track);
              },
            ),
            
            const SizedBox(height: UXComponents.paddingL),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLogOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return UXCard(
      onTap: onTap,
      semanticLabel: '$title: $subtitle',
      padding: const EdgeInsets.all(UXComponents.paddingM),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: UXComponents.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackBar(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Text('$feature coming in Stage 2!'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}