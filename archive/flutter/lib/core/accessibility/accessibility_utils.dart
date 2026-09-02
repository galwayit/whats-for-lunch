import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Comprehensive accessibility utilities for WCAG 2.1 AA compliance
class AccessibilityUtils {
  AccessibilityUtils._();
  
  // WCAG AA minimum contrast ratios
  static const double minContrastRatioAA = 4.5;
  static const double minContrastRatioAALarge = 3.0;
  static const double minContrastRatioAAA = 7.0;
  
  // Minimum touch target sizes (44pt iOS, 48dp Android)
  static const double minTouchTargetSize = 48.0;
  static const double minTouchTargetSizeIOS = 44.0;
  
  /// Calculates luminance of a color for contrast ratio computation
  static double getLuminance(Color color) {
    return color.computeLuminance();
  }
  
  /// Calculates contrast ratio between two colors
  static double getContrastRatio(Color color1, Color color2) {
    final lum1 = getLuminance(color1);
    final lum2 = getLuminance(color2);
    final lighter = lum1 > lum2 ? lum1 : lum2;
    final darker = lum1 > lum2 ? lum2 : lum1;
    return (lighter + 0.05) / (darker + 0.05);
  }
  
  /// Checks if color combination meets WCAG AA standards
  static bool meetsContrastAA(Color foreground, Color background, {bool isLargeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    return isLargeText ? ratio >= minContrastRatioAALarge : ratio >= minContrastRatioAA;
  }
  
  /// Checks if color combination meets WCAG AAA standards
  static bool meetsContrastAAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= minContrastRatioAAA;
  }
  
  /// Ensures minimum touch target size
  static Size ensureMinimumTouchTarget(Size size, {bool isiOS = false}) {
    final minSize = isiOS ? minTouchTargetSizeIOS : minTouchTargetSize;
    return Size(
      size.width < minSize ? minSize : size.width,
      size.height < minSize ? minSize : size.height,
    );
  }
  
  /// Creates accessible color variants for better contrast
  static Color getAccessibleColor(Color color, Color background, {bool isLargeText = false}) {
    if (meetsContrastAA(color, background, isLargeText: isLargeText)) {
      return color;
    }
    
    // Adjust color brightness until it meets contrast requirements
    final bgLuminance = getLuminance(background);
    final shouldDarken = bgLuminance > 0.5;
    
    HSVColor hsvColor = HSVColor.fromColor(color);
    
    for (double adjustment = 0.1; adjustment <= 1.0; adjustment += 0.1) {
      final adjustedColor = shouldDarken
          ? hsvColor.withValue((hsvColor.value * (1.0 - adjustment)).clamp(0.0, 1.0))
          : hsvColor.withValue((hsvColor.value + adjustment).clamp(0.0, 1.0));
      
      final testColor = adjustedColor.toColor();
      if (meetsContrastAA(testColor, background, isLargeText: isLargeText)) {
        return testColor;
      }
    }
    
    // Fallback to high contrast colors
    return bgLuminance > 0.5 ? Colors.black : Colors.white;
  }
  
  /// Provides semantic announcement for screen readers
  static void announceToScreenReader(String message, {bool assertive = false}) {
    // Note: Direct semantic announcements require platform-specific implementation
    // For now, this is a placeholder that could be enhanced with platform channels
    // or third-party accessibility packages
  }
  
  /// Creates accessible widget with proper semantics
  static Widget makeAccessible({
    required Widget child,
    String? label,
    String? hint,
    String? value,
    bool? button,
    bool? selected,
    bool? enabled,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool excludeSemantics = false,
  }) {
    if (excludeSemantics) return child;
    
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: button,
      selected: selected,
      enabled: enabled,
      onTap: onTap != null ? () {
        HapticFeedback.lightImpact();
        onTap();
      } : null,
      onLongPress: onLongPress != null ? () {
        HapticFeedback.mediumImpact();
        onLongPress();
      } : null,
      child: child,
    );
  }
  
  /// Focus management utilities
  static void requestFocus(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }
  
  /// Dismisses keyboard and clears focus
  static void dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
  
  /// Creates accessible button with proper touch targets and feedback
  static Widget createAccessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    String? semanticLabel,
    String? tooltip,
    EdgeInsets? padding,
    bool hapticFeedback = true,
  }) {
    Widget button = child;
    
    if (padding != null || tooltip != null || semanticLabel != null) {
      button = Tooltip(
        message: tooltip ?? '',
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: button,
        ),
      );
    }
    
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPressed == null ? null : () {
          if (hapticFeedback) HapticFeedback.lightImpact();
          onPressed();
        },
        child: button,
      ),
    );
  }
  
  /// Text scaling utilities for accessibility
  static double getScaledFontSize(BuildContext context, double baseSize) {
    final mediaQuery = MediaQuery.of(context);
    final textScaler = mediaQuery.textScaler;
    
    // Limit scaling to prevent layout issues while maintaining accessibility
    final clampedScale = textScaler.scale(1.0).clamp(0.8, 2.0);
    return baseSize * clampedScale;
  }
  
  /// Determines if reduced motion is preferred
  static bool shouldReduceMotions(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
  
  /// Returns appropriate animation duration based on accessibility settings
  static Duration getAccessibleAnimationDuration(
    Duration baseDuration,
    BuildContext context,
  ) {
    return shouldReduceMotions(context) 
        ? Duration.zero 
        : baseDuration;
  }
  
  /// High contrast mode detection and utilities
  static bool isHighContrastMode(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }
  
  /// Voice over / talk back detection
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }
  
  /// Creates accessible form field with proper labeling
  static Widget createAccessibleFormField({
    required Widget child,
    String? label,
    String? helperText,
    String? errorText,
    bool required = false,
  }) {
    String? semanticLabel = label;
    if (required && label != null) {
      semanticLabel = '$label, required';
    }
    if (errorText != null && errorText.isNotEmpty) {
      semanticLabel = '$semanticLabel, error: $errorText';
    }
    
    return Semantics(
      label: semanticLabel,
      hint: helperText,
      textField: true,
      child: child,
    );
  }
}

/// Extension methods for enhanced accessibility
extension AccessibilityExtension on Widget {
  /// Wraps widget with accessibility features
  Widget accessible({
    String? label,
    String? hint,
    String? value,
    bool? button,
    bool? selected,
    bool? enabled,
    VoidCallback? onTap,
  }) {
    return AccessibilityUtils.makeAccessible(
      child: this,
      label: label,
      hint: hint,
      value: value,
      button: button,
      selected: selected,
      enabled: enabled,
      onTap: onTap,
    );
  }
  
  /// Adds semantic announcements
  Widget withAnnouncement(String message, {bool assertive = false}) {
    return Builder(
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AccessibilityUtils.announceToScreenReader(message, assertive: assertive);
        });
        return this;
      },
    );
  }
}