import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibility/accessibility_utils.dart';
import '../../core/accessibility/focus_manager.dart';
import '../../core/constants/app_routes.dart';
import '../../core/responsive/responsive_utils.dart';
import '../providers/budget_providers.dart';
import '../providers/simple_providers.dart';
import 'ux_components.dart';

/// Enhanced bottom navigation bar with contextual badges and smooth animations
/// Follows UX advisor requirements for thumb-friendly design and engagement
class EnhancedBottomNavigation extends ConsumerStatefulWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const EnhancedBottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  ConsumerState<EnhancedBottomNavigation> createState() => _EnhancedBottomNavigationState();
}

class _EnhancedBottomNavigationState extends ConsumerState<EnhancedBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _badgeAnimationController;
  late AnimationController _selectionAnimationController;
  late List<AnimationController> _iconAnimationControllers;
  
  @override
  void initState() {
    super.initState();
    
    _badgeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _selectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Create individual animation controllers for each navigation item
    _iconAnimationControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
    
    // Start badge animation
    _badgeAnimationController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(EnhancedBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _selectionAnimationController.forward().then((_) {
        _selectionAnimationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _badgeAnimationController.dispose();
    _selectionAnimationController.dispose();
    for (final controller in _iconAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeklyInvestment = ref.watch(weeklyInvestmentProvider);
    final achievementState = ref.watch(achievementProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                0,
                Icons.home_outlined,
                Icons.home_rounded,
                'Home',
                badgeCount: null,
                onTap: () => _navigateToPage(context, AppRoutes.home, 0),
              ),
              _buildNavItem(
                context,
                1,
                Icons.explore_outlined,
                Icons.explore,
                'Discover',
                badgeCount: null,
                onTap: () => _navigateToPage(context, AppRoutes.discover, 1),
              ),
              _buildNavItem(
                context,
                2,
                Icons.add_circle_outline,
                Icons.add_circle,
                'Track',
                badgeCount: weeklyInvestment.remainingCapacity > 0 ? null : 0,
                badgeColor: weeklyInvestment.remainingCapacity <= 0 ? Colors.red : null,
                showPulseBadge: weeklyInvestment.remainingCapacity <= 20,
                onTap: () => _navigateToPage(context, AppRoutes.track, 2),
              ),
              _buildNavItem(
                context,
                3,
                Icons.person_outline,
                Icons.person,
                'Profile',
                badgeCount: achievementState.unlockedAchievements.isNotEmpty && 
                          achievementState.latestAchievement != null ? 1 : null,
                badgeColor: Colors.amber,
                onTap: () => _navigateToPage(context, AppRoutes.profile, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    {
    int? badgeCount,
    Color? badgeColor,
    bool showPulseBadge = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isSelected = widget.currentIndex == index;
    
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label navigation item',
      child: GestureDetector(
        onTapDown: (_) {
          _iconAnimationControllers[index].forward();
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          _iconAnimationControllers[index].reverse();
          onTap();
        },
        onTapCancel: () {
          _iconAnimationControllers[index].reverse();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _iconAnimationControllers[index],
            _selectionAnimationController,
          ]),
          builder: (context, child) {
            final scaleValue = 1.0 - (_iconAnimationControllers[index].value * 0.1);
            final selectionScale = isSelected ? 1.0 + (_selectionAnimationController.value * 0.1) : 1.0;
            
            return Transform.scale(
              scale: scaleValue * selectionScale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected
                      ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                      : Colors.transparent,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isSelected ? filledIcon : outlinedIcon,
                          size: 28,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        
                        // Badge
                        if (badgeCount != null)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: _buildBadge(
                              badgeCount,
                              badgeColor ?? theme.colorScheme.error,
                              showPulseBadge,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 11,
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

  Widget _buildBadge(int count, Color color, bool shouldPulse) {
    return AnimatedBuilder(
      animation: _badgeAnimationController,
      builder: (context, child) {
        final pulseScale = shouldPulse 
            ? 1.0 + (_badgeAnimationController.value * 0.2)
            : 1.0;
            
        return Transform.scale(
          scale: pulseScale,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: shouldPulse
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: 4,
                        spreadRadius: _badgeAnimationController.value * 2,
                      ),
                    ]
                  : null,
            ),
            child: count > 0
                ? Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _navigateToPage(BuildContext context, String route, int index) {
    if (widget.currentIndex != index) {
      widget.onTap?.call(index);
      context.go(route);
    }
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
                    color: Colors.black.withOpacity(0.3 * _menuAnimation.value),
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
                            color: Colors.black.withOpacity(0.1),
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
                                color: item.color.withOpacity(0.3),
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
                  backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
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
              color: action.color.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
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