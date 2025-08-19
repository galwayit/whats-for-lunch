class UserPreferences {
  final List<String> dietaryRestrictions;
  final List<String> cuisinePreferences;
  final int budgetLevel; // 1-4 (corresponding to $ symbols)
  final double maxTravelDistance; // in kilometers
  final bool includeChains;
  final List<String> allergens;
  final int mealFrequencyPerDay;
  final double weeklyBudget;

  const UserPreferences({
    this.dietaryRestrictions = const [],
    this.cuisinePreferences = const [],
    this.budgetLevel = 2,
    this.maxTravelDistance = 5.0,
    this.includeChains = true,
    this.allergens = const [],
    this.mealFrequencyPerDay = 3,
    this.weeklyBudget = 200.0,
  });

  UserPreferences copyWith({
    List<String>? dietaryRestrictions,
    List<String>? cuisinePreferences,
    int? budgetLevel,
    double? maxTravelDistance,
    bool? includeChains,
    List<String>? allergens,
    int? mealFrequencyPerDay,
    double? weeklyBudget,
  }) {
    return UserPreferences(
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      cuisinePreferences: cuisinePreferences ?? this.cuisinePreferences,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      maxTravelDistance: maxTravelDistance ?? this.maxTravelDistance,
      includeChains: includeChains ?? this.includeChains,
      allergens: allergens ?? this.allergens,
      mealFrequencyPerDay: mealFrequencyPerDay ?? this.mealFrequencyPerDay,
      weeklyBudget: weeklyBudget ?? this.weeklyBudget,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dietaryRestrictions': dietaryRestrictions,
      'cuisinePreferences': cuisinePreferences,
      'budgetLevel': budgetLevel,
      'maxTravelDistance': maxTravelDistance,
      'includeChains': includeChains,
      'allergens': allergens,
      'mealFrequencyPerDay': mealFrequencyPerDay,
      'weeklyBudget': weeklyBudget,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      dietaryRestrictions: List<String>.from(json['dietaryRestrictions'] ?? []),
      cuisinePreferences: List<String>.from(json['cuisinePreferences'] ?? []),
      budgetLevel: json['budgetLevel'] ?? 2,
      maxTravelDistance: (json['maxTravelDistance'] ?? 5.0).toDouble(),
      includeChains: json['includeChains'] ?? true,
      allergens: List<String>.from(json['allergens'] ?? []),
      mealFrequencyPerDay: json['mealFrequencyPerDay'] ?? 3,
      weeklyBudget: (json['weeklyBudget'] ?? 200.0).toDouble(),
    );
  }

  @override
  String toString() {
    return 'UserPreferences(dietaryRestrictions: $dietaryRestrictions, cuisinePreferences: $cuisinePreferences, budgetLevel: $budgetLevel, maxTravelDistance: $maxTravelDistance, includeChains: $includeChains, allergens: $allergens, mealFrequencyPerDay: $mealFrequencyPerDay, weeklyBudget: $weeklyBudget)';
  }
}