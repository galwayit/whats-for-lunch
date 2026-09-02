import 'dart:math' show pi;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_routes.dart';
import 'ux_components.dart';

/// Bottom navigation bar with frosted glass styling and clean tab design.
///
/// Matches the template design: white/80 backdrop-blur container with a subtle
/// top border. Active tabs use a green-tinted rounded container with filled
/// icons; inactive tabs use outlined icons at reduced opacity.
class EnhancedBottomNavigation extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const EnhancedBottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  // Design tokens
  static const Color _primaryGreen = Color(0xFF2F7F3F);
  static const Color _brownText = Color(0xFF6B4E3D);

  /// Navigation items configuration.
  static const List<_NavItemData> _items = [
    _NavItemData(
      outlinedIcon: Icons.home_outlined,
      filledIcon: Icons.home,
      label: 'Home',
      route: AppRoutes.home,
    ),
    _NavItemData(
      outlinedIcon: Icons.explore_outlined,
      filledIcon: Icons.explore,
      label: 'Discover',
      route: AppRoutes.discover,
    ),
    _NavItemData(
      outlinedIcon: Icons.analytics_outlined,
      filledIcon: Icons.analytics,
      label: 'Track',
      route: AppRoutes.track,
    ),
    _NavItemData(
      outlinedIcon: Icons.person_outline,
      filledIcon: Icons.person,
      label: 'Profile',
      route: AppRoutes.profile,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: _brownText.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: 8,
              ),
              child: Row(
                children: List.generate(_items.length, (index) {
                  return Expanded(
                    child: _NavItem(
                      data: _items[index],
                      isSelected: currentIndex == index,
                      onTap: () => _navigateToPage(context, index),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    if (currentIndex != index) {
      onTap?.call(index);
      context.go(_items[index].route);
    }
  }
}

/// Data class for a single navigation item.
class _NavItemData {
  final IconData outlinedIcon;
  final IconData filledIcon;
  final String label;
  final String route;

  const _NavItemData({
    required this.outlinedIcon,
    required this.filledIcon,
    required this.label,
    required this.route,
  });
}

/// A single tab item inside the bottom navigation bar.
///
/// Active state: green bg at 10% opacity, rounded-2xl container, filled icon,
/// green text. Inactive state: outlined icon, brown text at 50% opacity.
class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = EnhancedBottomNavigation._primaryGreen;
    final inactiveColor =
        EnhancedBottomNavigation._brownText.withValues(alpha: 0.5);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${data.label} navigation item',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? data.filledIcon : data.outlinedIcon,
                size: 24,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                data.label.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating action button with contextual menu for quick actions
class EnhancedFloatingActionButton extends StatefulWidget {
  final VoidCallback? onQuickLog;
  final VoidCallback? onTakePhoto;
  final VoidCallback? onAIRecommend;

  const EnhancedFloatingActionButton({
    super.key,
    this.onQuickLog,
    this.onTakePhoto,
    this.onAIRecommend,
  });

  @override
  State<EnhancedFloatingActionButton> createState() => _EnhancedFloatingActionButtonState();
}

class _EnhancedFloatingActionButtonState extends State<EnhancedFloatingActionButton>
    with TickerProviderStateMixin {
  late AnimationController _menuAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _menuAnimation;
  late Animation<double> _fabRotationAnimation;
  
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    
    _menuAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _menuAnimation = CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeInOut,
    );
    
    _fabRotationAnimation = Tween<double>(
      begin: 0,
      end: 0.125, // 45 degrees
    ).animate(CurvedAnimation(
      parent: _menuAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _menuAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
    
    if (_isMenuOpen) {
      _menuAnimationController.forward();
    } else {
      _menuAnimationController.reverse();
    }
    
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Backdrop
        if (_isMenuOpen)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _menuAnimation,
              builder: (context, child) {
                return GestureDetector(
                  onTap: _toggleMenu,
                  child: Container(
                    color: Colors.black.withValues(alpha:0.3 * _menuAnimation.value),
                  ),
                );
              },
            ),
          ),
        
        // Menu items
        ..._buildMenuItems(theme),
        
        // Main FAB
        AnimatedBuilder(
          animation: _fabAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 - (_fabAnimationController.value * 0.1),
              child: AnimatedBuilder(
                animation: _fabRotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _fabRotationAnimation.value * 2 * pi,
                    child: FloatingActionButton(
                      onPressed: _toggleMenu,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 6,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _isMenuOpen ? Icons.close : Icons.add,
                          key: ValueKey(_isMenuOpen),
                          size: 28,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildMenuItems(ThemeData theme) {
    final items = [
      _MenuItem(
        icon: Icons.camera_alt,
        label: 'Take Photo',
        onTap: () {
          _toggleMenu();
          widget.onTakePhoto?.call();
        },
        color: Colors.blue,
        position: 1,
      ),
      _MenuItem(
        icon: Icons.auto_awesome,
        label: 'AI Recommend',
        onTap: () {
          _toggleMenu();
          widget.onAIRecommend?.call();
        },
        color: Colors.purple,
        position: 2,
      ),
      _MenuItem(
        icon: Icons.restaurant_menu,
        label: 'Quick Log',
        onTap: () {
          _toggleMenu();
          widget.onQuickLog?.call();
        },
        color: Colors.green,
        position: 3,
      ),
    ];

    return items.map((item) => _buildMenuItem(theme, item)).toList();
  }

  Widget _buildMenuItem(ThemeData theme, _MenuItem item) {
    return AnimatedBuilder(
      animation: _menuAnimation,
      builder: (context, child) {
        final slideOffset = 70.0 * item.position * (1 - _menuAnimation.value);
        
        return Transform.translate(
          offset: Offset(0, -slideOffset),
          child: Transform.scale(
            scale: _menuAnimation.value,
            child: Opacity(
              opacity: _menuAnimation.value,
              child: Padding(
                padding: EdgeInsets.only(bottom: 70.0 * item.position),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        item.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Mini FAB
                    Semantics(
                      button: true,
                      label: item.label,
                      child: GestureDetector(
                        onTap: item.onTap,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: item.color.withValues(alpha:0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            item.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final int position;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.position,
  });
}

/// Context-aware app bar with dynamic titles and actions
class EnhancedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showInvestmentIndicator;
  final double? investmentProgress;
  final VoidCallback? onInvestmentTap;

  const EnhancedAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showInvestmentIndicator = false,
    this.investmentProgress,
    this.onInvestmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      leading: leading,
      actions: [
        if (showInvestmentIndicator && investmentProgress != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: onInvestmentTap,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(
                  value: investmentProgress,
                  backgroundColor: theme.colorScheme.outline.withValues(alpha:0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(investmentProgress!),
                  ),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        ...?actions,
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.7) {
      return Colors.green;
    } else if (progress < 0.9) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Quick action shortcuts that appear in various contexts
class QuickActionShortcuts extends StatelessWidget {
  final List<QuickAction> actions;
  final ScrollPhysics? physics;

  const QuickActionShortcuts({
    super.key,
    required this.actions,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: physics,
        padding: const EdgeInsets.symmetric(horizontal: UXComponents.paddingM),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          
          return Padding(
            padding: EdgeInsets.only(
              right: index < actions.length - 1 ? UXComponents.paddingM : 0,
            ),
            child: _buildActionShortcut(context, action),
          );
        },
      ),
    );
  }

  Widget _buildActionShortcut(BuildContext context, QuickAction action) {
    final theme = Theme.of(context);
    
    return Semantics(
      button: true,
      label: '${action.label} shortcut',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          action.onTap();
        },
        child: Container(
          width: 70,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: action.color.withValues(alpha:0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                action.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}