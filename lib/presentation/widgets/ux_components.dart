import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/accessibility_utils.dart';
import '../../core/accessibility/focus_manager.dart';
import '../../core/responsive/responsive_utils.dart';

/// A collection of reusable UX components following Material Design 3 principles
/// with emphasis on accessibility, thumb-friendly design, and clear visual hierarchy.

class UXComponents {
  // Minimum touch target size for mobile accessibility (44x44 logical pixels)
  static const double minTouchTarget = 44.0;
  
  // Standard padding and spacing values
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;
  
  // Standard border radius values
  static const double borderRadius = 8.0;
  static const double borderRadiusL = 12.0;
  static const double borderRadiusXL = 16.0;
}

/// Enhanced button with proper touch targets and accessibility
class UXPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final IconData? icon;
  final String? semanticLabel;

  const UXPrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.icon,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? text,
      child: SizedBox(
        width: double.infinity,
        height: UXComponents.minTouchTarget + 8, // Extra height for comfort
        child: ElevatedButton(
          onPressed: isLoading ? null : () {
            HapticFeedback.lightImpact();
            onPressed?.call();
          },
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        text,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Secondary button with ghost styling
class UXSecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final String? semanticLabel;

  const UXSecondaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel ?? text,
      child: SizedBox(
        height: UXComponents.minTouchTarget,
        child: TextButton(
          onPressed: onPressed == null ? null : () {
            HapticFeedback.lightImpact();
            onPressed!.call();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress indicator for onboarding flows with enhanced accessibility
class UXProgressIndicator extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final String? semanticLabel;
  final bool announceChanges;
  final Duration animationDuration;

  const UXProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.semanticLabel,
    this.announceChanges = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<UXProgressIndicator> createState() => _UXProgressIndicatorState();
}

class _UXProgressIndicatorState extends State<UXProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  int _previousStep = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _updateProgress();
  }

  @override
  void didUpdateWidget(UXProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _previousStep = oldWidget.currentStep;
      _updateProgress();
      
      // Announce step change to screen readers
      if (widget.announceChanges) {
        final progress = ((widget.currentStep + 1) / widget.totalSteps * 100).round();
        AccessibilityUtils.announceToScreenReader(
          'Progress updated. Step ${widget.currentStep + 1} of ${widget.totalSteps}. $progress percent complete.',
          assertive: false,
        );
      }
    }
  }

  void _updateProgress() {
    final progress = (widget.currentStep + 1) / widget.totalSteps;
    _progressAnimation = Tween<double>(
      begin: _previousStep >= 0 ? (_previousStep + 1) / widget.totalSteps : 0,
      end: progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReducedMotion = AccessibilityUtils.shouldReduceMotions(context);
    
    return ResponsivePadding(
      mobile: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      tablet: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: AccessibilityUtils.makeAccessible(
        label: widget.semanticLabel ?? 'Step ${widget.currentStep + 1} of ${widget.totalSteps}',
        value: '${(((widget.currentStep + 1) / widget.totalSteps * 100).round())}% complete',
        child: Column(
          children: [
            ResponsiveWidget(
              mobile: _buildMobileProgress(theme, isReducedMotion),
              tablet: _buildTabletProgress(theme, isReducedMotion),
              desktop: _buildDesktopProgress(theme, isReducedMotion),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileProgress(ThemeData theme, bool isReducedMotion) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Step ${widget.currentStep + 1} of ${widget.totalSteps}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                final progress = isReducedMotion 
                    ? (widget.currentStep + 1) / widget.totalSteps
                    : _progressAnimation.value;
                return Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            final progress = isReducedMotion 
                ? (widget.currentStep + 1) / widget.totalSteps
                : _progressAnimation.value;
            return LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              minHeight: 8,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabletProgress(ThemeData theme, bool isReducedMotion) {
    return _buildMobileProgress(theme, isReducedMotion);
  }

  Widget _buildDesktopProgress(ThemeData theme, bool isReducedMotion) {
    return Row(
      children: List.generate(widget.totalSteps, (index) {
        final isCompleted = index < widget.currentStep;
        final isCurrent = index == widget.currentStep;
        
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < widget.totalSteps - 1)
                const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }
}

/// Enhanced text input with validation feedback
class UXTextInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helperText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final bool autofocus;
  final String? semanticLabel;

  const UXTextInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.semanticLabel,
  });

  @override
  State<UXTextInput> createState() => _UXTextInputState();
}

class _UXTextInputState extends State<UXTextInput> {
  String? _errorText;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_hasInteracted && widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(widget.controller.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      textField: true,
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          helperText: widget.helperText,
          errorText: _errorText,
          contentPadding: const EdgeInsets.symmetric(
            vertical: UXComponents.paddingM,
            horizontal: UXComponents.paddingM,
          ),
        ),
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofocus: widget.autofocus,
        onChanged: (value) {
          if (!_hasInteracted) {
            setState(() {
              _hasInteracted = true;
            });
          }
        },
        onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      ),
    );
  }
}

/// Loading overlay for async operations
class UXLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final Widget child;

  const UXLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black26,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(UXComponents.paddingL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: UXComponents.paddingM),
                        Text(
                          message!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Error state widget with recovery options
class UXErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final IconData? icon;

  const UXErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryButtonText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: UXComponents.paddingM),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UXComponents.paddingS),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: UXComponents.paddingL),
              UXPrimaryButton(
                onPressed: onRetry,
                text: retryButtonText ?? 'Try Again',
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Animated fade in wrapper
class UXFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const UXFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
  });

  @override
  State<UXFadeIn> createState() => _UXFadeInState();
}

