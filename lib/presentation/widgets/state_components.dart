import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/accessibility_utils.dart';
import 'ux_components.dart';

/// Comprehensive error state widget with accessibility and recovery options
class AccessibleErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String? semanticMessage;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final VoidCallback? onDismiss;
  final String? dismissButtonText;
  final List<ErrorAction>? additionalActions;
  final bool showRetryTimer;
  final Duration? retryDelay;

  const AccessibleErrorState({
    super.key,
    required this.title,
    required this.message,
    this.semanticMessage,
    this.icon,
    this.onRetry,
    this.retryButtonText,
    this.onDismiss,
    this.dismissButtonText,
    this.additionalActions,
    this.showRetryTimer = false,
    this.retryDelay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighContrast = AccessibilityUtils.isHighContrastMode(context);
    final colorScheme = theme.colorScheme;

    return AccessibilityUtils.makeAccessible(
      label: 'Error: $title',
      hint: semanticMessage ?? message,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(UXComponents.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon
              Container(
                padding: const EdgeInsets.all(UXComponents.paddingL),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: isHighContrast ? Border.all(
                    color: colorScheme.error,
                    width: 2,
                  ) : null,
                ),
                child: Icon(
                  icon ?? Icons.error_outline,
                  size: 64,
                  color: colorScheme.error,
                  semanticLabel: 'Error icon',
                ),
              ),

              const SizedBox(height: UXComponents.paddingL),

              // Title
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: UXComponents.paddingM),

              // Message
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: UXComponents.paddingL),

              // Action Buttons
              _buildActionButtons(context, theme),

              // Additional Actions
              if (additionalActions?.isNotEmpty == true) ...[
                const SizedBox(height: UXComponents.paddingM),
                _buildAdditionalActions(context, theme),
              ],

              // Auto-retry timer
              if (showRetryTimer && retryDelay != null && onRetry != null) ...[
                const SizedBox(height: UXComponents.paddingM),
                _AutoRetryTimer(
                  delay: retryDelay!,
                  onRetry: onRetry!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    final buttons = <Widget>[];

    if (onRetry != null) {
      buttons.add(
        Expanded(
          child: UXPrimaryButton(
            onPressed: onRetry,
            text: retryButtonText ?? 'Try Again',
            icon: Icons.refresh,
            semanticLabel: 'Retry the failed operation',
          ),
        ),
      );
    }

    if (onDismiss != null) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: UXComponents.paddingM));
      }
      buttons.add(
        Expanded(
          child: UXSecondaryButton(
            onPressed: onDismiss,
            text: dismissButtonText ?? 'Dismiss',
            icon: Icons.close,
            semanticLabel: 'Dismiss this error',
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(children: buttons);
  }

  Widget _buildAdditionalActions(BuildContext context, ThemeData theme) {
    if (additionalActions?.isEmpty != false) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: UXComponents.paddingS,
      runSpacing: UXComponents.paddingS,
      children: additionalActions!.map((action) {
        return AccessibilityUtils.createAccessibleButton(
          child: Chip(
            label: Text(action.label),
            avatar: action.icon != null ? Icon(action.icon, size: 18) : null,
          ),
          onPressed: action.onPressed,
          semanticLabel: action.semanticLabel ?? action.label,
        );
      }).toList(),
    );
  }
}

/// Auto-retry timer component
class _AutoRetryTimer extends StatefulWidget {
  final Duration delay;
  final VoidCallback onRetry;

  const _AutoRetryTimer({
    required this.delay,
    required this.onRetry,
  });

  @override
  State<_AutoRetryTimer> createState() => _AutoRetryTimerState();
}

