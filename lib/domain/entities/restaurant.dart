class Restaurant {
  final String placeId;
  final String name;
  final String location;
  final int? priceLevel;
  final double? rating;
  final String? cuisineType;
  final DateTime cachedAt;

  const Restaurant({
    required this.placeId,
    required this.name,
    required this.location,
    this.priceLevel,
    this.rating,
    this.cuisineType,
    required this.cachedAt,
  });

  Restaurant copyWith({
    String? placeId,
    String? name,
    String? location,
    int? priceLevel,
    double? rating,
    String? cuisineType,
    DateTime? cachedAt,
  }) {
    return Restaurant(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      location: location ?? this.location,
      priceLevel: priceLevel ?? this.priceLevel,
      rating: rating ?? this.rating,
      cuisineType: cuisineType ?? this.cuisineType,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}