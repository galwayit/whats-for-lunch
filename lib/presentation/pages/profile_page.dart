import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/user_preferences.dart';
import '../providers/simple_providers.dart' as simple;

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(simple.currentUserProvider);
    final preferences = ref.watch(simple.userPreferencesProvider);

    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      body: SafeArea(
        child: currentUser != null
            ? _buildContent(context, ref, currentUser['name'] ?? 'User', preferences)
            : const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, String userName, UserPreferences? preferences) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        _buildProfileHeader(context, userName),
        const SizedBox(height: 20),
        _buildPreferencesSection(context, preferences),
        const SizedBox(height: 20),
        _buildSettingsSection(context, ref),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.brownText.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryGreen,
                ),
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.brownText,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'FOOD EXPLORER',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context, UserPreferences? preferences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'YOUR PREFERENCES',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.brownText.withValues(alpha: 0.6),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.brownText.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _buildPreferenceTile(
                context,
                icon: Icons.payments,
                title: 'Budget Level',
                value: preferences != null ? '\$' * preferences.budgetLevel : 'Not set',
                onTap: () => context.go(AppRoutes.preferences),
              ),
              Divider(height: 1, color: AppTheme.brownText.withValues(alpha: 0.05), indent: 56),
              _buildPreferenceTile(
                context,
                icon: Icons.near_me,
                title: 'Max Distance',
                value: preferences != null
                    ? '${preferences.maxTravelDistance.toStringAsFixed(1)} km'
                    : 'Not set',
                onTap: () => context.go(AppRoutes.preferences),
              ),
              Divider(height: 1, color: AppTheme.brownText.withValues(alpha: 0.05), indent: 56),
              _buildPreferenceTile(
                context,
                icon: Icons.restaurant_menu,
                title: 'Include Chains',
                value: preferences != null
                    ? preferences.includeChains ? 'Yes' : 'No'
                    : 'Not set',
                onTap: () => context.go(AppRoutes.preferences),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.brownText,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.brownTextLight,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppTheme.brownText.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'SETTINGS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.brownText.withValues(alpha: 0.6),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.brownText.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                context,
                icon: Icons.tune,
                title: 'Edit Preferences',
                subtitle: 'Update your food preferences',
                onTap: () => context.go(AppRoutes.preferences),
              ),
              Divider(height: 1, color: AppTheme.brownText.withValues(alpha: 0.05), indent: 56),
              _buildSettingsTile(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage app notifications',
                onTap: () => _showNotificationSettings(context, ref),
              ),
              Divider(height: 1, color: AppTheme.brownText.withValues(alpha: 0.05), indent: 56),
              _buildSettingsTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy',
                subtitle: 'Data and privacy settings',
                onTap: () => _showPrivacySettings(context, ref),
              ),
              Divider(height: 1, color: AppTheme.brownText.withValues(alpha: 0.05), indent: 56),
              _buildSettingsTile(
                context,
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help and report issues',
                onTap: () => _showHelpAndSupport(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brownText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.brownTextLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.brownText.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
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

// Bottom sheet widgets - styled to match template patterns

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
        color: AppTheme.creamBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildSheetHandle(),
          _buildSheetHeader(context, 'Notification Settings'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Text(
                  'Smart notifications help you stay on track with your food goals.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppTheme.brownTextLight,
                  ),
                ),
                const SizedBox(height: 20),
                _buildToggleTile('Meal Reminders', 'Get reminded for your next meal',
                    Icons.restaurant, _mealReminders, (v) => setState(() => _mealReminders = v)),
                _buildToggleTile('Budget Alerts', 'Stay informed about spending',
                    Icons.account_balance_wallet, _budgetAlerts, (v) => setState(() => _budgetAlerts = v)),
                _buildToggleTile('Weekly Insights', 'Receive personalized reports',
                    Icons.analytics, _weeklyInsights, (v) => setState(() => _weeklyInsights = v)),
                _buildToggleTile('Achievement Updates', 'Celebrate milestones',
                    Icons.emoji_events, _achievementUpdates, (v) => setState(() => _achievementUpdates = v)),
                _buildToggleTile('New Restaurants', 'Discover new places nearby',
                    Icons.new_releases, _newRestaurants, (v) => setState(() => _newRestaurants = v)),
                _buildToggleTile('Promotional Offers', 'Special deals and offers',
                    Icons.local_offer, _promotionalOffers, (v) => setState(() => _promotionalOffers = v)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Notification preferences saved!',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Save Preferences'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.brownText.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.brownText)),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.brownTextLight)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PrivacySettingsSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _PrivacySettingsSheet({required this.ref});

  @override
  ConsumerState<_PrivacySettingsSheet> createState() => _PrivacySettingsSheetState();
}

