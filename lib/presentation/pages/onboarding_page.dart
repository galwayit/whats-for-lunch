import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../domain/entities/user_preferences.dart';
import '../providers/simple_providers.dart';
import '../widgets/ux_components.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  late AnimationController _fadeController;
  
  int _currentPage = 0;
  bool _isLoading = false;
  UserPreferences _preferences = const UserPreferences();
  
  final List<String> _pageDescriptions = [
    'Welcome to your personalized lunch companion',
    'Let\'s get to know you better',
    'Set your dining preferences',
    'You\'re ready to discover great food!'
  ];

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
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: UXLoadingOverlay(
        isLoading: _isLoading,
        message: 'Setting up your profile...',
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _fadeController.reset();
                    _fadeController.forward();
                    // Haptic feedback for page changes
                    HapticFeedback.lightImpact();
                  },
                  children: [
                    _buildWelcomePage(),
                    _buildNameInputPage(),
                    _buildPreferencesPage(),
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

  Widget _buildProgressIndicator() {
    return UXProgressIndicator(
      currentStep: _currentPage,
      totalSteps: 4,
    );
  }

  Widget _buildWelcomePage() {
    return UXFadeIn(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'app_icon',
              child: Icon(
                Icons.restaurant_menu,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: UXComponents.paddingXL),
            Text(
              'What We Have For Lunch',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UXComponents.paddingM),
            Text(
              _pageDescriptions[_currentPage],
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UXComponents.paddingXXL),
            UXPrimaryButton(
              onPressed: () => _nextPage(),
              text: 'Get Started',
              icon: Icons.arrow_forward,
              semanticLabel: 'Start onboarding process',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameInputPage() {
    return UXFadeIn(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'What should we call you?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UXComponents.paddingM),
            Text(
              _pageDescriptions[_currentPage],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UXComponents.paddingXL),
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
            const SizedBox(height: UXComponents.paddingXXL),
            Row(
              children: [
                Expanded(
                  child: UXSecondaryButton(
                    onPressed: () => _previousPage(),
                    text: 'Back',
                    icon: Icons.arrow_back,
                    semanticLabel: 'Go back to welcome page',
                  ),
                ),
                const SizedBox(width: UXComponents.paddingM),
                Expanded(
                  flex: 2,
                  child: UXPrimaryButton(
                    onPressed: _nameController.text.trim().isNotEmpty 
                        ? () => _nextPage() 
                        : null,
                    text: 'Next',
                    icon: Icons.arrow_forward,
                    semanticLabel: 'Continue to preferences setup',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesPage() {
    return UXFadeIn(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us your preferences',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: UXComponents.paddingS),
            Text(
              _pageDescriptions[_currentPage],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: UXComponents.paddingL),
            Expanded(
              child: ListView(
                children: [
                  _buildBudgetSelector(),
                  const SizedBox(height: UXComponents.paddingL),
                  _buildDistanceSelector(),
                  const SizedBox(height: UXComponents.paddingL),
                  _buildChainsToggle(),
                  const SizedBox(height: UXComponents.paddingXL),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: UXSecondaryButton(
                    onPressed: () => _previousPage(),
                    text: 'Back',
                    icon: Icons.arrow_back,
                    semanticLabel: 'Go back to name input',
                  ),
                ),
                const SizedBox(width: UXComponents.paddingM),
                Expanded(
                  flex: 2,
                  child: UXPrimaryButton(
                    onPressed: () => _nextPage(),
                    text: 'Next',
                    icon: Icons.arrow_forward,
                    semanticLabel: 'Continue to completion page',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSelector() {
    const List<String> budgetDescriptions = [
      'Budget-friendly (\$5-15)',
      'Moderate (\$15-30)', 
      'Upscale (\$30-50)',
      'Fine dining (\$50+)'
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Level',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Select your typical spending range per meal',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: List.generate(4, (index) {
            final level = index + 1;
            final symbols = '\$' * level;
            final isSelected = _preferences.budgetLevel == level;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
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
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          symbols,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        budgetDescriptions[index],
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDistanceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Max Travel Distance: ${_preferences.maxTravelDistance.toStringAsFixed(1)} km',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: _preferences.maxTravelDistance,
          min: 1.0,
          max: 20.0,
          divisions: 19,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences.copyWith(maxTravelDistance: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildChainsToggle() {
    return SwitchListTile(
      title: const Text('Include Chain Restaurants'),
      subtitle: const Text('McDonald\'s, Subway, etc.'),
      value: _preferences.includeChains,
      onChanged: (value) {
        setState(() {
          _preferences = _preferences.copyWith(includeChains: value);
        });
      },
    );
  }

  Widget _buildCompletePage() {
    return UXFadeIn(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'completion_icon',
              child: Icon(
                Icons.check_circle,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: UXComponents.paddingXL),
            Text(
              'You\'re all set!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UXComponents.paddingM),
            Text(
              _pageDescriptions[_currentPage],
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UXComponents.paddingL),
            // Summary of preferences
            UXCard(
              padding: const EdgeInsets.all(UXComponents.paddingM),
              child: Column(
                children: [
                  Text(
                    'Your Preferences',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: UXComponents.paddingS),
                  _buildPreferenceSummary(),
                ],
              ),
            ),
            const SizedBox(height: UXComponents.paddingXXL),
            UXPrimaryButton(
              onPressed: () => _completeOnboarding(),
              text: 'Start Using App',
              icon: Icons.launch,
              isLoading: _isLoading,
              semanticLabel: 'Complete onboarding and start using the app',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSummary() {
    final budgetLabels = ['Budget', 'Moderate', 'Upscale', 'Fine dining'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Budget:', style: Theme.of(context).textTheme.bodyMedium),
            Text(
              budgetLabels[_preferences.budgetLevel - 1],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: UXComponents.paddingS),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Max Distance:', style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '${_preferences.maxTravelDistance.toStringAsFixed(1)} km',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: UXComponents.paddingS),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Chain Restaurants:', style: Theme.of(context).textTheme.bodyMedium),
            Text(
              _preferences.includeChains ? 'Included' : 'Excluded',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _nextPage() {
    if (_currentPage < 3) {
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

  Future<void> _completeOnboarding() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Provide haptic feedback for successful action
      HapticFeedback.mediumImpact();
      
      // Create user with preferences
      final createUser = ref.read(createUserProvider);
      await createUser(_nameController.text.trim());
      
      // Update preferences
      ref.read(userPreferencesProvider.notifier).updatePreferences(_preferences);
      
      // Add slight delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate to main app
      if (mounted) {
        context.go(AppRoutes.hungry);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        // Use heavy haptic feedback for errors
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
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