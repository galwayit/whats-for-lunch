/// Enhanced user preferences for Stage 3 restaurant discovery
/// Includes 20+ dietary categories, allergen safety levels, and context-aware preferences
class UserPreferences {
  // Comprehensive dietary categories (20+ options)
  final List<String> dietaryRestrictions;
  final List<String> cuisinePreferences;
  final List<String> allergens;
  final Map<String, AllergenSafetyLevel> allergenSafetyLevels;
  
  // Contextual preferences
  final Map<String, List<String>> contextualPreferences; // time, mood, occasion
  final Map<String, double> cuisineRatings; // learned from history
  final Map<String, int> restaurantVisitCounts; // frequency tracking
  
  // Discovery and filtering preferences
  final int budgetLevel; // 1-4 (corresponding to $ symbols)
  final double maxTravelDistance; // in kilometers
  final bool includeChains;
  final int mealFrequencyPerDay;
  final double weeklyBudget;
  
  // Maps and location preferences
  final bool enableLocationServices;
  final bool showMapView;
  final int mapZoomLevel;
  final List<double>? lastKnownLocation; // [lat, lng]
  
  // Advanced filtering options
  final bool requireDietaryVerification;
  final double minimumRating;
  final List<String> preferredPriceRanges;
  final bool avoidBusyTimes;
  final Map<String, bool> accessibilityRequirements;

  const UserPreferences({
    this.dietaryRestrictions = const [],
    this.cuisinePreferences = const [],
    this.allergens = const [],
    this.allergenSafetyLevels = const {},
    this.contextualPreferences = const {},
    this.cuisineRatings = const {},
    this.restaurantVisitCounts = const {},
    this.budgetLevel = 2,
    this.maxTravelDistance = 5.0,
    this.includeChains = true,
    this.mealFrequencyPerDay = 3,
    this.weeklyBudget = 200.0,
    this.enableLocationServices = true,
    this.showMapView = true,
    this.mapZoomLevel = 14,
    this.lastKnownLocation,
    this.requireDietaryVerification = true,
    this.minimumRating = 3.0,
    this.preferredPriceRanges = const [r'$', r'$$'],
    this.avoidBusyTimes = false,
    this.accessibilityRequirements = const {},
  });

