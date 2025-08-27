import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiRecommendationProvider);
    final aiAvailable = ref.watch(aiAvailabilityProvider);
    final usageSummary = ref.watch(aiUsageSummaryProvider);
    final investmentAnalysis = ref.watch(aiInvestmentAnalysisProvider);
    // final shouldTriggerRecommendations = ref.watch(smartRecommendationTriggerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'AI Investment Advisor',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAIInfoDialog(context),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'usage',
                child: ListTile(
                  leading: Icon(Icons.analytics_outlined),
                  title: Text('Usage Statistics'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Recommendation History'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('AI Preferences'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: !aiAvailable
          ? _buildAIUnavailableView(context)
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildMainContent(context, aiState, usageSummary, investmentAnalysis),
              ),
            ),
      floatingActionButton: aiAvailable && !aiState.isLoading
          ? FloatingActionButton.extended(
              onPressed: () => _generateRecommendations(context),
              icon: const Icon(Icons.smart_toy_outlined),
              label: Text(aiState.hasRecommendations ? 'New Recommendations' : 'Get AI Recommendations'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    AIRecommendationState aiState,
    Map<String, dynamic> usageSummary,
    Map<String, dynamic> investmentAnalysis,
  ) {
    return CustomScrollView(
      slivers: [
        // Usage and status header
        SliverToBoxAdapter(
          child: _buildStatusHeader(context, usageSummary),
        ),

        // Investment analysis
        if (investmentAnalysis['hasAnalysis'] == true)
          SliverToBoxAdapter(
            child: _buildInvestmentAnalysis(context, investmentAnalysis),
          ),

        // Craving input section
        SliverToBoxAdapter(
          child: _buildCravingInput(context),
        ),

        // Loading state
        if (aiState.isLoading)
          SliverToBoxAdapter(
            child: AIRecommendationLoading(
              message: _getLoadingMessage(context),
            ),
          ),

        // Error state
        if (aiState.hasError)
          SliverToBoxAdapter(
            child: _buildErrorState(context, aiState.errorMessage!),
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
                      onRestaurantSelected: (restaurant) => _selectRestaurant(context, recommendation.id, restaurant.placeId),
                      onFeedbackSubmitted: (rating, feedback) => _submitFeedback(recommendation.id, rating, feedback),
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
            child: _buildEmptyState(context),
          ),

        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildStatusHeader(BuildContext context, Map<String, dynamic> usageSummary) {
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

  Widget _buildInvestmentAnalysis(BuildContext context, Map<String, dynamic> analysis) {
    final topRec = analysis['topRecommendation'] as Map<String, dynamic>;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Investment Analysis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                topRec['name'],
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildAnalysisChip(
                    context,
                    'Investment: \$${topRec['investmentCost'].toStringAsFixed(2)}',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildAnalysisChip(
                    context,
                    'Value: ${topRec['valueScore']}%',
                    _getValueColor(topRec['valueScore']),
                  ),
                  const SizedBox(width: 8),
                  _buildAnalysisChip(
                    context,
                    'Confidence: ${topRec['confidence']}%',
                    _getConfidenceColor(topRec['confidence']),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                analysis['summary'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCravingInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you craving?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cravingsController,
                decoration: InputDecoration(
                  hintText: 'e.g., "spicy Asian food" or "comfort food"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.restaurant_menu),
                  suffixIcon: _cravingsController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
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
                    icon: Icon(_showAdvancedOptions ? Icons.expand_less : Icons.expand_more),
                    label: const Text('Advanced Options'),
                  ),
                  const Spacer(),
                  if (_cravingsController.text.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _generateRecommendations(context),
                      icon: const Icon(Icons.smart_toy, size: 18),
                      label: const Text('Get Suggestions'),
                    ),
                ],
              ),
              if (_showAdvancedOptions) ...[
                const SizedBox(height: 16),
                _buildAdvancedOptions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferences',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            FilterChip(
              label: const Text('Budget-Friendly'),
              selected: false,
              onSelected: (selected) {},
            ),
            FilterChip(
              label: const Text('Quick Service'),
              selected: false,
              onSelected: (selected) {},
            ),
            FilterChip(
              label: const Text('High Rated'),
              selected: false,
              onSelected: (selected) {},
            ),
            FilterChip(
              label: const Text('New Experience'),
              selected: false,
              onSelected: (selected) {},
            ),
          ],
        ),
      ],
    );
  }

  String _getLoadingMessage(BuildContext context) {
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

  Widget _buildErrorState(BuildContext context, String error) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                _getErrorIcon(error),
                size: 48,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(height: 12),
              Text(
                _getErrorTitle(error),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getErrorDescription(error),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
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
                        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      child: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _generateRecommendations(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.onErrorContainer,
                        foregroundColor: Theme.of(context).colorScheme.errorContainer,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              ),
              if (_isNetworkError(error)) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => context.go('/discover'),
                  icon: const Icon(Icons.explore),
                  label: const Text('Browse Restaurants Instead'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'AI Investment Advisor Ready',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Discover intelligent dining investments tailored to your budget, preferences, and culinary aspirations. Our AI analyzes value propositions to maximize your satisfaction per dollar.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Think of every meal as an investment in your happiness and well-being.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
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
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Start My Investment Journey'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIUnavailableView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 80,
            color: Theme.of(context).colorScheme.error.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'AI Service Unavailable',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'The AI recommendation service is currently unavailable. Please check your API configuration.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/discover'),
            child: const Text('Browse Restaurants Instead'),
          ),
        ],
      ),
    );
  }

  // Actions and helpers
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

  void _selectRestaurant(BuildContext context, String recommendationId, String placeId) {
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
        content: const Text('Thank you for your feedback!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Color _getValueColor(int valueScore) {
    if (valueScore >= 80) return Colors.green;
    if (valueScore >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getConfidenceColor(int confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }

  void _showAIInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Investment Advisor'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How it works:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Analyzes your dining history and preferences'),
              Text('• Considers your budget and location'),
              Text('• Evaluates restaurant quality and value'),
              Text('• Provides investment-minded recommendations'),
              SizedBox(height: 16),
              Text(
                'Privacy & Trust:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Your data stays private and secure'),
              Text('• AI recommendations improve with feedback'),
              Text('• Cost tracking helps manage spending'),
              Text('• Always provides reasoning for transparency'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showBudgetAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Budget Alert'),
        content: const Text(
          'You\'re approaching your daily AI recommendation budget. '
          'Consider reviewing your usage or adjusting your daily limits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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

  // Enhanced error handling methods
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
    final networkKeywords = ['network', 'connection', 'timeout', 'internet', 'offline'];
    final errorLower = error.toLowerCase();
    return networkKeywords.any((keyword) => errorLower.contains(keyword));
  }

  bool _isRateLimitError(String error) {
    final rateLimitKeywords = ['rate limit', 'too many requests', 'quota', 'throttle'];
    final errorLower = error.toLowerCase();
    return rateLimitKeywords.any((keyword) => errorLower.contains(keyword));
  }

  bool _isBudgetError(String error) {
    final budgetKeywords = ['budget', 'limit exceeded', 'daily cost', 'daily limit'];
    final errorLower = error.toLowerCase();
    return budgetKeywords.any((keyword) => errorLower.contains(keyword));
  }

  void _showErrorDetails(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Technical Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(error),
              const SizedBox(height: 16),
              const Text(
                'Troubleshooting:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_isNetworkError(error)) ...[
                const Text('• Check your internet connection'),
                const Text('• Try switching between Wi-Fi and mobile data'),
                const Text('• Wait a few moments and try again'),
              ] else if (_isRateLimitError(error)) ...[
                const Text('• Wait 1-2 minutes before trying again'),
                const Text('• Consider using the browse feature instead'),
                const Text('• The service will resume normal operation shortly'),
              ] else if (_isBudgetError(error)) ...[
                const Text('• More recommendations available tomorrow'),
                const Text('• Use the restaurant browser to explore options'),
                const Text('• Review your recent recommendations'),
              ] else ...[
                const Text('• Try restarting the app'),
                const Text('• Check for app updates'),
                const Text('• Contact support if the issue persists'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!_isBudgetError(error))
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _generateRecommendations(context);
              },
              child: const Text('Try Again'),
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

  // AI Onboarding methods
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to AI Dining Advisor',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Transform every meal into a smart investment decision. Our AI analyzes your preferences, budget, and dining patterns to recommend experiences that maximize your satisfaction and value.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildFeatureList(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Maybe Later'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _generateRecommendations(context);
                    },
                    child: const Text('Get Started'),
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
        'description': 'AI evaluates value, quality, and your personal preferences',
      },
      {
        'icon': Icons.trending_up,
        'title': 'Investment Mindset',
        'description': 'Every recommendation optimizes your dining ROI',
      },
      {
        'icon': Icons.schedule,
        'title': 'Contextual Timing',
        'description': 'Perfect suggestions based on time, location, and mood',
      },
    ];

    return Column(
      children: features.map((feature) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                feature['icon'] as IconData,
                size: 20,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature['title'] as String,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    feature['description'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}