import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ai_photo_analysis_service.dart';
import '../../services/photo_service.dart';
import '../providers/photo_providers.dart';
import 'ux_components.dart';

/// Widget that displays AI analysis results for photos
class AIPhotoAnalysisWidget extends ConsumerStatefulWidget {
  final List<PhotoResult> photos;
  final ValueChanged<MealAnalysisResult>? onAnalysisComplete;
  final bool autoAnalyze;

  const AIPhotoAnalysisWidget({
    super.key,
    required this.photos,
    this.onAnalysisComplete,
    this.autoAnalyze = false,
  });

  @override
  ConsumerState<AIPhotoAnalysisWidget> createState() => _AIPhotoAnalysisWidgetState();
}

class _AIPhotoAnalysisWidgetState extends ConsumerState<AIPhotoAnalysisWidget> {
  MealAnalysisResult? _analysisResult;
  bool _isAnalyzing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.autoAnalyze && widget.photos.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _analyzePhotos();
      });
    }
  }

  @override
  void didUpdateWidget(AIPhotoAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoAnalyze && 
        widget.photos.isNotEmpty && 
        widget.photos != oldWidget.photos &&
        !_isAnalyzing) {
      _analyzePhotos();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return UXCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: UXComponents.paddingS),
              Text(
                'AI Meal Analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_analysisResult != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UXComponents.paddingS,
                    vertical: UXComponents.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Analyzed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: UXComponents.paddingM),

          // Analysis button or loading state
          if (_isAnalyzing) ...[
            _buildLoadingState(),
          ] else if (_analysisResult == null) ...[
            _buildAnalyzeButton(),
          ],

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: UXComponents.paddingM),
            _buildErrorMessage(),
          ],

          // Analysis results
          if (_analysisResult != null) ...[
            const SizedBox(height: UXComponents.paddingM),
            _buildAnalysisResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(UXComponents.paddingL),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: UXComponents.paddingM),
          Text(
            'Analyzing your meal photos...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: UXComponents.paddingS),
          Text(
            'This may take a few seconds',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return Column(
      children: [
        UXPrimaryButton(
          onPressed: _analyzePhotos,
          text: 'Analyze with AI',
          icon: Icons.auto_awesome,
          semanticLabel: 'Analyze meal photos with AI',
        ),
        const SizedBox(height: UXComponents.paddingS),
        Text(
          'Get insights about your meal, cuisine type, and estimated cost',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(UXComponents.paddingM),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UXComponents.borderRadius),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: UXComponents.paddingS),
          Expanded(
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
              _analyzePhotos();
            },
            child: Text(
              'Retry',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    final analysis = _analysisResult!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dish name and cuisine
        _buildResultSection(
          'Identified Meal',
          analysis.dishName,
          Icons.restaurant,
          Colors.blue,
        ),
        const SizedBox(height: UXComponents.paddingM),

        // Cuisine type and meal type
        Row(
          children: [
            Expanded(
              child: _buildResultChip(
                analysis.cuisineType,
                Icons.public,
                Colors.orange,
              ),
            ),
            const SizedBox(width: UXComponents.paddingS),
            Expanded(
              child: _buildResultChip(
                analysis.mealType,
                Icons.schedule,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: UXComponents.paddingM),

        // Health score and estimated cost
        Row(
          children: [
            Expanded(
              child: _buildScoreWidget(
                'Health Score',
                '${analysis.healthScore}/10',
                analysis.healthScore,
                Icons.favorite,
              ),
            ),
            const SizedBox(width: UXComponents.paddingM),
            Expanded(
              child: _buildResultSection(
                'Est. Cost',
                '\$${analysis.estimatedCost}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
          ],
        ),

        // Description
        if (analysis.description.isNotEmpty) ...[
          const SizedBox(height: UXComponents.paddingM),
          _buildDescriptionSection(analysis.description),
        ],

        // Ingredients
        if (analysis.ingredients.isNotEmpty) ...[
          const SizedBox(height: UXComponents.paddingM),
          _buildIngredientsSection(analysis.ingredients),
        ],

        // Suggestions
        if (analysis.suggestions.isNotEmpty) ...[
          const SizedBox(height: UXComponents.paddingM),
          _buildSuggestionsSection(analysis.suggestions),
        ],

        // Confidence indicator
        const SizedBox(height: UXComponents.paddingM),
        _buildConfidenceIndicator(analysis.confidence),

        // Action buttons
        const SizedBox(height: UXComponents.paddingM),
        Row(
          children: [
            Expanded(
              child: UXSecondaryButton(
                onPressed: _analyzePhotos,
                text: 'Analyze Again',
                icon: Icons.refresh,
              ),
            ),
            const SizedBox(width: UXComponents.paddingM),
            Expanded(
              child: UXSecondaryButton(
                onPressed: () => _showDetailedAnalysis(analysis),
                text: 'View Details',
                icon: Icons.info_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultSection(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(UXComponents.paddingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UXComponents.borderRadius),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: UXComponents.paddingS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UXComponents.paddingM,
        vertical: UXComponents.paddingS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: UXComponents.paddingXS),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreWidget(String label, String score, int value, IconData icon) {
    final color = value >= 7 ? Colors.green : (value >= 4 ? Colors.orange : Colors.red);
    
    return Container(
      padding: const EdgeInsets.all(UXComponents.paddingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(UXComponents.borderRadius),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: UXComponents.paddingS),
              Text(
                score,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: UXComponents.paddingXS),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(String description) {
    return Container(
      padding: const EdgeInsets.all(UXComponents.paddingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(UXComponents.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: UXComponents.paddingS),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: UXComponents.paddingS),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(List<String> ingredients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.inventory_2,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
            const SizedBox(width: UXComponents.paddingS),
            Text(
              'Identified Ingredients',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: UXComponents.paddingS),
        Wrap(
          spacing: UXComponents.paddingS,
          runSpacing: UXComponents.paddingS,
          children: ingredients.map((ingredient) => Chip(
            label: Text(
              ingredient,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestionsSection(List<String> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
            const SizedBox(width: UXComponents.paddingS),
            Text(
              'AI Suggestions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: UXComponents.paddingS),
        ...suggestions.map((suggestion) => Padding(
          padding: const EdgeInsets.only(bottom: UXComponents.paddingS),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.arrow_right,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: UXComponents.paddingS),
              Expanded(
                child: Text(
                  suggestion,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    final color = confidence >= 0.8 ? Colors.green : (confidence >= 0.5 ? Colors.orange : Colors.red);
    final percentage = (confidence * 100).toInt();

    return Row(
      children: [
        Icon(
          Icons.psychology,
          color: color,
          size: 16,
        ),
        const SizedBox(width: UXComponents.paddingS),
        Text(
          'AI Confidence: $percentage%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: UXComponents.paddingS),
        Expanded(
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Future<void> _analyzePhotos() async {
    if (widget.photos.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      // Get API key from environment configuration
      const String apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'demo_key_replace_in_production');
      
      if (apiKey == 'demo_key_replace_in_production' || apiKey == 'your-gemini-api-key-here') {
        throw Exception('API key not configured. Please set GEMINI_API_KEY environment variable.');
      }
      
      final analysisService = AIPhotoAnalysisService(apiKey);
      
      // Use the first photo for analysis
      final result = await analysisService.analyzeMealPhoto(widget.photos.first);
      
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      widget.onAnalysisComplete?.call(result);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.toString().replaceAll('AIPhotoAnalysisException: ', '');
      });
    }
  }

  void _showDetailedAnalysis(MealAnalysisResult analysis) {
    showDialog(
      context: context,
      builder: (context) => AIAnalysisDetailDialog(analysis: analysis),
    );
  }
}

/// Detailed analysis dialog
class AIAnalysisDetailDialog extends StatelessWidget {
  final MealAnalysisResult analysis;

  const AIAnalysisDetailDialog({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: UXComponents.paddingS),
          const Text('AI Analysis Details'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem('Dish Name', analysis.dishName),
              _buildDetailItem('Cuisine Type', analysis.cuisineType),
              _buildDetailItem('Meal Type', analysis.mealType),
              _buildDetailItem('Estimated Cost', '\$${analysis.estimatedCost}'),
              _buildDetailItem('Health Score', '${analysis.healthScore}/10'),
              
              if (analysis.ingredients.isNotEmpty) ...[
                const SizedBox(height: UXComponents.paddingM),
                Text(
                  'Ingredients:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: UXComponents.paddingS),
                Text(analysis.ingredients.join(', ')),
              ],
              
              if (analysis.description.isNotEmpty) ...[
                const SizedBox(height: UXComponents.paddingM),
                Text(
                  'Description:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: UXComponents.paddingS),
                Text(analysis.description),
              ],
              
              const SizedBox(height: UXComponents.paddingM),
              Text(
                'Confidence: ${(analysis.confidence * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UXComponents.paddingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: UXComponents.paddingS),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}