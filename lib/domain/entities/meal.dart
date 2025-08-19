class Meal {
  final int? id;
  final int userId;
  final String? restaurantId;
  final String mealType;
  final double cost;
  final DateTime date;
  final String? notes;

  const Meal({
    this.id,
    required this.userId,
    this.restaurantId,
    required this.mealType,
    required this.cost,
    required this.date,
    this.notes,
  });

  Meal copyWith({
    int? id,
    int? userId,
    String? restaurantId,
    String? mealType,
    double? cost,
    DateTime? date,
    String? notes,
  }) {
    return Meal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      mealType: mealType ?? this.mealType,
      cost: cost ?? this.cost,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}