class _UXFadeInState extends State<UXFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _animation.value)),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Card with enhanced elevation and accessibility
class UXCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const UXCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: margin ?? const EdgeInsets.all(UXComponents.paddingS),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(UXComponents.paddingM),
        child: child,
      ),
    );

    if (onTap != null) {
      return Semantics(
        button: true,
        label: semanticLabel,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap!.call();
          },
          borderRadius: BorderRadius.circular(12),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Specialized currency input with positive psychology messaging
class UXCurrencyInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final ValueChanged<double?>? onChanged;
  final bool autofocus;
  final String? positiveMessage;

  const UXCurrencyInput({
    super.key,
    required this.controller,
    this.label = 'Investment Amount',
    this.hint = 'How much did you invest in this experience?',
    this.validator,
    this.onChanged,
    this.autofocus = false,
    this.positiveMessage,
  });

  @override
  State<UXCurrencyInput> createState() => _UXCurrencyInputState();
}

class _UXCurrencyInputState extends State<UXCurrencyInput> {
  String? _errorText;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final value = double.tryParse(text.replaceAll(RegExp(r'[^\d.]'), ''));
    
    if (_hasInteracted && widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(text);
      });
    }

    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: widget.controller,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              errorText: _errorText,
              prefixIcon: const Icon(Icons.attach_money),
              suffixIcon: widget.positiveMessage != null
                  ? Tooltip(
                      message: widget.positiveMessage!,
                      child: Icon(
                        Icons.psychology,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: UXComponents.paddingM,
                horizontal: UXComponents.paddingM,
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            autofocus: widget.autofocus,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onChanged: (value) {
              if (!_hasInteracted) {
                setState(() {
                  _hasInteracted = true;
                });
              }
            },
          ),
          if (widget.positiveMessage != null && widget.controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: UXComponents.paddingS),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: UXComponents.paddingS),
                  Expanded(
                    child: Text(
                      widget.positiveMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
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
}

/// Autocomplete input for restaurant names
class UXRestaurantInput extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const UXRestaurantInput({
    super.key,
    required this.controller,
    this.label = 'Restaurant or Place',
    this.hint = 'Where did you enjoy this experience?',
    this.validator,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  ConsumerState<UXRestaurantInput> createState() => _UXRestaurantInputState();
}

class _UXRestaurantInputState extends ConsumerState<UXRestaurantInput> {
  String? _errorText;
  bool _hasInteracted = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_hasInteracted && widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(widget.controller.text);
      });
    }

    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      textField: true,
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          // For now, return simple suggestions
          // This will be enhanced with actual restaurant data later
          final suggestions = [
            'Local Cafe',
            'Downtown Bistro',
            'Fine Dining Restaurant',
            'Popular Chain',
            'Neighborhood Favorite',
            'Food Truck',
            'Grocery Store',
          ];
          
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          
          return suggestions.where((String option) {
            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (String selection) {
          widget.controller.text = selection;
          widget.onChanged?.call(selection);
        },
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          // Sync our controller with the autocomplete controller
          textEditingController.text = widget.controller.text;
          textEditingController.selection = widget.controller.selection;
          
          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              errorText: _errorText,
              prefixIcon: const Icon(Icons.restaurant),
              suffixIcon: Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: UXComponents.paddingM,
                horizontal: UXComponents.paddingM,
              ),
            ),
            textInputAction: TextInputAction.next,
            autofocus: widget.autofocus,
            onChanged: (value) {
              widget.controller.text = value;
              widget.controller.selection = textEditingController.selection;
              
              if (!_hasInteracted) {
                setState(() {
                  _hasInteracted = true;
                });
              }
            },
            onFieldSubmitted: (_) => onFieldSubmitted(),
          );
        },
      ),
    );
  }
}

