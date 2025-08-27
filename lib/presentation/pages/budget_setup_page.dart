import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../providers/budget_providers.dart';
import '../providers/user_preferences_provider.dart';
import '../widgets/ux_components.dart';
import '../widgets/ux_investment_components.dart';

/// 3-step budget setup page following UX advisor requirements
/// Target: Sub-30-second completion with positive psychology messaging
class BudgetSetupPage extends ConsumerStatefulWidget {
  const BudgetSetupPage({super.key});

  @override
  ConsumerState<BudgetSetupPage> createState() => _BudgetSetupPageState();
}

class _BudgetSetupPageState extends ConsumerState<BudgetSetupPage> {
  late PageController _pageController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(budgetSetupProvider);
    
    return Scaffold(
      appBar: _buildAppBar(context, setupState),
      body: Column(
        children: [
          // Progress indicator
          UXProgressIndicator(
            currentStep: setupState.currentStep,
            totalSteps: 3,
            semanticLabel: 'Budget setup progress',
          ),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Prevent manual swiping
              children: [
                _buildInvestmentGoalsStep(context, setupState),
                _buildExperiencePreferencesStep(context, setupState),
                _buildCelebrationSetupStep(context, setupState),
              ],
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(context, setupState),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, BudgetSetupState setupState) {
    return AppBar(
      title: const Text(
        'Investment Setup',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      leading: setupState.currentStep > 0 
        ? IconButton(
            onPressed: () {
              _previousStep();
            },
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Previous step',
          )
        : IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Cancel setup',
          ),
    );
  }

  Widget _buildInvestmentGoalsStep(BuildContext context, BudgetSetupState setupState) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UXComponents.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with positive messaging
          UXFadeIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.psychology,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: UXComponents.paddingM),
                Text(
                  'Investment Goals',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: UXComponents.paddingS),
                Text(
                  'Think of dining as an investment in your happiness and well-being. How much would you like to invest each week?',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: UXComponents.paddingXL),
          
          // Investment capacity selector
          UXFadeIn(
            delay: const Duration(milliseconds: 200),
            child: UXInvestmentCapacitySelector(
              selectedCapacity: setupState.weeklyCapacity,
              onChanged: (capacity) {
                ref.read(budgetSetupProvider.notifier).updateWeeklyCapacity(capacity);
                HapticFeedback.lightImpact();
              },
            ),
          ),
          const SizedBox(height: UXComponents.paddingXL),
          
          // Investment tips
          UXFadeIn(
            delay: const Duration(milliseconds: 400),
            child: _buildInvestmentTips(context),
          ),
        ],
      ),
    );
  }

  Widget _buildExperiencePreferencesStep(BuildContext context, BudgetSetupState setupState) {
    final theme = Theme.of(context);
    final experienceTypes = [
      'Fine Dining',
      'Casual Dining',
      'Fast Casual',
      'Delivery',
      'Takeout',
      'Coffee Shops',
      'Food Trucks',
      'Home Cooking',
    ];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UXComponents.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          UXFadeIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.explore,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: UXComponents.paddingM),
                Text(
                  'Experience Preferences',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: UXComponents.paddingS),
                Text(
                  'What types of dining experiences do you enjoy? This helps us provide better investment guidance.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: UXComponents.paddingXL),
          
          // Experience type selection
          UXFadeIn(
            delay: const Duration(milliseconds: 200),
            child: Wrap(
              spacing: UXComponents.paddingS,
              runSpacing: UXComponents.paddingS,
              children: experienceTypes.map((type) => 
                _buildExperienceChip(context, type, setupState.experiencePreferences)
              ).toList(),
            ),
          ),
          const SizedBox(height: UXComponents.paddingXL),
          
          // Selection guidance
          if (setupState.experiencePreferences.isNotEmpty)
            UXFadeIn(
              delay: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.all(UXComponents.paddingM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primaryContainer,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: UXComponents.paddingS),
                    Expanded(
                      child: Text(
                        'Great choices! We\'ll tailor investment guidance to your preferences.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCelebrationSetupStep(BuildContext context, BudgetSetupState setupState) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(UXComponents.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          UXFadeIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.celebration,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: UXComponents.paddingM),
                Text(
                  'Celebration Setup',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: UXComponents.paddingS),
                Text(
                  'Let\'s set up how you\'d like to celebrate your investment achievements and milestones.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: UXComponents.paddingXL),
          
          // Achievement celebration toggle
          UXFadeIn(
            delay: const Duration(milliseconds: 200),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(UXComponents.paddingL),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(UXComponents.paddingS),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: UXComponents.paddingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Achievement Celebrations',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Get notifications and celebrations when you reach investment milestones',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: setupState.celebrateAchievements,
                          onChanged: (value) {
                            ref.read(budgetSetupProvider.notifier).toggleCelebrations(value);
                            HapticFeedback.lightImpact();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: UXComponents.paddingL),
          
          // Setup summary
          UXFadeIn(
            delay: const Duration(milliseconds: 400),
            child: _buildSetupSummary(context, setupState),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentTips(BuildContext context) {
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
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: UXComponents.paddingS),
                Text(
                  'Investment Tips',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UXComponents.paddingM),
            _buildTipItem(
              context,
              Icons.psychology,
              'Mindset Matters',
              'Think of dining as an investment in experiences, not just expenses.',
            ),
            _buildTipItem(
              context,
              Icons.balance,
              'Balance is Key',
              'Aim for 70-80% capacity usage for optimal balance.',
            ),
            _buildTipItem(
              context,
              Icons.trending_up,
              'Track Progress',
              'Regular tracking leads to better investment decisions.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceChip(BuildContext context, String type, List<String> selected) {
    final theme = Theme.of(context);
    final isSelected = selected.contains(type);
    
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Experience type $type',
      child: FilterChip(
        label: Text(type),
        selected: isSelected,
        onSelected: (selected) {
          HapticFeedback.lightImpact();
          final notifier = ref.read(budgetSetupProvider.notifier);
          final currentPreferences = List<String>.from(
            ref.read(budgetSetupProvider).experiencePreferences
          );
          
          if (selected) {
            currentPreferences.add(type);
          } else {
            currentPreferences.remove(type);
          }
          
          notifier.updateExperiencePreferences(currentPreferences);
        },
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        selectedColor: theme.colorScheme.primaryContainer,
        checkmarkColor: theme.colorScheme.onPrimaryContainer,
        labelStyle: TextStyle(
          color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSetupSummary(BuildContext context, BudgetSetupState setupState) {
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
                  Icons.summarize,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: UXComponents.paddingS),
                Text(
                  'Setup Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UXComponents.paddingM),
            _buildSummaryItem(
              context,
              'Weekly Investment Capacity',
              '\$${setupState.weeklyCapacity.toStringAsFixed(0)}',
              Icons.account_balance_wallet,
            ),
            _buildSummaryItem(
              context,
              'Experience Preferences',
              '${setupState.experiencePreferences.length} selected',
              Icons.restaurant,
            ),
            _buildSummaryItem(
              context,
              'Achievement Celebrations',
              setupState.celebrateAchievements ? 'Enabled' : 'Disabled',
              Icons.celebration,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: UXComponents.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: UXComponents.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
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

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: UXComponents.paddingS),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: UXComponents.paddingS),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, BudgetSetupState setupState) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(UXComponents.paddingL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (setupState.currentStep > 0)
              Expanded(
                child: UXSecondaryButton(
                  onPressed: _previousStep,
                  text: 'Previous',
                  icon: Icons.arrow_back,
                ),
              ),
            if (setupState.currentStep > 0)
              const SizedBox(width: UXComponents.paddingM),
            Expanded(
              flex: 2,
              child: UXPrimaryButton(
                onPressed: setupState.canProceed && !_isSubmitting
                  ? (setupState.currentStep < 2 ? _nextStep : _completeSetup)
                  : null,
                text: setupState.currentStep < 2 ? 'Continue' : 'Complete Setup',
                icon: setupState.currentStep < 2 ? Icons.arrow_forward : Icons.check,
                isLoading: _isSubmitting,
                semanticLabel: setupState.currentStep < 2 
                  ? 'Continue to next step'
                  : 'Complete investment setup',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    final notifier = ref.read(budgetSetupProvider.notifier);
    notifier.nextStep();
    
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    HapticFeedback.lightImpact();
  }

  void _previousStep() {
    final notifier = ref.read(budgetSetupProvider.notifier);
    notifier.previousStep();
    
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    HapticFeedback.lightImpact();
  }

  Future<void> _completeSetup() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final setupState = ref.read(budgetSetupProvider);
      final userPreferencesNotifier = ref.read(userPreferencesProvider.notifier);
      
      // Update user preferences with budget setup
      await userPreferencesNotifier.updateWeeklyBudget(setupState.weeklyCapacity);
      
      // Mark setup as completed
      ref.read(budgetSetupProvider.notifier).completeSetup();
      
      // Show success feedback
      HapticFeedback.heavyImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: UXComponents.paddingS),
                const Expanded(
                  child: Text(
                    'Investment setup complete! Start tracking your experiences.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to track page
        context.go(AppRoutes.track);
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}