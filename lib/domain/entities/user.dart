class UserEntity {
  final int? id;
  final String name;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;

  const UserEntity({
    this.id,
    required this.name,
    required this.preferences,
    required this.createdAt,
  });

  UserEntity copyWith({
    int? id,
    String? name,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}