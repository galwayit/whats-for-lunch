import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../domain/entities/user_preferences.dart';
import '../providers/simple_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final preferences = ref.watch(userPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: currentUser != null
          ? _buildContent(context, ref, currentUser['name'] ?? 'User', preferences)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, String userName, UserPreferences? preferences) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProfileHeader(context, userName),
        const SizedBox(height: 24),
        _buildPreferencesSection(context, preferences),
        const SizedBox(height: 24),
        _buildSettingsSection(context),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, String userName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Food Explorer',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context, UserPreferences? preferences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Preferences',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Budget Level'),
                subtitle: Text(
                  preferences != null 
                    ? '\$' * (preferences.budgetLevel ?? 2)
                    : 'Not set',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.preferences),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Max Distance'),
                subtitle: Text(
                  preferences != null 
                    ? '${(preferences.maxTravelDistance ?? 5.0).toStringAsFixed(1)} km'
                    : 'Not set',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.preferences),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restaurant_menu),
                title: const Text('Include Chains'),
                subtitle: Text(
                  preferences != null 
                    ? (preferences.includeChains ?? true) ? 'Yes' : 'No'
                    : 'Not set',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.preferences),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Edit Preferences'),
                subtitle: const Text('Update your food preferences'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRoutes.preferences),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                subtitle: const Text('Manage app notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement notifications settings
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy'),
                subtitle: const Text('Data and privacy settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement privacy settings
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help and report issues'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement help & support
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}