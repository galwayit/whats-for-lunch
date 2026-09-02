// Onboarding flow with 5 steps: welcome, name input, preferences,
// dietary selection, and completion. Styled to match the template design with
// cream background, green primary, brown text, and card-based layouts.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_routes.dart';
import '../../domain/entities/user_preferences.dart';
import '../providers/simple_providers.dart' as simple;
import '../widgets/ux_components.dart';

// ---------------------------------------------------------------------------
// Design tokens (matching the HTML template)
// ---------------------------------------------------------------------------
const _kCreamBg = Color(0xFFFFF8E7);
const _kPrimaryGreen = Color(0xFF2F7F3F);
const _kBrownText = Color(0xFF6B4E3D);
const _kOrangeAccent = Color(0xFFFF6B35);

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _customDietController = TextEditingController();
  late AnimationController _fadeController;

  int _currentPage = 0;
  bool _isLoading = false;
  UserPreferences _preferences = const UserPreferences();

  /// Short descriptions shown beside the step counter in the progress bar.
  final List<String> _stepDescriptions = [
    'Getting Started',
    'Your Name',
    'Budget & Distance',
    'Dietary Needs',
    'All Done!',
  ];

  /// Longer descriptions used as subtitles inside each step page.
  final List<String> _pageDescriptions = [
    'Discover and plan your daily meals with ease and joy.',
    'Let\'s get to know you better.',
    'Set your budget and distance preferences.',
    'Tell us about your dietary needs.',
    'You\'re ready to discover great food!',
  ];

  // -----------------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _customDietController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Text style helpers
  // -----------------------------------------------------------------------

  TextStyle _jakartaSans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? _kBrownText,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCreamBg,
      body: UXLoadingOverlay(
        isLoading: _isLoading,
        message: 'Setting up your profile...',
        child: SafeArea(
          child: Column(
            children: [
              // Top app bar + progress
              _buildTopAppBar(),
              _buildProgressSection(),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _fadeController.reset();
                    _fadeController.forward();
                    HapticFeedback.lightImpact();
                  },
                  children: [
                    _buildWelcomePage(),
                    _buildNameInputPage(),
                    _buildPreferencesPage(),
                    _buildDietaryPage(),
                    _buildCompletePage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Top App Bar
  // -----------------------------------------------------------------------

  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          // Back button (only visible after page 0)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _currentPage > 0 ? () => _previousPage() : null,
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  Icons.arrow_back,
                  color: _currentPage > 0
                      ? _kBrownText
                      : _kBrownText.withValues(alpha: 0.3),
                  size: 22,
                ),
              ),
            ),
          ),

          // Centered title
          Expanded(
            child: Text(
              'Onboarding',
              textAlign: TextAlign.center,
              style: _jakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kBrownText,
              ),
            ),
          ),

          // Spacer for centering
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Progress bar section
  // -----------------------------------------------------------------------

  Widget _buildProgressSection() {
    final double progressFraction = (_currentPage + 1) / 5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          // "STEP X OF 5" label + description
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP ${_currentPage + 1} OF 5',
                style: _jakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                _stepDescriptions[_currentPage],
                style: _jakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kBrownText.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress track
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: _kPrimaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                widthFactor: progressFraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: _kPrimaryGreen,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Reusable semi-transparent card wrapper
  // -----------------------------------------------------------------------

  Widget _templateCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _kBrownText.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // -----------------------------------------------------------------------
  // Reusable green CTA button (full-width, rounded-xl, shadow-lg)
  // -----------------------------------------------------------------------

  Widget _greenButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    final enabled = onPressed != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: enabled
            ? _kPrimaryGreen
            : _kPrimaryGreen.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        elevation: enabled ? 6 : 0,
        shadowColor: _kPrimaryGreen.withValues(alpha: 0.4),
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed.call();
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  Text(
                    text,
                    style: _jakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white, size: 24),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Reusable back button (outline / secondary style matching template)
  // -----------------------------------------------------------------------

  Widget _outlineBackButton({required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _kBrownText.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back, color: _kBrownText, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Back',
                  style: _jakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kBrownText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =======================================================================
  //  STEP 1 -- Welcome Page
  // =======================================================================

  Widget _buildWelcomePage() {
    return UXFadeIn(
      child: Column(
        children: [
          // Scrollable centre area
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _templateCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon circle
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: _kPrimaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.restaurant_menu,
                            size: 60,
                            color: _kPrimaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'Welcome to\nWhat We Have For Lunch',
                        textAlign: TextAlign.center,
                        style: _jakartaSans(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: _kBrownText,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subtitle
                      Text(
                        _pageDescriptions[0],
                        textAlign: TextAlign.center,
                        style: _jakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: _kBrownText.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Fixed footer CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Column(
              children: [
                _greenButton(
                  text: 'Get Started',
                  icon: Icons.chevron_right,
                  onPressed: () => _nextPage(),
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: _jakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kBrownText.withValues(alpha: 0.6),
                    ),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: _jakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kPrimaryGreen,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  //  STEP 2 -- Name Input Page
  // =======================================================================

  Widget _buildNameInputPage() {
    return UXFadeIn(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _templateCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon circle
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _kPrimaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_outline,
                            size: 48,
                            color: _kPrimaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'What should we call you?',
                        textAlign: TextAlign.center,
                        style: _jakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _kBrownText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pageDescriptions[1],
                        textAlign: TextAlign.center,
                        style: _jakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _kBrownText.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 28),

                      UXTextInput(
                        controller: _nameController,
                        label: 'Your Name',
                        hint: 'Enter your first name',
                        helperText: 'This helps us personalize your experience',
                        textInputAction: TextInputAction.next,
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                        onSubmitted: () {
                          if (_nameController.text.trim().isNotEmpty) {
                            _nextPage();
                          }
                        },
                        semanticLabel: 'Enter your name for personalization',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom buttons
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nameController,
            builder: (context, value, child) {
              final isNameValid = value.text.trim().length >= 2;
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _outlineBackButton(onPressed: () => _previousPage()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _greenButton(
                        text: 'Next',
                        icon: Icons.chevron_right,
                        onPressed: isNameValid ? () => _nextPage() : null,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =======================================================================
  //  STEP 3 -- Preferences (Budget & Distance)
  // =======================================================================

  Widget _buildPreferencesPage() {
    return UXFadeIn(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              children: [
                // Section header inside a card
                _templateCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon circle
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _kPrimaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 36,
                            color: _kPrimaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Budget & Distance',
                        style: _jakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _kBrownText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _pageDescriptions[2],
                        style: _jakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _kBrownText.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Budget selector
                _templateCard(
                  padding: const EdgeInsets.all(24),
                  child: _buildBudgetSelector(),
                ),
                const SizedBox(height: 16),

                // Distance selector
                _templateCard(
                  padding: const EdgeInsets.all(24),
                  child: _buildDistanceSelector(),
                ),
                const SizedBox(height: 16),

                // Chain toggle
                _templateCard(
                  padding: const EdgeInsets.all(24),
                  child: _buildChainsToggle(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: _outlineBackButton(onPressed: () => _previousPage()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _greenButton(
                    text: 'Next',
                    icon: Icons.chevron_right,
                    onPressed: () => _nextPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSelector() {
    const List<String> budgetDescriptions = [
      'Budget-friendly (\$5-15)',
      'Moderate (\$15-30)',
      'Upscale (\$30-50)',
      'Fine dining (\$50+)',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Level',
          style: _jakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kBrownText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select your typical spending range per meal',
          style: _jakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _kBrownText.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(4, (index) {
          final level = index + 1;
          final symbols = '\$' * level;
          final isSelected = _preferences.budgetLevel == level;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                setState(() {
                  _preferences = _preferences.copyWith(budgetLevel: level);
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? _kPrimaryGreen
                        : _kBrownText.withValues(alpha: 0.15),
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? _kPrimaryGreen.withValues(alpha: 0.08)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _kPrimaryGreen
                            : _kBrownText.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        symbols,
                        style: _jakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : _kBrownText.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        budgetDescriptions[index],
                        style: _jakartaSans(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected ? _kPrimaryGreen : _kBrownText,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle,
                          color: _kPrimaryGreen, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDistanceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Max Travel Distance',
              style: _jakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kBrownText,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _kPrimaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_preferences.maxTravelDistance.toStringAsFixed(1)} km',
                style: _jakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kPrimaryGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _kPrimaryGreen,
            inactiveTrackColor: _kPrimaryGreen.withValues(alpha: 0.15),
            thumbColor: _kPrimaryGreen,
            overlayColor: _kPrimaryGreen.withValues(alpha: 0.12),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: Slider(
            value: _preferences.maxTravelDistance,
            min: 1.0,
            max: 20.0,
            divisions: 19,
            onChanged: (value) {
              setState(() {
                _preferences =
                    _preferences.copyWith(maxTravelDistance: value);
              });
            },
          ),
        ),
        // Min/max labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 km',
                style: _jakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kBrownText.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '20 km',
                style: _jakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kBrownText.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChainsToggle() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Include Chain Restaurants',
                style: _jakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kBrownText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'McDonald\'s, Subway, etc.',
                style: _jakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kBrownText.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _preferences.includeChains,
          activeTrackColor: _kPrimaryGreen,
          activeThumbColor: Colors.white,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences.copyWith(includeChains: value);
            });
          },
        ),
      ],
    );
  }

  // =======================================================================
  //  STEP 4 -- Dietary Page
  // =======================================================================

  Widget _buildDietaryPage() {
    const List<String> commonDiets = [
      'No restrictions',
      'Vegetarian',
      'Vegan',
      'Gluten-free',
      'Keto',
      'Paleo',
      'Dairy-free',
      'Nut allergies',
      'Cannot find my diet',
    ];

    return UXFadeIn(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              children: [
                // Header card
                _templateCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _kOrangeAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.eco_outlined,
                            size: 36,
                            color: _kOrangeAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Dietary Preferences',
                        style: _jakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _kBrownText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _pageDescriptions[3],
                        style: _jakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _kBrownText.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Diet options in a card
                _templateCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select your dietary needs (multiple selections allowed):',
                        style: _jakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kBrownText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...commonDiets.map((diet) => _buildDietOption(diet)),

                      // Custom diet input (only show if "Cannot find my diet" is selected)
                      if (_preferences.dietaryRestrictions
                          .contains('Cannot find my diet')) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Please specify your dietary needs:',
                          style: _jakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kBrownText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        UXTextInput(
                          controller: _customDietController,
                          label: 'Custom dietary requirements',
                          hint: 'e.g., Low sodium, Mediterranean, etc.',
                          helperText:
                              'Describe any specific dietary needs or restrictions',
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (_preferences.dietaryRestrictions
                                    .contains('Cannot find my diet') &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please specify your dietary needs';
                            }
                            return null;
                          },
                          semanticLabel: 'Enter custom dietary requirements',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: _outlineBackButton(onPressed: () => _previousPage()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _greenButton(
                    text: 'Next',
                    icon: Icons.chevron_right,
                    onPressed:
                        _canProceedFromDietary() ? () => _nextPage() : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietOption(String diet) {
    final isSelected = _preferences.dietaryRestrictions.contains(diet);
    final isCustom = diet == 'Cannot find my diet';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            List<String> newRestrictions =
                List.from(_preferences.dietaryRestrictions);

            if (diet == 'No restrictions') {
              if (isSelected) {
                newRestrictions.clear();
              } else {
                newRestrictions = ['No restrictions'];
                _customDietController.clear();
              }
            } else {
              newRestrictions.remove('No restrictions');

              if (isSelected) {
                newRestrictions.remove(diet);
                if (isCustom) {
                  _customDietController.clear();
                }
              } else {
                newRestrictions.add(diet);
              }
            }

            _preferences =
                _preferences.copyWith(dietaryRestrictions: newRestrictions);
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? _kOrangeAccent
                  : _kBrownText.withValues(alpha: 0.15),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? _kOrangeAccent.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? _kOrangeAccent
                        : _kBrownText.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  color: isSelected ? _kOrangeAccent : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  diet,
                  style: _jakartaSans(
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? _kOrangeAccent : _kBrownText,
                  ),
                ),
              ),
              if (isCustom)
                Icon(
                  Icons.edit,
                  size: 18,
                  color: isSelected
                      ? _kOrangeAccent
                      : _kBrownText.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canProceedFromDietary() {
    if (_preferences.dietaryRestrictions.isEmpty ||
        _preferences.dietaryRestrictions.contains('No restrictions')) {
      return true;
    }

    if (_preferences.dietaryRestrictions.contains('Cannot find my diet')) {
      return _customDietController.text.trim().isNotEmpty;
    }

    return true;
  }

  // =======================================================================
  //  STEP 5 -- Completion Page
  // =======================================================================

  Widget _buildCompletePage() {
    return UXFadeIn(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Completion hero card
                    _templateCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: _kPrimaryGreen.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_circle,
                                size: 60,
                                color: _kPrimaryGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'You\'re all set!',
                            textAlign: TextAlign.center,
                            style: _jakartaSans(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: _kBrownText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _pageDescriptions[4],
                            textAlign: TextAlign.center,
                            style: _jakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _kBrownText.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Preference summary card
                    _templateCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Your Preferences',
                            style: _jakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _kBrownText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPreferenceSummary(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: _greenButton(
              text: 'Start Using App',
              icon: Icons.chevron_right,
              isLoading: _isLoading,
              onPressed: () => _completeOnboarding(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSummary() {
    final budgetLabels = ['Budget', 'Moderate', 'Upscale', 'Fine dining'];
    final divider = Divider(
      color: _kBrownText.withValues(alpha: 0.1),
      height: 24,
    );

    Widget row(String label, String value) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _jakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kBrownText.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: _jakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kBrownText,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        row('Budget', budgetLabels[_preferences.budgetLevel - 1]),
        divider,
        row('Max Distance',
            '${_preferences.maxTravelDistance.toStringAsFixed(1)} km'),
        divider,
        row('Chain Restaurants',
            _preferences.includeChains ? 'Included' : 'Excluded'),
        divider,
        row('Dietary', _getDietarySummary()),
      ],
    );
  }

  String _getDietarySummary() {
    if (_preferences.dietaryRestrictions.isEmpty) {
      return 'No restrictions';
    }

    if (_preferences.dietaryRestrictions.contains('No restrictions')) {
      return 'No restrictions';
    }

    List<String> displayRestrictions =
        List.from(_preferences.dietaryRestrictions);

    // Replace the placeholder with the actual custom text
    if (displayRestrictions.contains('Cannot find my diet') &&
        _customDietController.text.trim().isNotEmpty) {
      displayRestrictions.remove('Cannot find my diet');
      displayRestrictions.add(_customDietController.text.trim());
    }

    if (displayRestrictions.length == 1) {
      return displayRestrictions.first;
    } else if (displayRestrictions.length <= 3) {
      return displayRestrictions.join(', ');
    } else {
      return '${displayRestrictions.take(2).join(', ')} & ${displayRestrictions.length - 2} more';
    }
  }

  // -----------------------------------------------------------------------
  // Navigation helpers
  // -----------------------------------------------------------------------

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // -----------------------------------------------------------------------
  // Complete onboarding -- persist user + preferences, navigate to app
  // -----------------------------------------------------------------------

  Future<void> _completeOnboarding() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      HapticFeedback.mediumImpact();

      // Create user via provider
      final createUser = ref.read(simple.createUserProvider);
      await createUser(_nameController.text.trim());

      // Process dietary preferences (replace placeholder with custom text)
      List<String> finalDietaryRestrictions =
          List.from(_preferences.dietaryRestrictions);
      if (finalDietaryRestrictions.contains('Cannot find my diet') &&
          _customDietController.text.trim().isNotEmpty) {
        finalDietaryRestrictions.remove('Cannot find my diet');
        finalDietaryRestrictions.add(_customDietController.text.trim());
      }

      final finalPreferences = _preferences.copyWith(
        dietaryRestrictions: finalDietaryRestrictions,
      );

      // Persist preferences
      await ref
          .read(simple.userPreferencesProvider.notifier)
          .updatePreferences(finalPreferences);

      // Brief delay for UX polish
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        context.go(AppRoutes.hungry);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        HapticFeedback.heavyImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error creating profile. Please try again.',
                    style: _jakartaSans(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _completeOnboarding(),
            ),
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Animated fractionally-sized box for smooth progress bar transitions
// ---------------------------------------------------------------------------

class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final double widthFactor;
  final Widget child;

  const AnimatedFractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.child,
    required super.duration,
    super.curve,
  });

  @override
  AnimatedWidgetBaseState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      child: widget.child,
    );
  }
}
