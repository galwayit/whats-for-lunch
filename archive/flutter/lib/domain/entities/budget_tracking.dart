class BudgetTracking {
  final int? id;
  final int userId;
  final double amount;
  final String category;
  final DateTime date;

  const BudgetTracking({
    this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.date,
  });

  BudgetTracking copyWith({
    int? id,
    int? userId,
    double? amount,
    String? category,
    DateTime? date,
  }) {
    return BudgetTracking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }
}