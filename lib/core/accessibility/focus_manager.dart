import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced focus management for accessibility and keyboard navigation
class AppFocusManager {
  AppFocusManager._();

  /// Requests focus for a node with proper timing
  static void requestFocus(FocusNode focusNode, {bool delayed = true}) {
    if (delayed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (focusNode.canRequestFocus) {
          focusNode.requestFocus();
        }
      });
    } else {
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    }
  }

  /// Moves focus to next focusable element
  static void focusNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
    HapticFeedback.lightImpact();
  }

  /// Moves focus to previous focusable element
  static void focusPrevious(BuildContext context) {
    FocusScope.of(context).previousFocus();
    HapticFeedback.lightImpact();
  }

  /// Dismisses keyboard and removes focus
  static void dismissFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Creates focus traversal group for better navigation control
  static Widget createFocusGroup({
    required Widget child,
    FocusTraversalPolicy? policy,
    bool autoRequestFocus = false,
  }) {
    return FocusTraversalGroup(
      policy: policy ?? OrderedTraversalPolicy(),
      child: autoRequestFocus
          ? Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FocusScope.of(context).requestFocus();
                });
                return child;
              },
            )
          : child,
    );
  }

  /// Creates an accessible form with proper focus management
  static Widget createAccessibleForm({
    required List<Widget> children,
    FocusNode? initialFocus,
    VoidCallback? onSubmit,
  }) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Builder(
        builder: (context) {
          // Set initial focus if provided
          if (initialFocus != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              requestFocus(initialFocus);
            });
          }

          return Column(
            children: children.map((child) {
              // Wrap text fields with keyboard submission handling
              if (child is TextFormField || 
                  child.runtimeType.toString().contains('TextField')) {
                return _wrapWithSubmissionHandler(child, context, onSubmit);
              }
              return child;
            }).toList(),
          );
        },
      ),
    );
  }

  /// Wraps a widget with keyboard submission handling
  static Widget _wrapWithSubmissionHandler(
    Widget child, 
    BuildContext context, 
    VoidCallback? onSubmit,
  ) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          if (onSubmit != null) {
            onSubmit();
          } else {
            focusNext(context);
          }
        }
      },
      child: child,
    );
  }

  /// Creates accessible navigation with proper focus indicators
  static Widget createAccessibleNavigation({
    required List<NavigationItem> items,
    required int currentIndex,
    required ValueChanged<int> onTap,
    Axis direction = Axis.horizontal,
  }) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: direction == Axis.horizontal
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _buildNavigationItems(items, currentIndex, onTap),
            )
          : Column(
              children: _buildNavigationItems(items, currentIndex, onTap),
            ),
    );
  }

  static List<Widget> _buildNavigationItems(
    List<NavigationItem> items,
    int currentIndex,
    ValueChanged<int> onTap,
  ) {
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      
      return AccessibleNavigationItem(
        item: item,
        isSelected: index == currentIndex,
        onTap: () => onTap(index),
        focusOrder: index,
      );
    }).toList();
  }
}

/// Navigation item data class
class NavigationItem {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String? semanticLabel;
  final String? badge;

  NavigationItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.semanticLabel,
    this.badge,
  });
}

/// Accessible navigation item with focus management
class AccessibleNavigationItem extends StatefulWidget {
  final NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final int focusOrder;

  const AccessibleNavigationItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.focusOrder,
  });

  @override
  State<AccessibleNavigationItem> createState() => _AccessibleNavigationItemState();
}

class _AccessibleNavigationItemState extends State<AccessibleNavigationItem> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FocusableActionDetector(
      focusNode: _focusNode,
      onShowHoverHighlight: (hover) => setState(() {}),
      onShowFocusHighlight: (focus) => setState(() {
        _isFocused = focus;
      }),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            HapticFeedback.lightImpact();
            widget.onTap();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        selected: widget.isSelected,
        label: widget.item.semanticLabel ?? widget.item.label,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: widget.isSelected
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : Colors.transparent,
              border: _isFocused
                  ? Border.all(
                      color: colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            transform: Matrix4.identity()
              ..scale(_isPressed ? 0.95 : 1.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      widget.isSelected
                          ? (widget.item.selectedIcon ?? widget.item.icon)
                          : widget.item.icon,
                      color: widget.isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                    if (widget.item.badge != null)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.item.badge!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onError,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: widget.isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: widget.isSelected 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Accessible dialog with focus management
class AccessibleDialog extends StatefulWidget {
  final String title;
  final String? content;
  final List<Widget> actions;
  final Widget? child;
  final bool dismissible;
  final String? semanticLabel;

  const AccessibleDialog({
    super.key,
    required this.title,
    this.content,
    this.actions = const [],
    this.child,
    this.dismissible = true,
    this.semanticLabel,
  });

  @override
  State<AccessibleDialog> createState() => _AccessibleDialogState();
}

class _AccessibleDialogState extends State<AccessibleDialog> {
  final FocusNode _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Focus title when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? widget.title,
      child: AlertDialog(
        title: Focus(
          focusNode: _titleFocusNode,
          child: Text(widget.title),
        ),
        content: widget.child ?? (widget.content != null 
            ? Text(widget.content!) 
            : null),
        actions: widget.actions.isNotEmpty 
            ? [AppFocusManager.createFocusGroup(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: widget.actions.map((action) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: action,
                    );
                  }).toList(),
                ),
              )]
            : null,
      ),
    );
  }
}

/// Custom focus traversal policy for better accessibility
class AccessibilityTraversalPolicy extends FocusTraversalPolicy {
  @override
  FocusNode? findFirstFocusInDirection(FocusNode currentNode, TraversalDirection direction) {
    return findFirstFocus(currentNode);
  }

  @override
  Iterable<FocusNode> sortDescendants(
    Iterable<FocusNode> descendants, 
    FocusNode currentNode,
  ) {
    // Sort by reading order (top to bottom, left to right)
    final sorted = descendants.toList()
      ..sort((a, b) {
        final aRect = a.rect;
        final bRect = b.rect;
        
        // Compare vertical position first
        final verticalDiff = aRect.top.compareTo(bRect.top);
        if (verticalDiff.abs() > 20) { // Allow for some vertical tolerance
          return verticalDiff;
        }
        
        // If roughly on same line, compare horizontal position
        return aRect.left.compareTo(bRect.left);
      });
    
    return sorted;
  }

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    final sorted = sortDescendants(
      currentNode.nearestScope?.descendants ?? [],
      currentNode,
    ).toList();
    
    final currentIndex = sorted.indexOf(currentNode);
    if (currentIndex == -1) return false;

    FocusNode? next;
    switch (direction) {
      case TraversalDirection.up:
      case TraversalDirection.left:
        if (currentIndex > 0) {
          next = sorted[currentIndex - 1];
        }
        break;
      case TraversalDirection.down:
      case TraversalDirection.right:
        if (currentIndex < sorted.length - 1) {
          next = sorted[currentIndex + 1];
        }
        break;
    }

    if (next != null && next.canRequestFocus) {
      next.requestFocus();
      return true;
    }

    return false;
  }
}