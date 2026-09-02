// @file hungry_page.dart
// @description "I'm Hungry" page with AI-powered recommendation teaser,
//   progress card, and quick-action buttons. Styled to match the template
//   design pattern: cream background, custom SafeArea header, brown text,
//   green accents, and GoogleFonts.plusJakartaSans throughout.
// @modified 2026-03-11

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/ux_components.dart';

// ---------------------------------------------------------------------------
// HungryPage
// ---------------------------------------------------------------------------

class HungryPage extends ConsumerWidget {
  const HungryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      // No standard AppBar -- custom header inside SafeArea
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(UXComponents.paddingL),
          child: Column(
            children: [
              // Custom page header
              _buildHeader(context),

              const SizedBox(height: UXComponents.paddingM),

              // Main content: hero section
              Expanded(
                child: UXFadeIn(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon container: green/10 bg, rounded-full
                      _buildHeroIcon(),

                      const SizedBox(height: UXComponents.paddingXL),

                      // Title
                      Text(
                        'AI-Powered Recommendations',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.brownText,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: UXComponents.paddingM),

                      // Subtitle / description
                      Text(
                        'Get personalized restaurant recommendations based on your preferences, budget, and location',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.brownTextLight,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: UXComponents.paddingXL),

                      // Progress indicator card
                      _buildProgressCard(context),
                    ],
                  ),
                ),
              ),

              // Bottom quick-action section
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Custom header (replaces AppBar)
  // -------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'I\'M HUNGRY',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryGreen,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Hero icon container: green/10 bg, rounded-full, restaurant_menu icon
  // -------------------------------------------------------------------------

  Widget _buildHeroIcon() {
    return Hero(
      tag: 'hungry_icon',
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.restaurant_menu,
          size: 60,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Progress card: white/40 bg, rounded-16, subtle border, green track
  // -------------------------------------------------------------------------

  Widget _buildProgressCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(UXComponents.paddingM),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.construction,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: UXComponents.paddingS),
              Expanded(
                child: Text(
                  'Smart Recommendations Available',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: UXComponents.paddingS),

          // Green track progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.85, // 85% complete - most features available
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryGreen,
              ),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: UXComponents.paddingS),

          Text(
            'Personalized recommendations based on your preferences',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.brownTextLight,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Quick actions: "Meanwhile, you can:" + secondary buttons
  // -------------------------------------------------------------------------

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Meanwhile, you can:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.brownText,
          ),
        ),

        const SizedBox(height: UXComponents.paddingM),

        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context: context,
                label: 'Explore Map',
                icon: Icons.map,
                semanticLabel: 'Explore restaurants on interactive map',
                onPressed: () => context.go('/discover'),
              ),
            ),
            const SizedBox(width: UXComponents.paddingM),
            Expanded(
              child: _buildActionButton(
                context: context,
                label: 'Track Meals',
                icon: Icons.add_circle_outline,
                semanticLabel: 'Start tracking your meals',
                onPressed: () => _showTrackingInfo(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Secondary action button styled with green accent
  // -------------------------------------------------------------------------

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String semanticLabel,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: UXComponents.minTouchTarget + 8,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Tracking info dialog
  // -------------------------------------------------------------------------

  void _showTrackingInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.creamBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Start Tracking',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.brownText,
          ),
        ),
        content: Text(
          'Ready to start tracking your meals? Start logging your dining experiences and build your food investment portfolio today!',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.brownTextLight,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Maybe Later',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.brownTextLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Navigate to track page - handled by main scaffold FAB
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Let\'s Go!',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
