import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../domain/entities/user_preferences.dart';
import '../providers/simple_providers.dart' as simple;
import '../providers/user_preferences_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(simple.currentUserProvider);
    // Use simple preferences provider for consistency
    final preferences = ref.watch(simple.simpleUserPreferencesProvider);

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
        _buildSettingsSection(context, ref),
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

  Widget _buildSettingsSection(BuildContext context, WidgetRef ref) {
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
                onTap: () => _showNotificationSettings(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy'),
                subtitle: const Text('Data and privacy settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacySettings(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help and report issues'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showHelpAndSupport(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showNotificationSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationSettingsSheet(ref: ref),
    );
  }

  void _showPrivacySettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PrivacySettingsSheet(ref: ref),
    );
  }

  void _showHelpAndSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _HelpAndSupportSheet(),
    );
  }
}

/// Notification Settings Bottom Sheet
class _NotificationSettingsSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  
  const _NotificationSettingsSheet({required this.ref});

  @override
  ConsumerState<_NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends ConsumerState<_NotificationSettingsSheet> {
  bool _mealReminders = true;
  bool _budgetAlerts = true;
  bool _newRestaurants = false;
  bool _weeklyInsights = true;
  bool _achievementUpdates = true;
  bool _promotionalOffers = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notification Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Text(
                  'Smart notifications help you stay on track with your food investment goals.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                _buildNotificationTile(
                  'Meal Reminders',
                  'Get reminded when it\'s time to invest in your next meal',
                  Icons.restaurant,
                  _mealReminders,
                  (value) => setState(() => _mealReminders = value),
                  isRecommended: true,
                ),
                _buildNotificationTile(
                  'Budget Alerts',
                  'Stay informed about your weekly food investment progress',
                  Icons.account_balance_wallet,
                  _budgetAlerts,
                  (value) => setState(() => _budgetAlerts = value),
                  isRecommended: true,
                ),
                _buildNotificationTile(
                  'Weekly Insights',
                  'Receive personalized reports on your food investment returns',
                  Icons.analytics,
                  _weeklyInsights,
                  (value) => setState(() => _weeklyInsights = value),
                  isRecommended: true,
                ),
                _buildNotificationTile(
                  'Achievement Updates',
                  'Celebrate milestones in your culinary investment journey',
                  Icons.emoji_events,
                  _achievementUpdates,
                  (value) => setState(() => _achievementUpdates = value),
                ),
                _buildNotificationTile(
                  'New Restaurants',
                  'Discover fresh investment opportunities in your area',
                  Icons.new_releases,
                  _newRestaurants,
                  (value) => setState(() => _newRestaurants = value),
                ),
                _buildNotificationTile(
                  'Promotional Offers',
                  'Special deals and limited-time investment opportunities',
                  Icons.local_offer,
                  _promotionalOffers,
                  (value) => setState(() => _promotionalOffers = value),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Save settings logic would go here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification preferences saved!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Preferences'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    {bool isRecommended = false}
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Recommended',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Privacy Settings Bottom Sheet
class _PrivacySettingsSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  
  const _PrivacySettingsSheet({required this.ref});

  @override
  ConsumerState<_PrivacySettingsSheet> createState() => _PrivacySettingsSheetState();
}

class _PrivacySettingsSheetState extends ConsumerState<_PrivacySettingsSheet> {
  bool _locationSharing = true;
  bool _analyticsTracking = true;
  bool _dataExportEnabled = true;
  bool _marketingCommunications = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Privacy & Data',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Text(
                  'Your privacy matters. Control how your data is used to enhance your food investment experience.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                _buildPrivacySection(
                  'Data Collection',
                  [
                    _buildPrivacyTile(
                      'Location Services',
                      'Allow us to find restaurants near you and improve recommendations',
                      Icons.location_on,
                      _locationSharing,
                      (value) => setState(() => _locationSharing = value),
                    ),
                    _buildPrivacyTile(
                      'Usage Analytics',
                      'Help us improve the app by sharing anonymous usage data',
                      Icons.analytics,
                      _analyticsTracking,
                      (value) => setState(() => _analyticsTracking = value),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPrivacySection(
                  'Communications',
                  [
                    _buildPrivacyTile(
                      'Marketing Communications',
                      'Receive personalized offers and food investment insights',
                      Icons.email,
                      _marketingCommunications,
                      (value) => setState(() => _marketingCommunications = value),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPrivacySection(
                  'Data Management',
                  [
                    _buildActionTile(
                      'Export My Data',
                      'Download a copy of all your data and meal investment history',
                      Icons.download,
                      () => _exportData(),
                    ),
                    _buildActionTile(
                      'Delete My Account',
                      'Permanently remove your account and all associated data',
                      Icons.delete_forever,
                      () => _showDeleteAccountDialog(),
                      isDestructive: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Save privacy settings logic would go here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Privacy settings saved!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Settings'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildPrivacyTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    {bool isDestructive = false}
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDestructive ? Colors.red : null,
        ),
        onTap: onTap,
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Your data export will be prepared and sent to your email address. This may take a few minutes to complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export initiated. Check your email shortly.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your meal history and preferences.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete account logic would go here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion initiated. You will be logged out shortly.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}

/// Help and Support Bottom Sheet
class _HelpAndSupportSheet extends StatelessWidget {
  const _HelpAndSupportSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Help & Support',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Text(
                  'Get help with your food investment journey. We\'re here to support your success.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                _buildHelpSection(
                  'Frequently Asked Questions',
                  [
                    _buildFAQItem(
                      'How do I track my food investment ROI?',
                      'Use the Track tab to log meals and see how your food choices contribute to your health and happiness investment goals.',
                    ),
                    _buildFAQItem(
                      'What does budget level mean?',
                      'Budget levels (\$ to \$\$\$\$) help us recommend restaurants that align with your investment comfort zone.',
                    ),
                    _buildFAQItem(
                      'How are restaurant recommendations personalized?',
                      'We analyze your preferences, meal history, and investment patterns to suggest restaurants that maximize your satisfaction ROI.',
                    ),
                    _buildFAQItem(
                      'Can I export my meal data?',
                      'Yes! Go to Privacy Settings to export all your meal investment data and insights.',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildHelpSection(
                  'Get in Touch',
                  [
                    _buildContactTile(
                      'Send Feedback',
                      'Share ideas to improve your food investment experience',
                      Icons.feedback,
                      () => _sendFeedback(context),
                    ),
                    _buildContactTile(
                      'Report an Issue',
                      'Let us know about bugs or problems you\'ve encountered',
                      Icons.bug_report,
                      () => _reportIssue(context),
                    ),
                    _buildContactTile(
                      'Contact Support',
                      'Get personalized help from our support team',
                      Icons.support_agent,
                      () => _contactSupport(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildHelpSection(
                  'App Information',
                  [
                    _buildInfoTile('Version', '1.0.0'),
                    _buildInfoTile('Last Updated', 'Today'),
                    _buildInfoTile('Privacy Policy', 'View our commitment to your privacy', onTap: () => _viewPrivacyPolicy(context)),
                    _buildInfoTile('Terms of Service', 'Read the terms of use', onTap: () => _viewTermsOfService(context)),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.blue,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }

  static void _sendFeedback(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: const Text(
          'Your feedback helps us improve your food investment experience. You will be redirected to our feedback form.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Launch feedback form/email
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening feedback form...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  static void _reportIssue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const Text(
          'Help us fix problems quickly by reporting issues. Include details about what you were doing when the problem occurred.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Launch issue reporting form
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening issue report form...'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  static void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text(
          'Our support team is here to help you maximize your food investment success. Typical response time is within 24 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Launch support contact
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connecting you with support...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Contact'),
          ),
        ],
      ),
    );
  }

  static void _viewPrivacyPolicy(BuildContext context) {
    // In a real app, this would open a web view or navigate to privacy policy
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening privacy policy...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  static void _viewTermsOfService(BuildContext context) {
    // In a real app, this would open a web view or navigate to terms
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening terms of service...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}