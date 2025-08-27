import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';

import '../../core/services/logging_service.dart';
import '../../domain/entities/user_preferences.dart';
import '../providers/simple_providers.dart';
import '../providers/user_preferences_provider.dart';

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
      // First, try to get preferences from userPreferencesProvider
      UserPreferences? preferences = ref.read(userPreferencesProvider);
      
      // If that's null, try to get from simple provider (which is used during onboarding)
      if (preferences == null) {
        final simplePreferences = ref.read(simpleUserPreferencesProvider);
        if (simplePreferences != null) {
          preferences = simplePreferences;
          // Sync the preferences to the main provider
          final currentUserId = ref.read(currentUserIdProvider);
          if (currentUserId != null) {
            await ref.read(userPreferencesProvider.notifier).loadUserPreferences(currentUserId);
            // Update with the preferences from simple provider
            await ref.read(userPreferencesProvider.notifier).updatePreferences(simplePreferences);
          }
        }
      }
      
      // If still null, create default preferences
      if (preferences == null) {
        preferences = const UserPreferences();
      }
      
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
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to leave without saving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
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
      appBar: AppBar(
        title: const Text('Preferences'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackPress,
          tooltip: 'Go back',
        ),
        actions: [
          TextButton(
            onPressed: _workingPreferences != null ? _savePreferences : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_hasUnsavedChanges()) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                const Text('Save'),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading || _workingPreferences == null
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildBudgetSection(),
              const SizedBox(height: 24),
              _buildLocationSection(),
              const SizedBox(height: 24),
              _buildRestaurantSection(),
              const SizedBox(height: 24),
              _buildBudgetManagementSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildBudgetSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Preferences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Budget Level',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(4, (index) {
                final level = index + 1;
                final symbols = '\$' * level;
                final isSelected = _workingPreferences!.budgetLevel == level;
                
                return ChoiceChip(
                  label: Text(symbols),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _workingPreferences = _workingPreferences!.copyWith(budgetLevel: level);
                      });
                    }
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              'Weekly Budget: \$${_workingPreferences!.weeklyBudget.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _workingPreferences!.weeklyBudget,
              min: 50.0,
              max: 1000.0,
              divisions: 19,
              onChanged: (value) {
                setState(() {
                  _workingPreferences = _workingPreferences!.copyWith(weeklyBudget: value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Preferences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Max Travel Distance: ${_workingPreferences!.maxTravelDistance.toStringAsFixed(1)} km',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _workingPreferences!.maxTravelDistance,
              min: 1.0,
              max: 20.0,
              divisions: 19,
              onChanged: (value) {
                setState(() {
                  _workingPreferences = _workingPreferences!.copyWith(maxTravelDistance: value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant Preferences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Include Chain Restaurants'),
              subtitle: const Text('McDonald\'s, Subway, KFC, etc.'),
              value: _workingPreferences!.includeChains,
              onChanged: (value) {
                setState(() {
                  _workingPreferences = _workingPreferences!.copyWith(includeChains: value);
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _handleBackPress,
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _workingPreferences != null ? _savePreferences : null,
                icon: Icon(_hasUnsavedChanges() ? Icons.save : Icons.check),
                label: Text(_hasUnsavedChanges() ? 'Save Changes' : 'Save Preferences'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: _hasUnsavedChanges() 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diet Tracking',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Meals per day: ${_workingPreferences!.mealFrequencyPerDay}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _workingPreferences!.mealFrequencyPerDay.toDouble(),
              min: 1.0,
              max: 6.0,
              divisions: 5,
              onChanged: (value) {
                setState(() {
                  _workingPreferences = _workingPreferences!.copyWith(mealFrequencyPerDay: value.toInt());
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePreferences() async {
    if (_workingPreferences == null) return;

    try {
      // Save to the main provider first
      await ref.read(userPreferencesProvider.notifier).updatePreferences(_workingPreferences!);
      
      // Update the simple provider (this is synchronous)
      try {
        ref.read(simpleUserPreferencesProvider.notifier).updatePreferences(_workingPreferences!);
      } catch (e) {
        // Log simple provider error but don't fail the entire operation
        LoggingService().warning('Simple provider update failed', tag: 'Preferences', error: e);
      }
      
      if (mounted) {
        // Update original preferences to match working preferences (no more unsaved changes)
        setState(() {
          _originalPreferences = _workingPreferences;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully')),
        );
        
        // Add a small delay before popping to ensure snackbar is shown
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate back to Profile page after successful save
        if (mounted) {
          context.go(AppRoutes.profile);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    }
  }
}