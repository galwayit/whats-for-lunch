import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ux_components.dart';

/// Investment capacity visualization with circular progress ring design
/// Follows UX advisor requirements for positive psychology and 800ms animations
class UXInvestmentCapacityRing extends StatefulWidget {
  final double currentSpent;
  final double weeklyCapacity;
  final double remainingCapacity;
  final bool animate;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const UXInvestmentCapacityRing({
    super.key,
    required this.currentSpent,
    required this.weeklyCapacity,
    required this.remainingCapacity,
    this.animate = true,
    this.title = 'Weekly Investment',
    this.subtitle = 'Remaining Capacity',
    this.onTap,
  });

  @override
  State<UXInvestmentCapacityRing> createState() => _UXInvestmentCapacityRingState();
}

/// Compact horizontal investment capacity indicator
/// Optimized for mobile discovery page with minimal vertical space usage
class UXCompactInvestmentIndicator extends StatelessWidget {
  final double currentSpent;
  final double weeklyCapacity;
  final double remainingCapacity;
  final String title;
  final VoidCallback? onTap;

  const UXCompactInvestmentIndicator({
    super.key,
    required this.currentSpent,
    required this.weeklyCapacity,
    required this.remainingCapacity,
    this.title = 'Weekly Budget',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressValue = weeklyCapacity > 0 ? (currentSpent / weeklyCapacity).clamp(0.0, 1.0) : 0.0;
    
    Color progressColor;
    if (progressValue < 0.7) {
      progressColor = Colors.green;
    } else if (progressValue < 0.9) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Semantics(
      label: '$title: \$${currentSpent.toStringAsFixed(2)} spent of \$${weeklyCapacity.toStringAsFixed(2)} capacity',
      value: '${(progressValue * 100).round()}% used',
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap != null ? () {
          HapticFeedback.lightImpact();
          onTap!();
        } : null,
        child: Container(
          height: 52, // Compact height vs 120px ring - slightly more room
          padding: const EdgeInsets.symmetric(
            horizontal: UXComponents.paddingM,
            vertical: UXComponents.paddingS,
          ),
          margin: const EdgeInsets.symmetric(horizontal: UXComponents.paddingS),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: progressColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Progress ring - small version
              SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 3,
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                    // Progress circle
                    CircularProgressIndicator(
                      value: progressValue,
                      strokeWidth: 3,
                      color: progressColor,
                    ),
                    // Center dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: progressColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: UXComponents.paddingS),
              
              // Budget info - single line to prevent overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$title: \$${remainingCapacity.toStringAsFixed(0)} left',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Percentage indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: UXComponents.paddingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progressValue * 100).round()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              if (onTap != null) ...[
                const SizedBox(width: UXComponents.paddingXS),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UXInvestmentCapacityRingState extends State<UXInvestmentCapacityRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800), // UX advisor specified duration
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.currentSpent / widget.weeklyCapacity,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    if (widget.animate) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(UXInvestmentCapacityRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSpent != widget.currentSpent ||
        oldWidget.weeklyCapacity != widget.weeklyCapacity) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.currentSpent / widget.weeklyCapacity,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
      if (widget.animate) {
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressValue = widget.currentSpent / widget.weeklyCapacity;
    
    Color progressColor;
    if (progressValue < 0.7) {
      progressColor = Colors.green;
    } else if (progressValue < 0.9) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Semantics(
      label: '${widget.title}: \$${widget.currentSpent.toStringAsFixed(2)} spent of \$${widget.weeklyCapacity.toStringAsFixed(2)} weekly capacity',
      value: '${(progressValue * 100).round()}% used',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap != null ? () {
          HapticFeedback.lightImpact();
          widget.onTap!();
        } : null,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    CustomPaint(
                      size: const Size(120, 120),
                      painter: _CircularProgressPainter(
                        progress: 1.0,
                        color: theme.colorScheme.surfaceContainerHighest,
                        strokeWidth: 8.0,
                      ),
                    ),
                    // Progress circle
                    CustomPaint(
                      size: const Size(120, 120),
                      painter: _CircularProgressPainter(
                        progress: _progressAnimation.value,
                        color: progressColor,
                        strokeWidth: 8.0,
                        gradient: LinearGradient(
                          colors: [
                            progressColor.withOpacity(0.6),
                            progressColor,
                          ],
                        ),
                      ),
                    ),
                    // Center content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '\$${widget.remainingCapacity.toStringAsFixed(0)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    // Glow effect for high usage
                    if (progressValue > 0.8)
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: progressColor.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter for circular progress ring
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final Gradient? gradient;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (gradient != null) {
      paint.shader = gradient!.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    } else {
      paint.color = color;
    }

    const startAngle = -pi / 2; // Start from top
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Weekly investment overview card with achievement progress
class UXWeeklyInvestmentOverview extends StatelessWidget {
  final double weeklySpent;
  final double weeklyCapacity;
  final int experiencesLogged;
  final int targetExperiences;
  final List<String> achievements;
  final VoidCallback? onViewDetails;

  const UXWeeklyInvestmentOverview({
    super.key,
    required this.weeklySpent,
    required this.weeklyCapacity,
    required this.experiencesLogged,
    required this.targetExperiences,
    this.achievements = const [],
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capacityProgress = weeklySpent / weeklyCapacity;
    final experienceProgress = experiencesLogged / targetExperiences;

    return Card(
      margin: const EdgeInsets.all(UXComponents.paddingM),
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: UXComponents.paddingS),
                Expanded(
                  child: Text(
                    'This Week\'s Investment',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onViewDetails != null)
                  TextButton(
                    onPressed: onViewDetails,
                    child: const Text('Details'),
                  ),
              ],
            ),
            const SizedBox(height: UXComponents.paddingL),
            
            // Investment metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Capacity Used',
                    '\$${weeklySpent.toStringAsFixed(2)}',
                    '\$${weeklyCapacity.toStringAsFixed(2)}',
                    capacityProgress,
                    Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: UXComponents.paddingM),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Experiences',
                    experiencesLogged.toString(),
                    '$targetExperiences target',
                    experienceProgress,
                    Icons.restaurant,
                  ),
                ),
              ],
            ),
            
            if (achievements.isNotEmpty) ...[
              const SizedBox(height: UXComponents.paddingL),
              _buildAchievementsSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    double progress,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(UXComponents.paddingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: UXComponents.paddingXS),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UXComponents.paddingS),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: UXComponents.paddingS),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress < 0.8 ? Colors.green : 
              progress < 0.95 ? Colors.orange : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 20,
            ),
            const SizedBox(width: UXComponents.paddingS),
            Text(
              'Recent Achievements',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: UXComponents.paddingS),
        Wrap(
          spacing: UXComponents.paddingS,
          runSpacing: UXComponents.paddingS,
          children: achievements.take(3).map((achievement) => 
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UXComponents.paddingS,
                vertical: UXComponents.paddingXS,
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              child: Text(
                achievement,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.amber.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ).toList(),
        ),
      ],
    );
  }
}

