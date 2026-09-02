// @file ai_recommendations_page.dart
// @description AI Recommendations page with investment mindset messaging and
//   trust indicators. Styled using the template design pattern (cream background,
//   custom header row, semi-transparent white cards, GoogleFonts.plusJakartaSans
//   typography, AppTheme design tokens).
// @modified 2026-03-11

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../providers/ai_providers.dart';
import '../widgets/ai_recommendation_components.dart';
import '../widgets/ux_investment_components.dart';

/// AI Recommendations page with investment mindset messaging and trust indicators
class AIRecommendationsPage extends ConsumerStatefulWidget {
  const AIRecommendationsPage({super.key});

  @override
  ConsumerState<AIRecommendationsPage> createState() => _AIRecommendationsPageState();
}

class _AIRecommendationsPageState extends ConsumerState<AIRecommendationsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _cravingsController = TextEditingController();
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimationController.forward();
    _slideAnimationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForFirstTimeUser();
    });
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _cravingsController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiRecommendationProvider);
    final aiAvailable = ref.watch(aiAvailabilityProvider);
    final usageSummary = ref.watch(aiUsageSummaryProvider);
    final investmentAnalysis = ref.watch(aiInvestmentAnalysisProvider);

    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header row (replaces AppBar)
            _buildCustomHeader(),

            // Body content
            Expanded(
              child: !aiAvailable
                  ? _buildAIUnavailableView()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildMainContent(
                            aiState, usageSummary, investmentAnalysis),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: aiAvailable && !aiState.isLoading
          ? FloatingActionButton.extended(
              onPressed: () => _generateRecommendations(context),
              icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
              label: Text(
                aiState.hasRecommendations
                    ? 'New Recommendations'
                    : 'Get AI Recommendations',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppTheme.primaryGreen,
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Custom header (back arrow + centered title + info/menu actions)
  // ---------------------------------------------------------------------------

  Widget _buildCustomHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.brownText),
            onPressed: () => context.pop(),
            tooltip: 'Go back',
          ),

          // Centered title
          Expanded(
            child: Center(
              child: Text(
                'AI Investment Advisor',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brownText,
                ),
              ),
            ),
          ),

          // Info button
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.brownText),
            onPressed: () => _showAIInfoDialog(context),
            tooltip: 'About AI Advisor',
          ),

          // Menu button
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.brownText),
            color: AppTheme.creamBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'usage',
                child: ListTile(
                  leading: const Icon(
                    Icons.analytics_outlined,
                    color: AppTheme.primaryGreen,
                  ),
                  title: Text(
                    'Usage Statistics',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.brownText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: const Icon(
                    Icons.history,
                    color: AppTheme.primaryGreen,
                  ),
                  title: Text(
                    'Recommendation History',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.brownText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: const Icon(
                    Icons.settings,
                    color: AppTheme.primaryGreen,
                  ),
                  title: Text(
                    'AI Preferences',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.brownText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main content (CustomScrollView)
  // ---------------------------------------------------------------------------

  Widget _buildMainContent(
    AIRecommendationState aiState,
    Map<String, dynamic> usageSummary,
    Map<String, dynamic> investmentAnalysis,
  ) {
    return CustomScrollView(
      slivers: [
        // Usage and status header
        SliverToBoxAdapter(
          child: _buildStatusHeader(usageSummary),
        ),

        // Investment analysis
        if (investmentAnalysis['hasAnalysis'] == true)
          SliverToBoxAdapter(
            child: _buildInvestmentAnalysis(investmentAnalysis),
          ),

        // Craving input section
        SliverToBoxAdapter(
          child: _buildCravingInput(),
        ),

        // Loading state
        if (aiState.isLoading)
          SliverToBoxAdapter(
            child: AIRecommendationLoading(
              message: _getLoadingMessage(),
            ),
          ),

        // Error state
        if (aiState.hasError)
          SliverToBoxAdapter(
            child: _buildErrorState(aiState.errorMessage!),
          ),

        // Recommendations list
        if (aiState.hasRecommendations && !aiState.isLoading)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final recommendation = aiState.recommendations[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AIRecommendationCard(
                      recommendation: recommendation,
                      onRestaurantSelected: (restaurant) =>
                          _selectRestaurant(context, recommendation.id,
                              restaurant.placeId),
                      onFeedbackSubmitted: (rating, feedback) =>
                          _submitFeedback(recommendation.id, rating, feedback),
                    ),
                  );
                },
                childCount: aiState.recommendations.length,
              ),
            ),
          ),

        // Empty state
        if (!aiState.hasRecommendations && !aiState.isLoading && !aiState.hasError)
          SliverFillRemaining(
            child: _buildEmptyState(),
          ),

        // Bottom spacing for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Template card helper
  // ---------------------------------------------------------------------------

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
  // Status header
  // ---------------------------------------------------------------------------

  Widget _buildStatusHeader(Map<String, dynamic> usageSummary) {
    final todayCost = usageSummary['todayCost'] ?? 0.0;
    final remainingBudget = usageSummary['remainingBudget'] ?? 5.0;
    final todayRequests = usageSummary['todayRequests'] ?? 0;
    final successRate = usageSummary['successRate'] ?? 1.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          InvestmentMetricsCard(
            title: 'AI Investment Advisor Status',
            metrics: [
              InvestmentMetric(
                label: 'Today\'s AI Investment',
                value: '\$${todayCost.toStringAsFixed(2)}',
                change: remainingBudget > 1.0 ? 'Within Budget' : 'Near Limit',
                isPositive: remainingBudget > 1.0,
                icon: Icons.psychology,
              ),
              InvestmentMetric(
                label: 'Smart Recommendations',
                value: todayRequests.toString(),
                change: '${((successRate * 100).round())}% Success Rate',
                isPositive: successRate > 0.8,
                icon: Icons.auto_awesome,
              ),
            ],
            actionLabel: remainingBudget < 1.0 ? 'Budget Alert' : 'Ready',
            onActionPressed: remainingBudget < 1.0
                ? () => _showBudgetAlert(context)
                : null,
          ),
          const SizedBox(height: 12),
          UXInvestmentGuidance(
            currentCost: todayCost,
            remainingCapacity: remainingBudget,
            guidanceLevel: _getGuidanceLevel(remainingBudget),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Investment analysis card
  // ---------------------------------------------------------------------------

  Widget _buildInvestmentAnalysis(Map<String, dynamic> analysis) {
    final topRec = analysis['topRecommendation'] as Map<String, dynamic>;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Investment Analysis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.brownText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              topRec['name'],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.brownText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildAnalysisChip(
                  'Investment: \$${topRec['investmentCost'].toStringAsFixed(2)}',
                  AppTheme.infoColor,
                ),
                _buildAnalysisChip(
                  'Value: ${topRec['valueScore']}%',
                  _getValueColor(topRec['valueScore']),
                ),
                _buildAnalysisChip(
                  'Confidence: ${topRec['confidence']}%',
                  _getConfidenceColor(topRec['confidence']),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              analysis['summary'],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.brownTextLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Craving input section
  // ---------------------------------------------------------------------------

  Widget _buildCravingInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What are you craving?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.brownText,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cravingsController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.brownText,
              ),
              decoration: InputDecoration(
                hintText: 'e.g., "spicy Asian food" or "comfort food"',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.brownTextLight.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.brownText.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.brownText.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryGreen,
                    width: 2,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.restaurant_menu,
                  color: AppTheme.primaryGreen,
                ),
                suffixIcon: _cravingsController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppTheme.brownTextLight,
                        ),
                        onPressed: () {
                          setState(() {
                            _cravingsController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAdvancedOptions = !_showAdvancedOptions;
                    });
                  },
                  icon: Icon(
                    _showAdvancedOptions
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppTheme.primaryGreen,
                  ),
                  label: Text(
                    'Advanced Options',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                const Spacer(),
                if (_cravingsController.text.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _generateRecommendations(context),
                    icon: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
                    label: Text(
                      'Get Suggestions',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
            if (_showAdvancedOptions) ...[
              const SizedBox(height: 16),
              _buildAdvancedOptions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREFERENCES',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.brownTextLight,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildTemplateFilterChip(
              label: 'Budget-Friendly',
              selected: false,
              onSelected: (selected) {},
            ),
            _buildTemplateFilterChip(
              label: 'Quick Service',
              selected: false,
              onSelected: (selected) {},
            ),
            _buildTemplateFilterChip(
              label: 'High Rated',
              selected: false,
              onSelected: (selected) {},
            ),
            _buildTemplateFilterChip(
              label: 'New Experience',
              selected: false,
              onSelected: (selected) {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplateFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppTheme.brownText,
        ),
      ),
      selected: selected,
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppTheme.primaryGreen : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9999),
      ),
      checkmarkColor: Colors.white,
      onSelected: onSelected,
    );
  }

  // ---------------------------------------------------------------------------
  // Loading message
  // ---------------------------------------------------------------------------

  String _getLoadingMessage() {
    final cravings = _cravingsController.text.trim();
    if (cravings.isNotEmpty) {
      return 'Finding the perfect "$cravings" investment opportunities...';
    }

    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 11) {
      return 'Discovering breakfast investment opportunities...';
    } else if (hour >= 11 && hour < 15) {
      return 'Analyzing lunch value propositions...';
    } else if (hour >= 17 && hour < 22) {
      return 'Evaluating dinner investment potential...';
    }

    return 'Finding your next great dining investment...';
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.errorColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getErrorIcon(error),
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 12),
            Text(
              _getErrorTitle(error),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getErrorDescription(error),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.brownText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showErrorDetails(context, error),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.brownText,
                      side: const BorderSide(color: AppTheme.brownText),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Details',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _generateRecommendations(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isNetworkError(error)) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.go('/discover'),
                icon: const Icon(
                  Icons.explore,
                  color: AppTheme.primaryGreen,
                ),
                label: Text(
                  'Browse Restaurants Instead',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              size: 64,
              color: AppTheme.primaryGreen.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI Investment Advisor Ready',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Discover intelligent dining investments tailored to your budget, preferences, and culinary aspirations. Our AI analyzes value propositions to maximize your satisfaction per dollar.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: AppTheme.brownTextLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Think of every meal as an investment in your happiness and well-being.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppTheme.brownText,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _generateRecommendations(context),
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: Text(
              'Start My Investment Journey',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AI unavailable view
  // ---------------------------------------------------------------------------

  Widget _buildAIUnavailableView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off,
              size: 64,
              color: AppTheme.errorColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI Service Unavailable',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.errorColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'The AI recommendation service is currently unavailable. Please check your API configuration.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: AppTheme.brownTextLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/discover'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Browse Restaurants Instead',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions and helpers
  // ---------------------------------------------------------------------------

  void _handleMenuAction(String action) {
    switch (action) {
      case 'usage':
        _showUsageStatistics(context);
        break;
      case 'history':
        _showRecommendationHistory(context);
        break;
      case 'settings':
        _showAISettings(context);
        break;
    }
  }

  Future<void> _generateRecommendations(BuildContext context) async {
    final generateFunction = ref.read(generateRecommendationsProvider);

    await generateFunction(
      specificCravings: _cravingsController.text.trim().isEmpty
          ? null
          : _cravingsController.text.trim(),
    );
  }

  void _selectRestaurant(
      BuildContext context, String recommendationId, String placeId) {
    // Submit feedback that this restaurant was selected
    ref.read(submitRecommendationFeedbackProvider)(
      recommendationId,
      5, // 5-star rating for selection
      'Selected this recommendation',
      wasSelected: true,
    );

    // Navigate to restaurant details
    context.go('/restaurant/$placeId');
  }

  void _submitFeedback(String recommendationId, int rating, String? feedback) {
    ref.read(submitRecommendationFeedbackProvider)(
      recommendationId,
      rating,
      feedback,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Thank you for your feedback!',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Color _getValueColor(int valueScore) {
    if (valueScore >= 80) return AppTheme.successGreen;
    if (valueScore >= 60) return AppTheme.ctaOrange;
    return AppTheme.errorColor;
  }

  Color _getConfidenceColor(int confidence) {
    if (confidence >= 80) return AppTheme.successGreen;
    if (confidence >= 60) return AppTheme.ctaOrange;
    return AppTheme.errorColor;
  }

  // ---------------------------------------------------------------------------
  // AI info dialog
  // ---------------------------------------------------------------------------

  void _showAIInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.creamBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'AI Investment Advisor',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.brownText,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HOW IT WORKS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brownTextLight,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoBullet('Analyzes your dining history and preferences'),
              _buildInfoBullet('Considers your budget and location'),
              _buildInfoBullet('Evaluates restaurant quality and value'),
              _buildInfoBullet('Provides investment-minded recommendations'),
              const SizedBox(height: 16),
              Text(
                'PRIVACY & TRUST',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brownTextLight,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoBullet('Your data stays private and secure'),
              _buildInfoBullet('AI recommendations improve with feedback'),
              _buildInfoBullet('Cost tracking helps manage spending'),
              _buildInfoBullet('Always provides reasoning for transparency'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
            ),
            child: Text(
              'Got it',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(
              Icons.check_circle_outline,
              size: 14,
              color: AppTheme.successGreen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.brownText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Budget alert dialog
  // ---------------------------------------------------------------------------

  void _showBudgetAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.creamBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Budget Alert',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.brownText,
          ),
        ),
        content: Text(
          'You\'re approaching your daily AI recommendation budget. '
          'Consider reviewing your usage or adjusting your daily limits.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.brownTextLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
            ),
            child: Text(
              'OK',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUsageStatistics(BuildContext context) {
    // Implementation for usage statistics modal
  }

  void _showRecommendationHistory(BuildContext context) {
    // Implementation for recommendation history modal
  }

  void _showAISettings(BuildContext context) {
    // Implementation for AI settings modal
  }

  // ---------------------------------------------------------------------------
  // Enhanced error handling methods
  // ---------------------------------------------------------------------------

  IconData _getErrorIcon(String error) {
    if (_isNetworkError(error)) return Icons.wifi_off;
    if (_isRateLimitError(error)) return Icons.hourglass_empty;
    if (_isBudgetError(error)) return Icons.account_balance_wallet;
    return Icons.error_outline;
  }

  String _getErrorTitle(String error) {
    if (_isNetworkError(error)) return 'Connection Issue';
    if (_isRateLimitError(error)) return 'Service Temporarily Busy';
    if (_isBudgetError(error)) return 'Daily Limit Reached';
    return 'Unable to Generate Recommendations';
  }

  String _getErrorDescription(String error) {
    if (_isNetworkError(error)) {
      return 'We\'re having trouble connecting to our AI service. Please check your internet connection and try again.';
    }
    if (_isRateLimitError(error)) {
      return 'Our AI service is currently experiencing high demand. Please wait a moment and try again.';
    }
    if (_isBudgetError(error)) {
      return 'You\'ve reached your daily recommendation limit. More recommendations will be available tomorrow.';
    }
    return 'Something went wrong while generating your recommendations. Don\'t worry, we\'ll help you find great restaurants!';
  }

  bool _isNetworkError(String error) {
    final networkKeywords = [
      'network',
      'connection',
      'timeout',
      'internet',
      'offline'
    ];
    final errorLower = error.toLowerCase();
    return networkKeywords.any((keyword) => errorLower.contains(keyword));
  }

  bool _isRateLimitError(String error) {
    final rateLimitKeywords = [
      'rate limit',
      'too many requests',
      'quota',
      'throttle'
    ];
    final errorLower = error.toLowerCase();
    return rateLimitKeywords.any((keyword) => errorLower.contains(keyword));
  }

  bool _isBudgetError(String error) {
    final budgetKeywords = [
      'budget',
      'limit exceeded',
      'daily cost',
      'daily limit'
    ];
    final errorLower = error.toLowerCase();
    return budgetKeywords.any((keyword) => errorLower.contains(keyword));
  }

  // ---------------------------------------------------------------------------
  // Error details dialog
  // ---------------------------------------------------------------------------

  void _showErrorDetails(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.creamBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Error Details',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.brownText,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TECHNICAL DETAILS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brownTextLight,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.brownText,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'TROUBLESHOOTING',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brownTextLight,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              if (_isNetworkError(error)) ...[
                _buildInfoBullet('Check your internet connection'),
                _buildInfoBullet(
                    'Try switching between Wi-Fi and mobile data'),
                _buildInfoBullet('Wait a few moments and try again'),
              ] else if (_isRateLimitError(error)) ...[
                _buildInfoBullet(
                    'Wait 1-2 minutes before trying again'),
                _buildInfoBullet(
                    'Consider using the browse feature instead'),
                _buildInfoBullet(
                    'The service will resume normal operation shortly'),
              ] else if (_isBudgetError(error)) ...[
                _buildInfoBullet(
                    'More recommendations available tomorrow'),
                _buildInfoBullet(
                    'Use the restaurant browser to explore options'),
                _buildInfoBullet('Review your recent recommendations'),
              ] else ...[
                _buildInfoBullet('Try restarting the app'),
                _buildInfoBullet('Check for app updates'),
                _buildInfoBullet(
                    'Contact support if the issue persists'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.brownText,
            ),
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!_isBudgetError(error))
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _generateRecommendations(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getGuidanceLevel(double remainingBudget) {
    if (remainingBudget > 3.0) return 'excellent';
    if (remainingBudget > 1.0) return 'good';
    if (remainingBudget > 0.5) return 'moderate';
    return 'high';
  }

  // ---------------------------------------------------------------------------
  // AI Onboarding methods
  // ---------------------------------------------------------------------------

  Future<void> _checkForFirstTimeUser() async {
    // Check if this is the user's first time using AI recommendations
    // In a real app, this would use SharedPreferences or similar
    final aiState = ref.read(aiRecommendationProvider);
    if (aiState.recommendations.isEmpty && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showAIOnboarding();
      }
    }
  }

  void _showAIOnboarding() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildOnboardingDialog(),
    );
  }

  Widget _buildOnboardingDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppTheme.creamBg,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 32,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome to AI Dining Advisor',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.brownText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Transform every meal into a smart investment decision. Our AI analyzes your preferences, budget, and dining patterns to recommend experiences that maximize your satisfaction and value.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: AppTheme.brownTextLight,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildFeatureList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.brownText,
                      side: const BorderSide(color: AppTheme.brownText),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _generateRecommendations(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      {
        'icon': Icons.psychology,
        'title': 'Smart Analysis',
        'description':
            'AI evaluates value, quality, and your personal preferences',
      },
      {
        'icon': Icons.trending_up,
        'title': 'Investment Mindset',
        'description': 'Every recommendation optimizes your dining ROI',
      },
      {
        'icon': Icons.schedule,
        'title': 'Contextual Timing',
        'description':
            'Perfect suggestions based on time, location, and mood',
      },
    ];

    return Column(
      children: features
          .map((feature) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.brownText.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        size: 20,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['title'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.brownText,
                            ),
                          ),
                          Text(
                            feature['description'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.brownTextLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
