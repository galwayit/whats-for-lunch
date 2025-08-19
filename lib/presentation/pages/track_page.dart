import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../domain/entities/meal.dart';
import '../providers/budget_providers.dart';
import '../providers/meal_providers.dart';
import '../providers/photo_providers.dart';
import '../providers/simple_providers.dart';
import '../widgets/enhanced_meal_history.dart';
import '../widgets/meal_entry_form.dart';
import '../widgets/photo_components.dart';
import '../widgets/ux_components.dart';
import '../widgets/ux_investment_components.dart';
import '../../services/photo_service.dart';

/// Comprehensive meal logging page with positive psychology messaging and mobile-first design
class TrackPage extends ConsumerStatefulWidget {
  const TrackPage({super.key});

  @override
  ConsumerState<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends ConsumerState<TrackPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final weeklyInvestment = ref.watch(weeklyInvestmentProvider);
    final achievementState = ref.watch(achievementProvider);
    
    // Initialize achievement watcher
    ref.watch(initializeAchievementWatcherProvider);
    
    // If no user is logged in, show onboarding prompt
    if (currentUser == null) {
      return _buildOnboardingPrompt(context);
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          Column(
            children: [
              // Investment capacity header
              _buildInvestmentCapacityHeader(context, weeklyInvestment),
              
              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    // Main meal logging form
          MealEntryForm(
            autofocus: true,
            onSubmitted: () {
              // Optionally navigate to a success page or stay on form
              _showSuccessMessage();
            },
          ),
          
          // Quick actions page
          _buildQuickActionsPage(context),
          
          // Recent meals and investment overview
          _buildInvestmentOverviewPage(context),
        ],
                ),
              ),
            ],
          ),
          
          // Achievement notification overlay
          if (achievementState.latestAchievement != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: UXAchievementNotification(
                  title: achievementState.latestAchievement!.title,
                  description: achievementState.latestAchievement!.description,
                  icon: _getAchievementIcon(achievementState.latestAchievement!.iconName),
                  show: true,
                  onDismiss: () {
                    ref.read(achievementProvider.notifier).dismissLatestAchievement();
                  },
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildPageIndicator(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        _getPageTitle(),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      actions: [
        // Settings/preferences button
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.go(AppRoutes.profile);
          },
          icon: const Icon(Icons.tune),
          tooltip: 'Preferences',
        ),
        // Help/info button
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showHelpDialog(context);
          },
          icon: const Icon(Icons.help_outline),
          tooltip: 'Help',
        ),
      ],
    );
  }

  String _getPageTitle() {
    switch (_currentPage) {
      case 0:
        return 'Log Experience';
      case 1:
        return 'Quick Actions';
      case 2:
        return 'Investment Overview';
      default:
        return 'Track';
    }
  }

  Widget _buildOnboardingPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experience Logging'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: UXComponents.paddingL),
            Text(
              'Start Your Journey',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UXComponents.paddingM),
            Text(
              'To begin logging your dining experiences and track your investments in happiness, please complete your profile setup.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UXComponents.paddingXL),
            UXPrimaryButton(
              onPressed: () {
                context.go(AppRoutes.profile);
              },
              text: 'Set Up Profile',
              icon: Icons.person_add,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsPage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UXComponents.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UXFadeIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Logging',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: UXComponents.paddingS),
                Text(
                  'Log common experiences with a single tap',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: UXComponents.paddingXL),
          
          QuickActionButtons(
            onQuickAction: (type) {
              // Switch to main form page after quick action
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Quick action applied! Complete the details below.'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          
          const SizedBox(height: UXComponents.paddingXL),
          
          // Tips for efficient logging
          UXCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: UXComponents.paddingS),
                    Text(
                      'Logging Tips',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UXComponents.paddingM),
                _buildTipItem(
                  context,
                  Icons.timer,
                  'Log immediately',
                  'Best results when you log right after eating',
                ),
                _buildTipItem(
                  context,
                  Icons.psychology,
                  'Focus on experience',
                  'Remember this is an investment in your well-being',
                ),
                _buildTipItem(
                  context,
                  Icons.auto_awesome,
                  'Use smart defaults',
                  'The app learns your patterns to save time',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UXComponents.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: UXComponents.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMealsPage(BuildContext context) {
    final recentMealsAsync = ref.watch(recentMealsProvider);
    
    return recentMealsAsync.when(
      data: (meals) => _buildRecentMealsList(context, meals),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => UXErrorState(
        title: 'Unable to load recent experiences',
        message: 'We\'re having trouble loading your recent dining experiences. Please try again.',
        onRetry: () {
          ref.invalidate(recentMealsProvider);
        },
      ),
    );
  }

  Widget _buildRecentMealsList(BuildContext context, List<Meal> meals) {
    if (meals.isEmpty) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(UXComponents.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UXFadeIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Experiences',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: UXComponents.paddingS),
                Text(
                  'Your dining journey over the past 30 days',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: UXComponents.paddingL),
          
          // Quick stats
          _buildQuickStats(context, meals),
          const SizedBox(height: UXComponents.paddingL),
          
          // Meals list
          ...meals.take(10).map((meal) => _buildMealCard(context, meal)),
          
          if (meals.length > 10) ...[
            const SizedBox(height: UXComponents.paddingM),
            Center(
              child: UXSecondaryButton(
                onPressed: () {
                  // TODO: Navigate to full history page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Full history coming in next update!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                text: 'View All Experiences',
                icon: Icons.history,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: UXComponents.paddingL),
            Text(
              'Your Journey Starts Here',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UXComponents.paddingM),
            Text(
              'Begin logging your dining experiences to track your investments in happiness and well-being.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UXComponents.paddingXL),
            UXPrimaryButton(
              onPressed: () {
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              text: 'Log Your First Experience',
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, List<Meal> meals) {
    final totalSpent = meals.fold<double>(0.0, (sum, meal) => sum + meal.cost);
    final avgCost = meals.isNotEmpty ? totalSpent / meals.length : 0.0;
    final mealCount = meals.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total Invested',
            '\$${totalSpent.toStringAsFixed(2)}',
            Icons.account_balance_wallet,
            Colors.green,
          ),
        ),
        const SizedBox(width: UXComponents.paddingM),
        Expanded(
          child: _buildStatCard(
            context,
            'Experiences',
            mealCount.toString(),
            Icons.restaurant,
            Colors.blue,
          ),
        ),
        const SizedBox(width: UXComponents.paddingM),
        Expanded(
          child: _buildStatCard(
            context,
            'Avg. Cost',
            '\$${avgCost.toStringAsFixed(2)}',
            Icons.trending_up,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return UXCard(
      padding: const EdgeInsets.all(UXComponents.paddingM),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: UXComponents.paddingS),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, Meal meal) {
    return UXCard(
      margin: const EdgeInsets.only(bottom: UXComponents.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getMealTypeIcon(meal.mealType),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: UXComponents.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMealTypeName(meal.mealType),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (meal.notes != null && meal.notes!.isNotEmpty)
                      Text(
                        meal.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${meal.cost.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    _formatMealDate(meal.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Photos section
          const SizedBox(height: UXComponents.paddingM),
          Consumer(
            builder: (context, ref, child) {
              final photosAsyncValue = ref.watch(mealPhotosProvider(meal.id.toString()));
              
              return photosAsyncValue.when(
                data: (photos) {
                  if (photos.isEmpty) return const SizedBox.shrink();
                  
                  return PhotoGalleryWidget(
                    photos: photos,
                    showAddButton: false,
                  );
                },
                loading: () => const SizedBox(
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (error, stackTrace) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: UXComponents.paddingM,
        horizontal: UXComponents.paddingL,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < 3; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _currentPage
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
        ],
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Experience logged! Your journey continues...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            _pageController.animateToPage(
              2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Experience Logging Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This app helps you track your dining experiences as investments in your happiness and well-being.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                '💰 Investment Mindset',
                'Think of each meal as an investment in your well-being rather than just an expense.',
              ),
              _buildHelpItem(
                '⚡ Quick Logging',
                'Log experiences immediately for the most accurate tracking.',
              ),
              _buildHelpItem(
                '🎯 Smart Defaults',
                'The app learns your patterns and suggests appropriate values.',
              ),
              _buildHelpItem(
                '📊 Budget Awareness',
                'See how each experience fits into your weekly investment plan.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.local_cafe;
      case 'delivery':
        return Icons.delivery_dining;
      case 'takeout':
        return Icons.takeout_dining;
      case 'groceries':
        return Icons.shopping_cart;
      default:
        return Icons.restaurant;
    }
  }

  String _getMealTypeName(String mealType) {
    switch (mealType) {
      case 'dining_out':
        return 'Dining Out';
      case 'delivery':
        return 'Delivery';
      case 'takeout':
        return 'Takeout';
      case 'groceries':
        return 'Groceries';
      case 'snack':
        return 'Snack';
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return 'Experience';
    }
  }

  String _formatMealDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  /// Investment capacity header with circular progress ring
  Widget _buildInvestmentCapacityHeader(BuildContext context, WeeklyInvestmentState weeklyState) {
    final theme = Theme.of(context);
    
    if (weeklyState.isLoading) {
      return Container(
        padding: const EdgeInsets.all(UXComponents.paddingM),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (weeklyState.errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(UXComponents.paddingM),
        child: Text(
          'Investment data unavailable',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(UXComponents.paddingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Investment capacity ring
          UXInvestmentCapacityRing(
            currentSpent: weeklyState.currentSpent,
            weeklyCapacity: weeklyState.weeklyCapacity,
            remainingCapacity: weeklyState.remainingCapacity,
            animate: true,
            onTap: () {
              _pageController.animateToPage(
                2,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          const SizedBox(width: UXComponents.paddingL),
          
          // Quick stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Week\'s Investment',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: UXComponents.paddingXS),
                Text(
                  '\$${weeklyState.currentSpent.toStringAsFixed(2)} of \$${weeklyState.weeklyCapacity.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: UXComponents.paddingS),
                Row(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: UXComponents.paddingXS),
                    Text(
                      '${weeklyState.experiencesLogged} experiences logged',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Setup button if no budget configured
          if (weeklyState.weeklyCapacity <= 0)
            TextButton.icon(
              onPressed: () {
                context.push('/budget-setup');
              },
              icon: const Icon(Icons.settings),
              label: const Text('Setup'),
            ),
        ],
      ),
    );
  }

  /// Investment overview page with enhanced meal history timeline
  Widget _buildInvestmentOverviewPage(BuildContext context) {
    final weeklyInvestment = ref.watch(weeklyInvestmentProvider);
    final recentMealsAsync = ref.watch(recentMealsProvider);
    final achievementState = ref.watch(achievementProvider);
    
    return Column(
      children: [
        // Quick filters for timeline
        Container(
          padding: const EdgeInsets.symmetric(vertical: UXComponents.paddingS),
          child: MealTimelineFilters(
            selectedFilter: 'week', // This could be made stateful
            onFilterChanged: (filter) {
              // TODO: Implement filter logic
              HapticFeedback.lightImpact();
            },
          ),
        ),
        
        // Enhanced meal history timeline
        Expanded(
          child: recentMealsAsync.when(
            data: (meals) => EnhancedMealHistory(
              meals: meals,
              timeframe: 'week',
              onRefresh: () async {
                await ref.read(weeklyInvestmentProvider.notifier).refreshData();
                ref.invalidate(recentMealsProvider);
              },
              onMealTap: (meal) {
                _showMealDetailsDialog(context, meal);
              },
            ),
            loading: () => const EnhancedMealHistory(
              meals: [],
              isLoading: true,
            ),
            error: (error, stack) => EnhancedMealHistory(
              meals: [],
              errorMessage: 'Unable to load your meal history',
              onRefresh: () {
                ref.invalidate(recentMealsProvider);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyRecentMeals(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: UXComponents.paddingM),
            Text(
              'No Recent Experiences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: UXComponents.paddingS),
            Text(
              'Start logging your dining experiences to see them here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UXComponents.paddingL),
            UXSecondaryButton(
              onPressed: () {
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              text: 'Log First Experience',
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementProgress(BuildContext context, AchievementState achievementState) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                ),
                const SizedBox(width: UXComponents.paddingS),
                Text(
                  'Achievement Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${achievementState.unlockedAchievements.length}/${achievementState.availableAchievements.length}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UXComponents.paddingM),
            
            // Achievement progress bar
            LinearProgressIndicator(
              value: achievementState.availableAchievements.isNotEmpty
                ? achievementState.unlockedAchievements.length / achievementState.availableAchievements.length
                : 0.0,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
            const SizedBox(height: UXComponents.paddingM),
            
            // Level and points
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level: ${achievementState.currentLevel}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${achievementState.totalPoints} points earned',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (achievementState.unlockedAchievements.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _showAchievementsDialog(context, achievementState);
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInvestmentDetailsDialog(BuildContext context, WeeklyInvestmentState weeklyState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Investment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Weekly Capacity', '\$${weeklyState.weeklyCapacity.toStringAsFixed(2)}'),
              _buildDetailItem('Current Spent', '\$${weeklyState.currentSpent.toStringAsFixed(2)}'),
              _buildDetailItem('Remaining', '\$${weeklyState.remainingCapacity.toStringAsFixed(2)}'),
              _buildDetailItem('Experiences Logged', '${weeklyState.experiencesLogged}'),
              _buildDetailItem('Target Experiences', '${weeklyState.targetExperiences}'),
              _buildDetailItem('Capacity Usage', '${(weeklyState.capacityProgress * 100).toStringAsFixed(1)}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (weeklyState.weeklyCapacity > 0)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/budget-setup');
              },
              child: const Text('Adjust'),
            ),
        ],
      ),
    );
  }

  void _showAchievementsDialog(BuildContext context, AchievementState achievementState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Achievements'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: achievementState.availableAchievements.length,
            itemBuilder: (context, index) {
              final achievement = achievementState.availableAchievements[index];
              final isUnlocked = achievementState.unlockedAchievements
                  .any((a) => a.id == achievement.id);
              
              return ListTile(
                leading: Icon(
                  _getAchievementIcon(achievement.iconName),
                  color: isUnlocked ? Colors.amber : Colors.grey,
                ),
                title: Text(
                  achievement.title,
                  style: TextStyle(
                    fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
                subtitle: Text(
                  achievement.description,
                  style: TextStyle(
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
                trailing: isUnlocked 
                  ? const Icon(Icons.check_circle, color: Colors.amber)
                  : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UXComponents.paddingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'celebration':
        return Icons.celebration;
      case 'eco':
        return Icons.eco;
      case 'explore':
        return Icons.explore;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'psychology':
        return Icons.psychology;
      default:
        return Icons.emoji_events;
    }
  }

  void _showMealDetailsDialog(BuildContext context, Meal meal) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(UXComponents.paddingS),
              decoration: BoxDecoration(
                color: _getMealTypeColor(meal.mealType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getMealTypeIcon(meal.mealType),
                color: _getMealTypeColor(meal.mealType),
                size: 20,
              ),
            ),
            const SizedBox(width: UXComponents.paddingS),
            Expanded(
              child: Text(
                meal.restaurantName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Investment amount
              Container(
                padding: const EdgeInsets.all(UXComponents.paddingM),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.green),
                    const SizedBox(width: UXComponents.paddingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Investment Amount',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            '\$${meal.cost.toStringAsFixed(2)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: UXComponents.paddingM),
              
              // Experience details
              _buildDetailRow(context, 'Experience Type', _getMealTypeName(meal.mealType)),
              _buildDetailRow(context, 'Date & Time', _formatMealDateTime(meal.date)),
              
              if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                const SizedBox(height: UXComponents.paddingM),
                Text(
                  'Experience Notes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: UXComponents.paddingS),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(UXComponents.paddingM),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(meal.notes!),
                ),
              ],
              
              const SizedBox(height: UXComponents.paddingM),
              
              // Investment insight
              Container(
                padding: const EdgeInsets.all(UXComponents.paddingM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: UXComponents.paddingS),
                    Expanded(
                      child: Text(
                        'This experience represents an investment in your happiness and well-being.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to edit meal
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: UXComponents.paddingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMealDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    String dateStr;
    if (difference.inDays == 0) {
      dateStr = 'Today';
    } else if (difference.inDays == 1) {
      dateStr = 'Yesterday';
    } else if (difference.inDays < 7) {
      dateStr = '${difference.inDays} days ago';
    } else {
      dateStr = '${date.month}/${date.day}/${date.year}';
    }
    
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeStr = '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    
    return '$dateStr at $timeStr';
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.blue;
      case 'dinner':
        return Colors.purple;
      case 'snack':
        return Colors.green;
      case 'delivery':
        return Colors.red;
      case 'takeout':
        return Colors.amber;
      case 'groceries':
        return Colors.teal;
      default:
        return Colors.indigo;
    }
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.local_cafe;
      case 'delivery':
        return Icons.delivery_dining;
      case 'takeout':
        return Icons.takeout_dining;
      case 'groceries':
        return Icons.shopping_cart;
      default:
        return Icons.restaurant;
    }
  }
}