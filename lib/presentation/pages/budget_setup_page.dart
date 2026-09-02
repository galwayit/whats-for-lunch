// @file budget_setup_page.dart
// @description 3-step budget setup page following the template design pattern.
//   Styled with cream background, green primary, brown text, and card-based
//   layouts. Retains all existing business logic, state management, providers,
//   and navigation.
// @modified 2026-03-11

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../providers/budget_providers.dart';
import '../providers/simple_providers.dart' as simple;
import '../widgets/ux_investment_components.dart';

/// 3-step budget setup page following the template design pattern.
/// Target: Sub-30-second completion with positive psychology messaging.
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(budgetSetupProvider);

    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header row (replaces AppBar)
            _buildCustomHeader(context, setupState),

            // Step progress bar
            _buildProgressBar(setupState),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Custom header (back/close arrow + centered title)
  // ---------------------------------------------------------------------------

  Widget _buildCustomHeader(
      BuildContext context, BudgetSetupState setupState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        children: [
          // Back or close button
          IconButton(
            icon: Icon(
              setupState.currentStep > 0 ? Icons.arrow_back : Icons.close,
              color: AppTheme.brownText,
            ),
            onPressed: setupState.currentStep > 0
                ? _previousStep
                : () => context.pop(),
            tooltip: setupState.currentStep > 0
                ? 'Previous step'
                : 'Cancel setup',
          ),
          // Centered title
          Expanded(
            child: Center(
              child: Text(
                'Investment Setup',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brownText,
                ),
              ),
            ),
          ),
          // Placeholder to balance the row width
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Custom progress bar (STEP X OF 3 label + rounded bar)
  // ---------------------------------------------------------------------------

  Widget _buildProgressBar(BudgetSetupState setupState) {
    final step = setupState.currentStep + 1;
    final progress = step / 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step label
          Text(
            'STEP $step OF 3',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.brownTextLight,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          // Bar track
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable card container matching the template pattern
  // ---------------------------------------------------------------------------

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.brownText.withValues(alpha: 0.05),
        ),
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 - Investment Goals
  // ---------------------------------------------------------------------------

  Widget _buildInvestmentGoalsStep(
      BuildContext context, BudgetSetupState setupState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon + title + description
          _buildStepHeader(
            icon: Icons.psychology,
            title: 'Investment Goals',
            description:
                'Think of dining as an investment in your happiness and well-being. '
                'How much would you like to invest each week?',
          ),
          const SizedBox(height: 28),

          // Investment capacity selector (kept from ux_investment_components)
          UXInvestmentCapacitySelector(
            selectedCapacity: setupState.weeklyCapacity,
            onChanged: (capacity) {
              ref
                  .read(budgetSetupProvider.notifier)
                  .updateWeeklyCapacity(capacity);
              HapticFeedback.lightImpact();
            },
          ),
          const SizedBox(height: 28),

          // Investment tips card
          _buildInvestmentTips(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 - Experience Preferences
  // ---------------------------------------------------------------------------

  Widget _buildExperiencePreferencesStep(
      BuildContext context, BudgetSetupState setupState) {
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildStepHeader(
            icon: Icons.explore,
            title: 'Experience Preferences',
            description:
                'What types of dining experiences do you enjoy? '
                'This helps us provide better investment guidance.',
          ),
          const SizedBox(height: 28),

          // Experience type chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: experienceTypes
                .map((type) => _buildExperienceChip(
                      context,
                      type,
                      setupState.experiencePreferences,
                    ))
                .toList(),
          ),
          const SizedBox(height: 28),

          // Selection guidance banner
          if (setupState.experiencePreferences.isNotEmpty)
            _buildCard(
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Great choices! We\'ll tailor investment guidance to your preferences.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3 - Celebration Setup
  // ---------------------------------------------------------------------------

  Widget _buildCelebrationSetupStep(
      BuildContext context, BudgetSetupState setupState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildStepHeader(
            icon: Icons.celebration,
            title: 'Celebration Setup',
            description:
                'Let\'s set up how you\'d like to celebrate your investment '
                'achievements and milestones.',
          ),
          const SizedBox(height: 28),

          // Achievement celebration toggle card
          _buildCard(
            child: Row(
              children: [
                // Icon in circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.ctaOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppTheme.ctaOrange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievement Celebrations',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.brownText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Get notifications and celebrations when you reach investment milestones',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.brownTextLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: setupState.celebrateAchievements,
                  activeThumbColor: AppTheme.primaryGreen,
                  activeTrackColor:
                      AppTheme.primaryGreen.withValues(alpha: 0.3),
                  onChanged: (value) {
                    ref
                        .read(budgetSetupProvider.notifier)
                        .toggleCelebrations(value);
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Setup summary card
          _buildSetupSummary(context, setupState),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable step header: green icon container + title + description
  // ---------------------------------------------------------------------------

  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon in rounded container
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 28, color: AppTheme.primaryGreen),
        ),
        const SizedBox(height: 16),
        // Title
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.brownText,
          ),
        ),
        const SizedBox(height: 8),
        // Description
        Text(
          description,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppTheme.brownTextLight,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Investment tips card (step 1)
  // ---------------------------------------------------------------------------

  Widget _buildInvestmentTips() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Text(
            'INVESTMENT TIPS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.brownTextLight,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            Icons.psychology,
            'Mindset Matters',
            'Think of dining as an investment in experiences, not just expenses.',
          ),
          _buildTipItem(
            Icons.balance,
            'Balance is Key',
            'Aim for 70-80% capacity usage for optimal balance.',
          ),
          _buildTipItem(
            Icons.trending_up,
            'Track Progress',
            'Regular tracking leads to better investment decisions.',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Single tip row
  // ---------------------------------------------------------------------------

  Widget _buildTipItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brownText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.brownTextLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Experience chip (step 2)
  // ---------------------------------------------------------------------------

  Widget _buildExperienceChip(
      BuildContext context, String type, List<String> selected) {
    final isSelected = selected.contains(type);

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Experience type $type',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          final notifier = ref.read(budgetSetupProvider.notifier);
          final currentPreferences = List<String>.from(
            ref.read(budgetSetupProvider).experiencePreferences,
          );

          if (isSelected) {
            currentPreferences.remove(type);
          } else {
            currentPreferences.add(type);
          }

          notifier.updateExperiencePreferences(currentPreferences);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryGreen
                  : AppTheme.brownText.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, size: 16, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(
                type,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.brownText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Setup summary card (step 3)
  // ---------------------------------------------------------------------------

  Widget _buildSetupSummary(
      BuildContext context, BudgetSetupState setupState) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Text(
            'SETUP SUMMARY',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.brownTextLight,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(
            'Weekly Investment Capacity',
            '\$${setupState.weeklyCapacity.toStringAsFixed(0)}',
            Icons.account_balance_wallet,
          ),
          _buildSummaryItem(
            'Experience Preferences',
            '${setupState.experiencePreferences.length} selected',
            Icons.restaurant,
          ),
          _buildSummaryItem(
            'Achievement Celebrations',
            setupState.celebrateAchievements ? 'Enabled' : 'Disabled',
            Icons.celebration,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Single summary row
  // ---------------------------------------------------------------------------

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.brownText,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom navigation buttons (Previous / Continue / Complete)
  // ---------------------------------------------------------------------------

  Widget _buildNavigationButtons(
      BuildContext context, BudgetSetupState setupState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        border: Border(
          top: BorderSide(
            color: AppTheme.brownText.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous button (secondary style)
            if (setupState.currentStep > 0)
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextButton.icon(
                    onPressed: _previousStep,
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: AppTheme.primaryGreen,
                    ),
                    label: Text(
                      'Previous',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),
            if (setupState.currentStep > 0) const SizedBox(width: 12),

            // Continue / Complete button (primary style)
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: setupState.canProceed && !_isSubmitting
                      ? (setupState.currentStep < 2
                          ? _nextStep
                          : _completeSetup)
                      : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          setupState.currentStep < 2
                              ? Icons.arrow_forward
                              : Icons.check,
                          size: 18,
                        ),
                  label: Text(
                    setupState.currentStep < 2 ? 'Continue' : 'Complete Setup',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppTheme.primaryGreen.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor:
                        AppTheme.primaryGreen.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers (business logic unchanged)
  // ---------------------------------------------------------------------------

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

      // Update the unified preferences provider (in-memory + DB persistence)
      await ref
          .read(simple.userPreferencesProvider.notifier)
          .updateWeeklyBudget(setupState.weeklyCapacity);

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
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Investment setup complete! Start tracking your experiences.',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
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
            content: Text(
              'Setup failed: ${e.toString()}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppTheme.errorColor,
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
