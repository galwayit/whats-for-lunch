import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/ux_components.dart';

class HungryPage extends ConsumerWidget {
  const HungryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'I\'m Hungry',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(UXComponents.paddingL),
          child: Column(
            children: [
              // Coming soon hero section
              Expanded(
                child: UXFadeIn(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'hungry_icon',
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: Icon(
                            Icons.restaurant_menu,
                            size: 60,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: UXComponents.paddingXL),
                      Text(
                        'AI-Powered Recommendations',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: UXComponents.paddingM),
                      Text(
                        'Get personalized restaurant recommendations based on your preferences, budget, and location',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: UXComponents.paddingXL),
                      
                      // Progress indicator
                      UXCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.construction,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: UXComponents.paddingS),
                                Expanded(
                                  child: Text(
                                    'Smart Recommendations Available',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: UXComponents.paddingS),
                            LinearProgressIndicator(
                              value: 0.85, // 85% complete - most features available
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            const SizedBox(height: UXComponents.paddingS),
                            Text(
                              'Personalized recommendations based on your preferences',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Quick actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Meanwhile, you can:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: UXComponents.paddingM),
                  
                  Row(
                    children: [
                      Expanded(
                        child: UXSecondaryButton(
                          onPressed: () => context.go('/discover'),
                          text: 'Explore Map',
                          icon: Icons.map,
                          semanticLabel: 'Explore restaurants on interactive map',
                        ),
                      ),
                      const SizedBox(width: UXComponents.paddingM),
                      Expanded(
                        child: UXSecondaryButton(
                          onPressed: () => _showTrackingInfo(context),
                          text: 'Track Meals',
                          icon: Icons.add_circle_outline,
                          semanticLabel: 'Start tracking your meals',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExploreComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text('Discover amazing restaurants near you!'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTrackingInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Tracking'),
        content: const Text(
          'Ready to start tracking your meals? Start logging your dining experiences and build your food investment portfolio today!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // This would navigate to track page - handled by main scaffold FAB
            },
            child: const Text('Let\'s Go!'),
          ),
        ],
      ),
    );
  }
}