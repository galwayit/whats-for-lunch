import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                    Text(
                      text,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
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
              Text(text),
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress indicator for onboarding flows
class UXProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String? semanticLabel;

  const UXProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (currentStep + 1) / totalSteps;
    
    return Semantics(
      label: semanticLabel ?? 'Step ${currentStep + 1} of $totalSteps',
      value: '${((progress * 100).round())}% complete',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: UXComponents.paddingL,
          vertical: UXComponents.paddingM,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Step ${currentStep + 1} of $totalSteps',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
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