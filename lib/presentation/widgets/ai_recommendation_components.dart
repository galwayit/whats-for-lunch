import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/entities/ai_recommendation.dart';
import '../../domain/entities/restaurant.dart';

/// AI recommendation card with trust indicators and investment mindset messaging
class AIRecommendationCard extends StatefulWidget {
  final AIRecommendation recommendation;
  final Function(Restaurant) onRestaurantSelected;
  final Function(int rating, String? feedback) onFeedbackSubmitted;

  const AIRecommendationCard({
    super.key,
    required this.recommendation,
    required this.onRestaurantSelected,
    required this.onFeedbackSubmitted,
  });

  @override
  State<AIRecommendationCard> createState() => _AIRecommendationCardState();
}

class _AIRecommendationCardState extends State<AIRecommendationCard>
    with TickerProviderStateMixin {
  late AnimationController _expandAnimationController;
  late Animation<double> _expandAnimation;
  
  bool _isExpanded = false;
  bool _showReasoningDetails = false;
  int? _userRating;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    _expandAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _expandAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandAnimationController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          if (widget.recommendation.recommendedRestaurants.isNotEmpty)
            _buildPrimaryRecommendation(context),
          _buildTrustIndicators(context),
          _buildInvestmentInsights(context),
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) => SizeTransition(
              sizeFactor: _expandAnimation,
              child: child,
            ),
            child: _isExpanded ? _buildExpandedContent(context) : null,
          ),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.smart_toy,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Investment Recommendations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildConfidenceIndicator(context),
                    const SizedBox(width: 12),
                    Text(
                      _formatTimeStamp(widget.recommendation.generatedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            onPressed: _toggleExpanded,
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(BuildContext context) {
    final confidence = widget.recommendation.overallConfidence;
    final color = _getConfidenceColor(confidence);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${(confidence * 100).round()}% Confidence',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryRecommendation(BuildContext context) {
    final restaurant = widget.recommendation.recommendedRestaurants.first;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        child: InkWell(
          onTap: () => widget.onRestaurantSelected(restaurant),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                            restaurant.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (restaurant.address != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              restaurant.address!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (restaurant.photoReference != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: 'https://via.placeholder.com/80x60', // Placeholder
                          width: 80,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 80,
                            height: 60,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: const Icon(Icons.restaurant),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 80,
                            height: 60,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: const Icon(Icons.restaurant),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRestaurantMetrics(context, restaurant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantMetrics(BuildContext context, Restaurant restaurant) {
    return Row(
      children: [
        _buildMetricChip(
          context,
          Icons.attach_money,
          '\$${restaurant.averageMealCost?.toStringAsFixed(0) ?? '20'}',
          'Investment',
          Colors.green,
        ),
        const SizedBox(width: 8),
        if (restaurant.rating != null)
          _buildMetricChip(
            context,
            Icons.star,
            restaurant.rating!.toStringAsFixed(1),
            'Rating',
            Colors.orange,
          ),
        const SizedBox(width: 8),
        if (restaurant.valueScore != null)
          _buildMetricChip(
            context,
            Icons.trending_up,
            '${(restaurant.valueScore! * 100).round()}%',
            'Value',
            _getValueColor(restaurant.valueScore!),
          ),
      ],
    );
  }

  Widget _buildMetricChip(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustIndicators(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Reasoning',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showReasoningDetails = !_showReasoningDetails;
                  });
                },
                child: Text(_showReasoningDetails ? 'Show Less' : 'Show Details'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _showReasoningDetails 
                ? widget.recommendation.reasoning
                : _truncateReasoning(widget.recommendation.reasoning),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentInsights(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  size: 18,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Investment Insights',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.recommendation.investmentSummary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            _buildFactorWeights(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorWeights(BuildContext context) {
    final factors = widget.recommendation.topInfluencingFactors;
    
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: factors.map((factor) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            factor,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.recommendation.recommendedRestaurants.length > 1) ...[
            Text(
              'Alternative Options',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.recommendation.recommendedRestaurants.skip(1).map(
              (restaurant) => _buildAlternativeRestaurant(context, restaurant),
            ),
            const SizedBox(height: 16),
          ],
          _buildFeedbackSection(context),
        ],
      ),
    );
  }

  Widget _buildAlternativeRestaurant(BuildContext context, Restaurant restaurant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            Icons.restaurant,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(restaurant.name),
        subtitle: Text(
          '\$${restaurant.averageMealCost?.toStringAsFixed(0) ?? '20'} • '
          '${restaurant.rating?.toStringAsFixed(1) ?? 'N/A'}★',
        ),
        onTap: () => widget.onRestaurantSelected(restaurant),
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rate this recommendation',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            return IconButton(
              icon: Icon(
                starIndex <= (_userRating ?? 0) 
                    ? Icons.star
                    : Icons.star_border,
                color: starIndex <= (_userRating ?? 0)
                    ? Colors.amber
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              onPressed: () {
                setState(() {
                  _userRating = starIndex;
                });
              },
            );
          }),
        ),
        TextField(
          controller: _feedbackController,
          decoration: const InputDecoration(
            hintText: 'Optional: Share your thoughts on this recommendation',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _userRating != null
              ? () => _submitFeedback()
              : null,
          child: const Text('Submit Feedback'),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _toggleExpanded,
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              label: Text(_isExpanded ? 'Show Less' : 'See Details'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.recommendation.recommendedRestaurants.isNotEmpty
                  ? () => widget.onRestaurantSelected(
                        widget.recommendation.recommendedRestaurants.first,
                      )
                  : null,
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('View Restaurant'),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandAnimationController.forward();
      } else {
        _expandAnimationController.reverse();
      }
    });
  }

  void _submitFeedback() {
    if (_userRating != null) {
      widget.onFeedbackSubmitted(
        _userRating!,
        _feedbackController.text.trim().isEmpty 
            ? null 
            : _feedbackController.text.trim(),
      );
      
      // Reset feedback form
      setState(() {
        _userRating = null;
        _feedbackController.clear();
      });
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getValueColor(double valueScore) {
    if (valueScore >= 0.8) return Colors.green;
    if (valueScore >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _formatTimeStamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 5) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  String _truncateReasoning(String reasoning) {
    if (reasoning.length <= 150) return reasoning;
    return '${reasoning.substring(0, 150)}...';
  }
}

/// Compact AI recommendation summary widget
class AIRecommendationSummary extends StatelessWidget {
  final AIRecommendation recommendation;
  final VoidCallback? onViewDetails;

  const AIRecommendationSummary({
    super.key,
    required this.recommendation,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Recommendation',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(recommendation.overallConfidence)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(recommendation.overallConfidence * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getConfidenceColor(recommendation.overallConfidence),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recommendation.primaryRecommendation != null) ...[
              Text(
                recommendation.primaryRecommendation!.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recommendation.investmentSummary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (onViewDetails != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 36),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

/// AI loading indicator with progress and messaging
class AIRecommendationLoading extends StatefulWidget {
  final String? message;

  const AIRecommendationLoading({
    super.key,
    this.message,
  });

  @override
  State<AIRecommendationLoading> createState() => _AIRecommendationLoadingState();
}

class _AIRecommendationLoadingState extends State<AIRecommendationLoading>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _loadingMessages = [
    'Analyzing your dining preferences...',
    'Evaluating investment opportunities...',
    'Calculating value scores...',
    'Finding perfect matches...',
    'Generating personalized recommendations...',
  ];

  int _currentMessageIndex = 0;
  late String _currentMessage;

  @override
  void initState() {
    super.initState();
    
    _currentMessage = widget.message ?? _loadingMessages[0];
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.message == null) {
      _startMessageRotation();
    }
  }

  void _startMessageRotation() {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _loadingMessages.length;
          _currentMessage = _loadingMessages[_currentMessageIndex];
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary
                          .withOpacity(_pulseAnimation.value * 0.2),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) => Transform.rotate(
                    angle: _rotationController.value * 2.0 * 3.14159,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _currentMessage,
                key: ValueKey(_currentMessage),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few seconds...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}