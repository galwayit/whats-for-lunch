import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/meal.dart';
import '../providers/meal_providers.dart';

class TrackPage extends ConsumerStatefulWidget {
  const TrackPage({super.key});

  @override
  ConsumerState<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends ConsumerState<TrackPage> {
  final TextEditingController _restaurantController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedMealType = 'lunch';
  bool _isLogging = false;

  @override
  void dispose() {
    _restaurantController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentMealsAsync = ref.watch(recentMealsProvider);

    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSimpleMealEntry(),
            Expanded(
              child: _buildRecentMeals(recentMealsAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Meal Tracker',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.brownText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMealEntry() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.brownText.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.add_circle, color: AppTheme.ctaOrange, size: 22),
              const SizedBox(width: 8),
              Text(
                'Quick Meal Log',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Meal type selector
          Text(
            'MEAL TYPE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.brownText.withValues(alpha: 0.6),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['breakfast', 'lunch', 'dinner', 'snack'].map((type) {
              final isSelected = _selectedMealType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMealType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.ctaOrange
                            : AppTheme.ctaOrange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: AppTheme.ctaOrange.withValues(alpha: isSelected ? 1 : 0.2),
                        ),
                      ),
                      child: Text(
                        type == 'breakfast'
                            ? 'Brkfst'
                            : type[0].toUpperCase() + type.substring(1),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.ctaOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Restaurant name
          SizedBox(
            height: 50,
            child: TextField(
              controller: _restaurantController,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.brownText),
              decoration: InputDecoration(
                hintText: 'Where did you eat?',
                prefixIcon: Icon(Icons.restaurant, color: AppTheme.ctaOrange.withValues(alpha: 0.7), size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Cost input
          SizedBox(
            height: 50,
            child: TextField(
              controller: _costController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.brownText),
              decoration: InputDecoration(
                hintText: '\$0.00',
                prefixIcon: Icon(Icons.attach_money, color: AppTheme.successGreen.withValues(alpha: 0.7), size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Log button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLogging ? null : _logMeal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                disabledBackgroundColor: AppTheme.brownTextLight.withValues(alpha: 0.3),
              ),
              child: _isLogging
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Log This Meal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMeals(AsyncValue<List<Meal>> recentMealsAsync) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.brownText.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppTheme.primaryGreen, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Recent Meals',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: recentMealsAsync.when(
              data: (meals) =>
                  meals.isEmpty ? _buildEmptyMealsState() : _buildMealsList(meals),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
              error: (error, _) => Center(
                child: Text(
                  'Unable to load recent meals',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.brownTextLight),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList(List<Meal> meals) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getMealTypeColor(meal.mealType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getMealTypeIcon(meal.mealType),
                  color: _getMealTypeColor(meal.mealType),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.restaurantName ?? 'Unknown Restaurant',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brownText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatMealTime(meal.date),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.brownTextLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${meal.cost.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyMealsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 48,
            color: AppTheme.brownTextLight.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No meals logged yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.brownText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging to track your dining journey',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.brownTextLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return const Color(0xFFFFC107);
      case 'lunch':
        return AppTheme.ctaOrange;
      case 'dinner':
        return const Color(0xFF9C27B0);
      case 'snack':
        return AppTheme.successGreen;
      default:
        return const Color(0xFF2196F3);
    }
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.local_cafe;
      default:
        return Icons.restaurant;
    }
  }

  String _formatMealTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  Future<void> _logMeal() async {
    if (_restaurantController.text.trim().isEmpty) {
      _showMessage('Please enter a restaurant name');
      return;
    }

    final costText = _costController.text.trim();
    if (costText.isEmpty) {
      _showMessage('Please enter the cost');
      return;
    }

    final cost = double.tryParse(costText);
    if (cost == null || cost < 0) {
      _showMessage('Please enter a valid cost');
      return;
    }

    setState(() => _isLogging = true);

    try {
      final formState = MealFormState(
        restaurantName: _restaurantController.text.trim(),
        cost: cost,
        date: DateTime.now(),
        mealType: _selectedMealType,
        notes: _notesController.text.trim(),
        lastSaved: DateTime.now(),
      );

      final submitMeal = ref.read(submitMealProvider);
      await submitMeal(formState);

      _restaurantController.clear();
      _costController.clear();
      _notesController.clear();

      ref.invalidate(recentMealsProvider);

      HapticFeedback.lightImpact();
      _showMessage('Meal logged successfully!', isSuccess: true);
    } catch (e) {
      _showMessage('Failed to log meal: $e');
    } finally {
      setState(() => _isLogging = false);
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isSuccess ? AppTheme.primaryGreen : AppTheme.ctaOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