/// Meal category selector with positive messaging
class UXMealCategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onChanged;
  final List<MealCategoryOption> categories;

  const UXMealCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Experience Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: UXComponents.paddingS),
        Text(
          'What kind of dining experience was this?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: UXComponents.paddingM),
        Wrap(
          spacing: UXComponents.paddingS,
          runSpacing: UXComponents.paddingS,
          children: categories.map((category) => _buildCategoryChip(
            context,
            category,
            selectedCategory == category.id,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    MealCategoryOption category,
    bool isSelected,
  ) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${category.name}: ${category.description}',
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 16),
            const SizedBox(width: UXComponents.paddingXS),
            Flexible(
              child: Text(
                category.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            HapticFeedback.lightImpact();
            onChanged(category.id);
          }
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
  }
}

/// Meal category option data class
class MealCategoryOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final double suggestedBudget;

  const MealCategoryOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.suggestedBudget,
  });
}

/// Date and time picker with smart defaults
class UXDateTimePicker extends StatelessWidget {
  final DateTime selectedDateTime;
  final ValueChanged<DateTime> onChanged;
  final String label;
  final String? hint;

  const UXDateTimePicker({
    super.key,
    required this.selectedDateTime,
    required this.onChanged,
    this.label = 'Experience Date & Time',
    this.hint = 'When did you enjoy this meal?',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: UXComponents.paddingXS),
          Text(
            hint!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: UXComponents.paddingM),
        Row(
          children: [
            Expanded(
              child: _buildDateSelector(context),
            ),
            const SizedBox(width: UXComponents.paddingM),
            Expanded(
              child: _buildTimeSelector(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Select date',
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          final date = await showDatePicker(
            context: context,
            initialDate: selectedDateTime,
            firstDate: DateTime.now().subtract(const Duration(days: 30)),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            onChanged(DateTime(
              date.year,
              date.month,
              date.day,
              selectedDateTime.hour,
              selectedDateTime.minute,
            ));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(UXComponents.paddingM),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: UXComponents.paddingS),
              Expanded(
                child: Text(
                  _formatDate(selectedDateTime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Select time',
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(selectedDateTime),
          );
          if (time != null) {
            onChanged(DateTime(
              selectedDateTime.year,
              selectedDateTime.month,
              selectedDateTime.day,
              time.hour,
              time.minute,
            ));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(UXComponents.paddingM),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: UXComponents.paddingS),
              Expanded(
                child: Text(
                  _formatTime(selectedDateTime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}

/// Budget impact visualization with positive messaging
class UXBudgetImpactCard extends StatelessWidget {
  final double currentCost;
  final double weeklyBudget;
  final String impactMessage;
  final String impactLevel;

  const UXBudgetImpactCard({
    super.key,
    required this.currentCost,
    required this.weeklyBudget,
    required this.impactMessage,
    required this.impactLevel,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (currentCost / weeklyBudget) * 100;
    final remaining = weeklyBudget - currentCost;
    
    Color impactColor;
    IconData impactIcon;
    
    switch (impactLevel) {
      case 'low':
        impactColor = Colors.green;
        impactIcon = Icons.eco;
        break;
      case 'moderate':
        impactColor = Colors.blue;
        impactIcon = Icons.balance;
        break;
      case 'high':
        impactColor = Colors.orange;
        impactIcon = Icons.star;
        break;
      case 'very_high':
        impactColor = Colors.red;
        impactIcon = Icons.diamond;
        break;
      default:
        impactColor = Theme.of(context).colorScheme.primary;
        impactIcon = Icons.info;
    }

    return UXCard(
      padding: const EdgeInsets.all(UXComponents.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(impactIcon, color: impactColor, size: 24),
              const SizedBox(width: UXComponents.paddingS),
              Expanded(
                child: Text(
                  'Investment Impact',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: impactColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: UXComponents.paddingM),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(impactColor),
          ),
          const SizedBox(height: UXComponents.paddingM),
          Text(
            impactMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: UXComponents.paddingS),
          Text(
            'Remaining weekly budget: \$${remaining.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}