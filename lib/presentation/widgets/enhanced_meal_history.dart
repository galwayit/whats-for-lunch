import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/meal.dart';
import 'ux_components.dart';

/// Enhanced meal history timeline with smooth animations and rich visual design
/// Follows UX advisor requirements for engagement and investment psychology
class EnhancedMealHistory extends StatefulWidget {
  final List<Meal> meals;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRefresh;
  final ValueChanged<Meal>? onMealTap;
  final String timeframe;

  const EnhancedMealHistory({
    super.key,
    required this.meals,
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
    this.onMealTap,
    this.timeframe = 'week',
  });

  @override
  State<EnhancedMealHistory> createState() => _EnhancedMealHistoryState();
}

class _EnhancedMealHistoryState extends State<EnhancedMealHistory>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerFadeAnimation;
  
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingHeader = false;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    ));

    _scrollController.addListener(_onScroll);
    
    // Start animation when widget loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _headerAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const threshold = 100.0;
    if (_scrollController.offset > threshold && !_showFloatingHeader) {
      setState(() {
        _showFloatingHeader = true;
      });
      _headerAnimationController.forward();
    } else if (_scrollController.offset <= threshold && _showFloatingHeader) {
      setState(() {
        _showFloatingHeader = false;
      });
      _headerAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.errorMessage != null) {
      return _buildErrorState();
    }

    if (widget.meals.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.lightImpact();
            widget.onRefresh?.call();
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Main header
              SliverToBoxAdapter(
                child: _buildTimelineHeader(),
              ),
              
              // Meal timeline
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildAnimatedMealCard(
                    widget.meals[index],
                    index,
                  ),
                  childCount: widget.meals.length,
                ),
              ),
              
              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
        
        // Floating header
        if (_showFloatingHeader)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _headerFadeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -50 * (1 - _headerFadeAnimation.value)),
                  child: Opacity(
                    opacity: _headerFadeAnimation.value,
                    child: _buildFloatingHeader(),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTimelineHeader() {
    final theme = Theme.of(context);
    final totalSpent = widget.meals.fold<double>(0.0, (sum, meal) => sum + meal.cost);
    final avgCost = widget.meals.isNotEmpty ? totalSpent / widget.meals.length : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(UXComponents.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(UXComponents.paddingM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.timeline,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: UXComponents.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investment Journey',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${widget.meals.length} experiences this ${widget.timeframe}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: UXComponents.paddingL),
          
          // Investment summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Investment',
                  '\$${totalSpent.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
              const SizedBox(width: UXComponents.paddingM),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Average Experience',
                  '\$${avgCost.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingHeader() {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: UXComponents.paddingM,
        right: UXComponents.paddingM,
        bottom: UXComponents.paddingS,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timeline,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: UXComponents.paddingS),
          Text(
            'Investment Journey',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: UXComponents.paddingS,
              vertical: UXComponents.paddingXS,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.meals.length} experiences',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(UXComponents.paddingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(UXComponents.paddingXS),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                color: color,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: UXComponents.paddingS),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedMealCard(Meal meal, int index) {
    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        final animationOffset = (index * 0.1).clamp(0.0, 1.0);
        final animation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _listAnimationController,
          curve: Interval(
            animationOffset,
            (animationOffset + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ));

        return Transform.translate(
          offset: Offset(50 * (1 - animation.value), 0),
          child: Opacity(
            opacity: animation.value,
            child: Padding(
              padding: EdgeInsets.only(
                left: UXComponents.paddingL,
                right: UXComponents.paddingL,
                bottom: UXComponents.paddingM,
              ),
              child: _buildEnhancedMealCard(meal, index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedMealCard(Meal meal, int index) {
    final theme = Theme.of(context);
    final isEvenIndex = index % 2 == 0;
    
    return Semantics(
      button: true,
      label: 'Meal at ${meal.restaurantName} costing \$${meal.cost.toStringAsFixed(2)}',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onMealTap?.call(meal);
        },
        child: Row(
          children: [
            // Timeline indicator
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Container(
                    width: 3,
                    height: 20,
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getMealTypeColor(meal.mealType),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getMealTypeColor(meal.mealType).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 20,
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            
            // Meal card
            Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  left: isEvenIndex ? UXComponents.paddingM : UXComponents.paddingXL,
                  right: isEvenIndex ? UXComponents.paddingXL : UXComponents.paddingM,
                ),
                child: Card(
                  elevation: isEvenIndex ? 2 : 4,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.surface,
                          _getMealTypeColor(meal.mealType).withOpacity(0.05),
                        ],
                        begin: isEvenIndex ? Alignment.topLeft : Alignment.topRight,
                        end: isEvenIndex ? Alignment.bottomRight : Alignment.bottomLeft,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(UXComponents.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Row(
                            children: [
                              // Meal type icon
                              Container(
                                padding: const EdgeInsets.all(UXComponents.paddingS),
                                decoration: BoxDecoration(
                                  color: _getMealTypeColor(meal.mealType).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getMealTypeIcon(meal.mealType),
                                  color: _getMealTypeColor(meal.mealType),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: UXComponents.paddingM),
                              
                              // Restaurant info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      meal.restaurantName ?? meal.displayMealType,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _getMealTypeName(meal.mealType),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: _getMealTypeColor(meal.mealType),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Cost and time
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: UXComponents.paddingS,
                                      vertical: UXComponents.paddingXS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '\$${meal.cost.toStringAsFixed(2)}',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatMealTime(meal.date),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          // Notes if available
                          if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                            const SizedBox(height: UXComponents.paddingM),
                            Container(
                              padding: const EdgeInsets.all(UXComponents.paddingS),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.note_alt_outlined,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: UXComponents.paddingS),
                                  Expanded(
                                    child: Text(
                                      meal.notes!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // Investment insight
                          const SizedBox(height: UXComponents.paddingS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: UXComponents.paddingS,
                              vertical: UXComponents.paddingXS,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.psychology,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: UXComponents.paddingXS),
                                Expanded(
                                  child: Text(
                                    _getInvestmentInsight(meal),
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
                  ),
                ),
              ),
            ),
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
          Text('Loading your investment journey...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return UXErrorState(
      title: 'Unable to Load History',
      message: widget.errorMessage!,
      onRetry: widget.onRefresh,
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(UXComponents.paddingXL),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.timeline,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: UXComponents.paddingL),
            Text(
              'Your Journey Begins',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UXComponents.paddingM),
            Text(
              'Start logging your dining experiences to see your investment journey unfold here.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UXComponents.paddingXL),
            UXPrimaryButton(
              onPressed: widget.onRefresh,
              text: 'Log Your First Experience',
              icon: Icons.restaurant_menu,
            ),
          ],
        ),
      ),
    );
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

  String _formatMealTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  String _getInvestmentInsight(Meal meal) {
    final insights = [
      'Investment in happiness',
      'Nourishing your well-being',
      'Experience over expense',
      'Fueling your day',
      'Worth every penny',
      'Quality time investment',
      'Self-care moment',
      'Building memories',
    ];
    
    // Use meal cost to generate consistent insight for same meal
    final index = (meal.cost * 10).round() % insights.length;
    return insights[index];
  }
}

/// Meal filter chips for filtering the timeline
class MealTimelineFilters extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final List<String> availableFilters;

  const MealTimelineFilters({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.availableFilters = const ['all', 'today', 'week', 'month'],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: UXComponents.paddingM),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: availableFilters.length,
        itemBuilder: (context, index) {
          final filter = availableFilters[index];
          final isSelected = filter == selectedFilter;
          
          return Padding(
            padding: EdgeInsets.only(
              right: index < availableFilters.length - 1 ? UXComponents.paddingS : 0,
            ),
            child: FilterChip(
              label: Text(_getFilterDisplayName(filter)),
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.lightImpact();
                onFilterChanged(filter);
              },
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'all':
        return 'All Time';
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      default:
        return filter;
    }
  }
}