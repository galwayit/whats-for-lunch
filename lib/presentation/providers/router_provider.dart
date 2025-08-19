import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../pages/discover_page.dart';
import '../pages/home_page.dart';
import '../pages/hungry_page.dart';
import '../pages/onboarding_page.dart';
import '../pages/preferences_page.dart';
import '../pages/profile_page.dart';
import '../pages/track_page.dart';
import '../widgets/main_scaffold.dart';
import 'simple_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final currentUserId = ref.watch(currentUserIdProvider);
  
  return GoRouter(
    initialLocation: currentUserId == null ? AppRoutes.onboarding : AppRoutes.home,
    redirect: (context, state) {
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final hasUser = currentUserId != null;
      
      // If user is not onboarded and trying to access protected routes
      if (!hasUser && !isOnboarding) {
        return AppRoutes.onboarding;
      }
      
      // If user is onboarded but on onboarding page
      if (hasUser && isOnboarding) {
        return AppRoutes.home;
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.hungry,
            builder: (context, state) => const HungryPage(),
          ),
          GoRoute(
            path: AppRoutes.discover,
            builder: (context, state) => const DiscoverPage(),
          ),
          GoRoute(
            path: AppRoutes.track,
            builder: (context, state) => const TrackPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.preferences,
        builder: (context, state) => const PreferencesPage(),
      ),
    ],
  );
});