class _PrivacySettingsSheetState extends ConsumerState<_PrivacySettingsSheet> {
  bool _locationSharing = true;
  bool _analyticsTracking = true;
  bool _marketingCommunications = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppTheme.creamBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildSheetHandle(),
          _buildSheetHeader(context, 'Privacy & Data'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Text(
                  'Your privacy matters. Control how your data is used.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.brownTextLight),
                ),
                const SizedBox(height: 20),
                _buildSectionLabel('Data Collection'),
                _buildPrivacyToggle('Location Services', 'Find restaurants near you', Icons.location_on,
                    _locationSharing, (v) => setState(() => _locationSharing = v)),
                _buildPrivacyToggle('Usage Analytics', 'Help us improve the app', Icons.analytics,
                    _analyticsTracking, (v) => setState(() => _analyticsTracking = v)),
                const SizedBox(height: 16),
                _buildSectionLabel('Communications'),
                _buildPrivacyToggle('Marketing', 'Personalized offers', Icons.email,
                    _marketingCommunications, (v) => setState(() => _marketingCommunications = v)),
                const SizedBox(height: 16),
                _buildSectionLabel('Data Management'),
                _buildActionTile('Export My Data', 'Download a copy of all your data', Icons.download, () => _exportData()),
                _buildActionTile('Delete My Account', 'Permanently remove your account', Icons.delete_forever,
                    () => _showDeleteAccountDialog(), isDestructive: true),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Privacy settings saved!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
                            backgroundColor: AppTheme.primaryGreen),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Save Settings'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.brownText.withValues(alpha: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildPrivacyToggle(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.brownText.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.brownText)),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.brownTextLight)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.brownText.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, color: isDestructive ? Colors.red : AppTheme.primaryGreen, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : AppTheme.brownText)),
                    Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.brownTextLight)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: isDestructive ? Colors.red.withValues(alpha: 0.5) : AppTheme.brownText.withValues(alpha: 0.3), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Data', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Your data export will be prepared and sent to your email.',
            style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Data export initiated.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
                    backgroundColor: AppTheme.primaryGreen),
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
        title: Text('Delete Account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure? This action cannot be undone and will permanently remove all your data.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Account deletion initiated.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
                    backgroundColor: Colors.red),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}

class _HelpAndSupportSheet extends StatelessWidget {
  const _HelpAndSupportSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppTheme.creamBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildSheetHandle(),
          _buildSheetHeader(context, 'Help & Support'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Text(
                  'Get help with your food journey. We\'re here to support you.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.brownTextLight),
                ),
                const SizedBox(height: 20),
                _buildFAQItem('How do I track my meals?',
                    'Use the Track tab to log meals and see your dining history.'),
                _buildFAQItem('What does budget level mean?',
                    'Budget levels (\$ to \$\$\$\$) help us recommend restaurants that match your budget.'),
                _buildFAQItem('How are recommendations personalized?',
                    'We analyze your preferences and meal history to suggest the best restaurants.'),
                _buildFAQItem('Can I export my data?',
                    'Yes! Go to Privacy Settings to export all your data.'),
                const SizedBox(height: 20),
                _buildContactItem(context, 'Send Feedback', Icons.feedback, () => _showDialog(context, 'Send Feedback', 'Opening feedback form...')),
                _buildContactItem(context, 'Report an Issue', Icons.bug_report, () => _showDialog(context, 'Report Issue', 'Opening issue form...')),
                _buildContactItem(context, 'Contact Support', Icons.support_agent, () => _showDialog(context, 'Contact Support', 'Connecting with support...')),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.brownText.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Version', '1.0.0'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Last Updated', 'Today'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.brownText.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(question, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.brownText)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.brownTextLight, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.brownText.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 22),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.brownText))),
              Icon(Icons.chevron_right, color: AppTheme.brownText.withValues(alpha: 0.3), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.brownTextLight)),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.brownText)),
      ],
    );
  }

  static void _showDialog(BuildContext context, String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500)),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}

// Shared sheet helpers
Widget _buildSheetHandle() {
  return Container(
    width: 40,
    height: 4,
    margin: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.brownText.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

Widget _buildSheetHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.brownText,
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.brownText.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 18),
            color: AppTheme.brownText,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    ),
  );
}
