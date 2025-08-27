class Meal {
  final int? id;
  final int userId;
  final String? restaurantId;
  final String? restaurantName; // Added restaurant name for convenience
  final String mealType;
  final double cost;
  final DateTime date;
  final String? notes;
  final List<String> photoIds; // Photo IDs associated with this meal

  const Meal({
    this.id,
    required this.userId,
    this.restaurantId,
    this.restaurantName,
    required this.mealType,
    required this.cost,
    required this.date,
    this.notes,
    this.photoIds = const [],
  });

  Meal copyWith({
    int? id,
    int? userId,
    String? restaurantId,
    String? restaurantName,
    String? mealType,
    double? cost,
    DateTime? date,
    String? notes,
    List<String>? photoIds,
  }) {
    return Meal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      mealType: mealType ?? this.mealType,
      cost: cost ?? this.cost,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      photoIds: photoIds ?? this.photoIds,
    );
  }

  /// Check if this meal was logged today
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mealDay = DateTime(date.year, date.month, date.day);
    return mealDay == today;
  }

  /// Check if this meal was logged yesterday
  bool get isYesterday {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final mealDay = DateTime(date.year, date.month, date.day);
    return mealDay == yesterday;
  }

  /// Get a user-friendly display name for the meal type
  String get displayMealType {
    switch (mealType) {
      case 'dining_out':
        return 'Dining Out';
      case 'delivery':
        return 'Delivery';
      case 'takeout':
        return 'Takeout';
      case 'groceries':
        return 'Groceries';
      case 'snack':
        return 'Snack';
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return 'Experience';
    }
  }

  /// Format the cost as currency
  String get formattedCost => '\$${cost.toStringAsFixed(2)}';

  /// Check if this meal has photos
  bool get hasPhotos => photoIds.isNotEmpty;

  /// Get the number of photos for this meal
  int get photoCount => photoIds.length;


  @override
  String toString() {
    return 'Meal(id: $id, userId: $userId, restaurantId: $restaurantId, restaurantName: $restaurantName, mealType: $mealType, cost: $cost, date: $date, notes: $notes, photoIds: $photoIds)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Meal &&
        other.id == id &&
        other.userId == userId &&
        other.restaurantId == restaurantId &&
        other.restaurantName == restaurantName &&
        other.mealType == mealType &&
        other.cost == cost &&
        other.date == date &&
        other.notes == notes &&
        _listEquals(other.photoIds, photoIds);
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, restaurantId, restaurantName, mealType, cost, date, notes, Object.hashAll(photoIds));
  }

  // Helper function for list comparison
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}