  UserPreferences copyWith({
    List<String>? dietaryRestrictions,
    List<String>? cuisinePreferences,
    List<String>? allergens,
    Map<String, AllergenSafetyLevel>? allergenSafetyLevels,
    Map<String, List<String>>? contextualPreferences,
    Map<String, double>? cuisineRatings,
    Map<String, int>? restaurantVisitCounts,
    int? budgetLevel,
    double? maxTravelDistance,
    bool? includeChains,
    int? mealFrequencyPerDay,
    double? weeklyBudget,
    bool? enableLocationServices,
    bool? showMapView,
    int? mapZoomLevel,
    List<double>? lastKnownLocation,
    bool? requireDietaryVerification,
    double? minimumRating,
    List<String>? preferredPriceRanges,
    bool? avoidBusyTimes,
    Map<String, bool>? accessibilityRequirements,
  }) {
    return UserPreferences(
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      cuisinePreferences: cuisinePreferences ?? this.cuisinePreferences,
      allergens: allergens ?? this.allergens,
      allergenSafetyLevels: allergenSafetyLevels ?? this.allergenSafetyLevels,
      contextualPreferences: contextualPreferences ?? this.contextualPreferences,
      cuisineRatings: cuisineRatings ?? this.cuisineRatings,
      restaurantVisitCounts: restaurantVisitCounts ?? this.restaurantVisitCounts,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      maxTravelDistance: maxTravelDistance ?? this.maxTravelDistance,
      includeChains: includeChains ?? this.includeChains,
      mealFrequencyPerDay: mealFrequencyPerDay ?? this.mealFrequencyPerDay,
      weeklyBudget: weeklyBudget ?? this.weeklyBudget,
      enableLocationServices: enableLocationServices ?? this.enableLocationServices,
      showMapView: showMapView ?? this.showMapView,
      mapZoomLevel: mapZoomLevel ?? this.mapZoomLevel,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      requireDietaryVerification: requireDietaryVerification ?? this.requireDietaryVerification,
      minimumRating: minimumRating ?? this.minimumRating,
      preferredPriceRanges: preferredPriceRanges ?? this.preferredPriceRanges,
      avoidBusyTimes: avoidBusyTimes ?? this.avoidBusyTimes,
      accessibilityRequirements: accessibilityRequirements ?? this.accessibilityRequirements,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dietaryRestrictions': dietaryRestrictions,
      'cuisinePreferences': cuisinePreferences,
      'allergens': allergens,
      'allergenSafetyLevels': allergenSafetyLevels.map((k, v) => MapEntry(k, v.index)),
      'contextualPreferences': contextualPreferences,
      'cuisineRatings': cuisineRatings,
      'restaurantVisitCounts': restaurantVisitCounts,
      'budgetLevel': budgetLevel,
      'maxTravelDistance': maxTravelDistance,
      'includeChains': includeChains,
      'mealFrequencyPerDay': mealFrequencyPerDay,
      'weeklyBudget': weeklyBudget,
      'enableLocationServices': enableLocationServices,
      'showMapView': showMapView,
      'mapZoomLevel': mapZoomLevel,
      'lastKnownLocation': lastKnownLocation,
      'requireDietaryVerification': requireDietaryVerification,
      'minimumRating': minimumRating,
      'preferredPriceRanges': preferredPriceRanges,
      'avoidBusyTimes': avoidBusyTimes,
      'accessibilityRequirements': accessibilityRequirements,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      dietaryRestrictions: List<String>.from(json['dietaryRestrictions'] ?? []),
      cuisinePreferences: List<String>.from(json['cuisinePreferences'] ?? []),
      allergens: List<String>.from(json['allergens'] ?? []),
      allergenSafetyLevels: (json['allergenSafetyLevels'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, AllergenSafetyLevel.values[v as int])),
      contextualPreferences: (json['contextualPreferences'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, List<String>.from(v as List))),
      cuisineRatings: (json['cuisineRatings'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      restaurantVisitCounts: (json['restaurantVisitCounts'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as int)),
      budgetLevel: json['budgetLevel'] ?? 2,
      maxTravelDistance: (json['maxTravelDistance'] ?? 5.0).toDouble(),
      includeChains: json['includeChains'] ?? true,
      mealFrequencyPerDay: json['mealFrequencyPerDay'] ?? 3,
      weeklyBudget: (json['weeklyBudget'] ?? 200.0).toDouble(),
      enableLocationServices: json['enableLocationServices'] ?? true,
      showMapView: json['showMapView'] ?? true,
      mapZoomLevel: json['mapZoomLevel'] ?? 14,
      lastKnownLocation: json['lastKnownLocation'] != null 
          ? List<double>.from(json['lastKnownLocation'])
          : null,
      requireDietaryVerification: json['requireDietaryVerification'] ?? true,
      minimumRating: (json['minimumRating'] ?? 3.0).toDouble(),
      preferredPriceRanges: List<String>.from(json['preferredPriceRanges'] ?? [r'$', r'$$']),
      avoidBusyTimes: json['avoidBusyTimes'] ?? false,
      accessibilityRequirements: (json['accessibilityRequirements'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as bool)),
    );
  }

  @override
  String toString() {
    return 'UserPreferences(dietaryRestrictions: $dietaryRestrictions, cuisinePreferences: $cuisinePreferences, allergens: $allergens, budgetLevel: $budgetLevel, maxTravelDistance: $maxTravelDistance, weeklyBudget: $weeklyBudget, enableLocationServices: $enableLocationServices)';
  }

  /// Get comprehensive dietary categories (20+ options)
  static List<DietaryCategory> get allDietaryCategories => [
    DietaryCategory('vegetarian', 'Vegetarian', 'No meat, poultry, or fish'),
    DietaryCategory('vegan', 'Vegan', 'No animal products'),
    DietaryCategory('gluten_free', 'Gluten-Free', 'No wheat, barley, rye, or gluten'),
    DietaryCategory('dairy_free', 'Dairy-Free', 'No milk or dairy products'),
    DietaryCategory('nut_free', 'Nut-Free', 'No tree nuts or peanuts'),
    DietaryCategory('kosher', 'Kosher', 'Jewish dietary laws'),
    DietaryCategory('halal', 'Halal', 'Islamic dietary laws'),
    DietaryCategory('keto', 'Ketogenic', 'High-fat, low-carb diet'),
    DietaryCategory('paleo', 'Paleo', 'Stone-age inspired diet'),
    DietaryCategory('low_carb', 'Low-Carb', 'Reduced carbohydrate intake'),
    DietaryCategory('low_sodium', 'Low-Sodium', 'Reduced salt content'),
    DietaryCategory('low_sugar', 'Low-Sugar', 'Reduced sugar content'),
    DietaryCategory('diabetic_friendly', 'Diabetic-Friendly', 'Blood sugar conscious'),
    DietaryCategory('heart_healthy', 'Heart-Healthy', 'Cardiovascular wellness'),
    DietaryCategory('pescatarian', 'Pescatarian', 'Fish but no other meat'),
    DietaryCategory('raw_food', 'Raw Food', 'Uncooked and unprocessed'),
    DietaryCategory('organic', 'Organic', 'Certified organic ingredients'),
    DietaryCategory('whole30', 'Whole30', '30-day elimination diet'),
    DietaryCategory('mediterranean', 'Mediterranean', 'Mediterranean diet style'),
    DietaryCategory('anti_inflammatory', 'Anti-Inflammatory', 'Reduces inflammation'),
    DietaryCategory('fodmap_friendly', 'FODMAP-Friendly', 'Low FODMAP for IBS'),
    DietaryCategory('high_protein', 'High-Protein', 'Protein-rich options'),
    DietaryCategory('meal_prep_friendly', 'Meal-Prep Friendly', 'Good for meal preparation'),
  ];

  /// Get common allergens with safety considerations
  static List<AllergenInfo> get commonAllergens => [
    AllergenInfo('peanuts', 'Peanuts', AllergenSafetyLevel.severe),
    AllergenInfo('tree_nuts', 'Tree Nuts', AllergenSafetyLevel.severe),
    AllergenInfo('shellfish', 'Shellfish', AllergenSafetyLevel.severe),
    AllergenInfo('fish', 'Fish', AllergenSafetyLevel.moderate),
    AllergenInfo('eggs', 'Eggs', AllergenSafetyLevel.moderate),
    AllergenInfo('dairy', 'Dairy/Milk', AllergenSafetyLevel.moderate),
    AllergenInfo('soy', 'Soy', AllergenSafetyLevel.moderate),
    AllergenInfo('wheat', 'Wheat/Gluten', AllergenSafetyLevel.moderate),
    AllergenInfo('sesame', 'Sesame', AllergenSafetyLevel.moderate),
    AllergenInfo('sulfites', 'Sulfites', AllergenSafetyLevel.mild),
    AllergenInfo('msg', 'MSG', AllergenSafetyLevel.mild),
    AllergenInfo('artificial_colors', 'Artificial Colors', AllergenSafetyLevel.mild),
  ];
}

/// Allergen safety levels for risk assessment
enum AllergenSafetyLevel {
  mild,      // Discomfort but not dangerous
  moderate,  // Significant reaction, medical attention may be needed
  severe,    // Life-threatening, requires immediate medical attention
}

/// Dietary category information
class DietaryCategory {
  final String id;
  final String name;
  final String description;

  const DietaryCategory(this.id, this.name, this.description);
}

/// Allergen information with safety level
class AllergenInfo {
  final String id;
  final String name;
  final AllergenSafetyLevel defaultSafetyLevel;

  const AllergenInfo(this.id, this.name, this.defaultSafetyLevel);
}