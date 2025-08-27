import 'package:flutter/material.dart';

/// Comprehensive responsive design utilities for different screen sizes and orientations
class ResponsiveUtils {
  ResponsiveUtils._();

  // Breakpoints based on Material Design guidelines
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 905;
  static const double desktopBreakpoint = 1240;
  static const double largeDesktopBreakpoint = 1440;

  /// Get screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return ScreenSize.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenSize.tablet;
    } else if (width < desktopBreakpoint) {
      return ScreenSize.desktop;
    } else {
      return ScreenSize.largeDesktop;
    }
  }

  /// Check if device is mobile size
  static bool isMobile(BuildContext context) => 
      getScreenSize(context) == ScreenSize.mobile;

  /// Check if device is tablet size
  static bool isTablet(BuildContext context) => 
      getScreenSize(context) == ScreenSize.tablet;

  /// Check if device is desktop size
  static bool isDesktop(BuildContext context) => 
      getScreenSize(context).index >= ScreenSize.desktop.index;

  /// Get orientation
  static bool isPortrait(BuildContext context) => 
      MediaQuery.of(context).orientation == Orientation.portrait;

  static bool isLandscape(BuildContext context) => 
      MediaQuery.of(context).orientation == Orientation.landscape;

  /// Get responsive value based on screen size
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      desktop: const EdgeInsets.all(32),
      largeDesktop: const EdgeInsets.all(40),
    );
  }

  /// Get responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: const EdgeInsets.all(8),
      tablet: const EdgeInsets.all(12),
      desktop: const EdgeInsets.all(16),
      largeDesktop: const EdgeInsets.all(20),
    );
  }

  /// Get responsive font size
  static double getResponsiveFontSize({
    required BuildContext context,
    required double baseFontSize,
  }) {
    final scaleFactor = getResponsiveValue<double>(
      context: context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
      largeDesktop: 1.3,
    );
    
    return baseFontSize * scaleFactor;
  }

  /// Get responsive columns for grid layout
  static int getResponsiveColumns(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      largeDesktop: 4,
    );
  }

  /// Get responsive max width for content
  static double getMaxContentWidth(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: double.infinity,
      tablet: 768,
      desktop: 1024,
      largeDesktop: 1200,
    );
  }

  /// Create responsive safe area
  static Widget createResponsiveSafeArea({
    required BuildContext context,
    required Widget child,
    bool includeTop = true,
    bool includeBottom = true,
  }) {
    return SafeArea(
      top: includeTop,
      bottom: includeBottom,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: getMaxContentWidth(context),
        ),
        child: child,
      ),
    );
  }

  /// Create responsive scroll view
  static Widget createResponsiveScrollView({
    required BuildContext context,
    required List<Widget> children,
    ScrollController? controller,
    ScrollPhysics? physics,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return SingleChildScrollView(
      controller: controller,
      physics: physics,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: getMaxContentWidth(context),
        ),
        padding: getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: crossAxisAlignment,
          children: children,
        ),
      ),
    );
  }

  /// Create responsive grid
  static Widget createResponsiveGrid({
    required BuildContext context,
    required List<Widget> children,
    double childAspectRatio = 1.0,
    double crossAxisSpacing = 8.0,
    double mainAxisSpacing = 8.0,
    int? forceColumns,
  }) {
    final columns = forceColumns ?? getResponsiveColumns(context);
    
    return GridView.count(
      crossAxisCount: columns,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }

  /// Create responsive layout builder
  static Widget createResponsiveLayout({
    required WidgetBuilder mobile,
    WidgetBuilder? tablet,
    WidgetBuilder? desktop,
    WidgetBuilder? largeDesktop,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = getScreenSize(context);
        
        switch (screenSize) {
          case ScreenSize.mobile:
            return mobile(context);
          case ScreenSize.tablet:
            return (tablet ?? mobile)(context);
          case ScreenSize.desktop:
            return (desktop ?? tablet ?? mobile)(context);
          case ScreenSize.largeDesktop:
            return (largeDesktop ?? desktop ?? tablet ?? mobile)(context);
        }
      },
    );
  }

  /// Create responsive dialog
  static void showResponsiveDialog({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        return Dialog(
          insetPadding: getResponsiveValue(
            context: context,
            mobile: const EdgeInsets.all(16),
            tablet: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            desktop: const EdgeInsets.symmetric(horizontal: 200, vertical: 40),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: getResponsiveValue(
                context: context,
                mobile: double.infinity,
                tablet: 600,
                desktop: 800,
              ),
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: builder(context),
          ),
        );
      },
    );
  }

  /// Create responsive bottom sheet
  static void showResponsiveBottomSheet({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
  }) {
    if (isMobile(context)) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: isScrollControlled,
        useSafeArea: true,
        builder: builder,
      );
    } else {
      showResponsiveDialog(
        context: context,
        builder: builder,
      );
    }
  }

  /// Get adaptive text style based on screen size
  static TextStyle getAdaptiveTextStyle({
    required BuildContext context,
    required TextStyle baseStyle,
    double? mobileScale,
    double? tabletScale,
    double? desktopScale,
  }) {
    final scaleFactor = getResponsiveValue(
      context: context,
      mobile: mobileScale ?? 1.0,
      tablet: tabletScale ?? 1.1,
      desktop: desktopScale ?? 1.2,
    );

    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * scaleFactor,
    );
  }

  /// Check if touch input is available (mobile/tablet)
  static bool isTouchDevice(BuildContext context) {
    return isMobile(context) || isTablet(context);
  }

  /// Get touch target size based on platform
  static double getTouchTargetSize(BuildContext context) {
    return isTouchDevice(context) ? 48.0 : 40.0;
  }

  /// Create adaptive spacing
  static double getAdaptiveSpacing({
    required BuildContext context,
    double base = 8.0,
  }) {
    return getResponsiveValue(
      context: context,
      mobile: base,
      tablet: base * 1.25,
      desktop: base * 1.5,
    );
  }

  /// Get device pixel ratio adjusted size
  static double getPixelAdjustedSize({
    required BuildContext context,
    required double size,
  }) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    return size / pixelRatio;
  }
}

/// Screen size enumeration
enum ScreenSize {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Responsive widget wrapper
class ResponsiveWidget extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveWidget({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.createResponsiveLayout(
      mobile: (_) => mobile ?? const SizedBox.shrink(),
      tablet: tablet != null ? (_) => tablet! : null,
      desktop: desktop != null ? (_) => desktop! : null,
      largeDesktop: largeDesktop != null ? (_) => largeDesktop! : null,
    );
  }
}

/// Responsive padding wrapper
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;
  final EdgeInsets? largeDesktop;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: mobile ?? const EdgeInsets.all(16),
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Responsive text widget
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? mobileScale;
  final double? tabletScale;
  final double? desktopScale;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.mobileScale,
    this.tabletScale,
    this.desktopScale,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = style ?? theme.textTheme.bodyMedium!;
    
    final adaptiveStyle = ResponsiveUtils.getAdaptiveTextStyle(
      context: context,
      baseStyle: baseStyle,
      mobileScale: mobileScale,
      tabletScale: tabletScale,
      desktopScale: desktopScale,
    );

    return Text(
      text,
      style: adaptiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}