class _AutoRetryTimerState extends State<_AutoRetryTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.delay,
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);

    _controller.forward().then((_) {
      if (mounted) {
        widget.onRetry();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final secondsLeft = (_animation.value * widget.delay.inSeconds).ceil();
        return Column(
          children: [
            Text(
              'Retrying in $secondsLeft seconds...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: UXComponents.paddingS),
            LinearProgressIndicator(
              value: 1.0 - _animation.value,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Comprehensive empty state widget with contextual guidance
class AccessibleEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? semanticMessage;
  final IconData? icon;
  final Widget? illustration;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionText;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionText;
  final List<EmptyStateAction>? suggestions;
  final bool showSearchTips;

  const AccessibleEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.semanticMessage,
    this.icon,
    this.illustration,
    this.onPrimaryAction,
    this.primaryActionText,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.suggestions,
    this.showSearchTips = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isReducedMotion = AccessibilityUtils.shouldReduceMotions(context);

    return AccessibilityUtils.makeAccessible(
      label: 'Empty state: $title',
      hint: semanticMessage ?? message,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(UXComponents.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration or Icon
              if (illustration != null) ...[
                SizedBox(
                  height: 200,
                  child: illustration!,
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(UXComponents.paddingXL),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon ?? Icons.inbox_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: UXComponents.paddingL),

              // Title
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: UXComponents.paddingM),

              // Message
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: UXComponents.paddingL),

              // Primary Actions
              _buildPrimaryActions(context, theme),

              // Suggestions
              if (suggestions?.isNotEmpty == true) ...[
                const SizedBox(height: UXComponents.paddingL),
                _buildSuggestions(context, theme),
              ],

              // Search Tips
              if (showSearchTips) ...[
                const SizedBox(height: UXComponents.paddingL),
                _buildSearchTips(context, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryActions(BuildContext context, ThemeData theme) {
    final actions = <Widget>[];

    if (onPrimaryAction != null) {
      actions.add(
        UXPrimaryButton(
          onPressed: onPrimaryAction,
          text: primaryActionText ?? 'Get Started',
          semanticLabel: 'Start using this feature',
        ),
      );
    }

    if (onSecondaryAction != null) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(height: UXComponents.paddingM));
      }
      actions.add(
        UXSecondaryButton(
          onPressed: onSecondaryAction,
          text: secondaryActionText ?? 'Learn More',
          semanticLabel: 'Learn more about this feature',
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(children: actions);
  }

  Widget _buildSuggestions(BuildContext context, ThemeData theme) {
    if (suggestions?.isEmpty != false) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggestions:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: UXComponents.paddingM),
        ...suggestions!.map((suggestion) => _buildSuggestionItem(
          context,
          theme,
          suggestion,
        )),
      ],
    );
  }

  Widget _buildSuggestionItem(
    BuildContext context,
    ThemeData theme,
    EmptyStateAction suggestion,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UXComponents.paddingS),
      child: AccessibilityUtils.createAccessibleButton(
        child: Row(
          children: [
            if (suggestion.icon != null) ...[
              Icon(
                suggestion.icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: UXComponents.paddingM),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (suggestion.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        onPressed: suggestion.onPressed,
        semanticLabel: suggestion.semanticLabel ?? suggestion.title,
      ),
    );
  }

  Widget _buildSearchTips(BuildContext context, ThemeData theme) {
    const tips = [
      'Try different keywords',
      'Check your spelling',
      'Use more general terms',
      'Browse categories instead',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: UXComponents.paddingS),
                Text(
                  'Search Tips',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: UXComponents.paddingM),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: UXComponents.paddingXS),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: UXComponents.paddingS),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader with accessibility support
class AccessibleSkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool animate;
  final String? semanticLabel;

  const AccessibleSkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
    this.animate = true,
    this.semanticLabel,
  });

  @override
  State<AccessibleSkeletonLoader> createState() => _AccessibleSkeletonLoaderState();
}

class _AccessibleSkeletonLoaderState extends State<AccessibleSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    if (widget.animate && !AccessibilityUtils.shouldReduceMotions(context)) {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );
      _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    if (widget.animate) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget skeleton = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
      ),
    );

    if (widget.animate && !AccessibilityUtils.shouldReduceMotions(context)) {
      skeleton = AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: skeleton,
          );
        },
      );
    }

    return AccessibilityUtils.makeAccessible(
      label: widget.semanticLabel ?? 'Loading content',
      child: skeleton,
    );
  }
}

/// Data classes for actions
class ErrorAction {
  final String label;
  final String? semanticLabel;
  final IconData? icon;
  final VoidCallback onPressed;

  ErrorAction({
    required this.label,
    this.semanticLabel,
    this.icon,
    required this.onPressed,
  });
}

class EmptyStateAction {
  final String title;
  final String? description;
  final String? semanticLabel;
  final IconData? icon;
  final VoidCallback onPressed;

  EmptyStateAction({
    required this.title,
    this.description,
    this.semanticLabel,
    this.icon,
    required this.onPressed,
  });
}

/// Loading state with accessibility announcements
class AccessibleLoadingState extends StatefulWidget {
  final String? message;
  final bool showProgress;
  final double? progress;
  final Duration? timeout;
  final VoidCallback? onTimeout;
  final Widget? child;

  const AccessibleLoadingState({
    super.key,
    this.message,
    this.showProgress = false,
    this.progress,
    this.timeout,
    this.onTimeout,
    this.child,
  });

  @override
  State<AccessibleLoadingState> createState() => _AccessibleLoadingStateState();
}

class _AccessibleLoadingStateState extends State<AccessibleLoadingState> {
  @override
  void initState() {
    super.initState();
    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AccessibilityUtils.announceToScreenReader(
          widget.message!,
          assertive: false,
        );
      });
    }

    if (widget.timeout != null && widget.onTimeout != null) {
      Future.delayed(widget.timeout!, () {
        if (mounted) {
          widget.onTimeout!();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.child != null) {
      return widget.child!;
    }

    return AccessibilityUtils.makeAccessible(
      label: 'Loading',
      hint: widget.message ?? 'Please wait while content loads',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.showProgress && widget.progress != null) ...[
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: widget.progress,
                  strokeWidth: 4,
                ),
              ),
            ] else ...[
              const CircularProgressIndicator(),
            ],
            if (widget.message != null) ...[
              const SizedBox(height: UXComponents.paddingL),
              Text(
                widget.message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}