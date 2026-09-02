// @file preferences_page.dart
// @description User preferences editing page styled with the template design pattern.
//   Allows users to configure budget level, weekly budget, travel distance,
//   chain restaurant inclusion, and meals per day.
// @modified 2026-03-11

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user_preferences.dart';
import '../providers/simple_providers.dart';

class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key});

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  UserPreferences? _workingPreferences;
  UserPreferences? _originalPreferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreferences();
    });
  }

  Future<void> _loadPreferences() async {
    try {
      // Read from the unified preferences provider (single source of truth)
      UserPreferences? preferences = ref.read(userPreferencesProvider);

      // If still null, create default preferences
      preferences ??= const UserPreferences();

      setState(() {
        _workingPreferences = preferences;
        _originalPreferences = preferences;
        _isLoading = false;
      });
    } catch (e) {
      // On error, use default preferences
      const defaultPreferences = UserPreferences();
      setState(() {
        _workingPreferences = defaultPreferences;
        _originalPreferences = defaultPreferences;
        _isLoading = false;
      });
    }
  }

  bool _hasUnsavedChanges() {
    if (_workingPreferences == null || _originalPreferences == null) {
      return false;
    }
    return _workingPreferences != _originalPreferences;
  }

  Future<void> _handleBackPress() async {
    if (_hasUnsavedChanges()) {
      final shouldLeave = await _showUnsavedChangesDialog();
      if (shouldLeave && mounted) {
        context.go(AppRoutes.profile);
      }
    } else {
      context.go(AppRoutes.profile);
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.creamBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Unsaved Changes',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.brownText,
          ),
        ),
        content: Text(
          'You have unsaved changes. Are you sure you want to leave without saving?',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.brownTextLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
            ),
            child: Text(
              'Stay',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: Text(
              'Leave',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(userPreferencesProvider);

    // Update working preferences if the provider state changes
    if (!_isLoading && _workingPreferences == null && preferences != null) {
      _workingPreferences = preferences;
    }

    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header: back arrow + centered title + save action
            _buildCustomHeader(),
            // Body content
            Expanded(
              child: _isLoading || _workingPreferences == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                      ),
                    )
                  : _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Custom header row replacing the standard AppBar.
  /// Back arrow on the left, centered title, and a Save text button on the right.
  Widget _buildCustomHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.brownText),
            onPressed: _handleBackPress,
            tooltip: 'Go back',
          ),
          // Centered title
          Expanded(
            child: Center(
              child: Text(
                'Preferences',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.brownText,
                ),
              ),
            ),
          ),
          // Save action with unsaved-changes indicator
          TextButton(
            onPressed: _workingPreferences != null ? _savePreferences : null,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasUnsavedChanges()) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  'Save',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            children: [
              _buildBudgetSection(),
              const SizedBox(height: 16),
              _buildLocationSection(),
              const SizedBox(height: 16),
              _buildRestaurantSection(),
              const SizedBox(height: 16),
              _buildBudgetManagementSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Card container helper - white at 40% opacity, rounded-16, subtle border
  // ---------------------------------------------------------------------------
  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.brownText.withValues(alpha: 0.05),
        ),
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // Budget Preferences section
  // ---------------------------------------------------------------------------
  Widget _buildBudgetSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title
          Text(
            'Budget Preferences',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.brownText,
            ),
          ),
          const SizedBox(height: 16),

          // Budget level sub-label
          Text(
            'Budget Level',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.brownText,
            ),
          ),
          const SizedBox(height: 10),

          // Choice chips for budget level
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(4, (index) {
              final level = index + 1;
              final symbols = '\$' * level;
              final isSelected =
                  _workingPreferences!.budgetLevel == level;

              return ChoiceChip(
                label: Text(
                  symbols,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? Colors.white : AppTheme.brownText,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTheme.primaryGreen,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _workingPreferences =
                          _workingPreferences!.copyWith(budgetLevel: level);
                    });
                  }
                },
              );
            }),
          ),
          const SizedBox(height: 20),

          // Weekly budget slider
          Text(
            'Weekly Budget: \$${_workingPreferences!.weeklyBudget.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.brownText,
            ),
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryGreen,
              inactiveTrackColor:
                  AppTheme.primaryGreen.withValues(alpha: 0.12),
              thumbColor: AppTheme.primaryGreen,
              overlayColor:
                  AppTheme.primaryGreen.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _workingPreferences!.weeklyBudget,
              min: 50.0,
              max: 1000.0,
              divisions: 19,
              onChanged: (value) {
                setState(() {
                  _workingPreferences =
                      _workingPreferences!.copyWith(weeklyBudget: value);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Location Preferences section
  // ---------------------------------------------------------------------------
  Widget _buildLocationSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Preferences',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.brownText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Max Travel Distance: ${_workingPreferences!.maxTravelDistance.toStringAsFixed(1)} km',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.brownText,
            ),
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryGreen,
              inactiveTrackColor:
                  AppTheme.primaryGreen.withValues(alpha: 0.12),
              thumbColor: AppTheme.primaryGreen,
              overlayColor:
                  AppTheme.primaryGreen.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _workingPreferences!.maxTravelDistance,
              min: 1.0,
              max: 20.0,
              divisions: 19,
              onChanged: (value) {
                setState(() {
                  _workingPreferences = _workingPreferences!
                      .copyWith(maxTravelDistance: value);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Restaurant Preferences section
  // ---------------------------------------------------------------------------
  Widget _buildRestaurantSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restaurant Preferences',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.brownText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Icon container matching template pattern
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Include Chain Restaurants',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brownText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'McDonald\'s, Subway, KFC, etc.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.brownTextLight,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _workingPreferences!.includeChains,
                activeThumbColor: AppTheme.primaryGreen,
                activeTrackColor:
                    AppTheme.primaryGreen.withValues(alpha: 0.3),
                onChanged: (value) {
                  setState(() {
                    _workingPreferences = _workingPreferences!
                        .copyWith(includeChains: value);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Diet Tracking section (meals per day)
  // ---------------------------------------------------------------------------
  Widget _buildBudgetManagementSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diet Tracking',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.brownText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Meals per day: ${_workingPreferences!.mealFrequencyPerDay}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.brownText,
            ),
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryGreen,
              inactiveTrackColor:
                  AppTheme.primaryGreen.withValues(alpha: 0.12),
              thumbColor: AppTheme.primaryGreen,
              overlayColor:
                  AppTheme.primaryGreen.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _workingPreferences!.mealFrequencyPerDay.toDouble(),
              min: 1.0,
              max: 6.0,
              divisions: 5,
              onChanged: (value) {
                setState(() {
                  _workingPreferences = _workingPreferences!
                      .copyWith(mealFrequencyPerDay: value.toInt());
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom action buttons: Cancel (green text) + Save (green elevated)
  // ---------------------------------------------------------------------------
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        border: Border(
          top: BorderSide(
            color: AppTheme.brownText.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cancel - green text button
            Expanded(
              child: TextButton(
                onPressed: _handleBackPress,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Save - green elevated button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed:
                    _workingPreferences != null ? _savePreferences : null,
                icon: Icon(
                  _hasUnsavedChanges() ? Icons.save : Icons.check,
                  size: 20,
                ),
                label: Text(
                  _hasUnsavedChanges() ? 'Save Changes' : 'Save Preferences',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasUnsavedChanges()
                      ? AppTheme.primaryGreen
                      : AppTheme.primaryGreen.withValues(alpha: 0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor:
                      AppTheme.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Save logic - persists preferences and navigates back to profile
  // ---------------------------------------------------------------------------
  Future<void> _savePreferences() async {
    if (_workingPreferences == null) return;

    try {
      // Save to the unified provider (updates in-memory + persists to DB)
      await ref
          .read(userPreferencesProvider.notifier)
          .updatePreferences(_workingPreferences!);

      if (mounted) {
        // Update original preferences to match working preferences
        // (no more unsaved changes)
        setState(() {
          _originalPreferences = _workingPreferences;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Preferences saved successfully',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );

        // Add a small delay before navigating to ensure snackbar is shown
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigate back to Profile page after successful save
        if (mounted) {
          context.go(AppRoutes.profile);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving preferences: $e',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
