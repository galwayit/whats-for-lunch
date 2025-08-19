import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../domain/entities/user_preferences.dart';
import '../providers/budget_providers.dart';
import '../providers/meal_providers.dart';
import '../providers/simple_providers.dart' as simple;
import '../widgets/enhanced_navigation.dart';
import '../widgets/investment_charts.dart';
import '../widgets/ux_components.dart';
import '../widgets/ux_investment_components.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingHeader = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scrollController.addListener(_onScroll);
    
    // Start welcome animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const threshold = 120.0;
    if (_scrollController.offset > threshold && !_showFloatingHeader) {
      setState(() {
        _showFloatingHeader = true;
      });
    } else if (_scrollController.offset <= threshold && _showFloatingHeader) {
      setState(() {
        _showFloatingHeader = false;
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(simple.currentUserProvider);
    final preferences = ref.watch(simple.simpleUserPreferencesProvider);
    final weeklyInvestment = ref.watch(weeklyInvestmentProvider);

    return Scaffold(
      appBar: EnhancedAppBar(
        title: 'DietBuddy',
        subtitle: _showFloatingHeader ? 'Investment Dashboard' : null,
        showInvestmentIndicator: weeklyInvestment.weeklyCapacity > 0,
        investmentProgress: weeklyInvestment.capacityProgress,
        onInvestmentTap: () {
          context.go(AppRoutes.track);
        },
      ),
      body: currentUser != null
          ? _buildEnhancedContent(context, ref, currentUser['name'] ?? 'User', preferences)
          : _buildLoadingState(),
      floatingActionButton: EnhancedFloatingActionButton(
        onQuickLog: () {
          HapticFeedback.mediumImpact();
          context.go(AppRoutes.track);
        },
        onTakePhoto: () {
          HapticFeedback.mediumImpact();
          _showComingSoonDialog('Photo Recognition');
        },
        onAIRecommend: () {
          HapticFeedback.mediumImpact();
          context.go('/ai-recommendations');
        },
      ),
    );
  }

  Widget _buildEnhancedContent(BuildContext context, WidgetRef ref, String userName, UserPreferences? preferences) {
    final weeklyInvestment = ref.watch(weeklyInvestmentProvider);
    final recentMealsAsync = ref.watch(recentMealsProvider);
    
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await ref.read(weeklyInvestmentProvider.notifier).refreshData();
        ref.invalidate(recentMealsProvider);
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header with investment overview
            _buildWelcomeHeader(context, userName, weeklyInvestment),
            
            // Quick action shortcuts
            const SizedBox(height: UXComponents.paddingL),
            _buildQuickActionShortcuts(context),
            
            // Investment capacity ring (prominent display)
            if (weeklyInvestment.weeklyCapacity > 0) ...[
              const SizedBox(height: UXComponents.paddingL),
              _buildInvestmentCapacitySection(context, weeklyInvestment),
            ],
            
            // Charts and data visualizations
            const SizedBox(height: UXComponents.paddingL),
            recentMealsAsync.when(
              data: (meals) => meals.isNotEmpty 
                ? _buildDataVisualizationSection(context, meals, weeklyInvestment)
                : _buildEmptyDataState(context),
              loading: () => _buildLoadingCharts(),
              error: (error, stack) => _buildErrorState(context, error.toString()),
            ),
            
            // Weekly investment overview
            if (weeklyInvestment.weeklyCapacity > 0) ...[
              const SizedBox(height: UXComponents.paddingL),
              UXWeeklyInvestmentOverview(
                weeklySpent: weeklyInvestment.currentSpent,
                weeklyCapacity: weeklyInvestment.weeklyCapacity,
                experiencesLogged: weeklyInvestment.experiencesLogged,
                targetExperiences: weeklyInvestment.targetExperiences,
                achievements: [], // Will be populated when achievement system is integrated
                onViewDetails: () {
                  context.go(AppRoutes.track);
                },
              ),
            ],
            
            // Bottom padding for FAB
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: UXComponents.paddingM),
          Text('Loading your investment dashboard...'),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String userName, WeeklyInvestmentState weeklyState) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(UXComponents.paddingM),
      padding: const EdgeInsets.all(UXComponents.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $userName!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: UXComponents.paddingS),
                    Text(
                      weeklyState.weeklyCapacity > 0
                          ? 'Your investment journey continues...'
                          : 'Ready to start your investment journey?',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (weeklyState.weeklyCapacity > 0)
                Container(
                  padding: const EdgeInsets.all(UXComponents.paddingM),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${weeklyState.remainingCapacity.toStringAsFixed(0)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'left',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionShortcuts(BuildContext context) {
    final quickActions = [
      QuickAction(
        icon: Icons.restaurant,
        label: 'Hungry',
        color: Colors.orange,
        onTap: () => context.go(AppRoutes.hungry),
      ),
      QuickAction(
        icon: Icons.explore,
        label: 'Discover',
        color: Colors.blue,
        onTap: () => context.go(AppRoutes.discover),
      ),
      QuickAction(
        icon: Icons.add_circle,
        label: 'Log Meal',
        color: Colors.green,
        onTap: () => context.go(AppRoutes.track),
      ),
      QuickAction(
        icon: Icons.analytics,
        label: 'Insights',
        color: Colors.purple,
        onTap: () => context.go('/ai-recommendations'),
      ),
      QuickAction(
        icon: Icons.settings,
        label: 'Settings',
        color: Colors.grey,
        onTap: () => context.go(AppRoutes.profile),
      ),
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: UXComponents.paddingM),
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: UXComponents.paddingM),
        QuickActionShortcuts(actions: quickActions),
      ],
    );
  }

  Widget _buildInvestmentCapacitySection(BuildContext context, WeeklyInvestmentState weeklyState) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: UXComponents.paddingM),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(UXComponents.paddingL),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Investment Capacity',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: UXComponents.paddingS),
                        Text(
                          'Track your dining investment progress',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  UXInvestmentCapacityRing(
                    currentSpent: weeklyState.currentSpent,
                    weeklyCapacity: weeklyState.weeklyCapacity,
                    remainingCapacity: weeklyState.remainingCapacity,
                    animate: true,
                    onTap: () {
                      context.go(AppRoutes.track);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataVisualizationSection(BuildContext context, List meals, WeeklyInvestmentState weeklyState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: UXComponents.paddingM),
          child: Text(
            'Investment Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: UXComponents.paddingM),
        
        // Spending pattern chart
        Container(
          margin: const EdgeInsets.symmetric(horizontal: UXComponents.paddingM),
          child: InvestmentSpendingChart(
            meals: meals.cast(),
            timeframe: 'week',
            weeklyBudget: weeklyState.weeklyCapacity,
            showAnimation: true,
          ),
        ),
        
        const SizedBox(height: UXComponents.paddingL),
        
        // Category distribution chart
        Container(
          margin: const EdgeInsets.symmetric(horizontal: UXComponents.paddingM),
          child: MealCategoryChart(
            meals: meals.cast(),
            showAnimation: true,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDataState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(UXComponents.paddingM),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(UXComponents.paddingXL),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(UXComponents.paddingL),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: UXComponents.paddingL),
              Text(
                'Start Your Investment Journey',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: UXComponents.paddingM),
              Text(
                'Log your first dining experience to see beautiful visualizations of your investment in happiness and well-being.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: UXComponents.paddingL),
              UXPrimaryButton(
                onPressed: () {
                  context.go(AppRoutes.track);
                },
                text: 'Log First Experience',
                icon: Icons.restaurant_menu,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCharts() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: UXComponents.paddingM),
      height: 200,
      child: Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              const SizedBox(height: UXComponents.paddingM),
              Text('Loading investment insights...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: UXComponents.paddingM),
      child: UXErrorState(
        title: 'Unable to Load Data',
        message: 'We\'re having trouble loading your investment data. Please try again.',
        onRetry: () {
          ref.invalidate(recentMealsProvider);
        },
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Coming Soon!'),
          ],
        ),
        content: Text(
          '$feature is in development and will be available in the next update. Stay tuned for exciting new features!',
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
}