/// Investment guidance messages with positive psychology
class UXInvestmentGuidance extends StatelessWidget {
  final double currentCost;
  final double remainingCapacity;
  final String guidanceLevel;
  final VoidCallback? onOptimize;

  const UXInvestmentGuidance({
    super.key,
    required this.currentCost,
    required this.remainingCapacity,
    required this.guidanceLevel,
    this.onOptimize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    IconData icon;
    Color color;
    String title;
    String message;
    
    switch (guidanceLevel) {
      case 'excellent':
        icon = Icons.eco;
        color = Colors.green;
        title = 'Excellent Investment Choice!';
        message = 'This experience aligns perfectly with your weekly investment strategy.';
        break;
      case 'good':
        icon = Icons.thumb_up;
        color = Colors.blue;
        title = 'Good Investment Balance';
        message = 'A nice balance between enjoyment and your financial goals.';
        break;
      case 'moderate':
        icon = Icons.balance;
        color = Colors.orange;
        title = 'Moderate Investment Impact';
        message = 'Consider if this aligns with your priorities for the week.';
        break;
      case 'high':
        icon = Icons.warning;
        color = Colors.red;
        title = 'High Investment Alert';
        message = 'This will significantly impact your weekly capacity. Make sure it\'s worth it!';
        break;
      default:
        icon = Icons.info;
        color = theme.colorScheme.primary;
        title = 'Investment Planning';
        message = 'Track your dining experiences as investments in happiness.';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: UXComponents.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingM),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(UXComponents.paddingS),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
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
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (remainingCapacity < currentCost && onOptimize != null) ...[
                    const SizedBox(height: UXComponents.paddingS),
                    Text(
                      'Remaining capacity: \$${remainingCapacity.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onOptimize != null)
              TextButton(
                onPressed: onOptimize,
                child: const Text('Optimize'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Achievement notification with haptic feedback
class UXAchievementNotification extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool show;
  final VoidCallback? onDismiss;

  const UXAchievementNotification({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.color = Colors.amber,
    this.show = false,
    this.onDismiss,
  });

  @override
  State<UXAchievementNotification> createState() => _UXAchievementNotificationState();
}

class _UXAchievementNotificationState extends State<UXAchievementNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.bounceOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    if (widget.show) {
      _showNotification();
    }
  }

  @override
  void didUpdateWidget(UXAchievementNotification oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _showNotification();
    } else if (!widget.show && oldWidget.show) {
      _hideNotification();
    }
  }

  void _showNotification() {
    HapticFeedback.heavyImpact();
    _animationController.forward();
    
    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  void _hideNotification() {
    _animationController.reverse();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(UXComponents.paddingM),
              padding: const EdgeInsets.all(UXComponents.paddingL),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: widget.color.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(UXComponents.paddingM),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: UXComponents.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onDismiss,
                    icon: const Icon(Icons.close),
                    iconSize: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Investment capacity selector for budget setup
class UXInvestmentCapacitySelector extends StatelessWidget {
  final double selectedCapacity;
  final ValueChanged<double> onChanged;
  final List<double> presetAmounts;
  final bool allowCustom;

  const UXInvestmentCapacitySelector({
    super.key,
    required this.selectedCapacity,
    required this.onChanged,
    this.presetAmounts = const [100, 150, 200, 250, 300, 400],
    this.allowCustom = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
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
          'How much would you like to invest in dining experiences each week?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: UXComponents.paddingL),
        
        // Preset amounts grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: UXComponents.paddingS,
            mainAxisSpacing: UXComponents.paddingS,
            childAspectRatio: 2.0,
          ),
          itemCount: presetAmounts.length + (allowCustom ? 1 : 0),
          itemBuilder: (context, index) {
            if (allowCustom && index == presetAmounts.length) {
              return _buildCustomAmountButton(context);
            }
            
            final amount = presetAmounts[index];
            final isSelected = selectedCapacity == amount;
            
            return Semantics(
              button: true,
              selected: isSelected,
              label: 'Weekly capacity \$${amount.toStringAsFixed(0)}',
              child: Material(
                color: isSelected 
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onChanged(amount);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(UXComponents.paddingM),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '\$${amount.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'per week',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected 
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomAmountButton(BuildContext context) {
    final theme = Theme.of(context);
    final isCustomSelected = !presetAmounts.contains(selectedCapacity);
    
    return Semantics(
      button: true,
      label: 'Enter custom weekly capacity amount',
      child: Material(
        color: isCustomSelected 
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showCustomAmountDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(UXComponents.paddingM),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit,
                  color: isCustomSelected 
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
                ),
                const SizedBox(height: 2),
                Text(
                  'Custom',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isCustomSelected 
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomAmountDialog(BuildContext context) {
    final controller = TextEditingController(
      text: presetAmounts.contains(selectedCapacity) 
        ? '' 
        : selectedCapacity.toStringAsFixed(0),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Weekly Capacity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your preferred weekly investment capacity:'),
            const SizedBox(height: UXComponents.paddingM),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                onChanged(amount);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}

/// Investment metrics card component for AI recommendations page
class InvestmentMetricsCard extends StatelessWidget {
  final String title;
  final List<InvestmentMetric> metrics;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const InvestmentMetricsCard({
    super.key,
    required this.title,
    required this.metrics,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(UXComponents.paddingM),
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: UXComponents.paddingS),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (actionLabel != null && onActionPressed != null)
                  FilledButton(
                    onPressed: onActionPressed,
                    child: Text(actionLabel!),
                  ),
              ],
            ),
            const SizedBox(height: UXComponents.paddingL),
            
            // Metrics grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: metrics.length > 2 ? 2 : metrics.length,
                crossAxisSpacing: UXComponents.paddingM,
                mainAxisSpacing: UXComponents.paddingM,
                childAspectRatio: 1.2,
              ),
              itemCount: metrics.length,
              itemBuilder: (context, index) {
                return metrics[index];
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual investment metric component
class InvestmentMetric extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool isPositive;
  final IconData? icon;

  const InvestmentMetric({
    super.key,
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changeColor = isPositive ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(UXComponents.paddingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: changeColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: UXComponents.paddingXS),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: UXComponents.paddingS),
          
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: UXComponents.paddingXS),
          
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: changeColor,
              ),
              const SizedBox(width: UXComponents.paddingXS),
              Expanded(
                child: Text(
                  change,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}