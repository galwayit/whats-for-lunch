import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/user_preferences.dart';
import '../providers/simple_providers.dart';

class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key});

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  UserPreferences? _workingPreferences;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentPreferences = ref.read(userPreferencesProvider);
      if (currentPreferences != null) {
        setState(() {
          _workingPreferences = currentPreferences;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(userPreferencesProvider);
    
    if (_workingPreferences == null && preferences != null) {
      _workingPreferences = preferences;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _workingPreferences != null ? _savePreferences : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _workingPreferences == null
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBudgetSection(),
        const SizedBox(height: 24),
        _buildLocationSection(),
        const SizedBox(height: 24),
        _buildRestaurantSection(),
        const SizedBox(height: 24),
        _buildBudgetManagementSection(),
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
      ref.read(userPreferencesProvider.notifier).updatePreferences(_workingPreferences!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully')),
        );
        context.pop();
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