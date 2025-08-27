import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/budget_providers.dart';
import '../providers/meal_providers.dart';
import '../providers/photo_providers.dart';
import '../providers/simple_providers.dart';
import 'ux_components.dart';
import 'ux_investment_components.dart';
import 'photo_components.dart';
import 'ai_photo_analysis_widget.dart';
import '../../services/photo_service.dart';
import '../../services/ai_photo_analysis_service.dart';

/// Comprehensive meal entry form with auto-save, validation, and positive psychology messaging
class MealEntryForm extends ConsumerStatefulWidget {
  final VoidCallback? onSubmitted;
  final bool autofocus;

  const MealEntryForm({
    super.key,
    this.onSubmitted,
    this.autofocus = true,
  });

  @override
  ConsumerState<MealEntryForm> createState() => _MealEntryFormState();
}

class _MealEntryFormState extends ConsumerState<MealEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  
  Timer? _autoSaveTimer;
  bool _isSubmitting = false;
  List<PhotoResult> _selectedPhotos = [];
  MealAnalysisResult? _aiAnalysisResult;

  @override
  void initState() {
    super.initState();
    
    // Apply smart defaults when form loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mealFormProvider.notifier).applySmartDefaults();
    });

    // Set up listeners for auto-save
    _restaurantController.addListener(_onFieldChanged);
    _costController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _restaurantController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    // Debounce auto-save to avoid excessive calls
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _updateFormState();
    });
  }

  void _updateFormState() {
    final notifier = ref.read(mealFormProvider.notifier);
    
    notifier.updateRestaurantName(_restaurantController.text);
    notifier.updateCost(double.tryParse(_costController.text));
    notifier.updateNotes(_notesController.text);
  }

  String? _validateRestaurantName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please tell us where you enjoyed this experience';
    }
    return null;
  }

  String? _validateCost(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your investment amount';
    }
    
    final cost = double.tryParse(value);
    if (cost == null || cost <= 0) {
      return 'Please enter a valid amount';
    }
    
    if (cost > 1000) {
      return 'That\'s quite an investment! Please double-check the amount.';
    }
    
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final submitMeal = ref.read(submitMealProvider);
      final formState = ref.read(mealFormProvider);
      
      final success = await submitMeal(formState);
      
      if (success && mounted) {
        HapticFeedback.heavyImpact();
        
        // Clear form
        ref.read(mealFormProvider.notifier).clearForm();
        _restaurantController.clear();
        _costController.clear();
        _notesController.clear();
        setState(() {
          _selectedPhotos.clear();
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Experience logged successfully! 🎉',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        widget.onSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.toString().replaceAll('Exception: ', ''),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(mealFormProvider);
    // final budgetImpact = ref.watch(budgetImpactProvider); // Legacy - replaced with investmentImpact
    final mealCategories = ref.watch(mealCategoriesProvider);
    final weeklyInvestment = ref.watch(weeklyInvestmentProvider);
    final investmentImpact = ref.watch(mealInvestmentImpactProvider(formState.cost));

    // Convert meal categories to UX component format
    final categoryOptions = mealCategories.map((category) => 
      MealCategoryOption(
        id: category.id,
        name: category.name,
        description: category.description,
        icon: _getIconFromString(category.icon),
        suggestedBudget: category.suggestedBudget,
      )
    ).toList();

    return UXLoadingOverlay(
      isLoading: _isSubmitting,
      message: 'Saving your experience...',
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(UXComponents.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with positive messaging
              _buildHeader(context),
              const SizedBox(height: UXComponents.paddingXL),

              // Restaurant/Place input
              UXRestaurantInput(
                controller: _restaurantController,
                autofocus: widget.autofocus,
                validator: _validateRestaurantName,
                onChanged: (value) {
                  ref.read(mealFormProvider.notifier).updateRestaurantName(value);
                },
              ),
              const SizedBox(height: UXComponents.paddingL),

              // Cost input with real-time investment guidance
              UXCurrencyInput(
                controller: _costController,
                validator: _validateCost,
                positiveMessage: investmentImpact?.message ?? 'Every experience is an investment in your happiness',
                onChanged: (value) {
                  ref.read(mealFormProvider.notifier).updateCost(value);
                },
              ),
              const SizedBox(height: UXComponents.paddingL),

              // Real-time investment impact guidance
              if (investmentImpact != null) ...[
                UXInvestmentGuidance(
                  currentCost: investmentImpact.mealCost,
                  remainingCapacity: investmentImpact.projectedRemaining,
                  guidanceLevel: investmentImpact.guidanceLevel,
                  onOptimize: investmentImpact.exceedsCapacity ? () {
                    _showOptimizationSuggestions(context, investmentImpact);
                  } : null,
                ),
                const SizedBox(height: UXComponents.paddingL),
              ],
              
              // Weekly capacity preview if cost entered
              if (formState.cost != null && formState.cost! > 0 && !weeklyInvestment.isLoading) ...[
                _buildCapacityPreview(context, weeklyInvestment, formState.cost!),
                const SizedBox(height: UXComponents.paddingL),
              ],

              // Experience type selector
              UXMealCategorySelector(
                selectedCategory: formState.mealType,
                categories: categoryOptions,
                onChanged: (category) {
                  ref.read(mealFormProvider.notifier).updateMealType(category);
                },
              ),
              const SizedBox(height: UXComponents.paddingL),

              // Date and time picker
              UXDateTimePicker(
                selectedDateTime: formState.date,
                onChanged: (dateTime) {
                  ref.read(mealFormProvider.notifier).updateDate(dateTime);
                },
              ),
              const SizedBox(height: UXComponents.paddingL),

              // Notes input (optional)
              UXTextInput(
                controller: _notesController,
                label: 'Experience Notes (Optional)',
                hint: 'How was your experience? Any special memories?',
                onSubmitted: _submitForm,
              ),
              const SizedBox(height: UXComponents.paddingL),

              // Photo capture widget
              _buildPhotoSection(context, formState),
              const SizedBox(height: UXComponents.paddingL),

              // AI Photo Analysis widget
              if (_selectedPhotos.isNotEmpty) ...[
                AIPhotoAnalysisWidget(
                  photos: _selectedPhotos,
                  autoAnalyze: false,
                  onAnalysisComplete: _onAIAnalysisComplete,
                ),
                const SizedBox(height: UXComponents.paddingL),
              ],

              // Auto-save indicator
              _buildAutoSaveIndicator(context, formState),
              const SizedBox(height: UXComponents.paddingXL),

              // Submit button
              UXPrimaryButton(
                onPressed: formState.isValid && !_isSubmitting ? _submitForm : null,
                text: 'Log Experience',
                icon: Icons.celebration,
                isLoading: _isSubmitting,
                semanticLabel: 'Save your dining experience',
              ),
              const SizedBox(height: UXComponents.paddingM),

              // Secondary actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  UXSecondaryButton(
                    onPressed: () {
                      _formKey.currentState?.reset();
                      _restaurantController.clear();
                      _costController.clear();
                      _notesController.clear();
                      setState(() {
                        _selectedPhotos.clear();
                      });
                      ref.read(mealFormProvider.notifier).clearForm();
                      HapticFeedback.lightImpact();
                    },
                    text: 'Clear Form',
                    icon: Icons.refresh,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return UXFadeIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: UXComponents.paddingM),
              Expanded(
                child: Text(
                  'Log Your Experience',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UXComponents.paddingS),
          Text(
            'Every meal is an investment in your happiness and well-being. Let\'s capture this moment!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSaveIndicator(BuildContext context, MealFormState formState) {
    if (!formState.isDraft) {
      return const SizedBox.shrink();
    }

    final timeSinceLastSave = DateTime.now().difference(formState.lastSaved);
    final secondsAgo = timeSinceLastSave.inSeconds;

    String saveText;
    if (secondsAgo < 60) {
      saveText = 'Draft saved $secondsAgo seconds ago';
    } else {
      saveText = 'Draft saved ${timeSinceLastSave.inMinutes} minutes ago';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UXComponents.paddingM,
        vertical: UXComponents.paddingS,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primaryContainer,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_done,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: UXComponents.paddingS),
          Text(
            saveText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'delivery_dining':
        return Icons.delivery_dining;
      case 'takeout_dining':
        return Icons.takeout_dining;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_cafe':
        return Icons.local_cafe;
      default:
        return Icons.restaurant;
    }
  }

  Widget _buildCapacityPreview(BuildContext context, WeeklyInvestmentState weeklyState, double mealCost) {
    final theme = Theme.of(context);
    final projectedSpent = weeklyState.currentSpent + mealCost;
    final projectedRemaining = (weeklyState.weeklyCapacity - projectedSpent).clamp(0.0, double.infinity);
    final projectedProgress = projectedSpent / weeklyState.weeklyCapacity;
    
    Color previewColor;
    String previewLabel;
    
    if (projectedProgress < 0.7) {
      previewColor = Colors.green;
      previewLabel = 'On Track';
    } else if (projectedProgress < 0.9) {
      previewColor = Colors.orange;
      previewLabel = 'Watch Spending';
    } else {
      previewColor = Colors.red;
      previewLabel = 'Over Capacity';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: UXComponents.paddingS),
                Text(
                  'Weekly Capacity Preview',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UXComponents.paddingS,
                    vertical: UXComponents.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: previewColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: previewColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    previewLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: previewColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: UXComponents.paddingM),
            
            // Before and after comparison
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '\$${weeklyState.currentSpent.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                const SizedBox(width: UXComponents.paddingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'After This Meal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '\$${projectedSpent.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: previewColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: UXComponents.paddingS),
            
            // Progress bar
            LinearProgressIndicator(
              value: projectedProgress.clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(previewColor),
            ),
            const SizedBox(height: UXComponents.paddingS),
            
            // Remaining capacity
            Text(
              'Remaining capacity: \$${projectedRemaining.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptimizationSuggestions(BuildContext context, InvestmentImpact impact) {
    final suggestions = _generateOptimizationSuggestions(impact);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(UXComponents.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: UXComponents.paddingL),
              
              // Header
              Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: UXComponents.paddingS),
                  Text(
                    'Investment Optimization',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UXComponents.paddingS),
              Text(
                'Here are some suggestions to optimize your investment:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: UXComponents.paddingL),
              
              // Suggestions list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) => _buildSuggestionItem(
                    context,
                    suggestions[index],
                  ),
                ),
              ),
              
              // Action buttons
              const SizedBox(height: UXComponents.paddingL),
              Row(
                children: [
                  Expanded(
                    child: UXSecondaryButton(
                      onPressed: () => Navigator.of(context).pop(),
                      text: 'Keep Current Amount',
                    ),
                  ),
                  const SizedBox(width: UXComponents.paddingM),
                  Expanded(
                    child: UXPrimaryButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Apply suggested optimization
                        final suggestedAmount = _calculateOptimalAmount(impact);
                        _costController.text = suggestedAmount.toStringAsFixed(2);
                        ref.read(mealFormProvider.notifier).updateCost(suggestedAmount);
                      },
                      text: 'Apply Suggestion',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<OptimizationSuggestion> _generateOptimizationSuggestions(InvestmentImpact impact) {
    final suggestions = <OptimizationSuggestion>[];
    
    if (impact.exceedsCapacity) {
      suggestions.add(OptimizationSuggestion(
        icon: Icons.scale,
        title: 'Reduce Amount',
        description: 'Lower the cost to stay within your weekly capacity',
        action: 'Reduce to \$${impact.projectedRemaining.toStringAsFixed(2)}',
      ));
      
      suggestions.add(OptimizationSuggestion(
        icon: Icons.schedule,
        title: 'Plan for Next Week',
        description: 'Save this investment for next week when you have more capacity',
        action: 'Move to next week',
      ));
    }
    
    suggestions.add(OptimizationSuggestion(
      icon: Icons.group,
      title: 'Share the Experience',
      description: 'Split the cost with friends or family',
      action: 'Split cost in half',
    ));
    
    suggestions.add(OptimizationSuggestion(
      icon: Icons.restaurant_menu,
      title: 'Choose Different Option',
      description: 'Look for menu items that offer better value',
      action: 'Find alternatives',
    ));
    
    return suggestions;
  }

  double _calculateOptimalAmount(InvestmentImpact impact) {
    // Calculate amount that would use 80% of remaining capacity
    return (impact.projectedRemaining * 0.8).clamp(5.0, impact.mealCost);
  }

  Widget _buildPhotoSection(BuildContext context, MealFormState formState) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return const SizedBox.shrink();

    return PhotoCaptureWidget(
      userId: currentUser['id'] as int? ?? 0,
      photoType: PhotoTypes.meal,
      maxPhotos: 5,
      allowMultiple: true,
      customLabel: 'Capture Your Meal',
      onPhotosSelected: (photos) {
        setState(() {
          _selectedPhotos = photos;
        });
        
        // Show encouragement message when photos are added
        if (photos.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${photos.length} photo${photos.length == 1 ? '' : 's'} added! Your memories are captured.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  void _onAIAnalysisComplete(MealAnalysisResult result) {
    setState(() {
      _aiAnalysisResult = result;
    });

    // Auto-fill form fields based on AI analysis
    if (result.confidence > 0.6) {
      // Only auto-fill if confidence is decent
      if (_restaurantController.text.isEmpty && result.cuisineType.isNotEmpty) {
        _restaurantController.text = '${result.cuisineType} Restaurant';
        ref.read(mealFormProvider.notifier).updateRestaurantName(_restaurantController.text);
      }

      // Suggest meal type if not already set
      final currentMealType = ref.read(mealFormProvider).mealType;
      if (currentMealType.isEmpty || currentMealType == 'dining_out') {
        ref.read(mealFormProvider.notifier).updateMealType(result.mealType);
      }

      // Suggest cost if not already entered
      if (_costController.text.isEmpty && result.estimatedCost.isNotEmpty) {
        // Try to extract a reasonable cost estimate from the range
        final costMatch = RegExp(r'(\d+)').firstMatch(result.estimatedCost);
        if (costMatch != null) {
          final suggestedCost = double.tryParse(costMatch.group(1)!);
          if (suggestedCost != null && suggestedCost > 0 && suggestedCost < 100) {
            _costController.text = suggestedCost.toStringAsFixed(2);
            ref.read(mealFormProvider.notifier).updateCost(suggestedCost);
          }
        }
      }

      // Add AI insights to notes if notes are empty
      if (_notesController.text.isEmpty && result.description.isNotEmpty) {
        final aiNotes = '${result.description}\n\nAI identified: ${result.dishName}';
        if (result.suggestions.isNotEmpty) {
          final firstSuggestion = result.suggestions.first;
          _notesController.text = '$aiNotes\n\nTip: $firstSuggestion';
        } else {
          _notesController.text = aiNotes;
        }
        ref.read(mealFormProvider.notifier).updateNotes(_notesController.text);
      }

      // Show success message with AI insights
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI analyzed your photo: ${result.dishName} (${result.cuisineType})',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View Details',
              textColor: Colors.white,
              onPressed: () {
                // Could show a detailed analysis dialog
              },
            ),
          ),
        );
      }
    }
  }

  Widget _buildSuggestionItem(BuildContext context, OptimizationSuggestion suggestion) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: UXComponents.paddingS),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(UXComponents.paddingS),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            suggestion.icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          suggestion.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(suggestion.description),
        trailing: Text(
          suggestion.action,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class OptimizationSuggestion {
  final IconData icon;
  final String title;
  final String description;
  final String action;

  const OptimizationSuggestion({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
  });
}

/// Quick action buttons for common meal logging scenarios
class QuickActionButtons extends ConsumerWidget {
  final ValueChanged<String>? onQuickAction;

  const QuickActionButtons({
    super.key,
    this.onQuickAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: UXComponents.paddingS),
        Text(
          'Tap for instant logging with smart defaults',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: UXComponents.paddingM),
        Wrap(
          spacing: UXComponents.paddingS,
          runSpacing: UXComponents.paddingS,
          children: [
            _buildQuickActionChip(
              context,
              'Coffee Break',
              Icons.local_cafe,
              '\$5',
              () => _handleQuickAction(ref, 'coffee', 5.0),
            ),
            _buildQuickActionChip(
              context,
              'Quick Lunch',
              Icons.lunch_dining,
              '\$12',
              () => _handleQuickAction(ref, 'lunch', 12.0),
            ),
            _buildQuickActionChip(
              context,
              'Grocery Run',
              Icons.shopping_cart,
              '\$35',
              () => _handleQuickAction(ref, 'groceries', 35.0),
            ),
            _buildQuickActionChip(
              context,
              'Dinner Out',
              Icons.restaurant,
              '\$25',
              () => _handleQuickAction(ref, 'dinner', 25.0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(
    BuildContext context,
    String label,
    IconData icon,
    String price,
    VoidCallback onTap,
  ) {
    return Semantics(
      button: true,
      label: 'Quick log $label for $price',
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: UXComponents.paddingXS),
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  void _handleQuickAction(WidgetRef ref, String type, double cost) {
    final notifier = ref.read(mealFormProvider.notifier);
    
    // Set smart defaults based on action type
    switch (type) {
      case 'coffee':
        notifier.updateRestaurantName('Local Cafe');
        notifier.updateMealType('snack');
        break;
      case 'lunch':
        notifier.updateRestaurantName('Quick Service');
        notifier.updateMealType('lunch');
        break;
      case 'groceries':
        notifier.updateRestaurantName('Grocery Store');
        notifier.updateMealType('groceries');
        break;
      case 'dinner':
        notifier.updateRestaurantName('Restaurant');
        notifier.updateMealType('dining_out');
        break;
    }
    
    notifier.updateCost(cost);
    notifier.updateDate(DateTime.now());
    
    onQuickAction?.call(type);
  }
}