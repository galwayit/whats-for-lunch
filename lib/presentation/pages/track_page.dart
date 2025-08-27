import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/meal.dart';
import '../providers/meal_providers.dart';

/// Simplified meal tracking page focused on easy logging
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
      backgroundColor: const Color(0xFFFFF8E7), // Warm, appetizing cream
      appBar: AppBar(
        title: Text(
          'Log Your Meal',
          style: TextStyle(
            color: const Color(0xFF2E7D3E), // Fresh green
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Quick meal log - takes only the space it needs
          _buildSimpleMealEntry(),
          
          // Recent meals history - takes the rest of the screen
          Expanded(
            child: _buildRecentMeals(recentMealsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMealEntry() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D3E).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.add_circle,
                  color: const Color(0xFFFF6B35),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Meal Log',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D3E),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Meal type selector
            Text(
              'Meal Type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B4E3D),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: ['breakfast', 'lunch', 'dinner', 'snack'].map((type) {
                final isSelected = _selectedMealType == type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMealType = type;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? const Color(0xFFFF6B35) 
                            : const Color(0xFFFF6B35).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFF6B35).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          type == 'breakfast' ? 'Brkfst' : 
                          type.substring(0, 1).toUpperCase() + type.substring(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFFFF6B35),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 12),
            
            // Restaurant name input (more compact)
            SizedBox(
              height: 50,
              child: TextField(
                controller: _restaurantController,
                style: TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Restaurant',
                  hintText: 'Where did you eat?',
                  prefixIcon: Icon(Icons.restaurant, color: const Color(0xFFFF6B35), size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: const Color(0xFF2E7D3E).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: const Color(0xFFFF6B35), width: 2),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Cost input (more compact)
            SizedBox(
              height: 50,
              child: TextField(
                controller: _costController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Cost',
                  hintText: '\$0.00',
                  prefixIcon: Icon(Icons.attach_money, color: const Color(0xFF4CAF50), size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: const Color(0xFF2E7D3E).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: const Color(0xFFFF6B35), width: 2),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Log button (more compact)
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _isLogging ? null : _logMeal,
                icon: _isLogging 
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.add, size: 20),
                label: Text(
                  _isLogging ? 'Logging...' : 'Log This Meal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: const Color(0xFF8B6F47).withOpacity(0.3),
                ),
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildRecentMeals(AsyncValue<List<Meal>> recentMealsAsync) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D3E).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: const Color(0xFF2E7D3E),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Recent Meals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D3E),
                  ),
                ),
              ],
            ),
          ),
          
          // Scrollable content
          Expanded(
            child: recentMealsAsync.when(
              data: (meals) => meals.isEmpty
                ? _buildEmptyMealsState()
                : _buildMealsList(meals),
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFFFF6B35),
                ),
              ),
              error: (error, _) => Center(
                child: Text(
                  'Unable to load recent meals',
                  style: TextStyle(
                    color: const Color(0xFF8B6F47),
                  ),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2E7D3E).withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              // Meal type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getMealTypeColor(meal.mealType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getMealTypeIcon(meal.mealType),
                  color: _getMealTypeColor(meal.mealType),
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Meal details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.restaurantName ?? 'Unknown Restaurant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D3E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatMealTime(meal.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF8B6F47),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Cost
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${meal.cost.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4CAF50),
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
            color: const Color(0xFF8B6F47).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No meals logged yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B4E3D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging to track your dining journey',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF8B6F47),
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
        return const Color(0xFFFFC107); // Sunny yellow
      case 'lunch':
        return const Color(0xFFFF6B35); // Appetizing orange
      case 'dinner':
        return const Color(0xFF9C27B0); // Rich purple
      case 'snack':
        return const Color(0xFF4CAF50); // Fresh green
      default:
        return const Color(0xFF2196F3); // Blue
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

    setState(() {
      _isLogging = true;
    });

    try {
      // Use the meal form state to submit
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
      
      // Clear form
      _restaurantController.clear();
      _costController.clear();
      _notesController.clear();
      
      // Refresh recent meals
      ref.invalidate(recentMealsProvider);
      
      HapticFeedback.lightImpact();
      _showMessage('Meal logged successfully! 🎉', isSuccess: true);
      
    } catch (e) {
      _showMessage('Failed to log meal: $e');
    } finally {
      setState(() {
        _isLogging = false;
      });
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess 
          ? const Color(0xFF4CAF50) 
          : const Color(0xFFFF5722),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}