// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _preferencesMeta =
      const VerificationMeta('preferences');
  @override
  late final GeneratedColumn<String> preferences = GeneratedColumn<String>(
      'preferences', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, name, preferences, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('preferences')) {
      context.handle(
          _preferencesMeta,
          preferences.isAcceptableOrUnknown(
              data['preferences']!, _preferencesMeta));
    } else if (isInserting) {
      context.missing(_preferencesMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      preferences: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}preferences'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String name;
  final String preferences;
  final DateTime createdAt;
  const User(
      {required this.id,
      required this.name,
      required this.preferences,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['preferences'] = Variable<String>(preferences);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      name: Value(name),
      preferences: Value(preferences),
      createdAt: Value(createdAt),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      preferences: serializer.fromJson<String>(json['preferences']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'preferences': serializer.toJson<String>(preferences),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  User copyWith(
          {int? id, String? name, String? preferences, DateTime? createdAt}) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        preferences: preferences ?? this.preferences,
        createdAt: createdAt ?? this.createdAt,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      preferences:
          data.preferences.present ? data.preferences.value : this.preferences,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('preferences: $preferences, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, preferences, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.name == this.name &&
          other.preferences == this.preferences &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> preferences;
  final Value<DateTime> createdAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.preferences = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String preferences,
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        preferences = Value(preferences);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? preferences,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (preferences != null) 'preferences': preferences,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? preferences,
      Value<DateTime>? createdAt}) {
    return UsersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (preferences.present) {
      map['preferences'] = Variable<String>(preferences.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('preferences: $preferences, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MealsTable extends Meals with TableInfo<$MealsTable, Meal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _restaurantIdMeta =
      const VerificationMeta('restaurantId');
  @override
  late final GeneratedColumn<String> restaurantId = GeneratedColumn<String>(
      'restaurant_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mealTypeMeta =
      const VerificationMeta('mealType');
  @override
  late final GeneratedColumn<String> mealType = GeneratedColumn<String>(
      'meal_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<double> cost = GeneratedColumn<double>(
      'cost', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _restaurantNameMeta =
      const VerificationMeta('restaurantName');
  @override
  late final GeneratedColumn<String> restaurantName = GeneratedColumn<String>(
      'restaurant_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoIdsMeta =
      const VerificationMeta('photoIds');
  @override
  late final GeneratedColumn<String> photoIds = GeneratedColumn<String>(
      'photo_ids', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        restaurantId,
        mealType,
        cost,
        date,
        restaurantName,
        notes,
        photoIds
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meals';
  @override
  VerificationContext validateIntegrity(Insertable<Meal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('restaurant_id')) {
      context.handle(
          _restaurantIdMeta,
          restaurantId.isAcceptableOrUnknown(
              data['restaurant_id']!, _restaurantIdMeta));
    }
    if (data.containsKey('meal_type')) {
      context.handle(_mealTypeMeta,
          mealType.isAcceptableOrUnknown(data['meal_type']!, _mealTypeMeta));
    } else if (isInserting) {
      context.missing(_mealTypeMeta);
    }
    if (data.containsKey('cost')) {
      context.handle(
          _costMeta, cost.isAcceptableOrUnknown(data['cost']!, _costMeta));
    } else if (isInserting) {
      context.missing(_costMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('restaurant_name')) {
      context.handle(
          _restaurantNameMeta,
          restaurantName.isAcceptableOrUnknown(
              data['restaurant_name']!, _restaurantNameMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('photo_ids')) {
      context.handle(_photoIdsMeta,
          photoIds.isAcceptableOrUnknown(data['photo_ids']!, _photoIdsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Meal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      restaurantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}restaurant_id']),
      mealType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meal_type'])!,
      cost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      restaurantName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}restaurant_name']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      photoIds: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_ids'])!,
    );
  }

  @override
  $MealsTable createAlias(String alias) {
    return $MealsTable(attachedDatabase, alias);
  }
}

class Meal extends DataClass implements Insertable<Meal> {
  final int id;
  final int userId;
  final String? restaurantId;
  final String mealType;
  final double cost;
  final DateTime date;
  final String? restaurantName;
  final String? notes;
  final String photoIds;
  const Meal(
      {required this.id,
      required this.userId,
      this.restaurantId,
      required this.mealType,
      required this.cost,
      required this.date,
      this.restaurantName,
      this.notes,
      required this.photoIds});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || restaurantId != null) {
      map['restaurant_id'] = Variable<String>(restaurantId);
    }
    map['meal_type'] = Variable<String>(mealType);
    map['cost'] = Variable<double>(cost);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || restaurantName != null) {
      map['restaurant_name'] = Variable<String>(restaurantName);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['photo_ids'] = Variable<String>(photoIds);
    return map;
  }

  MealsCompanion toCompanion(bool nullToAbsent) {
    return MealsCompanion(
      id: Value(id),
      userId: Value(userId),
      restaurantId: restaurantId == null && nullToAbsent
          ? const Value.absent()
          : Value(restaurantId),
      mealType: Value(mealType),
      cost: Value(cost),
      date: Value(date),
      restaurantName: restaurantName == null && nullToAbsent
          ? const Value.absent()
          : Value(restaurantName),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      photoIds: Value(photoIds),
    );
  }

  factory Meal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meal(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      restaurantId: serializer.fromJson<String?>(json['restaurantId']),
      mealType: serializer.fromJson<String>(json['mealType']),
      cost: serializer.fromJson<double>(json['cost']),
      date: serializer.fromJson<DateTime>(json['date']),
      restaurantName: serializer.fromJson<String?>(json['restaurantName']),
      notes: serializer.fromJson<String?>(json['notes']),
      photoIds: serializer.fromJson<String>(json['photoIds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'restaurantId': serializer.toJson<String?>(restaurantId),
      'mealType': serializer.toJson<String>(mealType),
      'cost': serializer.toJson<double>(cost),
      'date': serializer.toJson<DateTime>(date),
      'restaurantName': serializer.toJson<String?>(restaurantName),
      'notes': serializer.toJson<String?>(notes),
      'photoIds': serializer.toJson<String>(photoIds),
    };
  }

  Meal copyWith(
          {int? id,
          int? userId,
          Value<String?> restaurantId = const Value.absent(),
          String? mealType,
          double? cost,
          DateTime? date,
          Value<String?> restaurantName = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          String? photoIds}) =>
      Meal(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        restaurantId:
            restaurantId.present ? restaurantId.value : this.restaurantId,
        mealType: mealType ?? this.mealType,
        cost: cost ?? this.cost,
        date: date ?? this.date,
        restaurantName:
            restaurantName.present ? restaurantName.value : this.restaurantName,
        notes: notes.present ? notes.value : this.notes,
        photoIds: photoIds ?? this.photoIds,
      );
  Meal copyWithCompanion(MealsCompanion data) {
    return Meal(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      restaurantId: data.restaurantId.present
          ? data.restaurantId.value
          : this.restaurantId,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
      cost: data.cost.present ? data.cost.value : this.cost,
      date: data.date.present ? data.date.value : this.date,
      restaurantName: data.restaurantName.present
          ? data.restaurantName.value
          : this.restaurantName,
      notes: data.notes.present ? data.notes.value : this.notes,
      photoIds: data.photoIds.present ? data.photoIds.value : this.photoIds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meal(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('restaurantId: $restaurantId, ')
          ..write('mealType: $mealType, ')
          ..write('cost: $cost, ')
          ..write('date: $date, ')
          ..write('restaurantName: $restaurantName, ')
          ..write('notes: $notes, ')
          ..write('photoIds: $photoIds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, restaurantId, mealType, cost,
      date, restaurantName, notes, photoIds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meal &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.restaurantId == this.restaurantId &&
          other.mealType == this.mealType &&
          other.cost == this.cost &&
          other.date == this.date &&
          other.restaurantName == this.restaurantName &&
          other.notes == this.notes &&
          other.photoIds == this.photoIds);
}

class MealsCompanion extends UpdateCompanion<Meal> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String?> restaurantId;
  final Value<String> mealType;
  final Value<double> cost;
  final Value<DateTime> date;
  final Value<String?> restaurantName;
  final Value<String?> notes;
  final Value<String> photoIds;
  const MealsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.restaurantId = const Value.absent(),
    this.mealType = const Value.absent(),
    this.cost = const Value.absent(),
    this.date = const Value.absent(),
    this.restaurantName = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoIds = const Value.absent(),
  });
  MealsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    this.restaurantId = const Value.absent(),
    required String mealType,
    required double cost,
    required DateTime date,
    this.restaurantName = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoIds = const Value.absent(),
  })  : userId = Value(userId),
        mealType = Value(mealType),
        cost = Value(cost),
        date = Value(date);
  static Insertable<Meal> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? restaurantId,
    Expression<String>? mealType,
    Expression<double>? cost,
    Expression<DateTime>? date,
    Expression<String>? restaurantName,
    Expression<String>? notes,
    Expression<String>? photoIds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (restaurantId != null) 'restaurant_id': restaurantId,
      if (mealType != null) 'meal_type': mealType,
      if (cost != null) 'cost': cost,
      if (date != null) 'date': date,
      if (restaurantName != null) 'restaurant_name': restaurantName,
      if (notes != null) 'notes': notes,
      if (photoIds != null) 'photo_ids': photoIds,
    });
  }

  MealsCompanion copyWith(
      {Value<int>? id,
      Value<int>? userId,
      Value<String?>? restaurantId,
      Value<String>? mealType,
      Value<double>? cost,
      Value<DateTime>? date,
      Value<String?>? restaurantName,
      Value<String?>? notes,
      Value<String>? photoIds}) {
    return MealsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      mealType: mealType ?? this.mealType,
      cost: cost ?? this.cost,
      date: date ?? this.date,
      restaurantName: restaurantName ?? this.restaurantName,
      notes: notes ?? this.notes,
      photoIds: photoIds ?? this.photoIds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (restaurantId.present) {
      map['restaurant_id'] = Variable<String>(restaurantId.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<String>(mealType.value);
    }
    if (cost.present) {
      map['cost'] = Variable<double>(cost.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (restaurantName.present) {
      map['restaurant_name'] = Variable<String>(restaurantName.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (photoIds.present) {
      map['photo_ids'] = Variable<String>(photoIds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('restaurantId: $restaurantId, ')
          ..write('mealType: $mealType, ')
          ..write('cost: $cost, ')
          ..write('date: $date, ')
          ..write('restaurantName: $restaurantName, ')
          ..write('notes: $notes, ')
          ..write('photoIds: $photoIds')
          ..write(')'))
        .toString();
  }
}

class $BudgetTrackingsTable extends BudgetTrackings
    with TableInfo<$BudgetTrackingsTable, BudgetTracking> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetTrackingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, userId, amount, category, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_trackings';
  @override
  VerificationContext validateIntegrity(Insertable<BudgetTracking> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetTracking map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetTracking(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
    );
  }

  @override
  $BudgetTrackingsTable createAlias(String alias) {
    return $BudgetTrackingsTable(attachedDatabase, alias);
  }
}

class BudgetTracking extends DataClass implements Insertable<BudgetTracking> {
  final int id;
  final int userId;
  final double amount;
  final String category;
  final DateTime date;
  const BudgetTracking(
      {required this.id,
      required this.userId,
      required this.amount,
      required this.category,
      required this.date});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['amount'] = Variable<double>(amount);
    map['category'] = Variable<String>(category);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  BudgetTrackingsCompanion toCompanion(bool nullToAbsent) {
    return BudgetTrackingsCompanion(
      id: Value(id),
      userId: Value(userId),
      amount: Value(amount),
      category: Value(category),
      date: Value(date),
    );
  }

  factory BudgetTracking.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetTracking(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      amount: serializer.fromJson<double>(json['amount']),
      category: serializer.fromJson<String>(json['category']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'amount': serializer.toJson<double>(amount),
      'category': serializer.toJson<String>(category),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  BudgetTracking copyWith(
          {int? id,
          int? userId,
          double? amount,
          String? category,
          DateTime? date}) =>
      BudgetTracking(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        date: date ?? this.date,
      );
  BudgetTracking copyWithCompanion(BudgetTrackingsCompanion data) {
    return BudgetTracking(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetTracking(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, amount, category, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetTracking &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.date == this.date);
}

class BudgetTrackingsCompanion extends UpdateCompanion<BudgetTracking> {
  final Value<int> id;
  final Value<int> userId;
  final Value<double> amount;
  final Value<String> category;
  final Value<DateTime> date;
  const BudgetTrackingsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.date = const Value.absent(),
  });
  BudgetTrackingsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required double amount,
    required String category,
    required DateTime date,
  })  : userId = Value(userId),
        amount = Value(amount),
        category = Value(category),
        date = Value(date);
  static Insertable<BudgetTracking> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<double>? amount,
    Expression<String>? category,
    Expression<DateTime>? date,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (date != null) 'date': date,
    });
  }

  BudgetTrackingsCompanion copyWith(
      {Value<int>? id,
      Value<int>? userId,
      Value<double>? amount,
      Value<String>? category,
      Value<DateTime>? date}) {
    return BudgetTrackingsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetTrackingsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }
}

class $RestaurantsTable extends Restaurants
    with TableInfo<$RestaurantsTable, Restaurant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RestaurantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _placeIdMeta =
      const VerificationMeta('placeId');
  @override
  late final GeneratedColumn<String> placeId = GeneratedColumn<String>(
      'place_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneNumberMeta =
      const VerificationMeta('phoneNumber');
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
      'phone_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _websiteMeta =
      const VerificationMeta('website');
  @override
  late final GeneratedColumn<String> website = GeneratedColumn<String>(
      'website', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _distanceFromUserMeta =
      const VerificationMeta('distanceFromUser');
  @override
  late final GeneratedColumn<double> distanceFromUser = GeneratedColumn<double>(
      'distance_from_user', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
      'rating', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _reviewCountMeta =
      const VerificationMeta('reviewCount');
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
      'review_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _priceLevelMeta =
      const VerificationMeta('priceLevel');
  @override
  late final GeneratedColumn<int> priceLevel = GeneratedColumn<int>(
      'price_level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _priceRangesMeta =
      const VerificationMeta('priceRanges');
  @override
  late final GeneratedColumn<String> priceRanges = GeneratedColumn<String>(
      'price_ranges', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _cuisineTypeMeta =
      const VerificationMeta('cuisineType');
  @override
  late final GeneratedColumn<String> cuisineType = GeneratedColumn<String>(
      'cuisine_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cuisineTypesMeta =
      const VerificationMeta('cuisineTypes');
  @override
  late final GeneratedColumn<String> cuisineTypes = GeneratedColumn<String>(
      'cuisine_types', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _supportedDietaryRestrictionsMeta =
      const VerificationMeta('supportedDietaryRestrictions');
  @override
  late final GeneratedColumn<String> supportedDietaryRestrictions =
      GeneratedColumn<String>(
          'supported_dietary_restrictions', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('[]'));
  static const VerificationMeta _allergenInfoMeta =
      const VerificationMeta('allergenInfo');
  @override
  late final GeneratedColumn<String> allergenInfo = GeneratedColumn<String>(
      'allergen_info', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _dietaryCompatibilityScoresMeta =
      const VerificationMeta('dietaryCompatibilityScores');
  @override
  late final GeneratedColumn<String> dietaryCompatibilityScores =
      GeneratedColumn<String>(
          'dietary_compatibility_scores', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('{}'));
  static const VerificationMeta _hasVerifiedDietaryInfoMeta =
      const VerificationMeta('hasVerifiedDietaryInfo');
  @override
  late final GeneratedColumn<bool> hasVerifiedDietaryInfo =
      GeneratedColumn<bool>('has_verified_dietary_info', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("has_verified_dietary_info" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _communityVerificationCountMeta =
      const VerificationMeta('communityVerificationCount');
  @override
  late final GeneratedColumn<int> communityVerificationCount =
      GeneratedColumn<int>('community_verification_count', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _openingHoursMeta =
      const VerificationMeta('openingHours');
  @override
  late final GeneratedColumn<String> openingHours = GeneratedColumn<String>(
      'opening_hours', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _isOpenNowMeta =
      const VerificationMeta('isOpenNow');
  @override
  late final GeneratedColumn<bool> isOpenNow = GeneratedColumn<bool>(
      'is_open_now', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_open_now" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _currentWaitTimeMeta =
      const VerificationMeta('currentWaitTime');
  @override
  late final GeneratedColumn<String> currentWaitTime = GeneratedColumn<String>(
      'current_wait_time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _featuresMeta =
      const VerificationMeta('features');
  @override
  late final GeneratedColumn<String> features = GeneratedColumn<String>(
      'features', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _averageMealCostMeta =
      const VerificationMeta('averageMealCost');
  @override
  late final GeneratedColumn<double> averageMealCost = GeneratedColumn<double>(
      'average_meal_cost', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _valueScoreMeta =
      const VerificationMeta('valueScore');
  @override
  late final GeneratedColumn<double> valueScore = GeneratedColumn<double>(
      'value_score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _mealTypeAverageCostsMeta =
      const VerificationMeta('mealTypeAverageCosts');
  @override
  late final GeneratedColumn<String> mealTypeAverageCosts =
      GeneratedColumn<String>('meal_type_average_costs', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('{}'));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastVerifiedMeta =
      const VerificationMeta('lastVerified');
  @override
  late final GeneratedColumn<DateTime> lastVerified = GeneratedColumn<DateTime>(
      'last_verified', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _photoReferenceMeta =
      const VerificationMeta('photoReference');
  @override
  late final GeneratedColumn<String> photoReference = GeneratedColumn<String>(
      'photo_reference', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoReferencesMeta =
      const VerificationMeta('photoReferences');
  @override
  late final GeneratedColumn<String> photoReferences = GeneratedColumn<String>(
      'photo_references', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  @override
  List<GeneratedColumn> get $columns => [
        placeId,
        name,
        location,
        address,
        phoneNumber,
        website,
        latitude,
        longitude,
        distanceFromUser,
        rating,
        reviewCount,
        priceLevel,
        priceRanges,
        cuisineType,
        cuisineTypes,
        supportedDietaryRestrictions,
        allergenInfo,
        dietaryCompatibilityScores,
        hasVerifiedDietaryInfo,
        communityVerificationCount,
        openingHours,
        isOpenNow,
        currentWaitTime,
        features,
        averageMealCost,
        valueScore,
        mealTypeAverageCosts,
        cachedAt,
        lastVerified,
        photoReference,
        photoReferences
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'restaurants';
  @override
  VerificationContext validateIntegrity(Insertable<Restaurant> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('place_id')) {
      context.handle(_placeIdMeta,
          placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta));
    } else if (isInserting) {
      context.missing(_placeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('phone_number')) {
      context.handle(
          _phoneNumberMeta,
          phoneNumber.isAcceptableOrUnknown(
              data['phone_number']!, _phoneNumberMeta));
    }
    if (data.containsKey('website')) {
      context.handle(_websiteMeta,
          website.isAcceptableOrUnknown(data['website']!, _websiteMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    if (data.containsKey('distance_from_user')) {
      context.handle(
          _distanceFromUserMeta,
          distanceFromUser.isAcceptableOrUnknown(
              data['distance_from_user']!, _distanceFromUserMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('review_count')) {
      context.handle(
          _reviewCountMeta,
          reviewCount.isAcceptableOrUnknown(
              data['review_count']!, _reviewCountMeta));
    }
    if (data.containsKey('price_level')) {
      context.handle(
          _priceLevelMeta,
          priceLevel.isAcceptableOrUnknown(
              data['price_level']!, _priceLevelMeta));
    }
    if (data.containsKey('price_ranges')) {
      context.handle(
          _priceRangesMeta,
          priceRanges.isAcceptableOrUnknown(
              data['price_ranges']!, _priceRangesMeta));
    }
    if (data.containsKey('cuisine_type')) {
      context.handle(
          _cuisineTypeMeta,
          cuisineType.isAcceptableOrUnknown(
              data['cuisine_type']!, _cuisineTypeMeta));
    }
    if (data.containsKey('cuisine_types')) {
      context.handle(
          _cuisineTypesMeta,
          cuisineTypes.isAcceptableOrUnknown(
              data['cuisine_types']!, _cuisineTypesMeta));
    }
    if (data.containsKey('supported_dietary_restrictions')) {
      context.handle(
          _supportedDietaryRestrictionsMeta,
          supportedDietaryRestrictions.isAcceptableOrUnknown(
              data['supported_dietary_restrictions']!,
              _supportedDietaryRestrictionsMeta));
    }
    if (data.containsKey('allergen_info')) {
      context.handle(
          _allergenInfoMeta,
          allergenInfo.isAcceptableOrUnknown(
              data['allergen_info']!, _allergenInfoMeta));
    }
    if (data.containsKey('dietary_compatibility_scores')) {
      context.handle(
          _dietaryCompatibilityScoresMeta,
          dietaryCompatibilityScores.isAcceptableOrUnknown(
              data['dietary_compatibility_scores']!,
              _dietaryCompatibilityScoresMeta));
    }
    if (data.containsKey('has_verified_dietary_info')) {
      context.handle(
          _hasVerifiedDietaryInfoMeta,
          hasVerifiedDietaryInfo.isAcceptableOrUnknown(
              data['has_verified_dietary_info']!, _hasVerifiedDietaryInfoMeta));
    }
    if (data.containsKey('community_verification_count')) {
      context.handle(
          _communityVerificationCountMeta,
          communityVerificationCount.isAcceptableOrUnknown(
              data['community_verification_count']!,
              _communityVerificationCountMeta));
    }
    if (data.containsKey('opening_hours')) {
      context.handle(
          _openingHoursMeta,
          openingHours.isAcceptableOrUnknown(
              data['opening_hours']!, _openingHoursMeta));
    }
    if (data.containsKey('is_open_now')) {
      context.handle(
          _isOpenNowMeta,
          isOpenNow.isAcceptableOrUnknown(
              data['is_open_now']!, _isOpenNowMeta));
    }
    if (data.containsKey('current_wait_time')) {
      context.handle(
          _currentWaitTimeMeta,
          currentWaitTime.isAcceptableOrUnknown(
              data['current_wait_time']!, _currentWaitTimeMeta));
    }
    if (data.containsKey('features')) {
      context.handle(_featuresMeta,
          features.isAcceptableOrUnknown(data['features']!, _featuresMeta));
    }
    if (data.containsKey('average_meal_cost')) {
      context.handle(
          _averageMealCostMeta,
          averageMealCost.isAcceptableOrUnknown(
              data['average_meal_cost']!, _averageMealCostMeta));
    }
    if (data.containsKey('value_score')) {
      context.handle(
          _valueScoreMeta,
          valueScore.isAcceptableOrUnknown(
              data['value_score']!, _valueScoreMeta));
    }
    if (data.containsKey('meal_type_average_costs')) {
      context.handle(
          _mealTypeAverageCostsMeta,
          mealTypeAverageCosts.isAcceptableOrUnknown(
              data['meal_type_average_costs']!, _mealTypeAverageCostsMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    if (data.containsKey('last_verified')) {
      context.handle(
          _lastVerifiedMeta,
          lastVerified.isAcceptableOrUnknown(
              data['last_verified']!, _lastVerifiedMeta));
    }
    if (data.containsKey('photo_reference')) {
      context.handle(
          _photoReferenceMeta,
          photoReference.isAcceptableOrUnknown(
              data['photo_reference']!, _photoReferenceMeta));
    }
    if (data.containsKey('photo_references')) {
      context.handle(
          _photoReferencesMeta,
          photoReferences.isAcceptableOrUnknown(
              data['photo_references']!, _photoReferencesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {placeId};
  @override
  Restaurant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Restaurant(
      placeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}place_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      phoneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_number']),
      website: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}website']),
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude']),
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude']),
      distanceFromUser: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}distance_from_user']),
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating']),
      reviewCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}review_count']),
      priceLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price_level']),
      priceRanges: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}price_ranges'])!,
      cuisineType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cuisine_type']),
      cuisineTypes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cuisine_types'])!,
      supportedDietaryRestrictions: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}supported_dietary_restrictions'])!,
      allergenInfo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}allergen_info'])!,
      dietaryCompatibilityScores: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}dietary_compatibility_scores'])!,
      hasVerifiedDietaryInfo: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}has_verified_dietary_info'])!,
      communityVerificationCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}community_verification_count'])!,
      openingHours: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}opening_hours'])!,
      isOpenNow: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_open_now'])!,
      currentWaitTime: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}current_wait_time']),
      features: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}features'])!,
      averageMealCost: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}average_meal_cost']),
      valueScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value_score']),
      mealTypeAverageCosts: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}meal_type_average_costs'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
      lastVerified: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_verified']),
      photoReference: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_reference']),
      photoReferences: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}photo_references'])!,
    );
  }

  @override
  $RestaurantsTable createAlias(String alias) {
    return $RestaurantsTable(attachedDatabase, alias);
  }
}

class Restaurant extends DataClass implements Insertable<Restaurant> {
  final String placeId;
  final String name;
  final String location;
  final String? address;
  final String? phoneNumber;
  final String? website;
  final double? latitude;
  final double? longitude;
  final double? distanceFromUser;
  final double? rating;
  final int? reviewCount;
  final int? priceLevel;
  final String priceRanges;
  final String? cuisineType;
  final String cuisineTypes;
  final String supportedDietaryRestrictions;
  final String allergenInfo;
  final String dietaryCompatibilityScores;
  final bool hasVerifiedDietaryInfo;
  final int communityVerificationCount;
  final String openingHours;
  final bool isOpenNow;
  final String? currentWaitTime;
  final String features;
  final double? averageMealCost;
  final double? valueScore;
  final String mealTypeAverageCosts;
  final DateTime cachedAt;
  final DateTime? lastVerified;
  final String? photoReference;
  final String photoReferences;
  const Restaurant(
      {required this.placeId,
      required this.name,
      required this.location,
      this.address,
      this.phoneNumber,
      this.website,
      this.latitude,
      this.longitude,
      this.distanceFromUser,
      this.rating,
      this.reviewCount,
      this.priceLevel,
      required this.priceRanges,
      this.cuisineType,
      required this.cuisineTypes,
      required this.supportedDietaryRestrictions,
      required this.allergenInfo,
      required this.dietaryCompatibilityScores,
      required this.hasVerifiedDietaryInfo,
      required this.communityVerificationCount,
      required this.openingHours,
      required this.isOpenNow,
      this.currentWaitTime,
      required this.features,
      this.averageMealCost,
      this.valueScore,
      required this.mealTypeAverageCosts,
      required this.cachedAt,
      this.lastVerified,
      this.photoReference,
      required this.photoReferences});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['place_id'] = Variable<String>(placeId);
    map['name'] = Variable<String>(name);
    map['location'] = Variable<String>(location);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || website != null) {
      map['website'] = Variable<String>(website);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || distanceFromUser != null) {
      map['distance_from_user'] = Variable<double>(distanceFromUser);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || reviewCount != null) {
      map['review_count'] = Variable<int>(reviewCount);
    }
    if (!nullToAbsent || priceLevel != null) {
      map['price_level'] = Variable<int>(priceLevel);
    }
    map['price_ranges'] = Variable<String>(priceRanges);
    if (!nullToAbsent || cuisineType != null) {
      map['cuisine_type'] = Variable<String>(cuisineType);
    }
    map['cuisine_types'] = Variable<String>(cuisineTypes);
    map['supported_dietary_restrictions'] =
        Variable<String>(supportedDietaryRestrictions);
    map['allergen_info'] = Variable<String>(allergenInfo);
    map['dietary_compatibility_scores'] =
        Variable<String>(dietaryCompatibilityScores);
    map['has_verified_dietary_info'] = Variable<bool>(hasVerifiedDietaryInfo);
    map['community_verification_count'] =
        Variable<int>(communityVerificationCount);
    map['opening_hours'] = Variable<String>(openingHours);
    map['is_open_now'] = Variable<bool>(isOpenNow);
    if (!nullToAbsent || currentWaitTime != null) {
      map['current_wait_time'] = Variable<String>(currentWaitTime);
    }
    map['features'] = Variable<String>(features);
    if (!nullToAbsent || averageMealCost != null) {
      map['average_meal_cost'] = Variable<double>(averageMealCost);
    }
    if (!nullToAbsent || valueScore != null) {
      map['value_score'] = Variable<double>(valueScore);
    }
    map['meal_type_average_costs'] = Variable<String>(mealTypeAverageCosts);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    if (!nullToAbsent || lastVerified != null) {
      map['last_verified'] = Variable<DateTime>(lastVerified);
    }
    if (!nullToAbsent || photoReference != null) {
      map['photo_reference'] = Variable<String>(photoReference);
    }
    map['photo_references'] = Variable<String>(photoReferences);
    return map;
  }

  RestaurantsCompanion toCompanion(bool nullToAbsent) {
    return RestaurantsCompanion(
      placeId: Value(placeId),
      name: Value(name),
      location: Value(location),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      website: website == null && nullToAbsent
          ? const Value.absent()
          : Value(website),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      distanceFromUser: distanceFromUser == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceFromUser),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      reviewCount: reviewCount == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewCount),
      priceLevel: priceLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(priceLevel),
      priceRanges: Value(priceRanges),
      cuisineType: cuisineType == null && nullToAbsent
          ? const Value.absent()
          : Value(cuisineType),
      cuisineTypes: Value(cuisineTypes),
      supportedDietaryRestrictions: Value(supportedDietaryRestrictions),
      allergenInfo: Value(allergenInfo),
      dietaryCompatibilityScores: Value(dietaryCompatibilityScores),
      hasVerifiedDietaryInfo: Value(hasVerifiedDietaryInfo),
      communityVerificationCount: Value(communityVerificationCount),
      openingHours: Value(openingHours),
      isOpenNow: Value(isOpenNow),
      currentWaitTime: currentWaitTime == null && nullToAbsent
          ? const Value.absent()
          : Value(currentWaitTime),
      features: Value(features),
      averageMealCost: averageMealCost == null && nullToAbsent
          ? const Value.absent()
          : Value(averageMealCost),
      valueScore: valueScore == null && nullToAbsent
          ? const Value.absent()
          : Value(valueScore),
      mealTypeAverageCosts: Value(mealTypeAverageCosts),
      cachedAt: Value(cachedAt),
      lastVerified: lastVerified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVerified),
      photoReference: photoReference == null && nullToAbsent
          ? const Value.absent()
          : Value(photoReference),
      photoReferences: Value(photoReferences),
    );
  }

  factory Restaurant.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Restaurant(
      placeId: serializer.fromJson<String>(json['placeId']),
      name: serializer.fromJson<String>(json['name']),
      location: serializer.fromJson<String>(json['location']),
      address: serializer.fromJson<String?>(json['address']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      website: serializer.fromJson<String?>(json['website']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      distanceFromUser: serializer.fromJson<double?>(json['distanceFromUser']),
      rating: serializer.fromJson<double?>(json['rating']),
      reviewCount: serializer.fromJson<int?>(json['reviewCount']),
      priceLevel: serializer.fromJson<int?>(json['priceLevel']),
      priceRanges: serializer.fromJson<String>(json['priceRanges']),
      cuisineType: serializer.fromJson<String?>(json['cuisineType']),
      cuisineTypes: serializer.fromJson<String>(json['cuisineTypes']),
      supportedDietaryRestrictions:
          serializer.fromJson<String>(json['supportedDietaryRestrictions']),
      allergenInfo: serializer.fromJson<String>(json['allergenInfo']),
      dietaryCompatibilityScores:
          serializer.fromJson<String>(json['dietaryCompatibilityScores']),
      hasVerifiedDietaryInfo:
          serializer.fromJson<bool>(json['hasVerifiedDietaryInfo']),
      communityVerificationCount:
          serializer.fromJson<int>(json['communityVerificationCount']),
      openingHours: serializer.fromJson<String>(json['openingHours']),
      isOpenNow: serializer.fromJson<bool>(json['isOpenNow']),
      currentWaitTime: serializer.fromJson<String?>(json['currentWaitTime']),
      features: serializer.fromJson<String>(json['features']),
      averageMealCost: serializer.fromJson<double?>(json['averageMealCost']),
      valueScore: serializer.fromJson<double?>(json['valueScore']),
      mealTypeAverageCosts:
          serializer.fromJson<String>(json['mealTypeAverageCosts']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      lastVerified: serializer.fromJson<DateTime?>(json['lastVerified']),
      photoReference: serializer.fromJson<String?>(json['photoReference']),
      photoReferences: serializer.fromJson<String>(json['photoReferences']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'placeId': serializer.toJson<String>(placeId),
      'name': serializer.toJson<String>(name),
      'location': serializer.toJson<String>(location),
      'address': serializer.toJson<String?>(address),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'website': serializer.toJson<String?>(website),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'distanceFromUser': serializer.toJson<double?>(distanceFromUser),
      'rating': serializer.toJson<double?>(rating),
      'reviewCount': serializer.toJson<int?>(reviewCount),
      'priceLevel': serializer.toJson<int?>(priceLevel),
      'priceRanges': serializer.toJson<String>(priceRanges),
      'cuisineType': serializer.toJson<String?>(cuisineType),
      'cuisineTypes': serializer.toJson<String>(cuisineTypes),
      'supportedDietaryRestrictions':
          serializer.toJson<String>(supportedDietaryRestrictions),
      'allergenInfo': serializer.toJson<String>(allergenInfo),
      'dietaryCompatibilityScores':
          serializer.toJson<String>(dietaryCompatibilityScores),
      'hasVerifiedDietaryInfo': serializer.toJson<bool>(hasVerifiedDietaryInfo),
      'communityVerificationCount':
          serializer.toJson<int>(communityVerificationCount),
      'openingHours': serializer.toJson<String>(openingHours),
      'isOpenNow': serializer.toJson<bool>(isOpenNow),
      'currentWaitTime': serializer.toJson<String?>(currentWaitTime),
      'features': serializer.toJson<String>(features),
      'averageMealCost': serializer.toJson<double?>(averageMealCost),
      'valueScore': serializer.toJson<double?>(valueScore),
      'mealTypeAverageCosts': serializer.toJson<String>(mealTypeAverageCosts),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'lastVerified': serializer.toJson<DateTime?>(lastVerified),
      'photoReference': serializer.toJson<String?>(photoReference),
      'photoReferences': serializer.toJson<String>(photoReferences),
    };
  }

  Restaurant copyWith(
          {String? placeId,
          String? name,
          String? location,
          Value<String?> address = const Value.absent(),
          Value<String?> phoneNumber = const Value.absent(),
          Value<String?> website = const Value.absent(),
          Value<double?> latitude = const Value.absent(),
          Value<double?> longitude = const Value.absent(),
          Value<double?> distanceFromUser = const Value.absent(),
          Value<double?> rating = const Value.absent(),
          Value<int?> reviewCount = const Value.absent(),
          Value<int?> priceLevel = const Value.absent(),
          String? priceRanges,
          Value<String?> cuisineType = const Value.absent(),
          String? cuisineTypes,
          String? supportedDietaryRestrictions,
          String? allergenInfo,
          String? dietaryCompatibilityScores,
          bool? hasVerifiedDietaryInfo,
          int? communityVerificationCount,
          String? openingHours,
          bool? isOpenNow,
          Value<String?> currentWaitTime = const Value.absent(),
          String? features,
          Value<double?> averageMealCost = const Value.absent(),
          Value<double?> valueScore = const Value.absent(),
          String? mealTypeAverageCosts,
          DateTime? cachedAt,
          Value<DateTime?> lastVerified = const Value.absent(),
          Value<String?> photoReference = const Value.absent(),
          String? photoReferences}) =>
      Restaurant(
        placeId: placeId ?? this.placeId,
        name: name ?? this.name,
        location: location ?? this.location,
        address: address.present ? address.value : this.address,
        phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
        website: website.present ? website.value : this.website,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
        distanceFromUser: distanceFromUser.present
            ? distanceFromUser.value
            : this.distanceFromUser,
        rating: rating.present ? rating.value : this.rating,
        reviewCount: reviewCount.present ? reviewCount.value : this.reviewCount,
        priceLevel: priceLevel.present ? priceLevel.value : this.priceLevel,
        priceRanges: priceRanges ?? this.priceRanges,
        cuisineType: cuisineType.present ? cuisineType.value : this.cuisineType,
        cuisineTypes: cuisineTypes ?? this.cuisineTypes,
        supportedDietaryRestrictions:
            supportedDietaryRestrictions ?? this.supportedDietaryRestrictions,
        allergenInfo: allergenInfo ?? this.allergenInfo,
        dietaryCompatibilityScores:
            dietaryCompatibilityScores ?? this.dietaryCompatibilityScores,
        hasVerifiedDietaryInfo:
            hasVerifiedDietaryInfo ?? this.hasVerifiedDietaryInfo,
        communityVerificationCount:
            communityVerificationCount ?? this.communityVerificationCount,
        openingHours: openingHours ?? this.openingHours,
        isOpenNow: isOpenNow ?? this.isOpenNow,
        currentWaitTime: currentWaitTime.present
            ? currentWaitTime.value
            : this.currentWaitTime,
        features: features ?? this.features,
        averageMealCost: averageMealCost.present
            ? averageMealCost.value
            : this.averageMealCost,
        valueScore: valueScore.present ? valueScore.value : this.valueScore,
        mealTypeAverageCosts: mealTypeAverageCosts ?? this.mealTypeAverageCosts,
        cachedAt: cachedAt ?? this.cachedAt,
        lastVerified:
            lastVerified.present ? lastVerified.value : this.lastVerified,
        photoReference:
            photoReference.present ? photoReference.value : this.photoReference,
        photoReferences: photoReferences ?? this.photoReferences,
      );
  Restaurant copyWithCompanion(RestaurantsCompanion data) {
    return Restaurant(
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      name: data.name.present ? data.name.value : this.name,
      location: data.location.present ? data.location.value : this.location,
      address: data.address.present ? data.address.value : this.address,
      phoneNumber:
          data.phoneNumber.present ? data.phoneNumber.value : this.phoneNumber,
      website: data.website.present ? data.website.value : this.website,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      distanceFromUser: data.distanceFromUser.present
          ? data.distanceFromUser.value
          : this.distanceFromUser,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewCount:
          data.reviewCount.present ? data.reviewCount.value : this.reviewCount,
      priceLevel:
          data.priceLevel.present ? data.priceLevel.value : this.priceLevel,
      priceRanges:
          data.priceRanges.present ? data.priceRanges.value : this.priceRanges,
      cuisineType:
          data.cuisineType.present ? data.cuisineType.value : this.cuisineType,
      cuisineTypes: data.cuisineTypes.present
          ? data.cuisineTypes.value
          : this.cuisineTypes,
      supportedDietaryRestrictions: data.supportedDietaryRestrictions.present
          ? data.supportedDietaryRestrictions.value
          : this.supportedDietaryRestrictions,
      allergenInfo: data.allergenInfo.present
          ? data.allergenInfo.value
          : this.allergenInfo,
      dietaryCompatibilityScores: data.dietaryCompatibilityScores.present
          ? data.dietaryCompatibilityScores.value
          : this.dietaryCompatibilityScores,
      hasVerifiedDietaryInfo: data.hasVerifiedDietaryInfo.present
          ? data.hasVerifiedDietaryInfo.value
          : this.hasVerifiedDietaryInfo,
      communityVerificationCount: data.communityVerificationCount.present
          ? data.communityVerificationCount.value
          : this.communityVerificationCount,
      openingHours: data.openingHours.present
          ? data.openingHours.value
          : this.openingHours,
      isOpenNow: data.isOpenNow.present ? data.isOpenNow.value : this.isOpenNow,
      currentWaitTime: data.currentWaitTime.present
          ? data.currentWaitTime.value
          : this.currentWaitTime,
      features: data.features.present ? data.features.value : this.features,
      averageMealCost: data.averageMealCost.present
          ? data.averageMealCost.value
          : this.averageMealCost,
      valueScore:
          data.valueScore.present ? data.valueScore.value : this.valueScore,
      mealTypeAverageCosts: data.mealTypeAverageCosts.present
          ? data.mealTypeAverageCosts.value
          : this.mealTypeAverageCosts,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      lastVerified: data.lastVerified.present
          ? data.lastVerified.value
          : this.lastVerified,
      photoReference: data.photoReference.present
          ? data.photoReference.value
          : this.photoReference,
      photoReferences: data.photoReferences.present
          ? data.photoReferences.value
          : this.photoReferences,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Restaurant(')
          ..write('placeId: $placeId, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('address: $address, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('website: $website, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('distanceFromUser: $distanceFromUser, ')
          ..write('rating: $rating, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('priceLevel: $priceLevel, ')
          ..write('priceRanges: $priceRanges, ')
          ..write('cuisineType: $cuisineType, ')
          ..write('cuisineTypes: $cuisineTypes, ')
          ..write(
              'supportedDietaryRestrictions: $supportedDietaryRestrictions, ')
          ..write('allergenInfo: $allergenInfo, ')
          ..write('dietaryCompatibilityScores: $dietaryCompatibilityScores, ')
          ..write('hasVerifiedDietaryInfo: $hasVerifiedDietaryInfo, ')
          ..write('communityVerificationCount: $communityVerificationCount, ')
          ..write('openingHours: $openingHours, ')
          ..write('isOpenNow: $isOpenNow, ')
          ..write('currentWaitTime: $currentWaitTime, ')
          ..write('features: $features, ')
          ..write('averageMealCost: $averageMealCost, ')
          ..write('valueScore: $valueScore, ')
          ..write('mealTypeAverageCosts: $mealTypeAverageCosts, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastVerified: $lastVerified, ')
          ..write('photoReference: $photoReference, ')
          ..write('photoReferences: $photoReferences')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        placeId,
        name,
        location,
        address,
        phoneNumber,
        website,
        latitude,
        longitude,
        distanceFromUser,
        rating,
        reviewCount,
        priceLevel,
        priceRanges,
        cuisineType,
        cuisineTypes,
        supportedDietaryRestrictions,
        allergenInfo,
        dietaryCompatibilityScores,
        hasVerifiedDietaryInfo,
        communityVerificationCount,
        openingHours,
        isOpenNow,
        currentWaitTime,
        features,
        averageMealCost,
        valueScore,
        mealTypeAverageCosts,
        cachedAt,
        lastVerified,
        photoReference,
        photoReferences
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Restaurant &&
          other.placeId == this.placeId &&
          other.name == this.name &&
          other.location == this.location &&
          other.address == this.address &&
          other.phoneNumber == this.phoneNumber &&
          other.website == this.website &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.distanceFromUser == this.distanceFromUser &&
          other.rating == this.rating &&
          other.reviewCount == this.reviewCount &&
          other.priceLevel == this.priceLevel &&
          other.priceRanges == this.priceRanges &&
          other.cuisineType == this.cuisineType &&
          other.cuisineTypes == this.cuisineTypes &&
          other.supportedDietaryRestrictions ==
              this.supportedDietaryRestrictions &&
          other.allergenInfo == this.allergenInfo &&
          other.dietaryCompatibilityScores == this.dietaryCompatibilityScores &&
          other.hasVerifiedDietaryInfo == this.hasVerifiedDietaryInfo &&
          other.communityVerificationCount == this.communityVerificationCount &&
          other.openingHours == this.openingHours &&
          other.isOpenNow == this.isOpenNow &&
          other.currentWaitTime == this.currentWaitTime &&
          other.features == this.features &&
          other.averageMealCost == this.averageMealCost &&
          other.valueScore == this.valueScore &&
          other.mealTypeAverageCosts == this.mealTypeAverageCosts &&
          other.cachedAt == this.cachedAt &&
          other.lastVerified == this.lastVerified &&
          other.photoReference == this.photoReference &&
          other.photoReferences == this.photoReferences);
}

class RestaurantsCompanion extends UpdateCompanion<Restaurant> {
  final Value<String> placeId;
  final Value<String> name;
  final Value<String> location;
  final Value<String?> address;
  final Value<String?> phoneNumber;
  final Value<String?> website;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<double?> distanceFromUser;
  final Value<double?> rating;
  final Value<int?> reviewCount;
  final Value<int?> priceLevel;
  final Value<String> priceRanges;
  final Value<String?> cuisineType;
  final Value<String> cuisineTypes;
  final Value<String> supportedDietaryRestrictions;
  final Value<String> allergenInfo;
  final Value<String> dietaryCompatibilityScores;
  final Value<bool> hasVerifiedDietaryInfo;
  final Value<int> communityVerificationCount;
  final Value<String> openingHours;
  final Value<bool> isOpenNow;
  final Value<String?> currentWaitTime;
  final Value<String> features;
  final Value<double?> averageMealCost;
  final Value<double?> valueScore;
  final Value<String> mealTypeAverageCosts;
  final Value<DateTime> cachedAt;
  final Value<DateTime?> lastVerified;
  final Value<String?> photoReference;
  final Value<String> photoReferences;
  final Value<int> rowid;
  const RestaurantsCompanion({
    this.placeId = const Value.absent(),
    this.name = const Value.absent(),
    this.location = const Value.absent(),
    this.address = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.website = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.distanceFromUser = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.priceLevel = const Value.absent(),
    this.priceRanges = const Value.absent(),
    this.cuisineType = const Value.absent(),
    this.cuisineTypes = const Value.absent(),
    this.supportedDietaryRestrictions = const Value.absent(),
    this.allergenInfo = const Value.absent(),
    this.dietaryCompatibilityScores = const Value.absent(),
    this.hasVerifiedDietaryInfo = const Value.absent(),
    this.communityVerificationCount = const Value.absent(),
    this.openingHours = const Value.absent(),
    this.isOpenNow = const Value.absent(),
    this.currentWaitTime = const Value.absent(),
    this.features = const Value.absent(),
    this.averageMealCost = const Value.absent(),
    this.valueScore = const Value.absent(),
    this.mealTypeAverageCosts = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.lastVerified = const Value.absent(),
    this.photoReference = const Value.absent(),
    this.photoReferences = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RestaurantsCompanion.insert({
    required String placeId,
    required String name,
    required String location,
    this.address = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.website = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.distanceFromUser = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.priceLevel = const Value.absent(),
    this.priceRanges = const Value.absent(),
    this.cuisineType = const Value.absent(),
    this.cuisineTypes = const Value.absent(),
    this.supportedDietaryRestrictions = const Value.absent(),
    this.allergenInfo = const Value.absent(),
    this.dietaryCompatibilityScores = const Value.absent(),
    this.hasVerifiedDietaryInfo = const Value.absent(),
    this.communityVerificationCount = const Value.absent(),
    this.openingHours = const Value.absent(),
    this.isOpenNow = const Value.absent(),
    this.currentWaitTime = const Value.absent(),
    this.features = const Value.absent(),
    this.averageMealCost = const Value.absent(),
    this.valueScore = const Value.absent(),
    this.mealTypeAverageCosts = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.lastVerified = const Value.absent(),
    this.photoReference = const Value.absent(),
    this.photoReferences = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : placeId = Value(placeId),
        name = Value(name),
        location = Value(location);
  static Insertable<Restaurant> custom({
    Expression<String>? placeId,
    Expression<String>? name,
    Expression<String>? location,
    Expression<String>? address,
    Expression<String>? phoneNumber,
    Expression<String>? website,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? distanceFromUser,
    Expression<double>? rating,
    Expression<int>? reviewCount,
    Expression<int>? priceLevel,
    Expression<String>? priceRanges,
    Expression<String>? cuisineType,
    Expression<String>? cuisineTypes,
    Expression<String>? supportedDietaryRestrictions,
    Expression<String>? allergenInfo,
    Expression<String>? dietaryCompatibilityScores,
    Expression<bool>? hasVerifiedDietaryInfo,
    Expression<int>? communityVerificationCount,
    Expression<String>? openingHours,
    Expression<bool>? isOpenNow,
    Expression<String>? currentWaitTime,
    Expression<String>? features,
    Expression<double>? averageMealCost,
    Expression<double>? valueScore,
    Expression<String>? mealTypeAverageCosts,
    Expression<DateTime>? cachedAt,
    Expression<DateTime>? lastVerified,
    Expression<String>? photoReference,
    Expression<String>? photoReferences,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (placeId != null) 'place_id': placeId,
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (address != null) 'address': address,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (website != null) 'website': website,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (distanceFromUser != null) 'distance_from_user': distanceFromUser,
      if (rating != null) 'rating': rating,
      if (reviewCount != null) 'review_count': reviewCount,
      if (priceLevel != null) 'price_level': priceLevel,
      if (priceRanges != null) 'price_ranges': priceRanges,
      if (cuisineType != null) 'cuisine_type': cuisineType,
      if (cuisineTypes != null) 'cuisine_types': cuisineTypes,
      if (supportedDietaryRestrictions != null)
        'supported_dietary_restrictions': supportedDietaryRestrictions,
      if (allergenInfo != null) 'allergen_info': allergenInfo,
      if (dietaryCompatibilityScores != null)
        'dietary_compatibility_scores': dietaryCompatibilityScores,
      if (hasVerifiedDietaryInfo != null)
        'has_verified_dietary_info': hasVerifiedDietaryInfo,
      if (communityVerificationCount != null)
        'community_verification_count': communityVerificationCount,
      if (openingHours != null) 'opening_hours': openingHours,
      if (isOpenNow != null) 'is_open_now': isOpenNow,
      if (currentWaitTime != null) 'current_wait_time': currentWaitTime,
      if (features != null) 'features': features,
      if (averageMealCost != null) 'average_meal_cost': averageMealCost,
      if (valueScore != null) 'value_score': valueScore,
      if (mealTypeAverageCosts != null)
        'meal_type_average_costs': mealTypeAverageCosts,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (lastVerified != null) 'last_verified': lastVerified,
      if (photoReference != null) 'photo_reference': photoReference,
      if (photoReferences != null) 'photo_references': photoReferences,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RestaurantsCompanion copyWith(
      {Value<String>? placeId,
      Value<String>? name,
      Value<String>? location,
      Value<String?>? address,
      Value<String?>? phoneNumber,
      Value<String?>? website,
      Value<double?>? latitude,
      Value<double?>? longitude,
      Value<double?>? distanceFromUser,
      Value<double?>? rating,
      Value<int?>? reviewCount,
      Value<int?>? priceLevel,
      Value<String>? priceRanges,
      Value<String?>? cuisineType,
      Value<String>? cuisineTypes,
      Value<String>? supportedDietaryRestrictions,
      Value<String>? allergenInfo,
      Value<String>? dietaryCompatibilityScores,
      Value<bool>? hasVerifiedDietaryInfo,
      Value<int>? communityVerificationCount,
      Value<String>? openingHours,
      Value<bool>? isOpenNow,
      Value<String?>? currentWaitTime,
      Value<String>? features,
      Value<double?>? averageMealCost,
      Value<double?>? valueScore,
      Value<String>? mealTypeAverageCosts,
      Value<DateTime>? cachedAt,
      Value<DateTime?>? lastVerified,
      Value<String?>? photoReference,
      Value<String>? photoReferences,
      Value<int>? rowid}) {
    return RestaurantsCompanion(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      location: location ?? this.location,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      priceLevel: priceLevel ?? this.priceLevel,
      priceRanges: priceRanges ?? this.priceRanges,
      cuisineType: cuisineType ?? this.cuisineType,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      supportedDietaryRestrictions:
          supportedDietaryRestrictions ?? this.supportedDietaryRestrictions,
      allergenInfo: allergenInfo ?? this.allergenInfo,
      dietaryCompatibilityScores:
          dietaryCompatibilityScores ?? this.dietaryCompatibilityScores,
      hasVerifiedDietaryInfo:
          hasVerifiedDietaryInfo ?? this.hasVerifiedDietaryInfo,
      communityVerificationCount:
          communityVerificationCount ?? this.communityVerificationCount,
      openingHours: openingHours ?? this.openingHours,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      currentWaitTime: currentWaitTime ?? this.currentWaitTime,
      features: features ?? this.features,
      averageMealCost: averageMealCost ?? this.averageMealCost,
      valueScore: valueScore ?? this.valueScore,
      mealTypeAverageCosts: mealTypeAverageCosts ?? this.mealTypeAverageCosts,
      cachedAt: cachedAt ?? this.cachedAt,
      lastVerified: lastVerified ?? this.lastVerified,
      photoReference: photoReference ?? this.photoReference,
      photoReferences: photoReferences ?? this.photoReferences,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (placeId.present) {
      map['place_id'] = Variable<String>(placeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (website.present) {
      map['website'] = Variable<String>(website.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (distanceFromUser.present) {
      map['distance_from_user'] = Variable<double>(distanceFromUser.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (priceLevel.present) {
      map['price_level'] = Variable<int>(priceLevel.value);
    }
    if (priceRanges.present) {
      map['price_ranges'] = Variable<String>(priceRanges.value);
    }
    if (cuisineType.present) {
      map['cuisine_type'] = Variable<String>(cuisineType.value);
    }
    if (cuisineTypes.present) {
      map['cuisine_types'] = Variable<String>(cuisineTypes.value);
    }
    if (supportedDietaryRestrictions.present) {
      map['supported_dietary_restrictions'] =
          Variable<String>(supportedDietaryRestrictions.value);
    }
    if (allergenInfo.present) {
      map['allergen_info'] = Variable<String>(allergenInfo.value);
    }
    if (dietaryCompatibilityScores.present) {
      map['dietary_compatibility_scores'] =
          Variable<String>(dietaryCompatibilityScores.value);
    }
    if (hasVerifiedDietaryInfo.present) {
      map['has_verified_dietary_info'] =
          Variable<bool>(hasVerifiedDietaryInfo.value);
    }
    if (communityVerificationCount.present) {
      map['community_verification_count'] =
          Variable<int>(communityVerificationCount.value);
    }
    if (openingHours.present) {
      map['opening_hours'] = Variable<String>(openingHours.value);
    }
    if (isOpenNow.present) {
      map['is_open_now'] = Variable<bool>(isOpenNow.value);
    }
    if (currentWaitTime.present) {
      map['current_wait_time'] = Variable<String>(currentWaitTime.value);
    }
    if (features.present) {
      map['features'] = Variable<String>(features.value);
    }
    if (averageMealCost.present) {
      map['average_meal_cost'] = Variable<double>(averageMealCost.value);
    }
    if (valueScore.present) {
      map['value_score'] = Variable<double>(valueScore.value);
    }
    if (mealTypeAverageCosts.present) {
      map['meal_type_average_costs'] =
          Variable<String>(mealTypeAverageCosts.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (lastVerified.present) {
      map['last_verified'] = Variable<DateTime>(lastVerified.value);
    }
    if (photoReference.present) {
      map['photo_reference'] = Variable<String>(photoReference.value);
    }
    if (photoReferences.present) {
      map['photo_references'] = Variable<String>(photoReferences.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RestaurantsCompanion(')
          ..write('placeId: $placeId, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('address: $address, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('website: $website, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('distanceFromUser: $distanceFromUser, ')
          ..write('rating: $rating, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('priceLevel: $priceLevel, ')
          ..write('priceRanges: $priceRanges, ')
          ..write('cuisineType: $cuisineType, ')
          ..write('cuisineTypes: $cuisineTypes, ')
          ..write(
              'supportedDietaryRestrictions: $supportedDietaryRestrictions, ')
          ..write('allergenInfo: $allergenInfo, ')
          ..write('dietaryCompatibilityScores: $dietaryCompatibilityScores, ')
          ..write('hasVerifiedDietaryInfo: $hasVerifiedDietaryInfo, ')
          ..write('communityVerificationCount: $communityVerificationCount, ')
          ..write('openingHours: $openingHours, ')
          ..write('isOpenNow: $isOpenNow, ')
          ..write('currentWaitTime: $currentWaitTime, ')
          ..write('features: $features, ')
          ..write('averageMealCost: $averageMealCost, ')
          ..write('valueScore: $valueScore, ')
          ..write('mealTypeAverageCosts: $mealTypeAverageCosts, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastVerified: $lastVerified, ')
          ..write('photoReference: $photoReference, ')
          ..write('photoReferences: $photoReferences, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RestaurantCacheTable extends RestaurantCache
    with TableInfo<$RestaurantCacheTable, RestaurantCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RestaurantCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _placeIdMeta =
      const VerificationMeta('placeId');
  @override
  late final GeneratedColumn<String> placeId = GeneratedColumn<String>(
      'place_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _searchQueryMeta =
      const VerificationMeta('searchQuery');
  @override
  late final GeneratedColumn<String> searchQuery = GeneratedColumn<String>(
      'search_query', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userLatitudeMeta =
      const VerificationMeta('userLatitude');
  @override
  late final GeneratedColumn<double> userLatitude = GeneratedColumn<double>(
      'user_latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _userLongitudeMeta =
      const VerificationMeta('userLongitude');
  @override
  late final GeneratedColumn<double> userLongitude = GeneratedColumn<double>(
      'user_longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [placeId, searchQuery, userLatitude, userLongitude, cachedAt, expiresAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'restaurant_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<RestaurantCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('place_id')) {
      context.handle(_placeIdMeta,
          placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta));
    } else if (isInserting) {
      context.missing(_placeIdMeta);
    }
    if (data.containsKey('search_query')) {
      context.handle(
          _searchQueryMeta,
          searchQuery.isAcceptableOrUnknown(
              data['search_query']!, _searchQueryMeta));
    } else if (isInserting) {
      context.missing(_searchQueryMeta);
    }
    if (data.containsKey('user_latitude')) {
      context.handle(
          _userLatitudeMeta,
          userLatitude.isAcceptableOrUnknown(
              data['user_latitude']!, _userLatitudeMeta));
    } else if (isInserting) {
      context.missing(_userLatitudeMeta);
    }
    if (data.containsKey('user_longitude')) {
      context.handle(
          _userLongitudeMeta,
          userLongitude.isAcceptableOrUnknown(
              data['user_longitude']!, _userLongitudeMeta));
    } else if (isInserting) {
      context.missing(_userLongitudeMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {placeId, searchQuery};
  @override
  RestaurantCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RestaurantCacheData(
      placeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}place_id'])!,
      searchQuery: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}search_query'])!,
      userLatitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}user_latitude'])!,
      userLongitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}user_longitude'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at'])!,
    );
  }

  @override
  $RestaurantCacheTable createAlias(String alias) {
    return $RestaurantCacheTable(attachedDatabase, alias);
  }
}

class RestaurantCacheData extends DataClass
    implements Insertable<RestaurantCacheData> {
  final String placeId;
  final String searchQuery;
  final double userLatitude;
  final double userLongitude;
  final DateTime cachedAt;
  final DateTime expiresAt;
  const RestaurantCacheData(
      {required this.placeId,
      required this.searchQuery,
      required this.userLatitude,
      required this.userLongitude,
      required this.cachedAt,
      required this.expiresAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['place_id'] = Variable<String>(placeId);
    map['search_query'] = Variable<String>(searchQuery);
    map['user_latitude'] = Variable<double>(userLatitude);
    map['user_longitude'] = Variable<double>(userLongitude);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  RestaurantCacheCompanion toCompanion(bool nullToAbsent) {
    return RestaurantCacheCompanion(
      placeId: Value(placeId),
      searchQuery: Value(searchQuery),
      userLatitude: Value(userLatitude),
      userLongitude: Value(userLongitude),
      cachedAt: Value(cachedAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory RestaurantCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RestaurantCacheData(
      placeId: serializer.fromJson<String>(json['placeId']),
      searchQuery: serializer.fromJson<String>(json['searchQuery']),
      userLatitude: serializer.fromJson<double>(json['userLatitude']),
      userLongitude: serializer.fromJson<double>(json['userLongitude']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'placeId': serializer.toJson<String>(placeId),
      'searchQuery': serializer.toJson<String>(searchQuery),
      'userLatitude': serializer.toJson<double>(userLatitude),
      'userLongitude': serializer.toJson<double>(userLongitude),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  RestaurantCacheData copyWith(
          {String? placeId,
          String? searchQuery,
          double? userLatitude,
          double? userLongitude,
          DateTime? cachedAt,
          DateTime? expiresAt}) =>
      RestaurantCacheData(
        placeId: placeId ?? this.placeId,
        searchQuery: searchQuery ?? this.searchQuery,
        userLatitude: userLatitude ?? this.userLatitude,
        userLongitude: userLongitude ?? this.userLongitude,
        cachedAt: cachedAt ?? this.cachedAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );
  RestaurantCacheData copyWithCompanion(RestaurantCacheCompanion data) {
    return RestaurantCacheData(
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      searchQuery:
          data.searchQuery.present ? data.searchQuery.value : this.searchQuery,
      userLatitude: data.userLatitude.present
          ? data.userLatitude.value
          : this.userLatitude,
      userLongitude: data.userLongitude.present
          ? data.userLongitude.value
          : this.userLongitude,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RestaurantCacheData(')
          ..write('placeId: $placeId, ')
          ..write('searchQuery: $searchQuery, ')
          ..write('userLatitude: $userLatitude, ')
          ..write('userLongitude: $userLongitude, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      placeId, searchQuery, userLatitude, userLongitude, cachedAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RestaurantCacheData &&
          other.placeId == this.placeId &&
          other.searchQuery == this.searchQuery &&
          other.userLatitude == this.userLatitude &&
          other.userLongitude == this.userLongitude &&
          other.cachedAt == this.cachedAt &&
          other.expiresAt == this.expiresAt);
}

class RestaurantCacheCompanion extends UpdateCompanion<RestaurantCacheData> {
  final Value<String> placeId;
  final Value<String> searchQuery;
  final Value<double> userLatitude;
  final Value<double> userLongitude;
  final Value<DateTime> cachedAt;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const RestaurantCacheCompanion({
    this.placeId = const Value.absent(),
    this.searchQuery = const Value.absent(),
    this.userLatitude = const Value.absent(),
    this.userLongitude = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RestaurantCacheCompanion.insert({
    required String placeId,
    required String searchQuery,
    required double userLatitude,
    required double userLongitude,
    this.cachedAt = const Value.absent(),
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  })  : placeId = Value(placeId),
        searchQuery = Value(searchQuery),
        userLatitude = Value(userLatitude),
        userLongitude = Value(userLongitude),
        expiresAt = Value(expiresAt);
  static Insertable<RestaurantCacheData> custom({
    Expression<String>? placeId,
    Expression<String>? searchQuery,
    Expression<double>? userLatitude,
    Expression<double>? userLongitude,
    Expression<DateTime>? cachedAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (placeId != null) 'place_id': placeId,
      if (searchQuery != null) 'search_query': searchQuery,
      if (userLatitude != null) 'user_latitude': userLatitude,
      if (userLongitude != null) 'user_longitude': userLongitude,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RestaurantCacheCompanion copyWith(
      {Value<String>? placeId,
      Value<String>? searchQuery,
      Value<double>? userLatitude,
      Value<double>? userLongitude,
      Value<DateTime>? cachedAt,
      Value<DateTime>? expiresAt,
      Value<int>? rowid}) {
    return RestaurantCacheCompanion(
      placeId: placeId ?? this.placeId,
      searchQuery: searchQuery ?? this.searchQuery,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      cachedAt: cachedAt ?? this.cachedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (placeId.present) {
      map['place_id'] = Variable<String>(placeId.value);
    }
    if (searchQuery.present) {
      map['search_query'] = Variable<String>(searchQuery.value);
    }
    if (userLatitude.present) {
      map['user_latitude'] = Variable<double>(userLatitude.value);
    }
    if (userLongitude.present) {
      map['user_longitude'] = Variable<double>(userLongitude.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RestaurantCacheCompanion(')
          ..write('placeId: $placeId, ')
          ..write('searchQuery: $searchQuery, ')
          ..write('userLatitude: $userLatitude, ')
          ..write('userLongitude: $userLongitude, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DietaryCompatibilityTable extends DietaryCompatibility
    with TableInfo<$DietaryCompatibilityTable, DietaryCompatibilityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DietaryCompatibilityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _placeIdMeta =
      const VerificationMeta('placeId');
  @override
  late final GeneratedColumn<String> placeId = GeneratedColumn<String>(
      'place_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES restaurants (place_id)'));
  static const VerificationMeta _dietaryRestrictionMeta =
      const VerificationMeta('dietaryRestriction');
  @override
  late final GeneratedColumn<String> dietaryRestriction =
      GeneratedColumn<String>('dietary_restriction', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _compatibilityScoreMeta =
      const VerificationMeta('compatibilityScore');
  @override
  late final GeneratedColumn<double> compatibilityScore =
      GeneratedColumn<double>('compatibility_score', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _isCommunityVerifiedMeta =
      const VerificationMeta('isCommunityVerified');
  @override
  late final GeneratedColumn<bool> isCommunityVerified = GeneratedColumn<bool>(
      'is_community_verified', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_community_verified" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _verificationCountMeta =
      const VerificationMeta('verificationCount');
  @override
  late final GeneratedColumn<int> verificationCount = GeneratedColumn<int>(
      'verification_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastVerifiedMeta =
      const VerificationMeta('lastVerified');
  @override
  late final GeneratedColumn<DateTime> lastVerified = GeneratedColumn<DateTime>(
      'last_verified', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        placeId,
        dietaryRestriction,
        compatibilityScore,
        isCommunityVerified,
        verificationCount,
        lastVerified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dietary_compatibility';
  @override
  VerificationContext validateIntegrity(
      Insertable<DietaryCompatibilityData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('place_id')) {
      context.handle(_placeIdMeta,
          placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta));
    } else if (isInserting) {
      context.missing(_placeIdMeta);
    }
    if (data.containsKey('dietary_restriction')) {
      context.handle(
          _dietaryRestrictionMeta,
          dietaryRestriction.isAcceptableOrUnknown(
              data['dietary_restriction']!, _dietaryRestrictionMeta));
    } else if (isInserting) {
      context.missing(_dietaryRestrictionMeta);
    }
    if (data.containsKey('compatibility_score')) {
      context.handle(
          _compatibilityScoreMeta,
          compatibilityScore.isAcceptableOrUnknown(
              data['compatibility_score']!, _compatibilityScoreMeta));
    } else if (isInserting) {
      context.missing(_compatibilityScoreMeta);
    }
    if (data.containsKey('is_community_verified')) {
      context.handle(
          _isCommunityVerifiedMeta,
          isCommunityVerified.isAcceptableOrUnknown(
              data['is_community_verified']!, _isCommunityVerifiedMeta));
    }
    if (data.containsKey('verification_count')) {
      context.handle(
          _verificationCountMeta,
          verificationCount.isAcceptableOrUnknown(
              data['verification_count']!, _verificationCountMeta));
    }
    if (data.containsKey('last_verified')) {
      context.handle(
          _lastVerifiedMeta,
          lastVerified.isAcceptableOrUnknown(
              data['last_verified']!, _lastVerifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DietaryCompatibilityData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DietaryCompatibilityData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      placeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}place_id'])!,
      dietaryRestriction: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}dietary_restriction'])!,
      compatibilityScore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}compatibility_score'])!,
      isCommunityVerified: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_community_verified'])!,
      verificationCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}verification_count'])!,
      lastVerified: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_verified']),
    );
  }

  @override
  $DietaryCompatibilityTable createAlias(String alias) {
    return $DietaryCompatibilityTable(attachedDatabase, alias);
  }
}

class DietaryCompatibilityData extends DataClass
    implements Insertable<DietaryCompatibilityData> {
  final int id;
  final String placeId;
  final String dietaryRestriction;
  final double compatibilityScore;
  final bool isCommunityVerified;
  final int verificationCount;
  final DateTime? lastVerified;
  const DietaryCompatibilityData(
      {required this.id,
      required this.placeId,
      required this.dietaryRestriction,
      required this.compatibilityScore,
      required this.isCommunityVerified,
      required this.verificationCount,
      this.lastVerified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['place_id'] = Variable<String>(placeId);
    map['dietary_restriction'] = Variable<String>(dietaryRestriction);
    map['compatibility_score'] = Variable<double>(compatibilityScore);
    map['is_community_verified'] = Variable<bool>(isCommunityVerified);
    map['verification_count'] = Variable<int>(verificationCount);
    if (!nullToAbsent || lastVerified != null) {
      map['last_verified'] = Variable<DateTime>(lastVerified);
    }
    return map;
  }

  DietaryCompatibilityCompanion toCompanion(bool nullToAbsent) {
    return DietaryCompatibilityCompanion(
      id: Value(id),
      placeId: Value(placeId),
      dietaryRestriction: Value(dietaryRestriction),
      compatibilityScore: Value(compatibilityScore),
      isCommunityVerified: Value(isCommunityVerified),
      verificationCount: Value(verificationCount),
      lastVerified: lastVerified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVerified),
    );
  }

  factory DietaryCompatibilityData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DietaryCompatibilityData(
      id: serializer.fromJson<int>(json['id']),
      placeId: serializer.fromJson<String>(json['placeId']),
      dietaryRestriction:
          serializer.fromJson<String>(json['dietaryRestriction']),
      compatibilityScore:
          serializer.fromJson<double>(json['compatibilityScore']),
      isCommunityVerified:
          serializer.fromJson<bool>(json['isCommunityVerified']),
      verificationCount: serializer.fromJson<int>(json['verificationCount']),
      lastVerified: serializer.fromJson<DateTime?>(json['lastVerified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'placeId': serializer.toJson<String>(placeId),
      'dietaryRestriction': serializer.toJson<String>(dietaryRestriction),
      'compatibilityScore': serializer.toJson<double>(compatibilityScore),
      'isCommunityVerified': serializer.toJson<bool>(isCommunityVerified),
      'verificationCount': serializer.toJson<int>(verificationCount),
      'lastVerified': serializer.toJson<DateTime?>(lastVerified),
    };
  }

  DietaryCompatibilityData copyWith(
          {int? id,
          String? placeId,
          String? dietaryRestriction,
          double? compatibilityScore,
          bool? isCommunityVerified,
          int? verificationCount,
          Value<DateTime?> lastVerified = const Value.absent()}) =>
      DietaryCompatibilityData(
        id: id ?? this.id,
        placeId: placeId ?? this.placeId,
        dietaryRestriction: dietaryRestriction ?? this.dietaryRestriction,
        compatibilityScore: compatibilityScore ?? this.compatibilityScore,
        isCommunityVerified: isCommunityVerified ?? this.isCommunityVerified,
        verificationCount: verificationCount ?? this.verificationCount,
        lastVerified:
            lastVerified.present ? lastVerified.value : this.lastVerified,
      );
  DietaryCompatibilityData copyWithCompanion(
      DietaryCompatibilityCompanion data) {
    return DietaryCompatibilityData(
      id: data.id.present ? data.id.value : this.id,
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      dietaryRestriction: data.dietaryRestriction.present
          ? data.dietaryRestriction.value
          : this.dietaryRestriction,
      compatibilityScore: data.compatibilityScore.present
          ? data.compatibilityScore.value
          : this.compatibilityScore,
      isCommunityVerified: data.isCommunityVerified.present
          ? data.isCommunityVerified.value
          : this.isCommunityVerified,
      verificationCount: data.verificationCount.present
          ? data.verificationCount.value
          : this.verificationCount,
      lastVerified: data.lastVerified.present
          ? data.lastVerified.value
          : this.lastVerified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DietaryCompatibilityData(')
          ..write('id: $id, ')
          ..write('placeId: $placeId, ')
          ..write('dietaryRestriction: $dietaryRestriction, ')
          ..write('compatibilityScore: $compatibilityScore, ')
          ..write('isCommunityVerified: $isCommunityVerified, ')
          ..write('verificationCount: $verificationCount, ')
          ..write('lastVerified: $lastVerified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, placeId, dietaryRestriction,
      compatibilityScore, isCommunityVerified, verificationCount, lastVerified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DietaryCompatibilityData &&
          other.id == this.id &&
          other.placeId == this.placeId &&
          other.dietaryRestriction == this.dietaryRestriction &&
          other.compatibilityScore == this.compatibilityScore &&
          other.isCommunityVerified == this.isCommunityVerified &&
          other.verificationCount == this.verificationCount &&
          other.lastVerified == this.lastVerified);
}

class DietaryCompatibilityCompanion
    extends UpdateCompanion<DietaryCompatibilityData> {
  final Value<int> id;
  final Value<String> placeId;
  final Value<String> dietaryRestriction;
  final Value<double> compatibilityScore;
  final Value<bool> isCommunityVerified;
  final Value<int> verificationCount;
  final Value<DateTime?> lastVerified;
  const DietaryCompatibilityCompanion({
    this.id = const Value.absent(),
    this.placeId = const Value.absent(),
    this.dietaryRestriction = const Value.absent(),
    this.compatibilityScore = const Value.absent(),
    this.isCommunityVerified = const Value.absent(),
    this.verificationCount = const Value.absent(),
    this.lastVerified = const Value.absent(),
  });
  DietaryCompatibilityCompanion.insert({
    this.id = const Value.absent(),
    required String placeId,
    required String dietaryRestriction,
    required double compatibilityScore,
    this.isCommunityVerified = const Value.absent(),
    this.verificationCount = const Value.absent(),
    this.lastVerified = const Value.absent(),
  })  : placeId = Value(placeId),
        dietaryRestriction = Value(dietaryRestriction),
        compatibilityScore = Value(compatibilityScore);
  static Insertable<DietaryCompatibilityData> custom({
    Expression<int>? id,
    Expression<String>? placeId,
    Expression<String>? dietaryRestriction,
    Expression<double>? compatibilityScore,
    Expression<bool>? isCommunityVerified,
    Expression<int>? verificationCount,
    Expression<DateTime>? lastVerified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (placeId != null) 'place_id': placeId,
      if (dietaryRestriction != null) 'dietary_restriction': dietaryRestriction,
      if (compatibilityScore != null) 'compatibility_score': compatibilityScore,
      if (isCommunityVerified != null)
        'is_community_verified': isCommunityVerified,
      if (verificationCount != null) 'verification_count': verificationCount,
      if (lastVerified != null) 'last_verified': lastVerified,
    });
  }

  DietaryCompatibilityCompanion copyWith(
      {Value<int>? id,
      Value<String>? placeId,
      Value<String>? dietaryRestriction,
      Value<double>? compatibilityScore,
      Value<bool>? isCommunityVerified,
      Value<int>? verificationCount,
      Value<DateTime?>? lastVerified}) {
    return DietaryCompatibilityCompanion(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      dietaryRestriction: dietaryRestriction ?? this.dietaryRestriction,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      isCommunityVerified: isCommunityVerified ?? this.isCommunityVerified,
      verificationCount: verificationCount ?? this.verificationCount,
      lastVerified: lastVerified ?? this.lastVerified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (placeId.present) {
      map['place_id'] = Variable<String>(placeId.value);
    }
    if (dietaryRestriction.present) {
      map['dietary_restriction'] = Variable<String>(dietaryRestriction.value);
    }
    if (compatibilityScore.present) {
      map['compatibility_score'] = Variable<double>(compatibilityScore.value);
    }
    if (isCommunityVerified.present) {
      map['is_community_verified'] = Variable<bool>(isCommunityVerified.value);
    }
    if (verificationCount.present) {
      map['verification_count'] = Variable<int>(verificationCount.value);
    }
    if (lastVerified.present) {
      map['last_verified'] = Variable<DateTime>(lastVerified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DietaryCompatibilityCompanion(')
          ..write('id: $id, ')
          ..write('placeId: $placeId, ')
          ..write('dietaryRestriction: $dietaryRestriction, ')
          ..write('compatibilityScore: $compatibilityScore, ')
          ..write('isCommunityVerified: $isCommunityVerified, ')
          ..write('verificationCount: $verificationCount, ')
          ..write('lastVerified: $lastVerified')
          ..write(')'))
        .toString();
  }
}

class $UserDiscoveryHistoryTable extends UserDiscoveryHistory
    with TableInfo<$UserDiscoveryHistoryTable, UserDiscoveryHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserDiscoveryHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _placeIdMeta =
      const VerificationMeta('placeId');
  @override
  late final GeneratedColumn<String> placeId = GeneratedColumn<String>(
      'place_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES restaurants (place_id)'));
  static const VerificationMeta _searchQueryMeta =
      const VerificationMeta('searchQuery');
  @override
  late final GeneratedColumn<String> searchQuery = GeneratedColumn<String>(
      'search_query', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _appliedFiltersMeta =
      const VerificationMeta('appliedFilters');
  @override
  late final GeneratedColumn<String> appliedFilters = GeneratedColumn<String>(
      'applied_filters', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _wasSelectedMeta =
      const VerificationMeta('wasSelected');
  @override
  late final GeneratedColumn<bool> wasSelected = GeneratedColumn<bool>(
      'was_selected', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("was_selected" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _viewedAtMeta =
      const VerificationMeta('viewedAt');
  @override
  late final GeneratedColumn<DateTime> viewedAt = GeneratedColumn<DateTime>(
      'viewed_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, placeId, searchQuery, appliedFilters, wasSelected, viewedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_discovery_history';
  @override
  VerificationContext validateIntegrity(
      Insertable<UserDiscoveryHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('place_id')) {
      context.handle(_placeIdMeta,
          placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta));
    } else if (isInserting) {
      context.missing(_placeIdMeta);
    }
    if (data.containsKey('search_query')) {
      context.handle(
          _searchQueryMeta,
          searchQuery.isAcceptableOrUnknown(
              data['search_query']!, _searchQueryMeta));
    }
    if (data.containsKey('applied_filters')) {
      context.handle(
          _appliedFiltersMeta,
          appliedFilters.isAcceptableOrUnknown(
              data['applied_filters']!, _appliedFiltersMeta));
    }
    if (data.containsKey('was_selected')) {
      context.handle(
          _wasSelectedMeta,
          wasSelected.isAcceptableOrUnknown(
              data['was_selected']!, _wasSelectedMeta));
    }
    if (data.containsKey('viewed_at')) {
      context.handle(_viewedAtMeta,
          viewedAt.isAcceptableOrUnknown(data['viewed_at']!, _viewedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserDiscoveryHistoryData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserDiscoveryHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      placeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}place_id'])!,
      searchQuery: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}search_query']),
      appliedFilters: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}applied_filters'])!,
      wasSelected: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}was_selected'])!,
      viewedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}viewed_at'])!,
    );
  }

  @override
  $UserDiscoveryHistoryTable createAlias(String alias) {
    return $UserDiscoveryHistoryTable(attachedDatabase, alias);
  }
}

class UserDiscoveryHistoryData extends DataClass
    implements Insertable<UserDiscoveryHistoryData> {
  final int id;
  final int userId;
  final String placeId;
  final String? searchQuery;
  final String appliedFilters;
  final bool wasSelected;
  final DateTime viewedAt;
  const UserDiscoveryHistoryData(
      {required this.id,
      required this.userId,
      required this.placeId,
      this.searchQuery,
      required this.appliedFilters,
      required this.wasSelected,
      required this.viewedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['place_id'] = Variable<String>(placeId);
    if (!nullToAbsent || searchQuery != null) {
      map['search_query'] = Variable<String>(searchQuery);
    }
    map['applied_filters'] = Variable<String>(appliedFilters);
    map['was_selected'] = Variable<bool>(wasSelected);
    map['viewed_at'] = Variable<DateTime>(viewedAt);
    return map;
  }

  UserDiscoveryHistoryCompanion toCompanion(bool nullToAbsent) {
    return UserDiscoveryHistoryCompanion(
      id: Value(id),
      userId: Value(userId),
      placeId: Value(placeId),
      searchQuery: searchQuery == null && nullToAbsent
          ? const Value.absent()
          : Value(searchQuery),
      appliedFilters: Value(appliedFilters),
      wasSelected: Value(wasSelected),
      viewedAt: Value(viewedAt),
    );
  }

  factory UserDiscoveryHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserDiscoveryHistoryData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      placeId: serializer.fromJson<String>(json['placeId']),
      searchQuery: serializer.fromJson<String?>(json['searchQuery']),
      appliedFilters: serializer.fromJson<String>(json['appliedFilters']),
      wasSelected: serializer.fromJson<bool>(json['wasSelected']),
      viewedAt: serializer.fromJson<DateTime>(json['viewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'placeId': serializer.toJson<String>(placeId),
      'searchQuery': serializer.toJson<String?>(searchQuery),
      'appliedFilters': serializer.toJson<String>(appliedFilters),
      'wasSelected': serializer.toJson<bool>(wasSelected),
      'viewedAt': serializer.toJson<DateTime>(viewedAt),
    };
  }

  UserDiscoveryHistoryData copyWith(
          {int? id,
          int? userId,
          String? placeId,
          Value<String?> searchQuery = const Value.absent(),
          String? appliedFilters,
          bool? wasSelected,
          DateTime? viewedAt}) =>
      UserDiscoveryHistoryData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        placeId: placeId ?? this.placeId,
        searchQuery: searchQuery.present ? searchQuery.value : this.searchQuery,
        appliedFilters: appliedFilters ?? this.appliedFilters,
        wasSelected: wasSelected ?? this.wasSelected,
        viewedAt: viewedAt ?? this.viewedAt,
      );
  UserDiscoveryHistoryData copyWithCompanion(
      UserDiscoveryHistoryCompanion data) {
    return UserDiscoveryHistoryData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      searchQuery:
          data.searchQuery.present ? data.searchQuery.value : this.searchQuery,
      appliedFilters: data.appliedFilters.present
          ? data.appliedFilters.value
          : this.appliedFilters,
      wasSelected:
          data.wasSelected.present ? data.wasSelected.value : this.wasSelected,
      viewedAt: data.viewedAt.present ? data.viewedAt.value : this.viewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserDiscoveryHistoryData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('placeId: $placeId, ')
          ..write('searchQuery: $searchQuery, ')
          ..write('appliedFilters: $appliedFilters, ')
          ..write('wasSelected: $wasSelected, ')
          ..write('viewedAt: $viewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, userId, placeId, searchQuery, appliedFilters, wasSelected, viewedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserDiscoveryHistoryData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.placeId == this.placeId &&
          other.searchQuery == this.searchQuery &&
          other.appliedFilters == this.appliedFilters &&
          other.wasSelected == this.wasSelected &&
          other.viewedAt == this.viewedAt);
}

class UserDiscoveryHistoryCompanion
    extends UpdateCompanion<UserDiscoveryHistoryData> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> placeId;
  final Value<String?> searchQuery;
  final Value<String> appliedFilters;
  final Value<bool> wasSelected;
  final Value<DateTime> viewedAt;
  const UserDiscoveryHistoryCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.placeId = const Value.absent(),
    this.searchQuery = const Value.absent(),
    this.appliedFilters = const Value.absent(),
    this.wasSelected = const Value.absent(),
    this.viewedAt = const Value.absent(),
  });
  UserDiscoveryHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String placeId,
    this.searchQuery = const Value.absent(),
    this.appliedFilters = const Value.absent(),
    this.wasSelected = const Value.absent(),
    this.viewedAt = const Value.absent(),
  })  : userId = Value(userId),
        placeId = Value(placeId);
  static Insertable<UserDiscoveryHistoryData> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? placeId,
    Expression<String>? searchQuery,
    Expression<String>? appliedFilters,
    Expression<bool>? wasSelected,
    Expression<DateTime>? viewedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (placeId != null) 'place_id': placeId,
      if (searchQuery != null) 'search_query': searchQuery,
      if (appliedFilters != null) 'applied_filters': appliedFilters,
      if (wasSelected != null) 'was_selected': wasSelected,
      if (viewedAt != null) 'viewed_at': viewedAt,
    });
  }

  UserDiscoveryHistoryCompanion copyWith(
      {Value<int>? id,
      Value<int>? userId,
      Value<String>? placeId,
      Value<String?>? searchQuery,
      Value<String>? appliedFilters,
      Value<bool>? wasSelected,
      Value<DateTime>? viewedAt}) {
    return UserDiscoveryHistoryCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      placeId: placeId ?? this.placeId,
      searchQuery: searchQuery ?? this.searchQuery,
      appliedFilters: appliedFilters ?? this.appliedFilters,
      wasSelected: wasSelected ?? this.wasSelected,
      viewedAt: viewedAt ?? this.viewedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (placeId.present) {
      map['place_id'] = Variable<String>(placeId.value);
    }
    if (searchQuery.present) {
      map['search_query'] = Variable<String>(searchQuery.value);
    }
    if (appliedFilters.present) {
      map['applied_filters'] = Variable<String>(appliedFilters.value);
    }
    if (wasSelected.present) {
      map['was_selected'] = Variable<bool>(wasSelected.value);
    }
    if (viewedAt.present) {
      map['viewed_at'] = Variable<DateTime>(viewedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserDiscoveryHistoryCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('placeId: $placeId, ')
          ..write('searchQuery: $searchQuery, ')
          ..write('appliedFilters: $appliedFilters, ')
          ..write('wasSelected: $wasSelected, ')
          ..write('viewedAt: $viewedAt')
          ..write(')'))
        .toString();
  }
}

class $AIRecommendationsTable extends AIRecommendations
    with TableInfo<$AIRecommendationsTable, AIRecommendation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AIRecommendationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _recommendedRestaurantIdsMeta =
      const VerificationMeta('recommendedRestaurantIds');
  @override
  late final GeneratedColumn<String> recommendedRestaurantIds =
      GeneratedColumn<String>('recommended_restaurant_ids', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reasoningMeta =
      const VerificationMeta('reasoning');
  @override
  late final GeneratedColumn<String> reasoning = GeneratedColumn<String>(
      'reasoning', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _factorWeightsMeta =
      const VerificationMeta('factorWeights');
  @override
  late final GeneratedColumn<String> factorWeights = GeneratedColumn<String>(
      'factor_weights', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _overallConfidenceMeta =
      const VerificationMeta('overallConfidence');
  @override
  late final GeneratedColumn<double> overallConfidence =
      GeneratedColumn<double>('overall_confidence', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _userContextMeta =
      const VerificationMeta('userContext');
  @override
  late final GeneratedColumn<String> userContext = GeneratedColumn<String>(
      'user_context', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _wasAcceptedMeta =
      const VerificationMeta('wasAccepted');
  @override
  late final GeneratedColumn<bool> wasAccepted = GeneratedColumn<bool>(
      'was_accepted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("was_accepted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _userFeedbackMeta =
      const VerificationMeta('userFeedback');
  @override
  late final GeneratedColumn<String> userFeedback = GeneratedColumn<String>(
      'user_feedback', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        recommendedRestaurantIds,
        reasoning,
        factorWeights,
        overallConfidence,
        userContext,
        generatedAt,
        wasAccepted,
        userFeedback,
        metadata,
        expiresAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'a_i_recommendations';
  @override
  VerificationContext validateIntegrity(Insertable<AIRecommendation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('recommended_restaurant_ids')) {
      context.handle(
          _recommendedRestaurantIdsMeta,
          recommendedRestaurantIds.isAcceptableOrUnknown(
              data['recommended_restaurant_ids']!,
              _recommendedRestaurantIdsMeta));
    } else if (isInserting) {
      context.missing(_recommendedRestaurantIdsMeta);
    }
    if (data.containsKey('reasoning')) {
      context.handle(_reasoningMeta,
          reasoning.isAcceptableOrUnknown(data['reasoning']!, _reasoningMeta));
    } else if (isInserting) {
      context.missing(_reasoningMeta);
    }
    if (data.containsKey('factor_weights')) {
      context.handle(
          _factorWeightsMeta,
          factorWeights.isAcceptableOrUnknown(
              data['factor_weights']!, _factorWeightsMeta));
    }
    if (data.containsKey('overall_confidence')) {
      context.handle(
          _overallConfidenceMeta,
          overallConfidence.isAcceptableOrUnknown(
              data['overall_confidence']!, _overallConfidenceMeta));
    } else if (isInserting) {
      context.missing(_overallConfidenceMeta);
    }
    if (data.containsKey('user_context')) {
      context.handle(
          _userContextMeta,
          userContext.isAcceptableOrUnknown(
              data['user_context']!, _userContextMeta));
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    }
    if (data.containsKey('was_accepted')) {
      context.handle(
          _wasAcceptedMeta,
          wasAccepted.isAcceptableOrUnknown(
              data['was_accepted']!, _wasAcceptedMeta));
    }
    if (data.containsKey('user_feedback')) {
      context.handle(
          _userFeedbackMeta,
          userFeedback.isAcceptableOrUnknown(
              data['user_feedback']!, _userFeedbackMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AIRecommendation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AIRecommendation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      recommendedRestaurantIds: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}recommended_restaurant_ids'])!,
      reasoning: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reasoning'])!,
      factorWeights: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}factor_weights'])!,
      overallConfidence: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}overall_confidence'])!,
      userContext: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_context'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}generated_at'])!,
      wasAccepted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}was_accepted'])!,
      userFeedback: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_feedback']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at'])!,
    );
  }

  @override
  $AIRecommendationsTable createAlias(String alias) {
    return $AIRecommendationsTable(attachedDatabase, alias);
  }
}

class AIRecommendation extends DataClass
    implements Insertable<AIRecommendation> {
  final String id;
  final int userId;
  final String recommendedRestaurantIds;
  final String reasoning;
  final String factorWeights;
  final double overallConfidence;
  final String userContext;
  final DateTime generatedAt;
  final bool wasAccepted;
  final String? userFeedback;
  final String metadata;
  final DateTime expiresAt;
  const AIRecommendation(
      {required this.id,
      required this.userId,
      required this.recommendedRestaurantIds,
      required this.reasoning,
      required this.factorWeights,
      required this.overallConfidence,
      required this.userContext,
      required this.generatedAt,
      required this.wasAccepted,
      this.userFeedback,
      required this.metadata,
      required this.expiresAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<int>(userId);
    map['recommended_restaurant_ids'] =
        Variable<String>(recommendedRestaurantIds);
    map['reasoning'] = Variable<String>(reasoning);
    map['factor_weights'] = Variable<String>(factorWeights);
    map['overall_confidence'] = Variable<double>(overallConfidence);
    map['user_context'] = Variable<String>(userContext);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['was_accepted'] = Variable<bool>(wasAccepted);
    if (!nullToAbsent || userFeedback != null) {
      map['user_feedback'] = Variable<String>(userFeedback);
    }
    map['metadata'] = Variable<String>(metadata);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  AIRecommendationsCompanion toCompanion(bool nullToAbsent) {
    return AIRecommendationsCompanion(
      id: Value(id),
      userId: Value(userId),
      recommendedRestaurantIds: Value(recommendedRestaurantIds),
      reasoning: Value(reasoning),
      factorWeights: Value(factorWeights),
      overallConfidence: Value(overallConfidence),
      userContext: Value(userContext),
      generatedAt: Value(generatedAt),
      wasAccepted: Value(wasAccepted),
      userFeedback: userFeedback == null && nullToAbsent
          ? const Value.absent()
          : Value(userFeedback),
      metadata: Value(metadata),
      expiresAt: Value(expiresAt),
    );
  }

  factory AIRecommendation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AIRecommendation(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      recommendedRestaurantIds:
          serializer.fromJson<String>(json['recommendedRestaurantIds']),
      reasoning: serializer.fromJson<String>(json['reasoning']),
      factorWeights: serializer.fromJson<String>(json['factorWeights']),
      overallConfidence: serializer.fromJson<double>(json['overallConfidence']),
      userContext: serializer.fromJson<String>(json['userContext']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      wasAccepted: serializer.fromJson<bool>(json['wasAccepted']),
      userFeedback: serializer.fromJson<String?>(json['userFeedback']),
      metadata: serializer.fromJson<String>(json['metadata']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<int>(userId),
      'recommendedRestaurantIds':
          serializer.toJson<String>(recommendedRestaurantIds),
      'reasoning': serializer.toJson<String>(reasoning),
      'factorWeights': serializer.toJson<String>(factorWeights),
      'overallConfidence': serializer.toJson<double>(overallConfidence),
      'userContext': serializer.toJson<String>(userContext),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'wasAccepted': serializer.toJson<bool>(wasAccepted),
      'userFeedback': serializer.toJson<String?>(userFeedback),
      'metadata': serializer.toJson<String>(metadata),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  AIRecommendation copyWith(
          {String? id,
          int? userId,
          String? recommendedRestaurantIds,
          String? reasoning,
          String? factorWeights,
          double? overallConfidence,
          String? userContext,
          DateTime? generatedAt,
          bool? wasAccepted,
          Value<String?> userFeedback = const Value.absent(),
          String? metadata,
          DateTime? expiresAt}) =>
      AIRecommendation(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        recommendedRestaurantIds:
            recommendedRestaurantIds ?? this.recommendedRestaurantIds,
        reasoning: reasoning ?? this.reasoning,
        factorWeights: factorWeights ?? this.factorWeights,
        overallConfidence: overallConfidence ?? this.overallConfidence,
        userContext: userContext ?? this.userContext,
        generatedAt: generatedAt ?? this.generatedAt,
        wasAccepted: wasAccepted ?? this.wasAccepted,
        userFeedback:
            userFeedback.present ? userFeedback.value : this.userFeedback,
        metadata: metadata ?? this.metadata,
        expiresAt: expiresAt ?? this.expiresAt,
      );
  AIRecommendation copyWithCompanion(AIRecommendationsCompanion data) {
    return AIRecommendation(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      recommendedRestaurantIds: data.recommendedRestaurantIds.present
          ? data.recommendedRestaurantIds.value
          : this.recommendedRestaurantIds,
      reasoning: data.reasoning.present ? data.reasoning.value : this.reasoning,
      factorWeights: data.factorWeights.present
          ? data.factorWeights.value
          : this.factorWeights,
      overallConfidence: data.overallConfidence.present
          ? data.overallConfidence.value
          : this.overallConfidence,
      userContext:
          data.userContext.present ? data.userContext.value : this.userContext,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      wasAccepted:
          data.wasAccepted.present ? data.wasAccepted.value : this.wasAccepted,
      userFeedback: data.userFeedback.present
          ? data.userFeedback.value
          : this.userFeedback,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AIRecommendation(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('recommendedRestaurantIds: $recommendedRestaurantIds, ')
          ..write('reasoning: $reasoning, ')
          ..write('factorWeights: $factorWeights, ')
          ..write('overallConfidence: $overallConfidence, ')
          ..write('userContext: $userContext, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('wasAccepted: $wasAccepted, ')
          ..write('userFeedback: $userFeedback, ')
          ..write('metadata: $metadata, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      recommendedRestaurantIds,
      reasoning,
      factorWeights,
      overallConfidence,
      userContext,
      generatedAt,
      wasAccepted,
      userFeedback,
      metadata,
      expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AIRecommendation &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.recommendedRestaurantIds == this.recommendedRestaurantIds &&
          other.reasoning == this.reasoning &&
          other.factorWeights == this.factorWeights &&
          other.overallConfidence == this.overallConfidence &&
          other.userContext == this.userContext &&
          other.generatedAt == this.generatedAt &&
          other.wasAccepted == this.wasAccepted &&
          other.userFeedback == this.userFeedback &&
          other.metadata == this.metadata &&
          other.expiresAt == this.expiresAt);
}

class AIRecommendationsCompanion extends UpdateCompanion<AIRecommendation> {
  final Value<String> id;
  final Value<int> userId;
  final Value<String> recommendedRestaurantIds;
  final Value<String> reasoning;
  final Value<String> factorWeights;
  final Value<double> overallConfidence;
  final Value<String> userContext;
  final Value<DateTime> generatedAt;
  final Value<bool> wasAccepted;
  final Value<String?> userFeedback;
  final Value<String> metadata;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const AIRecommendationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.recommendedRestaurantIds = const Value.absent(),
    this.reasoning = const Value.absent(),
    this.factorWeights = const Value.absent(),
    this.overallConfidence = const Value.absent(),
    this.userContext = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.wasAccepted = const Value.absent(),
    this.userFeedback = const Value.absent(),
    this.metadata = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AIRecommendationsCompanion.insert({
    required String id,
    required int userId,
    required String recommendedRestaurantIds,
    required String reasoning,
    this.factorWeights = const Value.absent(),
    required double overallConfidence,
    this.userContext = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.wasAccepted = const Value.absent(),
    this.userFeedback = const Value.absent(),
    this.metadata = const Value.absent(),
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        recommendedRestaurantIds = Value(recommendedRestaurantIds),
        reasoning = Value(reasoning),
        overallConfidence = Value(overallConfidence),
        expiresAt = Value(expiresAt);
  static Insertable<AIRecommendation> custom({
    Expression<String>? id,
    Expression<int>? userId,
    Expression<String>? recommendedRestaurantIds,
    Expression<String>? reasoning,
    Expression<String>? factorWeights,
    Expression<double>? overallConfidence,
    Expression<String>? userContext,
    Expression<DateTime>? generatedAt,
    Expression<bool>? wasAccepted,
    Expression<String>? userFeedback,
    Expression<String>? metadata,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (recommendedRestaurantIds != null)
        'recommended_restaurant_ids': recommendedRestaurantIds,
      if (reasoning != null) 'reasoning': reasoning,
      if (factorWeights != null) 'factor_weights': factorWeights,
      if (overallConfidence != null) 'overall_confidence': overallConfidence,
      if (userContext != null) 'user_context': userContext,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (wasAccepted != null) 'was_accepted': wasAccepted,
      if (userFeedback != null) 'user_feedback': userFeedback,
      if (metadata != null) 'metadata': metadata,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AIRecommendationsCompanion copyWith(
      {Value<String>? id,
      Value<int>? userId,
      Value<String>? recommendedRestaurantIds,
      Value<String>? reasoning,
      Value<String>? factorWeights,
      Value<double>? overallConfidence,
      Value<String>? userContext,
      Value<DateTime>? generatedAt,
      Value<bool>? wasAccepted,
      Value<String?>? userFeedback,
      Value<String>? metadata,
      Value<DateTime>? expiresAt,
      Value<int>? rowid}) {
    return AIRecommendationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recommendedRestaurantIds:
          recommendedRestaurantIds ?? this.recommendedRestaurantIds,
      reasoning: reasoning ?? this.reasoning,
      factorWeights: factorWeights ?? this.factorWeights,
      overallConfidence: overallConfidence ?? this.overallConfidence,
      userContext: userContext ?? this.userContext,
      generatedAt: generatedAt ?? this.generatedAt,
      wasAccepted: wasAccepted ?? this.wasAccepted,
      userFeedback: userFeedback ?? this.userFeedback,
      metadata: metadata ?? this.metadata,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (recommendedRestaurantIds.present) {
      map['recommended_restaurant_ids'] =
          Variable<String>(recommendedRestaurantIds.value);
    }
    if (reasoning.present) {
      map['reasoning'] = Variable<String>(reasoning.value);
    }
    if (factorWeights.present) {
      map['factor_weights'] = Variable<String>(factorWeights.value);
    }
    if (overallConfidence.present) {
      map['overall_confidence'] = Variable<double>(overallConfidence.value);
    }
    if (userContext.present) {
      map['user_context'] = Variable<String>(userContext.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (wasAccepted.present) {
      map['was_accepted'] = Variable<bool>(wasAccepted.value);
    }
    if (userFeedback.present) {
      map['user_feedback'] = Variable<String>(userFeedback.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AIRecommendationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('recommendedRestaurantIds: $recommendedRestaurantIds, ')
          ..write('reasoning: $reasoning, ')
          ..write('factorWeights: $factorWeights, ')
          ..write('overallConfidence: $overallConfidence, ')
          ..write('userContext: $userContext, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('wasAccepted: $wasAccepted, ')
          ..write('userFeedback: $userFeedback, ')
          ..write('metadata: $metadata, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AIRecommendationFeedbackTable extends AIRecommendationFeedback
    with
        TableInfo<$AIRecommendationFeedbackTable,
            AIRecommendationFeedbackData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AIRecommendationFeedbackTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _recommendationIdMeta =
      const VerificationMeta('recommendationId');
  @override
  late final GeneratedColumn<String> recommendationId = GeneratedColumn<String>(
      'recommendation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES a_i_recommendations (id)'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _placeIdMeta =
      const VerificationMeta('placeId');
  @override
  late final GeneratedColumn<String> placeId = GeneratedColumn<String>(
      'place_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES restaurants (place_id)'));
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
      'rating', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _feedbackTextMeta =
      const VerificationMeta('feedbackText');
  @override
  late final GeneratedColumn<String> feedbackText = GeneratedColumn<String>(
      'feedback_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _wasSelectedMeta =
      const VerificationMeta('wasSelected');
  @override
  late final GeneratedColumn<bool> wasSelected = GeneratedColumn<bool>(
      'was_selected', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("was_selected" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _submittedAtMeta =
      const VerificationMeta('submittedAt');
  @override
  late final GeneratedColumn<DateTime> submittedAt = GeneratedColumn<DateTime>(
      'submitted_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        recommendationId,
        userId,
        placeId,
        rating,
        feedbackText,
        wasSelected,
        submittedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'a_i_recommendation_feedback';
  @override
  VerificationContext validateIntegrity(
      Insertable<AIRecommendationFeedbackData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recommendation_id')) {
      context.handle(
          _recommendationIdMeta,
          recommendationId.isAcceptableOrUnknown(
              data['recommendation_id']!, _recommendationIdMeta));
    } else if (isInserting) {
      context.missing(_recommendationIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('place_id')) {
      context.handle(_placeIdMeta,
          placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta));
    } else if (isInserting) {
      context.missing(_placeIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('feedback_text')) {
      context.handle(
          _feedbackTextMeta,
          feedbackText.isAcceptableOrUnknown(
              data['feedback_text']!, _feedbackTextMeta));
    }
    if (data.containsKey('was_selected')) {
      context.handle(
          _wasSelectedMeta,
          wasSelected.isAcceptableOrUnknown(
              data['was_selected']!, _wasSelectedMeta));
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
          _submittedAtMeta,
          submittedAt.isAcceptableOrUnknown(
              data['submitted_at']!, _submittedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AIRecommendationFeedbackData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AIRecommendationFeedbackData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      recommendationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}recommendation_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      placeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}place_id'])!,
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rating'])!,
      feedbackText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}feedback_text']),
      wasSelected: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}was_selected'])!,
      submittedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}submitted_at'])!,
    );
  }

  @override
  $AIRecommendationFeedbackTable createAlias(String alias) {
    return $AIRecommendationFeedbackTable(attachedDatabase, alias);
  }
}

class AIRecommendationFeedbackData extends DataClass
    implements Insertable<AIRecommendationFeedbackData> {
  final int id;
  final String recommendationId;
  final int userId;
  final String placeId;
  final int rating;
  final String? feedbackText;
  final bool wasSelected;
  final DateTime submittedAt;
  const AIRecommendationFeedbackData(
      {required this.id,
      required this.recommendationId,
      required this.userId,
      required this.placeId,
      required this.rating,
      this.feedbackText,
      required this.wasSelected,
      required this.submittedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recommendation_id'] = Variable<String>(recommendationId);
    map['user_id'] = Variable<int>(userId);
    map['place_id'] = Variable<String>(placeId);
    map['rating'] = Variable<int>(rating);
    if (!nullToAbsent || feedbackText != null) {
      map['feedback_text'] = Variable<String>(feedbackText);
    }
    map['was_selected'] = Variable<bool>(wasSelected);
    map['submitted_at'] = Variable<DateTime>(submittedAt);
    return map;
  }

  AIRecommendationFeedbackCompanion toCompanion(bool nullToAbsent) {
    return AIRecommendationFeedbackCompanion(
      id: Value(id),
      recommendationId: Value(recommendationId),
      userId: Value(userId),
      placeId: Value(placeId),
      rating: Value(rating),
      feedbackText: feedbackText == null && nullToAbsent
          ? const Value.absent()
          : Value(feedbackText),
      wasSelected: Value(wasSelected),
      submittedAt: Value(submittedAt),
    );
  }

  factory AIRecommendationFeedbackData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AIRecommendationFeedbackData(
      id: serializer.fromJson<int>(json['id']),
      recommendationId: serializer.fromJson<String>(json['recommendationId']),
      userId: serializer.fromJson<int>(json['userId']),
      placeId: serializer.fromJson<String>(json['placeId']),
      rating: serializer.fromJson<int>(json['rating']),
      feedbackText: serializer.fromJson<String?>(json['feedbackText']),
      wasSelected: serializer.fromJson<bool>(json['wasSelected']),
      submittedAt: serializer.fromJson<DateTime>(json['submittedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recommendationId': serializer.toJson<String>(recommendationId),
      'userId': serializer.toJson<int>(userId),
      'placeId': serializer.toJson<String>(placeId),
      'rating': serializer.toJson<int>(rating),
      'feedbackText': serializer.toJson<String?>(feedbackText),
      'wasSelected': serializer.toJson<bool>(wasSelected),
      'submittedAt': serializer.toJson<DateTime>(submittedAt),
    };
  }

  AIRecommendationFeedbackData copyWith(
          {int? id,
          String? recommendationId,
          int? userId,
          String? placeId,
          int? rating,
          Value<String?> feedbackText = const Value.absent(),
          bool? wasSelected,
          DateTime? submittedAt}) =>
      AIRecommendationFeedbackData(
        id: id ?? this.id,
        recommendationId: recommendationId ?? this.recommendationId,
        userId: userId ?? this.userId,
        placeId: placeId ?? this.placeId,
        rating: rating ?? this.rating,
        feedbackText:
            feedbackText.present ? feedbackText.value : this.feedbackText,
        wasSelected: wasSelected ?? this.wasSelected,
        submittedAt: submittedAt ?? this.submittedAt,
      );
  AIRecommendationFeedbackData copyWithCompanion(
      AIRecommendationFeedbackCompanion data) {
    return AIRecommendationFeedbackData(
      id: data.id.present ? data.id.value : this.id,
      recommendationId: data.recommendationId.present
          ? data.recommendationId.value
          : this.recommendationId,
      userId: data.userId.present ? data.userId.value : this.userId,
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      rating: data.rating.present ? data.rating.value : this.rating,
      feedbackText: data.feedbackText.present
          ? data.feedbackText.value
          : this.feedbackText,
      wasSelected:
          data.wasSelected.present ? data.wasSelected.value : this.wasSelected,
      submittedAt:
          data.submittedAt.present ? data.submittedAt.value : this.submittedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AIRecommendationFeedbackData(')
          ..write('id: $id, ')
          ..write('recommendationId: $recommendationId, ')
          ..write('userId: $userId, ')
          ..write('placeId: $placeId, ')
          ..write('rating: $rating, ')
          ..write('feedbackText: $feedbackText, ')
          ..write('wasSelected: $wasSelected, ')
          ..write('submittedAt: $submittedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recommendationId, userId, placeId, rating,
      feedbackText, wasSelected, submittedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AIRecommendationFeedbackData &&
          other.id == this.id &&
          other.recommendationId == this.recommendationId &&
          other.userId == this.userId &&
          other.placeId == this.placeId &&
          other.rating == this.rating &&
          other.feedbackText == this.feedbackText &&
          other.wasSelected == this.wasSelected &&
          other.submittedAt == this.submittedAt);
}

class AIRecommendationFeedbackCompanion
    extends UpdateCompanion<AIRecommendationFeedbackData> {
  final Value<int> id;
  final Value<String> recommendationId;
  final Value<int> userId;
  final Value<String> placeId;
  final Value<int> rating;
  final Value<String?> feedbackText;
  final Value<bool> wasSelected;
  final Value<DateTime> submittedAt;
  const AIRecommendationFeedbackCompanion({
    this.id = const Value.absent(),
    this.recommendationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.placeId = const Value.absent(),
    this.rating = const Value.absent(),
    this.feedbackText = const Value.absent(),
    this.wasSelected = const Value.absent(),
    this.submittedAt = const Value.absent(),
  });
  AIRecommendationFeedbackCompanion.insert({
    this.id = const Value.absent(),
    required String recommendationId,
    required int userId,
    required String placeId,
    required int rating,
    this.feedbackText = const Value.absent(),
    this.wasSelected = const Value.absent(),
    this.submittedAt = const Value.absent(),
  })  : recommendationId = Value(recommendationId),
        userId = Value(userId),
        placeId = Value(placeId),
        rating = Value(rating);
  static Insertable<AIRecommendationFeedbackData> custom({
    Expression<int>? id,
    Expression<String>? recommendationId,
    Expression<int>? userId,
    Expression<String>? placeId,
    Expression<int>? rating,
    Expression<String>? feedbackText,
    Expression<bool>? wasSelected,
    Expression<DateTime>? submittedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recommendationId != null) 'recommendation_id': recommendationId,
      if (userId != null) 'user_id': userId,
      if (placeId != null) 'place_id': placeId,
      if (rating != null) 'rating': rating,
      if (feedbackText != null) 'feedback_text': feedbackText,
      if (wasSelected != null) 'was_selected': wasSelected,
      if (submittedAt != null) 'submitted_at': submittedAt,
    });
  }

  AIRecommendationFeedbackCompanion copyWith(
      {Value<int>? id,
      Value<String>? recommendationId,
      Value<int>? userId,
      Value<String>? placeId,
      Value<int>? rating,
      Value<String?>? feedbackText,
      Value<bool>? wasSelected,
      Value<DateTime>? submittedAt}) {
    return AIRecommendationFeedbackCompanion(
      id: id ?? this.id,
      recommendationId: recommendationId ?? this.recommendationId,
      userId: userId ?? this.userId,
      placeId: placeId ?? this.placeId,
      rating: rating ?? this.rating,
      feedbackText: feedbackText ?? this.feedbackText,
      wasSelected: wasSelected ?? this.wasSelected,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recommendationId.present) {
      map['recommendation_id'] = Variable<String>(recommendationId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (placeId.present) {
      map['place_id'] = Variable<String>(placeId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (feedbackText.present) {
      map['feedback_text'] = Variable<String>(feedbackText.value);
    }
    if (wasSelected.present) {
      map['was_selected'] = Variable<bool>(wasSelected.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<DateTime>(submittedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AIRecommendationFeedbackCompanion(')
          ..write('id: $id, ')
          ..write('recommendationId: $recommendationId, ')
          ..write('userId: $userId, ')
          ..write('placeId: $placeId, ')
          ..write('rating: $rating, ')
          ..write('feedbackText: $feedbackText, ')
          ..write('wasSelected: $wasSelected, ')
          ..write('submittedAt: $submittedAt')
          ..write(')'))
        .toString();
  }
}

class $AIUsageMetricsTable extends AIUsageMetrics
    with TableInfo<$AIUsageMetricsTable, AIUsageMetric> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AIUsageMetricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _requestTypeMeta =
      const VerificationMeta('requestType');
  @override
  late final GeneratedColumn<String> requestType = GeneratedColumn<String>(
      'request_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tokensUsedMeta =
      const VerificationMeta('tokensUsed');
  @override
  late final GeneratedColumn<int> tokensUsed = GeneratedColumn<int>(
      'tokens_used', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _costInCentsMeta =
      const VerificationMeta('costInCents');
  @override
  late final GeneratedColumn<double> costInCents = GeneratedColumn<double>(
      'cost_in_cents', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _responseTimeMsMeta =
      const VerificationMeta('responseTimeMs');
  @override
  late final GeneratedColumn<int> responseTimeMs = GeneratedColumn<int>(
      'response_time_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _wasSuccessfulMeta =
      const VerificationMeta('wasSuccessful');
  @override
  late final GeneratedColumn<bool> wasSuccessful = GeneratedColumn<bool>(
      'was_successful', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("was_successful" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        requestType,
        tokensUsed,
        costInCents,
        responseTimeMs,
        wasSuccessful,
        errorMessage,
        timestamp
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'a_i_usage_metrics';
  @override
  VerificationContext validateIntegrity(Insertable<AIUsageMetric> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('request_type')) {
      context.handle(
          _requestTypeMeta,
          requestType.isAcceptableOrUnknown(
              data['request_type']!, _requestTypeMeta));
    } else if (isInserting) {
      context.missing(_requestTypeMeta);
    }
    if (data.containsKey('tokens_used')) {
      context.handle(
          _tokensUsedMeta,
          tokensUsed.isAcceptableOrUnknown(
              data['tokens_used']!, _tokensUsedMeta));
    }
    if (data.containsKey('cost_in_cents')) {
      context.handle(
          _costInCentsMeta,
          costInCents.isAcceptableOrUnknown(
              data['cost_in_cents']!, _costInCentsMeta));
    }
    if (data.containsKey('response_time_ms')) {
      context.handle(
          _responseTimeMsMeta,
          responseTimeMs.isAcceptableOrUnknown(
              data['response_time_ms']!, _responseTimeMsMeta));
    }
    if (data.containsKey('was_successful')) {
      context.handle(
          _wasSuccessfulMeta,
          wasSuccessful.isAcceptableOrUnknown(
              data['was_successful']!, _wasSuccessfulMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AIUsageMetric map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AIUsageMetric(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      requestType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}request_type'])!,
      tokensUsed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tokens_used'])!,
      costInCents: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_in_cents'])!,
      responseTimeMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}response_time_ms']),
      wasSuccessful: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}was_successful'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $AIUsageMetricsTable createAlias(String alias) {
    return $AIUsageMetricsTable(attachedDatabase, alias);
  }
}

class AIUsageMetric extends DataClass implements Insertable<AIUsageMetric> {
  final int id;
  final int userId;
  final String requestType;
  final int tokensUsed;
  final double costInCents;
  final int? responseTimeMs;
  final bool wasSuccessful;
  final String? errorMessage;
  final DateTime timestamp;
  const AIUsageMetric(
      {required this.id,
      required this.userId,
      required this.requestType,
      required this.tokensUsed,
      required this.costInCents,
      this.responseTimeMs,
      required this.wasSuccessful,
      this.errorMessage,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['request_type'] = Variable<String>(requestType);
    map['tokens_used'] = Variable<int>(tokensUsed);
    map['cost_in_cents'] = Variable<double>(costInCents);
    if (!nullToAbsent || responseTimeMs != null) {
      map['response_time_ms'] = Variable<int>(responseTimeMs);
    }
    map['was_successful'] = Variable<bool>(wasSuccessful);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  AIUsageMetricsCompanion toCompanion(bool nullToAbsent) {
    return AIUsageMetricsCompanion(
      id: Value(id),
      userId: Value(userId),
      requestType: Value(requestType),
      tokensUsed: Value(tokensUsed),
      costInCents: Value(costInCents),
      responseTimeMs: responseTimeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(responseTimeMs),
      wasSuccessful: Value(wasSuccessful),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      timestamp: Value(timestamp),
    );
  }

  factory AIUsageMetric.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AIUsageMetric(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      requestType: serializer.fromJson<String>(json['requestType']),
      tokensUsed: serializer.fromJson<int>(json['tokensUsed']),
      costInCents: serializer.fromJson<double>(json['costInCents']),
      responseTimeMs: serializer.fromJson<int?>(json['responseTimeMs']),
      wasSuccessful: serializer.fromJson<bool>(json['wasSuccessful']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'requestType': serializer.toJson<String>(requestType),
      'tokensUsed': serializer.toJson<int>(tokensUsed),
      'costInCents': serializer.toJson<double>(costInCents),
      'responseTimeMs': serializer.toJson<int?>(responseTimeMs),
      'wasSuccessful': serializer.toJson<bool>(wasSuccessful),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  AIUsageMetric copyWith(
          {int? id,
          int? userId,
          String? requestType,
          int? tokensUsed,
          double? costInCents,
          Value<int?> responseTimeMs = const Value.absent(),
          bool? wasSuccessful,
          Value<String?> errorMessage = const Value.absent(),
          DateTime? timestamp}) =>
      AIUsageMetric(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        requestType: requestType ?? this.requestType,
        tokensUsed: tokensUsed ?? this.tokensUsed,
        costInCents: costInCents ?? this.costInCents,
        responseTimeMs:
            responseTimeMs.present ? responseTimeMs.value : this.responseTimeMs,
        wasSuccessful: wasSuccessful ?? this.wasSuccessful,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        timestamp: timestamp ?? this.timestamp,
      );
  AIUsageMetric copyWithCompanion(AIUsageMetricsCompanion data) {
    return AIUsageMetric(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      requestType:
          data.requestType.present ? data.requestType.value : this.requestType,
      tokensUsed:
          data.tokensUsed.present ? data.tokensUsed.value : this.tokensUsed,
      costInCents:
          data.costInCents.present ? data.costInCents.value : this.costInCents,
      responseTimeMs: data.responseTimeMs.present
          ? data.responseTimeMs.value
          : this.responseTimeMs,
      wasSuccessful: data.wasSuccessful.present
          ? data.wasSuccessful.value
          : this.wasSuccessful,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AIUsageMetric(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('requestType: $requestType, ')
          ..write('tokensUsed: $tokensUsed, ')
          ..write('costInCents: $costInCents, ')
          ..write('responseTimeMs: $responseTimeMs, ')
          ..write('wasSuccessful: $wasSuccessful, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, requestType, tokensUsed,
      costInCents, responseTimeMs, wasSuccessful, errorMessage, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AIUsageMetric &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.requestType == this.requestType &&
          other.tokensUsed == this.tokensUsed &&
          other.costInCents == this.costInCents &&
          other.responseTimeMs == this.responseTimeMs &&
          other.wasSuccessful == this.wasSuccessful &&
          other.errorMessage == this.errorMessage &&
          other.timestamp == this.timestamp);
}

class AIUsageMetricsCompanion extends UpdateCompanion<AIUsageMetric> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> requestType;
  final Value<int> tokensUsed;
  final Value<double> costInCents;
  final Value<int?> responseTimeMs;
  final Value<bool> wasSuccessful;
  final Value<String?> errorMessage;
  final Value<DateTime> timestamp;
  const AIUsageMetricsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.requestType = const Value.absent(),
    this.tokensUsed = const Value.absent(),
    this.costInCents = const Value.absent(),
    this.responseTimeMs = const Value.absent(),
    this.wasSuccessful = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  AIUsageMetricsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String requestType,
    this.tokensUsed = const Value.absent(),
    this.costInCents = const Value.absent(),
    this.responseTimeMs = const Value.absent(),
    this.wasSuccessful = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.timestamp = const Value.absent(),
  })  : userId = Value(userId),
        requestType = Value(requestType);
  static Insertable<AIUsageMetric> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? requestType,
    Expression<int>? tokensUsed,
    Expression<double>? costInCents,
    Expression<int>? responseTimeMs,
    Expression<bool>? wasSuccessful,
    Expression<String>? errorMessage,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (requestType != null) 'request_type': requestType,
      if (tokensUsed != null) 'tokens_used': tokensUsed,
      if (costInCents != null) 'cost_in_cents': costInCents,
      if (responseTimeMs != null) 'response_time_ms': responseTimeMs,
      if (wasSuccessful != null) 'was_successful': wasSuccessful,
      if (errorMessage != null) 'error_message': errorMessage,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  AIUsageMetricsCompanion copyWith(
      {Value<int>? id,
      Value<int>? userId,
      Value<String>? requestType,
      Value<int>? tokensUsed,
      Value<double>? costInCents,
      Value<int?>? responseTimeMs,
      Value<bool>? wasSuccessful,
      Value<String?>? errorMessage,
      Value<DateTime>? timestamp}) {
    return AIUsageMetricsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      requestType: requestType ?? this.requestType,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      costInCents: costInCents ?? this.costInCents,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      wasSuccessful: wasSuccessful ?? this.wasSuccessful,
      errorMessage: errorMessage ?? this.errorMessage,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (requestType.present) {
      map['request_type'] = Variable<String>(requestType.value);
    }
    if (tokensUsed.present) {
      map['tokens_used'] = Variable<int>(tokensUsed.value);
    }
    if (costInCents.present) {
      map['cost_in_cents'] = Variable<double>(costInCents.value);
    }
    if (responseTimeMs.present) {
      map['response_time_ms'] = Variable<int>(responseTimeMs.value);
    }
    if (wasSuccessful.present) {
      map['was_successful'] = Variable<bool>(wasSuccessful.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AIUsageMetricsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('requestType: $requestType, ')
          ..write('tokensUsed: $tokensUsed, ')
          ..write('costInCents: $costInCents, ')
          ..write('responseTimeMs: $responseTimeMs, ')
          ..write('wasSuccessful: $wasSuccessful, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $PhotosTable extends Photos with TableInfo<$PhotosTable, Photo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users (id)'));
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cloudUrlMeta =
      const VerificationMeta('cloudUrl');
  @override
  late final GeneratedColumn<String> cloudUrl = GeneratedColumn<String>(
      'cloud_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
      'file_size_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _contentTypeMeta =
      const VerificationMeta('contentType');
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
      'content_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('image/jpeg'));
  static const VerificationMeta _photoTypeMeta =
      const VerificationMeta('photoType');
  @override
  late final GeneratedColumn<String> photoType = GeneratedColumn<String>(
      'photo_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _associatedEntityIdMeta =
      const VerificationMeta('associatedEntityId');
  @override
  late final GeneratedColumn<String> associatedEntityId =
      GeneratedColumn<String>('associated_entity_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _uploadedAtMeta =
      const VerificationMeta('uploadedAt');
  @override
  late final GeneratedColumn<DateTime> uploadedAt = GeneratedColumn<DateTime>(
      'uploaded_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isUploadedMeta =
      const VerificationMeta('isUploaded');
  @override
  late final GeneratedColumn<bool> isUploaded = GeneratedColumn<bool>(
      'is_uploaded', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_uploaded" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        fileName,
        localPath,
        cloudUrl,
        fileSizeBytes,
        width,
        height,
        contentType,
        photoType,
        associatedEntityId,
        metadata,
        createdAt,
        uploadedAt,
        isUploaded,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(Insertable<Photo> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('cloud_url')) {
      context.handle(_cloudUrlMeta,
          cloudUrl.isAcceptableOrUnknown(data['cloud_url']!, _cloudUrlMeta));
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('content_type')) {
      context.handle(
          _contentTypeMeta,
          contentType.isAcceptableOrUnknown(
              data['content_type']!, _contentTypeMeta));
    }
    if (data.containsKey('photo_type')) {
      context.handle(_photoTypeMeta,
          photoType.isAcceptableOrUnknown(data['photo_type']!, _photoTypeMeta));
    } else if (isInserting) {
      context.missing(_photoTypeMeta);
    }
    if (data.containsKey('associated_entity_id')) {
      context.handle(
          _associatedEntityIdMeta,
          associatedEntityId.isAcceptableOrUnknown(
              data['associated_entity_id']!, _associatedEntityIdMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('uploaded_at')) {
      context.handle(
          _uploadedAtMeta,
          uploadedAt.isAcceptableOrUnknown(
              data['uploaded_at']!, _uploadedAtMeta));
    }
    if (data.containsKey('is_uploaded')) {
      context.handle(
          _isUploadedMeta,
          isUploaded.isAcceptableOrUnknown(
              data['is_uploaded']!, _isUploadedMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Photo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Photo(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      cloudUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cloud_url']),
      fileSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size_bytes'])!,
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      contentType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_type'])!,
      photoType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_type'])!,
      associatedEntityId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}associated_entity_id']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      uploadedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}uploaded_at']),
      isUploaded: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_uploaded'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $PhotosTable createAlias(String alias) {
    return $PhotosTable(attachedDatabase, alias);
  }
}

class Photo extends DataClass implements Insertable<Photo> {
  final String id;
  final int userId;
  final String fileName;
  final String localPath;
  final String? cloudUrl;
  final int fileSizeBytes;
  final int? width;
  final int? height;
  final String contentType;
  final String photoType;
  final String? associatedEntityId;
  final String metadata;
  final DateTime createdAt;
  final DateTime? uploadedAt;
  final bool isUploaded;
  final bool isDeleted;
  const Photo(
      {required this.id,
      required this.userId,
      required this.fileName,
      required this.localPath,
      this.cloudUrl,
      required this.fileSizeBytes,
      this.width,
      this.height,
      required this.contentType,
      required this.photoType,
      this.associatedEntityId,
      required this.metadata,
      required this.createdAt,
      this.uploadedAt,
      required this.isUploaded,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<int>(userId);
    map['file_name'] = Variable<String>(fileName);
    map['local_path'] = Variable<String>(localPath);
    if (!nullToAbsent || cloudUrl != null) {
      map['cloud_url'] = Variable<String>(cloudUrl);
    }
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    map['content_type'] = Variable<String>(contentType);
    map['photo_type'] = Variable<String>(photoType);
    if (!nullToAbsent || associatedEntityId != null) {
      map['associated_entity_id'] = Variable<String>(associatedEntityId);
    }
    map['metadata'] = Variable<String>(metadata);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || uploadedAt != null) {
      map['uploaded_at'] = Variable<DateTime>(uploadedAt);
    }
    map['is_uploaded'] = Variable<bool>(isUploaded);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  PhotosCompanion toCompanion(bool nullToAbsent) {
    return PhotosCompanion(
      id: Value(id),
      userId: Value(userId),
      fileName: Value(fileName),
      localPath: Value(localPath),
      cloudUrl: cloudUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudUrl),
      fileSizeBytes: Value(fileSizeBytes),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      contentType: Value(contentType),
      photoType: Value(photoType),
      associatedEntityId: associatedEntityId == null && nullToAbsent
          ? const Value.absent()
          : Value(associatedEntityId),
      metadata: Value(metadata),
      createdAt: Value(createdAt),
      uploadedAt: uploadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadedAt),
      isUploaded: Value(isUploaded),
      isDeleted: Value(isDeleted),
    );
  }

  factory Photo.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Photo(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      localPath: serializer.fromJson<String>(json['localPath']),
      cloudUrl: serializer.fromJson<String?>(json['cloudUrl']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      contentType: serializer.fromJson<String>(json['contentType']),
      photoType: serializer.fromJson<String>(json['photoType']),
      associatedEntityId:
          serializer.fromJson<String?>(json['associatedEntityId']),
      metadata: serializer.fromJson<String>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      uploadedAt: serializer.fromJson<DateTime?>(json['uploadedAt']),
      isUploaded: serializer.fromJson<bool>(json['isUploaded']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<int>(userId),
      'fileName': serializer.toJson<String>(fileName),
      'localPath': serializer.toJson<String>(localPath),
      'cloudUrl': serializer.toJson<String?>(cloudUrl),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'contentType': serializer.toJson<String>(contentType),
      'photoType': serializer.toJson<String>(photoType),
      'associatedEntityId': serializer.toJson<String?>(associatedEntityId),
      'metadata': serializer.toJson<String>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'uploadedAt': serializer.toJson<DateTime?>(uploadedAt),
      'isUploaded': serializer.toJson<bool>(isUploaded),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Photo copyWith(
          {String? id,
          int? userId,
          String? fileName,
          String? localPath,
          Value<String?> cloudUrl = const Value.absent(),
          int? fileSizeBytes,
          Value<int?> width = const Value.absent(),
          Value<int?> height = const Value.absent(),
          String? contentType,
          String? photoType,
          Value<String?> associatedEntityId = const Value.absent(),
          String? metadata,
          DateTime? createdAt,
          Value<DateTime?> uploadedAt = const Value.absent(),
          bool? isUploaded,
          bool? isDeleted}) =>
      Photo(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        fileName: fileName ?? this.fileName,
        localPath: localPath ?? this.localPath,
        cloudUrl: cloudUrl.present ? cloudUrl.value : this.cloudUrl,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        width: width.present ? width.value : this.width,
        height: height.present ? height.value : this.height,
        contentType: contentType ?? this.contentType,
        photoType: photoType ?? this.photoType,
        associatedEntityId: associatedEntityId.present
            ? associatedEntityId.value
            : this.associatedEntityId,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        uploadedAt: uploadedAt.present ? uploadedAt.value : this.uploadedAt,
        isUploaded: isUploaded ?? this.isUploaded,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  Photo copyWithCompanion(PhotosCompanion data) {
    return Photo(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      cloudUrl: data.cloudUrl.present ? data.cloudUrl.value : this.cloudUrl,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      contentType:
          data.contentType.present ? data.contentType.value : this.contentType,
      photoType: data.photoType.present ? data.photoType.value : this.photoType,
      associatedEntityId: data.associatedEntityId.present
          ? data.associatedEntityId.value
          : this.associatedEntityId,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      uploadedAt:
          data.uploadedAt.present ? data.uploadedAt.value : this.uploadedAt,
      isUploaded:
          data.isUploaded.present ? data.isUploaded.value : this.isUploaded,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Photo(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('fileName: $fileName, ')
          ..write('localPath: $localPath, ')
          ..write('cloudUrl: $cloudUrl, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('contentType: $contentType, ')
          ..write('photoType: $photoType, ')
          ..write('associatedEntityId: $associatedEntityId, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('isUploaded: $isUploaded, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      fileName,
      localPath,
      cloudUrl,
      fileSizeBytes,
      width,
      height,
      contentType,
      photoType,
      associatedEntityId,
      metadata,
      createdAt,
      uploadedAt,
      isUploaded,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Photo &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.fileName == this.fileName &&
          other.localPath == this.localPath &&
          other.cloudUrl == this.cloudUrl &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.width == this.width &&
          other.height == this.height &&
          other.contentType == this.contentType &&
          other.photoType == this.photoType &&
          other.associatedEntityId == this.associatedEntityId &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.uploadedAt == this.uploadedAt &&
          other.isUploaded == this.isUploaded &&
          other.isDeleted == this.isDeleted);
}

class PhotosCompanion extends UpdateCompanion<Photo> {
  final Value<String> id;
  final Value<int> userId;
  final Value<String> fileName;
  final Value<String> localPath;
  final Value<String?> cloudUrl;
  final Value<int> fileSizeBytes;
  final Value<int?> width;
  final Value<int?> height;
  final Value<String> contentType;
  final Value<String> photoType;
  final Value<String?> associatedEntityId;
  final Value<String> metadata;
  final Value<DateTime> createdAt;
  final Value<DateTime?> uploadedAt;
  final Value<bool> isUploaded;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const PhotosCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.localPath = const Value.absent(),
    this.cloudUrl = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.contentType = const Value.absent(),
    this.photoType = const Value.absent(),
    this.associatedEntityId = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    this.isUploaded = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotosCompanion.insert({
    required String id,
    required int userId,
    required String fileName,
    required String localPath,
    this.cloudUrl = const Value.absent(),
    required int fileSizeBytes,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.contentType = const Value.absent(),
    required String photoType,
    this.associatedEntityId = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    this.isUploaded = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        fileName = Value(fileName),
        localPath = Value(localPath),
        fileSizeBytes = Value(fileSizeBytes),
        photoType = Value(photoType);
  static Insertable<Photo> custom({
    Expression<String>? id,
    Expression<int>? userId,
    Expression<String>? fileName,
    Expression<String>? localPath,
    Expression<String>? cloudUrl,
    Expression<int>? fileSizeBytes,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? contentType,
    Expression<String>? photoType,
    Expression<String>? associatedEntityId,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? uploadedAt,
    Expression<bool>? isUploaded,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (fileName != null) 'file_name': fileName,
      if (localPath != null) 'local_path': localPath,
      if (cloudUrl != null) 'cloud_url': cloudUrl,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (contentType != null) 'content_type': contentType,
      if (photoType != null) 'photo_type': photoType,
      if (associatedEntityId != null)
        'associated_entity_id': associatedEntityId,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (uploadedAt != null) 'uploaded_at': uploadedAt,
      if (isUploaded != null) 'is_uploaded': isUploaded,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotosCompanion copyWith(
      {Value<String>? id,
      Value<int>? userId,
      Value<String>? fileName,
      Value<String>? localPath,
      Value<String?>? cloudUrl,
      Value<int>? fileSizeBytes,
      Value<int?>? width,
      Value<int?>? height,
      Value<String>? contentType,
      Value<String>? photoType,
      Value<String?>? associatedEntityId,
      Value<String>? metadata,
      Value<DateTime>? createdAt,
      Value<DateTime?>? uploadedAt,
      Value<bool>? isUploaded,
      Value<bool>? isDeleted,
      Value<int>? rowid}) {
    return PhotosCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      cloudUrl: cloudUrl ?? this.cloudUrl,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      contentType: contentType ?? this.contentType,
      photoType: photoType ?? this.photoType,
      associatedEntityId: associatedEntityId ?? this.associatedEntityId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isUploaded: isUploaded ?? this.isUploaded,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (cloudUrl.present) {
      map['cloud_url'] = Variable<String>(cloudUrl.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (photoType.present) {
      map['photo_type'] = Variable<String>(photoType.value);
    }
    if (associatedEntityId.present) {
      map['associated_entity_id'] = Variable<String>(associatedEntityId.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (uploadedAt.present) {
      map['uploaded_at'] = Variable<DateTime>(uploadedAt.value);
    }
    if (isUploaded.present) {
      map['is_uploaded'] = Variable<bool>(isUploaded.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('fileName: $fileName, ')
          ..write('localPath: $localPath, ')
          ..write('cloudUrl: $cloudUrl, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('contentType: $contentType, ')
          ..write('photoType: $photoType, ')
          ..write('associatedEntityId: $associatedEntityId, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('isUploaded: $isUploaded, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserRestaurantInteractionsTable extends UserRestaurantInteractions
    with
        TableInfo<$UserRestaurantInteractionsTable, UserRestaurantInteraction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserRestaurantInteractionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _restaurantPlaceIdMeta =
      const VerificationMeta('restaurantPlaceId');
  @override
  late final GeneratedColumn<String> restaurantPlaceId =
      GeneratedColumn<String>('restaurant_place_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _restaurantNameMeta =
      const VerificationMeta('restaurantName');
  @override
  late final GeneratedColumn<String> restaurantName = GeneratedColumn<String>(
      'restaurant_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _interactionTypeMeta =
      const VerificationMeta('interactionType');
  @override
  late final GeneratedColumn<String> interactionType = GeneratedColumn<String>(
      'interaction_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _interactionDateMeta =
      const VerificationMeta('interactionDate');
  @override
  late final GeneratedColumn<DateTime> interactionDate =
      GeneratedColumn<DateTime>('interaction_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _contextMeta =
      const VerificationMeta('context');
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
      'context', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        restaurantPlaceId,
        restaurantName,
        interactionType,
        interactionDate,
        context
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_restaurant_interactions';
  @override
  VerificationContext validateIntegrity(
      Insertable<UserRestaurantInteraction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('restaurant_place_id')) {
      context.handle(
          _restaurantPlaceIdMeta,
          restaurantPlaceId.isAcceptableOrUnknown(
              data['restaurant_place_id']!, _restaurantPlaceIdMeta));
    } else if (isInserting) {
      context.missing(_restaurantPlaceIdMeta);
    }
    if (data.containsKey('restaurant_name')) {
      context.handle(
          _restaurantNameMeta,
          restaurantName.isAcceptableOrUnknown(
              data['restaurant_name']!, _restaurantNameMeta));
    }
    if (data.containsKey('interaction_type')) {
      context.handle(
          _interactionTypeMeta,
          interactionType.isAcceptableOrUnknown(
              data['interaction_type']!, _interactionTypeMeta));
    } else if (isInserting) {
      context.missing(_interactionTypeMeta);
    }
    if (data.containsKey('interaction_date')) {
      context.handle(
          _interactionDateMeta,
          interactionDate.isAcceptableOrUnknown(
              data['interaction_date']!, _interactionDateMeta));
    } else if (isInserting) {
      context.missing(_interactionDateMeta);
    }
    if (data.containsKey('context')) {
      context.handle(_contextMeta,
          this.context.isAcceptableOrUnknown(data['context']!, _contextMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserRestaurantInteraction map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRestaurantInteraction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      restaurantPlaceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}restaurant_place_id'])!,
      restaurantName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}restaurant_name']),
      interactionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}interaction_type'])!,
      interactionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}interaction_date'])!,
      context: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}context']),
    );
  }

  @override
  $UserRestaurantInteractionsTable createAlias(String alias) {
    return $UserRestaurantInteractionsTable(attachedDatabase, alias);
  }
}

class UserRestaurantInteraction extends DataClass
    implements Insertable<UserRestaurantInteraction> {
  final int id;
  final int userId;
  final String restaurantPlaceId;
  final String? restaurantName;

  /// One of: 'viewed', 'selected', 'rejected', 'favorited'
  final String interactionType;
  final DateTime interactionDate;

  /// Optional JSON context (source screen, search query, filters, etc.)
  final String? context;
  const UserRestaurantInteraction(
      {required this.id,
      required this.userId,
      required this.restaurantPlaceId,
      this.restaurantName,
      required this.interactionType,
      required this.interactionDate,
      this.context});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['restaurant_place_id'] = Variable<String>(restaurantPlaceId);
    if (!nullToAbsent || restaurantName != null) {
      map['restaurant_name'] = Variable<String>(restaurantName);
    }
    map['interaction_type'] = Variable<String>(interactionType);
    map['interaction_date'] = Variable<DateTime>(interactionDate);
    if (!nullToAbsent || context != null) {
      map['context'] = Variable<String>(context);
    }
    return map;
  }

  UserRestaurantInteractionsCompanion toCompanion(bool nullToAbsent) {
    return UserRestaurantInteractionsCompanion(
      id: Value(id),
      userId: Value(userId),
      restaurantPlaceId: Value(restaurantPlaceId),
      restaurantName: restaurantName == null && nullToAbsent
          ? const Value.absent()
          : Value(restaurantName),
      interactionType: Value(interactionType),
      interactionDate: Value(interactionDate),
      context: context == null && nullToAbsent
          ? const Value.absent()
          : Value(context),
    );
  }

  factory UserRestaurantInteraction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRestaurantInteraction(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      restaurantPlaceId: serializer.fromJson<String>(json['restaurantPlaceId']),
      restaurantName: serializer.fromJson<String?>(json['restaurantName']),
      interactionType: serializer.fromJson<String>(json['interactionType']),
      interactionDate: serializer.fromJson<DateTime>(json['interactionDate']),
      context: serializer.fromJson<String?>(json['context']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'restaurantPlaceId': serializer.toJson<String>(restaurantPlaceId),
      'restaurantName': serializer.toJson<String?>(restaurantName),
      'interactionType': serializer.toJson<String>(interactionType),
      'interactionDate': serializer.toJson<DateTime>(interactionDate),
      'context': serializer.toJson<String?>(context),
    };
  }

  UserRestaurantInteraction copyWith(
          {int? id,
          int? userId,
          String? restaurantPlaceId,
          Value<String?> restaurantName = const Value.absent(),
          String? interactionType,
          DateTime? interactionDate,
          Value<String?> context = const Value.absent()}) =>
      UserRestaurantInteraction(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        restaurantPlaceId: restaurantPlaceId ?? this.restaurantPlaceId,
        restaurantName:
            restaurantName.present ? restaurantName.value : this.restaurantName,
        interactionType: interactionType ?? this.interactionType,
        interactionDate: interactionDate ?? this.interactionDate,
        context: context.present ? context.value : this.context,
      );
  UserRestaurantInteraction copyWithCompanion(
      UserRestaurantInteractionsCompanion data) {
    return UserRestaurantInteraction(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      restaurantPlaceId: data.restaurantPlaceId.present
          ? data.restaurantPlaceId.value
          : this.restaurantPlaceId,
      restaurantName: data.restaurantName.present
          ? data.restaurantName.value
          : this.restaurantName,
      interactionType: data.interactionType.present
          ? data.interactionType.value
          : this.interactionType,
      interactionDate: data.interactionDate.present
          ? data.interactionDate.value
          : this.interactionDate,
      context: data.context.present ? data.context.value : this.context,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRestaurantInteraction(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('restaurantPlaceId: $restaurantPlaceId, ')
          ..write('restaurantName: $restaurantName, ')
          ..write('interactionType: $interactionType, ')
          ..write('interactionDate: $interactionDate, ')
          ..write('context: $context')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, restaurantPlaceId, restaurantName,
      interactionType, interactionDate, context);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRestaurantInteraction &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.restaurantPlaceId == this.restaurantPlaceId &&
          other.restaurantName == this.restaurantName &&
          other.interactionType == this.interactionType &&
          other.interactionDate == this.interactionDate &&
          other.context == this.context);
}

class UserRestaurantInteractionsCompanion
    extends UpdateCompanion<UserRestaurantInteraction> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> restaurantPlaceId;
  final Value<String?> restaurantName;
  final Value<String> interactionType;
  final Value<DateTime> interactionDate;
  final Value<String?> context;
  const UserRestaurantInteractionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.restaurantPlaceId = const Value.absent(),
    this.restaurantName = const Value.absent(),
    this.interactionType = const Value.absent(),
    this.interactionDate = const Value.absent(),
    this.context = const Value.absent(),
  });
  UserRestaurantInteractionsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String restaurantPlaceId,
    this.restaurantName = const Value.absent(),
    required String interactionType,
    required DateTime interactionDate,
    this.context = const Value.absent(),
  })  : userId = Value(userId),
        restaurantPlaceId = Value(restaurantPlaceId),
        interactionType = Value(interactionType),
        interactionDate = Value(interactionDate);
  static Insertable<UserRestaurantInteraction> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? restaurantPlaceId,
    Expression<String>? restaurantName,
    Expression<String>? interactionType,
    Expression<DateTime>? interactionDate,
    Expression<String>? context,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (restaurantPlaceId != null) 'restaurant_place_id': restaurantPlaceId,
      if (restaurantName != null) 'restaurant_name': restaurantName,
      if (interactionType != null) 'interaction_type': interactionType,
      if (interactionDate != null) 'interaction_date': interactionDate,
      if (context != null) 'context': context,
    });
  }

  UserRestaurantInteractionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? userId,
      Value<String>? restaurantPlaceId,
      Value<String?>? restaurantName,
      Value<String>? interactionType,
      Value<DateTime>? interactionDate,
      Value<String?>? context}) {
    return UserRestaurantInteractionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantPlaceId: restaurantPlaceId ?? this.restaurantPlaceId,
      restaurantName: restaurantName ?? this.restaurantName,
      interactionType: interactionType ?? this.interactionType,
      interactionDate: interactionDate ?? this.interactionDate,
      context: context ?? this.context,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (restaurantPlaceId.present) {
      map['restaurant_place_id'] = Variable<String>(restaurantPlaceId.value);
    }
    if (restaurantName.present) {
      map['restaurant_name'] = Variable<String>(restaurantName.value);
    }
    if (interactionType.present) {
      map['interaction_type'] = Variable<String>(interactionType.value);
    }
    if (interactionDate.present) {
      map['interaction_date'] = Variable<DateTime>(interactionDate.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserRestaurantInteractionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('restaurantPlaceId: $restaurantPlaceId, ')
          ..write('restaurantName: $restaurantName, ')
          ..write('interactionType: $interactionType, ')
          ..write('interactionDate: $interactionDate, ')
          ..write('context: $context')
          ..write(')'))
        .toString();
  }
}

class $MealOutcomesTable extends MealOutcomes
    with TableInfo<$MealOutcomesTable, MealOutcome> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealOutcomesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<int> mealId = GeneratedColumn<int>(
      'meal_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _restaurantPlaceIdMeta =
      const VerificationMeta('restaurantPlaceId');
  @override
  late final GeneratedColumn<String> restaurantPlaceId =
      GeneratedColumn<String>('restaurant_place_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
      'rating', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _wouldRevisitMeta =
      const VerificationMeta('wouldRevisit');
  @override
  late final GeneratedColumn<bool> wouldRevisit = GeneratedColumn<bool>(
      'would_revisit', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("would_revisit" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _feedbackMeta =
      const VerificationMeta('feedback');
  @override
  late final GeneratedColumn<String> feedback = GeneratedColumn<String>(
      'feedback', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        mealId,
        userId,
        restaurantPlaceId,
        rating,
        wouldRevisit,
        feedback,
        recordedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_outcomes';
  @override
  VerificationContext validateIntegrity(Insertable<MealOutcome> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('meal_id')) {
      context.handle(_mealIdMeta,
          mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta));
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('restaurant_place_id')) {
      context.handle(
          _restaurantPlaceIdMeta,
          restaurantPlaceId.isAcceptableOrUnknown(
              data['restaurant_place_id']!, _restaurantPlaceIdMeta));
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('would_revisit')) {
      context.handle(
          _wouldRevisitMeta,
          wouldRevisit.isAcceptableOrUnknown(
              data['would_revisit']!, _wouldRevisitMeta));
    }
    if (data.containsKey('feedback')) {
      context.handle(_feedbackMeta,
          feedback.isAcceptableOrUnknown(data['feedback']!, _feedbackMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealOutcome map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealOutcome(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      mealId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}meal_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      restaurantPlaceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}restaurant_place_id']),
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rating']),
      wouldRevisit: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}would_revisit'])!,
      feedback: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}feedback']),
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
    );
  }

  @override
  $MealOutcomesTable createAlias(String alias) {
    return $MealOutcomesTable(attachedDatabase, alias);
  }
}

class MealOutcome extends DataClass implements Insertable<MealOutcome> {
  final int id;
  final int mealId;
  final int userId;
  final String? restaurantPlaceId;

  /// User rating from 1 to 5
  final int? rating;
  final bool wouldRevisit;

  /// Free-text feedback from the user
  final String? feedback;
  final DateTime recordedAt;
  const MealOutcome(
      {required this.id,
      required this.mealId,
      required this.userId,
      this.restaurantPlaceId,
      this.rating,
      required this.wouldRevisit,
      this.feedback,
      required this.recordedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['meal_id'] = Variable<int>(mealId);
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || restaurantPlaceId != null) {
      map['restaurant_place_id'] = Variable<String>(restaurantPlaceId);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    map['would_revisit'] = Variable<bool>(wouldRevisit);
    if (!nullToAbsent || feedback != null) {
      map['feedback'] = Variable<String>(feedback);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  MealOutcomesCompanion toCompanion(bool nullToAbsent) {
    return MealOutcomesCompanion(
      id: Value(id),
      mealId: Value(mealId),
      userId: Value(userId),
      restaurantPlaceId: restaurantPlaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(restaurantPlaceId),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      wouldRevisit: Value(wouldRevisit),
      feedback: feedback == null && nullToAbsent
          ? const Value.absent()
          : Value(feedback),
      recordedAt: Value(recordedAt),
    );
  }

  factory MealOutcome.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealOutcome(
      id: serializer.fromJson<int>(json['id']),
      mealId: serializer.fromJson<int>(json['mealId']),
      userId: serializer.fromJson<int>(json['userId']),
      restaurantPlaceId:
          serializer.fromJson<String?>(json['restaurantPlaceId']),
      rating: serializer.fromJson<int?>(json['rating']),
      wouldRevisit: serializer.fromJson<bool>(json['wouldRevisit']),
      feedback: serializer.fromJson<String?>(json['feedback']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mealId': serializer.toJson<int>(mealId),
      'userId': serializer.toJson<int>(userId),
      'restaurantPlaceId': serializer.toJson<String?>(restaurantPlaceId),
      'rating': serializer.toJson<int?>(rating),
      'wouldRevisit': serializer.toJson<bool>(wouldRevisit),
      'feedback': serializer.toJson<String?>(feedback),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  MealOutcome copyWith(
          {int? id,
          int? mealId,
          int? userId,
          Value<String?> restaurantPlaceId = const Value.absent(),
          Value<int?> rating = const Value.absent(),
          bool? wouldRevisit,
          Value<String?> feedback = const Value.absent(),
          DateTime? recordedAt}) =>
      MealOutcome(
        id: id ?? this.id,
        mealId: mealId ?? this.mealId,
        userId: userId ?? this.userId,
        restaurantPlaceId: restaurantPlaceId.present
            ? restaurantPlaceId.value
            : this.restaurantPlaceId,
        rating: rating.present ? rating.value : this.rating,
        wouldRevisit: wouldRevisit ?? this.wouldRevisit,
        feedback: feedback.present ? feedback.value : this.feedback,
        recordedAt: recordedAt ?? this.recordedAt,
      );
  MealOutcome copyWithCompanion(MealOutcomesCompanion data) {
    return MealOutcome(
      id: data.id.present ? data.id.value : this.id,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      userId: data.userId.present ? data.userId.value : this.userId,
      restaurantPlaceId: data.restaurantPlaceId.present
          ? data.restaurantPlaceId.value
          : this.restaurantPlaceId,
      rating: data.rating.present ? data.rating.value : this.rating,
      wouldRevisit: data.wouldRevisit.present
          ? data.wouldRevisit.value
          : this.wouldRevisit,
      feedback: data.feedback.present ? data.feedback.value : this.feedback,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealOutcome(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('userId: $userId, ')
          ..write('restaurantPlaceId: $restaurantPlaceId, ')
          ..write('rating: $rating, ')
          ..write('wouldRevisit: $wouldRevisit, ')
          ..write('feedback: $feedback, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mealId, userId, restaurantPlaceId, rating,
      wouldRevisit, feedback, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealOutcome &&
          other.id == this.id &&
          other.mealId == this.mealId &&
          other.userId == this.userId &&
          other.restaurantPlaceId == this.restaurantPlaceId &&
          other.rating == this.rating &&
          other.wouldRevisit == this.wouldRevisit &&
          other.feedback == this.feedback &&
          other.recordedAt == this.recordedAt);
}

class MealOutcomesCompanion extends UpdateCompanion<MealOutcome> {
  final Value<int> id;
  final Value<int> mealId;
  final Value<int> userId;
  final Value<String?> restaurantPlaceId;
  final Value<int?> rating;
  final Value<bool> wouldRevisit;
  final Value<String?> feedback;
  final Value<DateTime> recordedAt;
  const MealOutcomesCompanion({
    this.id = const Value.absent(),
    this.mealId = const Value.absent(),
    this.userId = const Value.absent(),
    this.restaurantPlaceId = const Value.absent(),
    this.rating = const Value.absent(),
    this.wouldRevisit = const Value.absent(),
    this.feedback = const Value.absent(),
    this.recordedAt = const Value.absent(),
  });
  MealOutcomesCompanion.insert({
    this.id = const Value.absent(),
    required int mealId,
    required int userId,
    this.restaurantPlaceId = const Value.absent(),
    this.rating = const Value.absent(),
    this.wouldRevisit = const Value.absent(),
    this.feedback = const Value.absent(),
    required DateTime recordedAt,
  })  : mealId = Value(mealId),
        userId = Value(userId),
        recordedAt = Value(recordedAt);
  static Insertable<MealOutcome> custom({
    Expression<int>? id,
    Expression<int>? mealId,
    Expression<int>? userId,
    Expression<String>? restaurantPlaceId,
    Expression<int>? rating,
    Expression<bool>? wouldRevisit,
    Expression<String>? feedback,
    Expression<DateTime>? recordedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mealId != null) 'meal_id': mealId,
      if (userId != null) 'user_id': userId,
      if (restaurantPlaceId != null) 'restaurant_place_id': restaurantPlaceId,
      if (rating != null) 'rating': rating,
      if (wouldRevisit != null) 'would_revisit': wouldRevisit,
      if (feedback != null) 'feedback': feedback,
      if (recordedAt != null) 'recorded_at': recordedAt,
    });
  }

  MealOutcomesCompanion copyWith(
      {Value<int>? id,
      Value<int>? mealId,
      Value<int>? userId,
      Value<String?>? restaurantPlaceId,
      Value<int?>? rating,
      Value<bool>? wouldRevisit,
      Value<String?>? feedback,
      Value<DateTime>? recordedAt}) {
    return MealOutcomesCompanion(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      userId: userId ?? this.userId,
      restaurantPlaceId: restaurantPlaceId ?? this.restaurantPlaceId,
      rating: rating ?? this.rating,
      wouldRevisit: wouldRevisit ?? this.wouldRevisit,
      feedback: feedback ?? this.feedback,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<int>(mealId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (restaurantPlaceId.present) {
      map['restaurant_place_id'] = Variable<String>(restaurantPlaceId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (wouldRevisit.present) {
      map['would_revisit'] = Variable<bool>(wouldRevisit.value);
    }
    if (feedback.present) {
      map['feedback'] = Variable<String>(feedback.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealOutcomesCompanion(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('userId: $userId, ')
          ..write('restaurantPlaceId: $restaurantPlaceId, ')
          ..write('rating: $rating, ')
          ..write('wouldRevisit: $wouldRevisit, ')
          ..write('feedback: $feedback, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $MealsTable meals = $MealsTable(this);
  late final $BudgetTrackingsTable budgetTrackings =
      $BudgetTrackingsTable(this);
  late final $RestaurantsTable restaurants = $RestaurantsTable(this);
  late final $RestaurantCacheTable restaurantCache =
      $RestaurantCacheTable(this);
  late final $DietaryCompatibilityTable dietaryCompatibility =
      $DietaryCompatibilityTable(this);
  late final $UserDiscoveryHistoryTable userDiscoveryHistory =
      $UserDiscoveryHistoryTable(this);
  late final $AIRecommendationsTable aIRecommendations =
      $AIRecommendationsTable(this);
  late final $AIRecommendationFeedbackTable aIRecommendationFeedback =
      $AIRecommendationFeedbackTable(this);
  late final $AIUsageMetricsTable aIUsageMetrics = $AIUsageMetricsTable(this);
  late final $PhotosTable photos = $PhotosTable(this);
  late final $UserRestaurantInteractionsTable userRestaurantInteractions =
      $UserRestaurantInteractionsTable(this);
  late final $MealOutcomesTable mealOutcomes = $MealOutcomesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        meals,
        budgetTrackings,
        restaurants,
        restaurantCache,
        dietaryCompatibility,
        userDiscoveryHistory,
        aIRecommendations,
        aIRecommendationFeedback,
        aIUsageMetrics,
        photos,
        userRestaurantInteractions,
        mealOutcomes
      ];
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  required String name,
  required String preferences,
  Value<DateTime> createdAt,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> preferences,
  Value<DateTime> createdAt,
});

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MealsTable, List<Meal>> _mealsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.meals,
          aliasName: $_aliasNameGenerator(db.users.id, db.meals.userId));

  $$MealsTableProcessedTableManager get mealsRefs {
    final manager = $$MealsTableTableManager($_db, $_db.meals)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_mealsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BudgetTrackingsTable, List<BudgetTracking>>
      _budgetTrackingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.budgetTrackings,
              aliasName:
                  $_aliasNameGenerator(db.users.id, db.budgetTrackings.userId));

  $$BudgetTrackingsTableProcessedTableManager get budgetTrackingsRefs {
    final manager =
        $$BudgetTrackingsTableTableManager($_db, $_db.budgetTrackings)
            .filter((f) => f.userId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_budgetTrackingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$UserDiscoveryHistoryTable,
      List<UserDiscoveryHistoryData>> _userDiscoveryHistoryRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.userDiscoveryHistory,
          aliasName: $_aliasNameGenerator(
              db.users.id, db.userDiscoveryHistory.userId));

  $$UserDiscoveryHistoryTableProcessedTableManager
      get userDiscoveryHistoryRefs {
    final manager =
        $$UserDiscoveryHistoryTableTableManager($_db, $_db.userDiscoveryHistory)
            .filter((f) => f.userId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_userDiscoveryHistoryRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AIRecommendationsTable, List<AIRecommendation>>
      _aIRecommendationsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.aIRecommendations,
              aliasName: $_aliasNameGenerator(
                  db.users.id, db.aIRecommendations.userId));

  $$AIRecommendationsTableProcessedTableManager get aIRecommendationsRefs {
    final manager =
        $$AIRecommendationsTableTableManager($_db, $_db.aIRecommendations)
            .filter((f) => f.userId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_aIRecommendationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AIRecommendationFeedbackTable,
      List<AIRecommendationFeedbackData>> _aIRecommendationFeedbackRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.aIRecommendationFeedback,
          aliasName: $_aliasNameGenerator(
              db.users.id, db.aIRecommendationFeedback.userId));

  $$AIRecommendationFeedbackTableProcessedTableManager
      get aIRecommendationFeedbackRefs {
    final manager = $$AIRecommendationFeedbackTableTableManager(
            $_db, $_db.aIRecommendationFeedback)
        .filter((f) => f.userId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_aIRecommendationFeedbackRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AIUsageMetricsTable, List<AIUsageMetric>>
      _aIUsageMetricsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.aIUsageMetrics,
              aliasName:
                  $_aliasNameGenerator(db.users.id, db.aIUsageMetrics.userId));

  $$AIUsageMetricsTableProcessedTableManager get aIUsageMetricsRefs {
    final manager = $$AIUsageMetricsTableTableManager($_db, $_db.aIUsageMetrics)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_aIUsageMetricsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PhotosTable, List<Photo>> _photosRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.photos,
          aliasName: $_aliasNameGenerator(db.users.id, db.photos.userId));

  $$PhotosTableProcessedTableManager get photosRefs {
    final manager = $$PhotosTableTableManager($_db, $_db.photos)
        .filter((f) => f.userId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_photosRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get preferences => $composableBuilder(
      column: $table.preferences, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> mealsRefs(
      Expression<bool> Function($$MealsTableFilterComposer f) f) {
    final $$MealsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.meals,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealsTableFilterComposer(
              $db: $db,
              $table: $db.meals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> budgetTrackingsRefs(
      Expression<bool> Function($$BudgetTrackingsTableFilterComposer f) f) {
    final $$BudgetTrackingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.budgetTrackings,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BudgetTrackingsTableFilterComposer(
              $db: $db,
              $table: $db.budgetTrackings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> userDiscoveryHistoryRefs(
      Expression<bool> Function($$UserDiscoveryHistoryTableFilterComposer f)
          f) {
    final $$UserDiscoveryHistoryTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userDiscoveryHistory,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserDiscoveryHistoryTableFilterComposer(
              $db: $db,
              $table: $db.userDiscoveryHistory,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> aIRecommendationsRefs(
      Expression<bool> Function($$AIRecommendationsTableFilterComposer f) f) {
    final $$AIRecommendationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.aIRecommendations,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AIRecommendationsTableFilterComposer(
              $db: $db,
              $table: $db.aIRecommendations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> aIRecommendationFeedbackRefs(
      Expression<bool> Function($$AIRecommendationFeedbackTableFilterComposer f)
          f) {
    final $$AIRecommendationFeedbackTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.aIRecommendationFeedback,
            getReferencedColumn: (t) => t.userId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AIRecommendationFeedbackTableFilterComposer(
                  $db: $db,
                  $table: $db.aIRecommendationFeedback,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> aIUsageMetricsRefs(
      Expression<bool> Function($$AIUsageMetricsTableFilterComposer f) f) {
    final $$AIUsageMetricsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.aIUsageMetrics,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AIUsageMetricsTableFilterComposer(
              $db: $db,
              $table: $db.aIUsageMetrics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> photosRefs(
      Expression<bool> Function($$PhotosTableFilterComposer f) f) {
    final $$PhotosTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.photos,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PhotosTableFilterComposer(
              $db: $db,
              $table: $db.photos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get preferences => $composableBuilder(
      column: $table.preferences, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get preferences => $composableBuilder(
      column: $table.preferences, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> mealsRefs<T extends Object>(
      Expression<T> Function($$MealsTableAnnotationComposer a) f) {
    final $$MealsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.meals,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealsTableAnnotationComposer(
              $db: $db,
              $table: $db.meals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> budgetTrackingsRefs<T extends Object>(
      Expression<T> Function($$BudgetTrackingsTableAnnotationComposer a) f) {
    final $$BudgetTrackingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.budgetTrackings,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BudgetTrackingsTableAnnotationComposer(
              $db: $db,
              $table: $db.budgetTrackings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> userDiscoveryHistoryRefs<T extends Object>(
      Expression<T> Function($$UserDiscoveryHistoryTableAnnotationComposer a)
          f) {
    final $$UserDiscoveryHistoryTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.userDiscoveryHistory,
            getReferencedColumn: (t) => t.userId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$UserDiscoveryHistoryTableAnnotationComposer(
                  $db: $db,
                  $table: $db.userDiscoveryHistory,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> aIRecommendationsRefs<T extends Object>(
      Expression<T> Function($$AIRecommendationsTableAnnotationComposer a) f) {
    final $$AIRecommendationsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.aIRecommendations,
            getReferencedColumn: (t) => t.userId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AIRecommendationsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.aIRecommendations,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> aIRecommendationFeedbackRefs<T extends Object>(
      Expression<T> Function(
              $$AIRecommendationFeedbackTableAnnotationComposer a)
          f) {
    final $$AIRecommendationFeedbackTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.aIRecommendationFeedback,
            getReferencedColumn: (t) => t.userId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AIRecommendationFeedbackTableAnnotationComposer(
                  $db: $db,
                  $table: $db.aIRecommendationFeedback,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> aIUsageMetricsRefs<T extends Object>(
      Expression<T> Function($$AIUsageMetricsTableAnnotationComposer a) f) {
    final $$AIUsageMetricsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.aIUsageMetrics,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AIUsageMetricsTableAnnotationComposer(
              $db: $db,
              $table: $db.aIUsageMetrics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> photosRefs<T extends Object>(
      Expression<T> Function($$PhotosTableAnnotationComposer a) f) {
    final $$PhotosTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.photos,
        getReferencedColumn: (t) => t.userId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PhotosTableAnnotationComposer(
              $db: $db,
              $table: $db.photos,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, $$UsersTableReferences),
    User,
    PrefetchHooks Function(
        {bool mealsRefs,
        bool budgetTrackingsRefs,
        bool userDiscoveryHistoryRefs,
        bool aIRecommendationsRefs,
        bool aIRecommendationFeedbackRefs,
        bool aIUsageMetricsRefs,
        bool photosRefs})> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> preferences = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            name: name,
            preferences: preferences,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String preferences,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            name: name,
            preferences: preferences,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$UsersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {mealsRefs = false,
              budgetTrackingsRefs = false,
              userDiscoveryHistoryRefs = false,
              aIRecommendationsRefs = false,
              aIRecommendationFeedbackRefs = false,
              aIUsageMetricsRefs = false,
              photosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (mealsRefs) db.meals,
                if (budgetTrackingsRefs) db.budgetTrackings,
                if (userDiscoveryHistoryRefs) db.userDiscoveryHistory,
                if (aIRecommendationsRefs) db.aIRecommendations,
                if (aIRecommendationFeedbackRefs) db.aIRecommendationFeedback,
                if (aIUsageMetricsRefs) db.aIUsageMetrics,
                if (photosRefs) db.photos
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mealsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._mealsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).mealsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (budgetTrackingsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$UsersTableReferences
                            ._budgetTrackingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .budgetTrackingsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (userDiscoveryHistoryRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$UsersTableReferences
                            ._userDiscoveryHistoryRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .userDiscoveryHistoryRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (aIRecommendationsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$UsersTableReferences
                            ._aIRecommendationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .aIRecommendationsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (aIRecommendationFeedbackRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$UsersTableReferences
                            ._aIRecommendationFeedbackRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .aIRecommendationFeedbackRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (aIUsageMetricsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._aIUsageMetricsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0)
                                .aIUsageMetricsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items),
                  if (photosRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UsersTableReferences._photosRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersTableReferences(db, table, p0).photosRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.userId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, $$UsersTableReferences),
    User,
    PrefetchHooks Function(
        {bool mealsRefs,
        bool budgetTrackingsRefs,
        bool userDiscoveryHistoryRefs,
        bool aIRecommendationsRefs,
        bool aIRecommendationFeedbackRefs,
        bool aIUsageMetricsRefs,
        bool photosRefs})>;
typedef $$MealsTableCreateCompanionBuilder = MealsCompanion Function({
  Value<int> id,
  required int userId,
  Value<String?> restaurantId,
  required String mealType,
  required double cost,
  required DateTime date,
  Value<String?> restaurantName,
  Value<String?> notes,
  Value<String> photoIds,
});
typedef $$MealsTableUpdateCompanionBuilder = MealsCompanion Function({
  Value<int> id,
  Value<int> userId,
  Value<String?> restaurantId,
  Value<String> mealType,
  Value<double> cost,
  Value<DateTime> date,
  Value<String?> restaurantName,
  Value<String?> notes,
  Value<String> photoIds,
});

final class $$MealsTableReferences
    extends BaseReferences<_$AppDatabase, $MealsTable, Meal> {
  $$MealsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) =>
      db.users.createAlias($_aliasNameGenerator(db.meals.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MealsTableFilterComposer extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get restaurantId => $composableBuilder(
      column: $table.restaurantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mealType => $composableBuilder(
      column: $table.mealType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cost => $composableBuilder(
      column: $table.cost, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get restaurantName => $composableBuilder(
      column: $table.restaurantName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoIds => $composableBuilder(
      column: $table.photoIds, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MealsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get restaurantId => $composableBuilder(
      column: $table.restaurantId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mealType => $composableBuilder(
      column: $table.mealType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cost => $composableBuilder(
      column: $table.cost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get restaurantName => $composableBuilder(
      column: $table.restaurantName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoIds => $composableBuilder(
      column: $table.photoIds, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MealsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get restaurantId => $composableBuilder(
      column: $table.restaurantId, builder: (column) => column);

  GeneratedColumn<String> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);

  GeneratedColumn<double> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get restaurantName => $composableBuilder(
      column: $table.restaurantName, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get photoIds =>
      $composableBuilder(column: $table.photoIds, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MealsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealsTable,
    Meal,
    $$MealsTableFilterComposer,
    $$MealsTableOrderingComposer,
    $$MealsTableAnnotationComposer,
    $$MealsTableCreateCompanionBuilder,
    $$MealsTableUpdateCompanionBuilder,
    (Meal, $$MealsTableReferences),
    Meal,
    PrefetchHooks Function({bool userId})> {
  $$MealsTableTableManager(_$AppDatabase db, $MealsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String?> restaurantId = const Value.absent(),
            Value<String> mealType = const Value.absent(),
            Value<double> cost = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String?> restaurantName = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> photoIds = const Value.absent(),
          }) =>
              MealsCompanion(
            id: id,
            userId: userId,
            restaurantId: restaurantId,
            mealType: mealType,
            cost: cost,
            date: date,
            restaurantName: restaurantName,
            notes: notes,
            photoIds: photoIds,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int userId,
            Value<String?> restaurantId = const Value.absent(),
            required String mealType,
            required double cost,
            required DateTime date,
            Value<String?> restaurantName = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> photoIds = const Value.absent(),
          }) =>
              MealsCompanion.insert(
            id: id,
            userId: userId,
            restaurantId: restaurantId,
            mealType: mealType,
            cost: cost,
            date: date,
            restaurantName: restaurantName,
            notes: notes,
            photoIds: photoIds,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$MealsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable: $$MealsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$MealsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MealsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealsTable,
    Meal,
    $$MealsTableFilterComposer,
    $$MealsTableOrderingComposer,
    $$MealsTableAnnotationComposer,
    $$MealsTableCreateCompanionBuilder,
    $$MealsTableUpdateCompanionBuilder,
    (Meal, $$MealsTableReferences),
    Meal,
    PrefetchHooks Function({bool userId})>;
typedef $$BudgetTrackingsTableCreateCompanionBuilder = BudgetTrackingsCompanion
    Function({
  Value<int> id,
  required int userId,
  required double amount,
  required String category,
  required DateTime date,
});
typedef $$BudgetTrackingsTableUpdateCompanionBuilder = BudgetTrackingsCompanion
    Function({
  Value<int> id,
  Value<int> userId,
  Value<double> amount,
  Value<String> category,
  Value<DateTime> date,
});

final class $$BudgetTrackingsTableReferences extends BaseReferences<
    _$AppDatabase, $BudgetTrackingsTable, BudgetTracking> {
  $$BudgetTrackingsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
      $_aliasNameGenerator(db.budgetTrackings.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BudgetTrackingsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetTrackingsTable> {
  $$BudgetTrackingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetTrackingsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetTrackingsTable> {
  $$BudgetTrackingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetTrackingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetTrackingsTable> {
  $$BudgetTrackingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetTrackingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BudgetTrackingsTable,
    BudgetTracking,
    $$BudgetTrackingsTableFilterComposer,
    $$BudgetTrackingsTableOrderingComposer,
    $$BudgetTrackingsTableAnnotationComposer,
    $$BudgetTrackingsTableCreateCompanionBuilder,
    $$BudgetTrackingsTableUpdateCompanionBuilder,
    (BudgetTracking, $$BudgetTrackingsTableReferences),
    BudgetTracking,
    PrefetchHooks Function({bool userId})> {
  $$BudgetTrackingsTableTableManager(
      _$AppDatabase db, $BudgetTrackingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetTrackingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetTrackingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetTrackingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
          }) =>
              BudgetTrackingsCompanion(
            id: id,
            userId: userId,
            amount: amount,
            category: category,
            date: date,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int userId,
            required double amount,
            required String category,
            required DateTime date,
          }) =>
              BudgetTrackingsCompanion.insert(
            id: id,
            userId: userId,
            amount: amount,
            category: category,
            date: date,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BudgetTrackingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$BudgetTrackingsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$BudgetTrackingsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BudgetTrackingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BudgetTrackingsTable,
    BudgetTracking,
    $$BudgetTrackingsTableFilterComposer,
    $$BudgetTrackingsTableOrderingComposer,
    $$BudgetTrackingsTableAnnotationComposer,
    $$BudgetTrackingsTableCreateCompanionBuilder,
    $$BudgetTrackingsTableUpdateCompanionBuilder,
    (BudgetTracking, $$BudgetTrackingsTableReferences),
    BudgetTracking,
    PrefetchHooks Function({bool userId})>;
typedef $$RestaurantsTableCreateCompanionBuilder = RestaurantsCompanion
    Function({
  required String placeId,
  required String name,
  required String location,
  Value<String?> address,
  Value<String?> phoneNumber,
  Value<String?> website,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<double?> distanceFromUser,
  Value<double?> rating,
  Value<int?> reviewCount,
  Value<int?> priceLevel,
  Value<String> priceRanges,
  Value<String?> cuisineType,
  Value<String> cuisineTypes,
  Value<String> supportedDietaryRestrictions,
  Value<String> allergenInfo,
  Value<String> dietaryCompatibilityScores,
  Value<bool> hasVerifiedDietaryInfo,
  Value<int> communityVerificationCount,
  Value<String> openingHours,
  Value<bool> isOpenNow,
  Value<String?> currentWaitTime,
  Value<String> features,
  Value<double?> averageMealCost,
  Value<double?> valueScore,
  Value<String> mealTypeAverageCosts,
  Value<DateTime> cachedAt,
  Value<DateTime?> lastVerified,
  Value<String?> photoReference,
  Value<String> photoReferences,
  Value<int> rowid,
});
typedef $$RestaurantsTableUpdateCompanionBuilder = RestaurantsCompanion
    Function({
  Value<String> placeId,
  Value<String> name,
  Value<String> location,
  Value<String?> address,
  Value<String?> phoneNumber,
  Value<String?> website,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<double?> distanceFromUser,
  Value<double?> rating,
  Value<int?> reviewCount,
  Value<int?> priceLevel,
  Value<String> priceRanges,
  Value<String?> cuisineType,
  Value<String> cuisineTypes,
  Value<String> supportedDietaryRestrictions,
  Value<String> allergenInfo,
  Value<String> dietaryCompatibilityScores,
  Value<bool> hasVerifiedDietaryInfo,
  Value<int> communityVerificationCount,
  Value<String> openingHours,
  Value<bool> isOpenNow,
  Value<String?> currentWaitTime,
  Value<String> features,
  Value<double?> averageMealCost,
  Value<double?> valueScore,
  Value<String> mealTypeAverageCosts,
  Value<DateTime> cachedAt,
  Value<DateTime?> lastVerified,
  Value<String?> photoReference,
  Value<String> photoReferences,
  Value<int> rowid,
});

final class $$RestaurantsTableReferences
    extends BaseReferences<_$AppDatabase, $RestaurantsTable, Restaurant> {
  $$RestaurantsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DietaryCompatibilityTable,
      List<DietaryCompatibilityData>> _dietaryCompatibilityRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.dietaryCompatibility,
          aliasName: $_aliasNameGenerator(
              db.restaurants.placeId, db.dietaryCompatibility.placeId));

  $$DietaryCompatibilityTableProcessedTableManager
      get dietaryCompatibilityRefs {
    final manager =
        $$DietaryCompatibilityTableTableManager($_db, $_db.dietaryCompatibility)
            .filter((f) => f.placeId.placeId($_item.placeId));

    final cache =
        $_typedResult.readTableOrNull(_dietaryCompatibilityRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$UserDiscoveryHistoryTable,
      List<UserDiscoveryHistoryData>> _userDiscoveryHistoryRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.userDiscoveryHistory,
          aliasName: $_aliasNameGenerator(
              db.restaurants.placeId, db.userDiscoveryHistory.placeId));

  $$UserDiscoveryHistoryTableProcessedTableManager
      get userDiscoveryHistoryRefs {
    final manager =
        $$UserDiscoveryHistoryTableTableManager($_db, $_db.userDiscoveryHistory)
            .filter((f) => f.placeId.placeId($_item.placeId));

    final cache =
        $_typedResult.readTableOrNull(_userDiscoveryHistoryRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AIRecommendationFeedbackTable,
      List<AIRecommendationFeedbackData>> _aIRecommendationFeedbackRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.aIRecommendationFeedback,
          aliasName: $_aliasNameGenerator(
              db.restaurants.placeId, db.aIRecommendationFeedback.placeId));

  $$AIRecommendationFeedbackTableProcessedTableManager
      get aIRecommendationFeedbackRefs {
    final manager = $$AIRecommendationFeedbackTableTableManager(
            $_db, $_db.aIRecommendationFeedback)
        .filter((f) => f.placeId.placeId($_item.placeId));

    final cache =
        $_typedResult.readTableOrNull(_aIRecommendationFeedbackRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RestaurantsTableFilterComposer
    extends Composer<_$AppDatabase, $RestaurantsTable> {
  $$RestaurantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get placeId => $composableBuilder(
      column: $table.placeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get website => $composableBuilder(
      column: $table.website, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceFromUser => $composableBuilder(
      column: $table.distanceFromUser,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reviewCount => $composableBuilder(
      column: $table.reviewCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priceLevel => $composableBuilder(
      column: $table.priceLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priceRanges => $composableBuilder(
      column: $table.priceRanges, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cuisineType => $composableBuilder(
      column: $table.cuisineType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cuisineTypes => $composableBuilder(
      column: $table.cuisineTypes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get supportedDietaryRestrictions => $composableBuilder(
      column: $table.supportedDietaryRestrictions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get allergenInfo => $composableBuilder(
      column: $table.allergenInfo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dietaryCompatibilityScores => $composableBuilder(
      column: $table.dietaryCompatibilityScores,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasVerifiedDietaryInfo => $composableBuilder(
      column: $table.hasVerifiedDietaryInfo,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get communityVerificationCount => $composableBuilder(
      column: $table.communityVerificationCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get openingHours => $composableBuilder(
      column: $table.openingHours, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isOpenNow => $composableBuilder(
      column: $table.isOpenNow, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentWaitTime => $composableBuilder(
      column: $table.currentWaitTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get features => $composableBuilder(
      column: $table.features, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get averageMealCost => $composableBuilder(
      column: $table.averageMealCost,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get valueScore => $composableBuilder(
      column: $table.valueScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mealTypeAverageCosts => $composableBuilder(
      column: $table.mealTypeAverageCosts,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastVerified => $composableBuilder(
      column: $table.lastVerified, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoReference => $composableBuilder(
      column: $table.photoReference,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoReferences => $composableBuilder(
      column: $table.photoReferences,
      builder: (column) => ColumnFilters(column));

  Expression<bool> dietaryCompatibilityRefs(
      Expression<bool> Function($$DietaryCompatibilityTableFilterComposer f)
          f) {
    final $$DietaryCompatibilityTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.placeId,
        referencedTable: $db.dietaryCompatibility,
        getReferencedColumn: (t) => t.placeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DietaryCompatibilityTableFilterComposer(
              $db: $db,
              $table: $db.dietaryCompatibility,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> userDiscoveryHistoryRefs(
      Expression<bool> Function($$UserDiscoveryHistoryTableFilterComposer f)
          f) {
    final $$UserDiscoveryHistoryTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.placeId,
        referencedTable: $db.userDiscoveryHistory,
        getReferencedColumn: (t) => t.placeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserDiscoveryHistoryTableFilterComposer(
              $db: $db,
              $table: $db.userDiscoveryHistory,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> aIRecommendationFeedbackRefs(
      Expression<bool> Function($$AIRecommendationFeedbackTableFilterComposer f)
          f) {
    final $$AIRecommendationFeedbackTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.placeId,
            referencedTable: $db.aIRecommendationFeedback,
            getReferencedColumn: (t) => t.placeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AIRecommendationFeedbackTableFilterComposer(
                  $db: $db,
                  $table: $db.aIRecommendationFeedback,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$RestaurantsTableOrderingComposer
    extends Composer<_$AppDatabase, $RestaurantsTable> {
  $$RestaurantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get placeId => $composableBuilder(
      column: $table.placeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get website => $composableBuilder(
      column: $table.website, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceFromUser => $composableBuilder(
      column: $table.distanceFromUser,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reviewCount => $composableBuilder(
      column: $table.reviewCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priceLevel => $composableBuilder(
      column: $table.priceLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priceRanges => $composableBuilder(
      column: $table.priceRanges, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cuisineType => $composableBuilder(
      column: $table.cuisineType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cuisineTypes => $composableBuilder(
      column: $table.cuisineTypes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get supportedDietaryRestrictions =>
      $composableBuilder(
          column: $table.supportedDietaryRestrictions,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get allergenInfo => $composableBuilder(
      column: $table.allergenInfo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dietaryCompatibilityScores => $composableBuilder(
      column: $table.dietaryCompatibilityScores,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasVerifiedDietaryInfo => $composableBuilder(
      column: $table.hasVerifiedDietaryInfo,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get communityVerificationCount => $composableBuilder(
      column: $table.communityVerificationCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get openingHours => $composableBuilder(
      column: $table.openingHours,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isOpenNow => $composableBuilder(
      column: $table.isOpenNow, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentWaitTime => $composableBuilder(
      column: $table.currentWaitTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get features => $composableBuilder(
      column: $table.features, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get averageMealCost => $composableBuilder(
      column: $table.averageMealCost,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get valueScore => $composableBuilder(
      column: $table.valueScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mealTypeAverageCosts => $composableBuilder(
      column: $table.mealTypeAverageCosts,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastVerified => $composableBuilder(
      column: $table.lastVerified,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoReference => $composableBuilder(
      column: $table.photoReference,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoReferences => $composableBuilder(
      column: $table.photoReferences,
      builder: (column) => ColumnOrderings(column));
}

class $$RestaurantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RestaurantsTable> {
  $$RestaurantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get placeId =>
      $composableBuilder(column: $table.placeId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => column);

  GeneratedColumn<String> get website =>
      $composableBuilder(column: $table.website, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get distanceFromUser => $composableBuilder(
      column: $table.distanceFromUser, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get reviewCount => $composableBuilder(
      column: $table.reviewCount, builder: (column) => column);

  GeneratedColumn<int> get priceLevel => $composableBuilder(
      column: $table.priceLevel, builder: (column) => column);

  GeneratedColumn<String> get priceRanges => $composableBuilder(
      column: $table.priceRanges, builder: (column) => column);

  GeneratedColumn<String> get cuisineType => $composableBuilder(
      column: $table.cuisineType, builder: (column) => column);

  GeneratedColumn<String> get cuisineTypes => $composableBuilder(
      column: $table.cuisineTypes, builder: (column) => column);

  GeneratedColumn<String> get supportedDietaryRestrictions =>
      $composableBuilder(
          column: $table.supportedDietaryRestrictions,
          builder: (column) => column);

  GeneratedColumn<String> get allergenInfo => $composableBuilder(
      column: $table.allergenInfo, builder: (column) => column);

  GeneratedColumn<String> get dietaryCompatibilityScores => $composableBuilder(
      column: $table.dietaryCompatibilityScores, builder: (column) => column);

  GeneratedColumn<bool> get hasVerifiedDietaryInfo => $composableBuilder(
      column: $table.hasVerifiedDietaryInfo, builder: (column) => column);

  GeneratedColumn<int> get communityVerificationCount => $composableBuilder(
      column: $table.communityVerificationCount, builder: (column) => column);

  GeneratedColumn<String> get openingHours => $composableBuilder(
      column: $table.openingHours, builder: (column) => column);

  GeneratedColumn<bool> get isOpenNow =>
      $composableBuilder(column: $table.isOpenNow, builder: (column) => column);

  GeneratedColumn<String> get currentWaitTime => $composableBuilder(
      column: $table.currentWaitTime, builder: (column) => column);

  GeneratedColumn<String> get features =>
      $composableBuilder(column: $table.features, builder: (column) => column);

  GeneratedColumn<double> get averageMealCost => $composableBuilder(
      column: $table.averageMealCost, builder: (column) => column);

  GeneratedColumn<double> get valueScore => $composableBuilder(
      column: $table.valueScore, builder: (column) => column);

  GeneratedColumn<String> get mealTypeAverageCosts => $composableBuilder(
      column: $table.mealTypeAverageCosts, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastVerified => $composableBuilder(
      column: $table.lastVerified, builder: (column) => column);

  GeneratedColumn<String> get photoReference => $composableBuilder(
      column: $table.photoReference, builder: (column) => column);

  GeneratedColumn<String> get photoReferences => $composableBuilder(
      column: $table.photoReferences, builder: (column) => column);

  Expression<T> dietaryCompatibilityRefs<T extends Object>(
      Expression<T> Function($$DietaryCompatibilityTableAnnotationComposer a)
          f) {
    final $$DietaryCompatibilityTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.placeId,
            referencedTable: $db.dietaryCompatibility,
            getReferencedColumn: (t) => t.placeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$DietaryCompatibilityTableAnnotationComposer(
                  $db: $db,
                  $table: $db.dietaryCompatibility,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> userDiscoveryHistoryRefs<T extends Object>(
      Expression<T> Function($$UserDiscoveryHistoryTableAnnotationComposer a)
          f) {
    final $$UserDiscoveryHistoryTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.placeId,
            referencedTable: $db.userDiscoveryHistory,
            getReferencedColumn: (t) => t.placeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$UserDiscoveryHistoryTableAnnotationComposer(
                  $db: $db,
                  $table: $db.userDiscoveryHistory,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> aIRecommendationFeedbackRefs<T extends Object>(
      Expression<T> Function(
              $$AIRecommendationFeedbackTableAnnotationComposer a)
          f) {
    final $$AIRecommendationFeedbackTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.placeId,
            referencedTable: $db.aIRecommendationFeedback,
            getReferencedColumn: (t) => t.placeId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AIRecommendationFeedbackTableAnnotationComposer(
                  $db: $db,
                  $table: $db.aIRecommendationFeedback,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$RestaurantsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RestaurantsTable,
    Restaurant,
    $$RestaurantsTableFilterComposer,
    $$RestaurantsTableOrderingComposer,
    $$RestaurantsTableAnnotationComposer,
    $$RestaurantsTableCreateCompanionBuilder,
    $$RestaurantsTableUpdateCompanionBuilder,
    (Restaurant, $$RestaurantsTableReferences),
    Restaurant,
    PrefetchHooks Function(
        {bool dietaryCompatibilityRefs,
        bool userDiscoveryHistoryRefs,
        bool aIRecommendationFeedbackRefs})> {
  $$RestaurantsTableTableManager(_$AppDatabase db, $RestaurantsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RestaurantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RestaurantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RestaurantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> placeId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> location = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> phoneNumber = const Value.absent(),
            Value<String?> website = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<double?> distanceFromUser = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<int?> reviewCount = const Value.absent(),
            Value<int?> priceLevel = const Value.absent(),
            Value<String> priceRanges = const Value.absent(),
            Value<String?> cuisineType = const Value.absent(),
            Value<String> cuisineTypes = const Value.absent(),
            Value<String> supportedDietaryRestrictions = const Value.absent(),
            Value<String> allergenInfo = const Value.absent(),
            Value<String> dietaryCompatibilityScores = const Value.absent(),
            Value<bool> hasVerifiedDietaryInfo = const Value.absent(),
            Value<int> communityVerificationCount = const Value.absent(),
            Value<String> openingHours = const Value.absent(),
            Value<bool> isOpenNow = const Value.absent(),
            Value<String?> currentWaitTime = const Value.absent(),
            Value<String> features = const Value.absent(),
            Value<double?> averageMealCost = const Value.absent(),
            Value<double?> valueScore = const Value.absent(),
            Value<String> mealTypeAverageCosts = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<DateTime?> lastVerified = const Value.absent(),
            Value<String?> photoReference = const Value.absent(),
            Value<String> photoReferences = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RestaurantsCompanion(
            placeId: placeId,
            name: name,
            location: location,
            address: address,
            phoneNumber: phoneNumber,
            website: website,
            latitude: latitude,
            longitude: longitude,
            distanceFromUser: distanceFromUser,
            rating: rating,
            reviewCount: reviewCount,
            priceLevel: priceLevel,
            priceRanges: priceRanges,
            cuisineType: cuisineType,
            cuisineTypes: cuisineTypes,
            supportedDietaryRestrictions: supportedDietaryRestrictions,
            allergenInfo: allergenInfo,
            dietaryCompatibilityScores: dietaryCompatibilityScores,
            hasVerifiedDietaryInfo: hasVerifiedDietaryInfo,
            communityVerificationCount: communityVerificationCount,
            openingHours: openingHours,
            isOpenNow: isOpenNow,
            currentWaitTime: currentWaitTime,
            features: features,
            averageMealCost: averageMealCost,
            valueScore: valueScore,
            mealTypeAverageCosts: mealTypeAverageCosts,
            cachedAt: cachedAt,
            lastVerified: lastVerified,
            photoReference: photoReference,
            photoReferences: photoReferences,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String placeId,
            required String name,
            required String location,
            Value<String?> address = const Value.absent(),
            Value<String?> phoneNumber = const Value.absent(),
            Value<String?> website = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<double?> distanceFromUser = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<int?> reviewCount = const Value.absent(),
            Value<int?> priceLevel = const Value.absent(),
            Value<String> priceRanges = const Value.absent(),
            Value<String?> cuisineType = const Value.absent(),
            Value<String> cuisineTypes = const Value.absent(),
            Value<String> supportedDietaryRestrictions = const Value.absent(),
            Value<String> allergenInfo = const Value.absent(),
            Value<String> dietaryCompatibilityScores = const Value.absent(),
            Value<bool> hasVerifiedDietaryInfo = const Value.absent(),
            Value<int> communityVerificationCount = const Value.absent(),
            Value<String> openingHours = const Value.absent(),
            Value<bool> isOpenNow = const Value.absent(),
            Value<String?> currentWaitTime = const Value.absent(),
            Value<String> features = const Value.absent(),
            Value<double?> averageMealCost = const Value.absent(),
            Value<double?> valueScore = const Value.absent(),
            Value<String> mealTypeAverageCosts = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<DateTime?> lastVerified = const Value.absent(),
            Value<String?> photoReference = const Value.absent(),
            Value<String> photoReferences = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RestaurantsCompanion.insert(
            placeId: placeId,
            name: name,
            location: location,
            address: address,
            phoneNumber: phoneNumber,
            website: website,
            latitude: latitude,
            longitude: longitude,
            distanceFromUser: distanceFromUser,
            rating: rating,
            reviewCount: reviewCount,
            priceLevel: priceLevel,
            priceRanges: priceRanges,
            cuisineType: cuisineType,
            cuisineTypes: cuisineTypes,
            supportedDietaryRestrictions: supportedDietaryRestrictions,
            allergenInfo: allergenInfo,
            dietaryCompatibilityScores: dietaryCompatibilityScores,
            hasVerifiedDietaryInfo: hasVerifiedDietaryInfo,
            communityVerificationCount: communityVerificationCount,
            openingHours: openingHours,
            isOpenNow: isOpenNow,
            currentWaitTime: currentWaitTime,
            features: features,
            averageMealCost: averageMealCost,
            valueScore: valueScore,
            mealTypeAverageCosts: mealTypeAverageCosts,
            cachedAt: cachedAt,
            lastVerified: lastVerified,
            photoReference: photoReference,
            photoReferences: photoReferences,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RestaurantsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {dietaryCompatibilityRefs = false,
              userDiscoveryHistoryRefs = false,
              aIRecommendationFeedbackRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (dietaryCompatibilityRefs) db.dietaryCompatibility,
                if (userDiscoveryHistoryRefs) db.userDiscoveryHistory,
                if (aIRecommendationFeedbackRefs) db.aIRecommendationFeedback
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dietaryCompatibilityRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$RestaurantsTableReferences
                            ._dietaryCompatibilityRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RestaurantsTableReferences(db, table, p0)
                                .dietaryCompatibilityRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.placeId == item.placeId),
                        typedResults: items),
                  if (userDiscoveryHistoryRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$RestaurantsTableReferences
                            ._userDiscoveryHistoryRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RestaurantsTableReferences(db, table, p0)
                                .userDiscoveryHistoryRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.placeId == item.placeId),
                        typedResults: items),
                  if (aIRecommendationFeedbackRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$RestaurantsTableReferences
                            ._aIRecommendationFeedbackRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RestaurantsTableReferences(db, table, p0)
                                .aIRecommendationFeedbackRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.placeId == item.placeId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RestaurantsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RestaurantsTable,
    Restaurant,
    $$RestaurantsTableFilterComposer,
    $$RestaurantsTableOrderingComposer,
    $$RestaurantsTableAnnotationComposer,
    $$RestaurantsTableCreateCompanionBuilder,
    $$RestaurantsTableUpdateCompanionBuilder,
    (Restaurant, $$RestaurantsTableReferences),
    Restaurant,
    PrefetchHooks Function(
        {bool dietaryCompatibilityRefs,
        bool userDiscoveryHistoryRefs,
        bool aIRecommendationFeedbackRefs})>;
typedef $$RestaurantCacheTableCreateCompanionBuilder = RestaurantCacheCompanion
    Function({
  required String placeId,
  required String searchQuery,
  required double userLatitude,
  required double userLongitude,
  Value<DateTime> cachedAt,
  required DateTime expiresAt,
  Value<int> rowid,
});
typedef $$RestaurantCacheTableUpdateCompanionBuilder = RestaurantCacheCompanion
    Function({
  Value<String> placeId,
  Value<String> searchQuery,
  Value<double> userLatitude,
  Value<double> userLongitude,
  Value<DateTime> cachedAt,
  Value<DateTime> expiresAt,
  Value<int> rowid,
});

class $$RestaurantCacheTableFilterComposer
    extends Composer<_$AppDatabase, $RestaurantCacheTable> {
  $$RestaurantCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get placeId => $composableBuilder(
      column: $table.placeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get searchQuery => $composableBuilder(
      column: $table.searchQuery, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get userLatitude => $composableBuilder(
      column: $table.userLatitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get userLongitude => $composableBuilder(
      column: $table.userLongitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));
}

class $$RestaurantCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $RestaurantCacheTable> {
  $$RestaurantCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get placeId => $composableBuilder(
      column: $table.placeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get searchQuery => $composableBuilder(
      column: $table.searchQuery, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get userLatitude => $composableBuilder(
      column: $table.userLatitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get userLongitude => $composableBuilder(
      column: $table.userLongitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));
}

class $$RestaurantCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $RestaurantCacheTable> {
  $$RestaurantCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get placeId =>
      $composableBuilder(column: $table.placeId, builder: (column) => column);

  GeneratedColumn<String> get searchQuery => $composableBuilder(
      column: $table.searchQuery, builder: (column) => column);

  GeneratedColumn<double> get userLatitude => $composableBuilder(
      column: $table.userLatitude, builder: (column) => column);

  GeneratedColumn<double> get userLongitude => $composableBuilder(
      column: $table.userLongitude, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$RestaurantCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RestaurantCacheTable,
    RestaurantCacheData,
    $$RestaurantCacheTableFilterComposer,
    $$RestaurantCacheTableOrderingComposer,
    $$RestaurantCacheTableAnnotationComposer,
    $$RestaurantCacheTableCreateCompanionBuilder,
    $$RestaurantCacheTableUpdateCompanionBuilder,
    (
      RestaurantCacheData,
      BaseReferences<_$AppDatabase, $RestaurantCacheTable, RestaurantCacheData>
    ),
    RestaurantCacheData,
    PrefetchHooks Function()> {
  $$RestaurantCacheTableTableManager(
      _$AppDatabase db, $RestaurantCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RestaurantCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RestaurantCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RestaurantCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> placeId = const Value.absent(),
            Value<String> searchQuery = const Value.absent(),
            Value<double> userLatitude = const Value.absent(),
            Value<double> userLongitude = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<DateTime> expiresAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RestaurantCacheCompanion(
            placeId: placeId,
            searchQuery: searchQuery,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
            cachedAt: cachedAt,
            expiresAt: expiresAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String placeId,
            required String searchQuery,
            required double userLatitude,
            required double userLongitude,
            Value<DateTime> cachedAt = const Value.absent(),
            required DateTime expiresAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              RestaurantCacheCompanion.insert(
            placeId: placeId,
            searchQuery: searchQuery,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
            cachedAt: cachedAt,
            expiresAt: expiresAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RestaurantCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RestaurantCacheTable,
    RestaurantCacheData,
    $$RestaurantCacheTableFilterComposer,
    $$RestaurantCacheTableOrderingComposer,
    $$RestaurantCacheTableAnnotationComposer,
    $$RestaurantCacheTableCreateCompanionBuilder,
    $$RestaurantCacheTableUpdateCompanionBuilder,
    (
      RestaurantCacheData,
      BaseReferences<_$AppDatabase, $RestaurantCacheTable, RestaurantCacheData>
    ),
    RestaurantCacheData,
    PrefetchHooks Function()>;
typedef $$DietaryCompatibilityTableCreateCompanionBuilder
    = DietaryCompatibilityCompanion Function({
  Value<int> id,
  required String placeId,
  required String dietaryRestriction,
  required double compatibilityScore,
  Value<bool> isCommunityVerified,
  Value<int> verificationCount,
  Value<DateTime?> lastVerified,
});
typedef $$DietaryCompatibilityTableUpdateCompanionBuilder
    = DietaryCompatibilityCompanion Function({
  Value<int> id,
  Value<String> placeId,
  Value<String> dietaryRestriction,
  Value<double> compatibilityScore,
  Value<bool> isCommunityVerified,
  Value<int> verificationCount,
  Value<DateTime?> lastVerified,
});

final class $$DietaryCompatibilityTableReferences extends BaseReferences<
    _$AppDatabase, $DietaryCompatibilityTable, DietaryCompatibilityData> {
  $$DietaryCompatibilityTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $RestaurantsTable _placeIdTable(_$AppDatabase db) =>
      db.restaurants.createAlias($_aliasNameGenerator(
          db.dietaryCompatibility.placeId, db.restaurants.placeId));

  $$RestaurantsTableProcessedTableManager? get placeId {
    if ($_item.placeId == null) return null;
    final manager = $$RestaurantsTableTableManager($_db, $_db.restaurants)
        .filter((f) => f.placeId($_item.placeId!));
    final item = $_typedResult.readTableOrNull(_placeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DietaryCompatibilityTableFilterComposer
    extends Composer<_$AppDatabase, $DietaryCompatibilityTable> {
  $$DietaryCompatibilityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dietaryRestriction => $composableBuilder(
      column: $table.dietaryRestriction,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get compatibilityScore => $composableBuilder(
      column: $table.compatibilityScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCommunityVerified => $composableBuilder(
      column: $table.isCommunityVerified,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get verificationCount => $composableBuilder(
      column: $table.verificationCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastVerified => $composableBuilder(
      column: $table.lastVerified, builder: (column) => ColumnFilters(column));

  $$RestaurantsTableFilterComposer get placeId {
    final $$RestaurantsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.placeId,
        referencedTable: $db.restaurants,
        getReferencedColumn: (t) => t.placeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RestaurantsTableFilterComposer(
              $db: $db,
              $table: $db.restaurants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DietaryCompatibilityTableOrderingComposer
    extends Composer<_$AppDatabase, $DietaryCompatibilityTable> {
  $$DietaryCompatibilityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dietaryRestriction => $composableBuilder(
      column: $table.dietaryRestriction,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get compatibilityScore => $composableBuilder(
      column: $table.compatibilityScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCommunityVerified => $composableBuilder(
      column: $table.isCommunityVerified,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get verificationCount => $composableBuilder(
      column: $table.verificationCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastVerified => $composableBuilder(
      column: $table.lastVerified,
      builder: (column) => ColumnOrderings(column));

  $$RestaurantsTableOrderingComposer get placeId {
    final $$RestaurantsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.placeId,
        referencedTable: $db.restaurants,
        getReferencedColumn: (t) => t.placeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RestaurantsTableOrderingComposer(
              $db: $db,
              $table: $db.restaurants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DietaryCompatibilityTableAnnotationComposer
    extends Composer<_$AppDatabase, $DietaryCompatibilityTable> {
  $$DietaryCompatibilityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dietaryRestriction => $composableBuilder(
      column: $table.dietaryRestriction, builder: (column) => column);

  GeneratedColumn<double> get compatibilityScore => $composableBuilder(
      column: $table.compatibilityScore, builder: (column) => column);

  GeneratedColumn<bool> get isCommunityVerified => $composableBuilder(
      column: $table.isCommunityVerified, builder: (column) => column);

  GeneratedColumn<int> get verificationCount => $composableBuilder(
      column: $table.verificationCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastVerified => $composableBuilder(
      column: $table.lastVerified, builder: (column) => column);

  $$RestaurantsTableAnnotationComposer get placeId {
    final $$RestaurantsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.placeId,
        referencedTable: $db.restaurants,
        getReferencedColumn: (t) => t.placeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RestaurantsTableAnnotationComposer(
              $db: $db,
              $table: $db.restaurants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DietaryCompatibilityTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DietaryCompatibilityTable,
    DietaryCompatibilityData,
    $$DietaryCompatibilityTableFilterComposer,
    $$DietaryCompatibilityTableOrderingComposer,
    $$DietaryCompatibilityTableAnnotationComposer,
    $$DietaryCompatibilityTableCreateCompanionBuilder,
    $$DietaryCompatibilityTableUpdateCompanionBuilder,
    (DietaryCompatibilityData, $$DietaryCompatibilityTableReferences),
    DietaryCompatibilityData,
    PrefetchHooks Function({bool placeId})> {
  $$DietaryCompatibilityTableTableManager(
      _$AppDatabase db, $DietaryCompatibilityTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DietaryCompatibilityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DietaryCompatibilityTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DietaryCompatibilityTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> placeId = const Value.absent(),
            Value<String> dietaryRestriction = const Value.absent(),
            Value<double> compatibilityScore = const Value.absent(),
            Value<bool> isCommunityVerified = const Value.absent(),
            Value<int> verificationCount = const Value.absent(),
            Value<DateTime?> lastVerified = const Value.absent(),
          }) =>
              DietaryCompatibilityCompanion(
            id: id,
            placeId: placeId,
            dietaryRestriction: dietaryRestriction,
            compatibilityScore: compatibilityScore,
            isCommunityVerified: isCommunityVerified,
            verificationCount: verificationCount,
            lastVerified: lastVerified,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String placeId,
            required String dietaryRestriction,
            required double compatibilityScore,
            Value<bool> isCommunityVerified = const Value.absent(),
            Value<int> verificationCount = const Value.absent(),
            Value<DateTime?> lastVerified = const Value.absent(),
          }) =>
              DietaryCompatibilityCompanion.insert(
            id: id,
            placeId: placeId,
            dietaryRestriction: dietaryRestriction,
            compatibilityScore: compatibilityScore,
            isCommunityVerified: isCommunityVerified,
            verificationCount: verificationCount,
            lastVerified: lastVerified,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DietaryCompatibilityTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({placeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (placeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.placeId,
                    referencedTable:
                        $$DietaryCompatibilityTableReferences._placeIdTable(db),
                    referencedColumn: $$DietaryCompatibilityTableReferences
                        ._placeIdTable(db)
                        .placeId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DietaryCompatibilityTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DietaryCompatibilityTable,
        DietaryCompatibilityData,
        $$DietaryCompatibilityTableFilterComposer,
        $$DietaryCompatibilityTableOrderingComposer,
        $$DietaryCompatibilityTableAnnotationComposer,
        $$DietaryCompatibilityTableCreateCompanionBuilder,
        $$DietaryCompatibilityTableUpdateCompanionBuilder,
        (DietaryCompatibilityData, $$DietaryCompatibilityTableReferences),
        DietaryCompatibilityData,
        PrefetchHooks Function({bool placeId})>;
typedef $$UserDiscoveryHistoryTableCreateCompanionBuilder
    = UserDiscoveryHistoryCompanion Function({
  Value<int> id,
  required int userId,
  required String placeId,
  Value<String?> searchQuery,
  Value<String> appliedFilters,
  Value<bool> wasSelected,
  Value<DateTime> viewedAt,
});
typedef $$UserDiscoveryHistoryTableUpdateCompanionBuilder
    = UserDiscoveryHistoryCompanion Function({
  Value<int> id,
  Value<int> userId,
  Value<String> placeId,
  Value<String?> searchQuery,
  Value<String> appliedFilters,
  Value<bool> wasSelected,
  Value<DateTime> viewedAt,
});

final class $$UserDiscoveryHistoryTableReferences extends BaseReferences<
    _$AppDatabase, $UserDiscoveryHistoryTable, UserDiscoveryHistoryData> {
  $$UserDiscoveryHistoryTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
      $_aliasNameGenerator(db.userDiscoveryHistory.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $RestaurantsTable _placeIdTable(_$AppDatabase db) =>
      db.restaurants.createAlias($_aliasNameGenerator(
          db.userDiscoveryHistory.placeId, db.restaurants.placeId));

  $$RestaurantsTableProcessedTableManager? get placeId {
    if ($_item.placeId == null) return null;
    final manager = $$RestaurantsTableTableManager($_db, $_db.restaurants)
        .filter((f) => f.placeId($_item.placeId!));
    final item = $_typedResult.readTableOrNull(_placeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UserDiscoveryHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $UserDiscoveryHistoryTable> {
  $$UserDiscoveryHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get searchQuery => $composableBuilder(
      column: $table.searchQuery, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get appliedFilters => $composableBuilder(
      column: $table.appliedFilters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wasSelected => $composableBuilder(
      column: $table.wasSelected, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get viewedAt => $composableBuilder(
      column: $table.viewedAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RestaurantsTableFilterComposer get placeId {
    final $$RestaurantsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.placeId,
        referencedTable: $db.restaurants,
        getReferencedColumn: (t) => t.placeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RestaurantsTableFilterComposer(
              $db: $db,
              $table: $db.restaurants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserDiscoveryHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $UserDiscoveryHistoryTable> {
  $$UserDiscoveryHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get searchQuery => $composableBuilder(
      column: $table.searchQuery, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get appliedFilters => $composableBuilder(
      column: $table.appliedFilters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wasSelected => $composableBuilder(
      column: $table.wasSelected, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get viewedAt => $composableBuilder(
      column: $table.viewedAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RestaurantsTableOrderingComposer get placeId {
    final $$RestaurantsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.placeId,
        referencedTable: $db.restaurants,
        getReferencedColumn: (t) => t.placeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RestaurantsTableOrderingComposer(
              $db: $db,
              $table: $db.restaurants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserDiscoveryHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserDiscoveryHistoryTable> {
  $$UserDiscoveryHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get searchQuery => $composableBuilder(
      column: $table.searchQuery, builder: (column) => column);

  GeneratedColumn<String> get appliedFilters => $composableBuilder(
      column: $table.appliedFilters, builder: (column) => column);

  GeneratedColumn<bool> get wasSelected => $composableBuilder(
      column: $table.wasSelected, builder: (column) => column);

  GeneratedColumn<DateTime> get viewedAt =>
      $composableBuilder(column: $table.viewedAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RestaurantsTableAnnotationComposer get placeId {
    final $$RestaurantsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.placeId,
        referencedTable: $db.restaurants,
        getReferencedColumn: (t) => t.placeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RestaurantsTableAnnotationComposer(
              $db: $db,
              $table: $db.restaurants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserDiscoveryHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserDiscoveryHistoryTable,
    UserDiscoveryHistoryData,
    $$UserDiscoveryHistoryTableFilterComposer,
    $$UserDiscoveryHistoryTableOrderingComposer,
    $$UserDiscoveryHistoryTableAnnotationComposer,
    $$UserDiscoveryHistoryTableCreateCompanionBuilder,
    $$UserDiscoveryHistoryTableUpdateCompanionBuilder,
    (UserDiscoveryHistoryData, $$UserDiscoveryHistoryTableReferences),
    UserDiscoveryHistoryData,
    PrefetchHooks Function({bool userId, bool placeId})> {
  $$UserDiscoveryHistoryTableTableManager(
      _$AppDatabase db, $UserDiscoveryHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserDiscoveryHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserDiscoveryHistoryTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserDiscoveryHistoryTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> placeId = const Value.absent(),
            Value<String?> searchQuery = const Value.absent(),
            Value<String> appliedFilters = const Value.absent(),
            Value<bool> wasSelected = const Value.absent(),
            Value<DateTime> viewedAt = const Value.absent(),
          }) =>
              UserDiscoveryHistoryCompanion(
            id: id,
            userId: userId,
            placeId: placeId,
            searchQuery: searchQuery,
            appliedFilters: appliedFilters,
            wasSelected: wasSelected,
            viewedAt: viewedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int userId,
            required String placeId,
            Value<String?> searchQuery = const Value.absent(),
            Value<String> appliedFilters = const Value.absent(),
            Value<bool> wasSelected = const Value.absent(),
            Value<DateTime> viewedAt = const Value.absent(),
          }) =>
              UserDiscoveryHistoryCompanion.insert(
            id: id,
            userId: userId,
            placeId: placeId,
            searchQuery: searchQuery,
            appliedFilters: appliedFilters,
            wasSelected: wasSelected,
            viewedAt: viewedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UserDiscoveryHistoryTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false, placeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$UserDiscoveryHistoryTableReferences._userIdTable(db),
                    referencedColumn: $$UserDiscoveryHistoryTableReferences
                        ._userIdTable(db)
                        .id,
                  ) as T;
                }
                if (placeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.placeId,
                    referencedTable:
                        $$UserDiscoveryHistoryTableReferences._placeIdTable(db),
                    referencedColumn: $$UserDiscoveryHistoryTableReferences
                        ._placeIdTable(db)
                        .placeId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$UserDiscoveryHistoryTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $UserDiscoveryHistoryTable,
        UserDiscoveryHistoryData,
        $$UserDiscoveryHistoryTableFilterComposer,
        $$UserDiscoveryHistoryTableOrderingComposer,
        $$UserDiscoveryHistoryTableAnnotationComposer,
        $$UserDiscoveryHistoryTableCreateCompanionBuilder,
        $$UserDiscoveryHistoryTableUpdateCompanionBuilder,
        (UserDiscoveryHistoryData, $$UserDiscoveryHistoryTableReferences),
        UserDiscoveryHistoryData,
        PrefetchHooks Function({bool userId, bool placeId})>;
typedef $$AIRecommendationsTableCreateCompanionBuilder
    = AIRecommendationsCompanion Function({
  required String id,
  required int userId,
  required String recommendedRestaurantIds,
  required String reasoning,
  Value<String> factorWeights,
  required double overallConfidence,
  Value<String> userContext,
  Value<DateTime> generatedAt,
  Value<bool> wasAccepted,
  Value<String?> userFeedback,
  Value<String> metadata,
  required DateTime expiresAt,
  Value<int> rowid,
});
typedef $$AIRecommendationsTableUpdateCompanionBuilder
    = AIRecommendationsCompanion Function({
  Value<String> id,
  Value<int> userId,
  Value<String> recommendedRestaurantIds,
  Value<String> reasoning,
  Value<String> factorWeights,
  Value<double> overallConfidence,
  Value<String> userContext,
  Value<DateTime> generatedAt,
  Value<bool> wasAccepted,
  Value<String?> userFeedback,
  Value<String> metadata,
  Value<DateTime> expiresAt,
  Value<int> rowid,
});

final class $$AIRecommendationsTableReferences extends BaseReferences<
    _$AppDatabase, $AIRecommendationsTable, AIRecommendation> {
  $$AIRecommendationsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
      $_aliasNameGenerator(db.aIRecommendations.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$AIRecommendationFeedbackTable,
      List<AIRecommendationFeedbackData>> _aIRecommendationFeedbackRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.aIRecommendationFeedback,
          aliasName: $_aliasNameGenerator(db.aIRecommendations.id,
              db.aIRecommendationFeedback.recommendationId));

  $$AIRecommendationFeedbackTableProcessedTableManager
      get aIRecommendationFeedbackRefs {
    final manager = $$AIRecommendationFeedbackTableTableManager(
            $_db, $_db.aIRecommendationFeedback)
        .filter((f) => f.recommendationId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_aIRecommendationFeedbackRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AIRecommendationsTableFilterComposer
    extends Composer<_$AppDatabase, $AIRecommendationsTable> {
  $$AIRecommendationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recommendedRestaurantIds => $composableBuilder(
      column: $table.recommendedRestaurantIds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reasoning => $composableBuilder(
      column: $table.reasoning, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get factorWeights => $composableBuilder(
      column: $table.factorWeights, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get overallConfidence => $composableBuilder(
      column: $table.overallConfidence,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userContext => $composableBuilder(
      column: $table.userContext, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wasAccepted => $composableBuilder(
      column: $table.wasAccepted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userFeedback => $composableBuilder(
      column: $table.userFeedback, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> aIRecommendationFeedbackRefs(
      Expression<bool> Function($$AIRecommendationFeedbackTableFilterComposer f)
          f) {
    final $$AIRecommendationFeedbackTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.aIRecommendationFeedback,
            getReferencedColumn: (t) => t.recommendationId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AIRecommendationFeedbackTableFilterComposer(
                  $db: $db,
                  $table: $db.aIRecommendationFeedback,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$AIRecommendationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AIRecommendationsTable> {
  $$AIRecommendationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recommendedRestaurantIds => $composableBuilder(
      column: $table.recommendedRestaurantIds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reasoning => $composableBuilder(
      column: $table.reasoning, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get factorWeights => $composableBuilder(
      column: $table.factorWeights,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get overallConfidence => $composableBuilder(
      column: $table.overallConfidence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userContext => $composableBuilder(
      column: $table.userContext, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wasAccepted => $composableBuilder(
      column: $table.wasAccepted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userFeedback => $composableBuilder(
      column: $table.userFeedback,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AIRecommendationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AIRecommendationsTable> {
  $$AIRecommendationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recommendedRestaurantIds => $composableBuilder(
      column: $table.recommendedRestaurantIds, builder: (column) => column);

  GeneratedColumn<String> get reasoning =>
      $composableBuilder(column: $table.reasoning, builder: (column) => column);

  GeneratedColumn<String> get factorWeights => $composableBuilder(
      column: $table.factorWeights, builder: (column) => column);

  GeneratedColumn<double> get overallConfidence => $composableBuilder(
      column: $table.overallConfidence, builder: (column) => column);

  GeneratedColumn<String> get userContext => $composableBuilder(
      column: $table.userContext, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => column);

  GeneratedColumn<bool> get wasAccepted => $composableBuilder(
      column: $table.wasAccepted, builder: (column) => column);

  GeneratedColumn<String> get userFeedback => $composableBuilder(
      column: $table.userFeedback, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> aIRecommendationFeedbackRefs<T extends Object>(
      Expression<T> Function(
              $$AIRecommendationFeedbackTableAnnotationComposer a)
          f) {
    final $$AIRecommendationFeedbackTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.aIRecommendationFeedback,
            getReferencedColumn: (t) => t.recommendationId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AIRecommendationFeedbackTableAnnotationComposer(
                  $db: $db,
                  $table: $db.aIRecommendationFeedback,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$AIRecommendationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AIRecommendationsTable,
    AIRecommendation,
    $$AIRecommendationsTableFilterComposer,
    $$AIRecommendationsTableOrderingComposer,
    $$AIRecommendationsTableAnnotationComposer,
    $$AIRecommendationsTableCreateCompanionBuilder,
    $$AIRecommendationsTableUpdateCompanionBuilder,
    (AIRecommendation, $$AIRecommendationsTableReferences),
    AIRecommendation,
    PrefetchHooks Function({bool userId, bool aIRecommendationFeedbackRefs})> {
  $$AIRecommendationsTableTableManager(
      _$AppDatabase db, $AIRecommendationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AIRecommendationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AIRecommendationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AIRecommendationsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> recommendedRestaurantIds = const Value.absent(),
            Value<String> reasoning = const Value.absent(),
            Value<String> factorWeights = const Value.absent(),
            Value<double> overallConfidence = const Value.absent(),
            Value<String> userContext = const Value.absent(),
            Value<DateTime> generatedAt = const Value.absent(),
            Value<bool> wasAccepted = const Value.absent(),
            Value<String?> userFeedback = const Value.absent(),
            Value<String> metadata = const Value.absent(),
            Value<DateTime> expiresAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AIRecommendationsCompanion(
            id: id,
            userId: userId,
            recommendedRestaurantIds: recommendedRestaurantIds,
            reasoning: reasoning,
            factorWeights: factorWeights,
            overallConfidence: overallConfidence,
            userContext: userContext,
            generatedAt: generatedAt,
            wasAccepted: wasAccepted,
            userFeedback: userFeedback,
            metadata: metadata,
            expiresAt: expiresAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int userId,
            required String recommendedRestaurantIds,
            required String reasoning,
            Value<String> factorWeights = const Value.absent(),
            required double overallConfidence,
            Value<String> userContext = const Value.absent(),
            Value<DateTime> generatedAt = const Value.absent(),
            Value<bool> wasAccepted = const Value.absent(),
            Value<String?> userFeedback = const Value.absent(),
            Value<String> metadata = const Value.absent(),
            required DateTime expiresAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AIRecommendationsCompanion.insert(
            id: id,
            userId: userId,
            recommendedRestaurantIds: recommendedRestaurantIds,
            reasoning: reasoning,
            factorWeights: factorWeights,
            overallConfidence: overallConfidence,
            userContext: userContext,
            generatedAt: generatedAt,
            wasAccepted: wasAccepted,
            userFeedback: userFeedback,
            metadata: metadata,
            expiresAt: expiresAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AIRecommendationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {userId = false, aIRecommendationFeedbackRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (aIRecommendationFeedbackRefs) db.aIRecommendationFeedback
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$AIRecommendationsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$AIRecommendationsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (aIRecommendationFeedbackRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$AIRecommendationsTableReferences
                            ._aIRecommendationFeedbackRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AIRecommendationsTableReferences(db, table, p0)
                                .aIRecommendationFeedbackRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.recommendationId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AIRecommendationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AIRecommendationsTable,
    AIRecommendation,
    $$AIRecommendationsTableFilterComposer,
    $$AIRecommendationsTableOrderingComposer,
    $$AIRecommendationsTableAnnotationComposer,
    $$AIRecommendationsTableCreateCompanionBuilder,
    $$AIRecommendationsTableUpdateCompanionBuilder,
    (AIRecommendation, $$AIRecommendationsTableReferences),
    AIRecommendation,
    PrefetchHooks Function({bool userId, bool aIRecommendationFeedbackRefs})>;
typedef $$AIRecommendationFeedbackTableCreateCompanionBuilder
    = AIRecommendationFeedbackCompanion Function({
  Value<int> id,
  required String recommendationId,
  required int userId,
  required String placeId,
  required int rating,
  Value<String?> feedbackText,
  Value<bool> wasSelected,
  Value<DateTime> submittedAt,
});
typedef $$AIRecommendationFeedbackTableUpdateCompanionBuilder
    = AIRecommendationFeedbackCompanion Function({
  Value<int> id,
  Value<String> recommendationId,
  Value<int> userId,
  Value<String> placeId,
  Value<int> rating,
  Value<String?> feedbackText,
  Value<bool> wasSelected,
  Value<DateTime> submittedAt,
});

final class $$AIRecommendationFeedbackTableReferences extends BaseReferences<
    _$AppDatabase,
    $AIRecommendationFeedbackTable,
    AIRecommendationFeedbackData> {
  $$AIRecommendationFeedbackTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AIRecommendationsTable _recommendationIdTable(_$AppDatabase db) =>
      db.aIRecommendations.createAlias($_aliasNameGenerator(
          db.aIRecommendationFeedback.recommendationId,
          db.aIRecommendations.id));

  $$AIRecommendationsTableProcessedTableManager? get recommendationId {
    if ($_item.recommendationId == null) return null;
    final manager =
        $$AIRecommendationsTableTableManager($_db, $_db.aIRecommendations)
            .filter((f) => f.id($_item.recommendationId!));
    final item = $_typedResult.readTableOrNull(_recommendationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users.createAlias(
      $_aliasNameGenerator(db.aIRecommendationFeedback.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $RestaurantsTable _placeIdTable(_$AppDatabase db) =>
      db.restaurants.createAlias($_aliasNameGenerator(
          db.aIRecommendationFeedback.placeId, db.restaurants.placeId));

  $$RestaurantsTableProcessedTableManager? get placeId {
    if ($_item.placeId == null) return null;
    final manager = $$RestaurantsTableTableManager($_db, $_db.restaurants)
        .filter((f) => f.placeId($_item.placeId!));
    final item = $_typedResult.readTableOrNull(_placeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AIRecommendationFeedbackTableFilterComposer
    extends Composer<_$AppDatabase, $AIRecommendationFeedbackTable> {
  $$AIRecommendationFeedbackTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get feedbackText => $composableBuilder(
      column: $table.feedbackText, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wasSelected => $composableBuilder(
      column: $table.wasSelected, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get submittedAt => $composableBuilder(
      column: $table.submittedAt, builder: (column) => ColumnFilters(column));

  $$AIRecommendationsTableFilterComposer get recommendationId {
    final $$AIRecommendationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recommendationId,
        referencedTable: $db.aIRecommendations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AIRecommendationsTableFilterComposer(
              $db: $db,
              $table: $db.aIRecommendations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RestaurantsTableFilterComposer get placeId {
    final $$RestaurantsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.placeId,
        referencedTable: $db.restaurants,
        getReferencedColumn: (t) => t.placeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RestaurantsTableFilterComposer(
              $db: $db,
              $table: $db.restaurants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AIRecommendationFeedbackTableOrderingComposer
    extends Composer<_$AppDatabase, $AIRecommendationFeedbackTable> {
  $$AIRecommendationFeedbackTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get feedbackText => $composableBuilder(
      column: $table.feedbackText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wasSelected => $composableBuilder(
      column: $table.wasSelected, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get submittedAt => $composableBuilder(
      column: $table.submittedAt, builder: (column) => ColumnOrderings(column));

  $$AIRecommendationsTableOrderingComposer get recommendationId {
    final $$AIRecommendationsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recommendationId,
        referencedTable: $db.aIRecommendations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AIRecommendationsTableOrderingComposer(
              $db: $db,
              $table: $db.aIRecommendations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RestaurantsTableOrderingComposer get placeId {
    final $$RestaurantsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.placeId,
        referencedTable: $db.restaurants,
        getReferencedColumn: (t) => t.placeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RestaurantsTableOrderingComposer(
              $db: $db,
              $table: $db.restaurants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AIRecommendationFeedbackTableAnnotationComposer
    extends Composer<_$AppDatabase, $AIRecommendationFeedbackTable> {
  $$AIRecommendationFeedbackTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get feedbackText => $composableBuilder(
      column: $table.feedbackText, builder: (column) => column);

  GeneratedColumn<bool> get wasSelected => $composableBuilder(
      column: $table.wasSelected, builder: (column) => column);

  GeneratedColumn<DateTime> get submittedAt => $composableBuilder(
      column: $table.submittedAt, builder: (column) => column);

  $$AIRecommendationsTableAnnotationComposer get recommendationId {
    final $$AIRecommendationsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.recommendationId,
            referencedTable: $db.aIRecommendations,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AIRecommendationsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.aIRecommendations,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RestaurantsTableAnnotationComposer get placeId {
    final $$RestaurantsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.placeId,
        referencedTable: $db.restaurants,
        getReferencedColumn: (t) => t.placeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RestaurantsTableAnnotationComposer(
              $db: $db,
              $table: $db.restaurants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AIRecommendationFeedbackTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AIRecommendationFeedbackTable,
    AIRecommendationFeedbackData,
    $$AIRecommendationFeedbackTableFilterComposer,
    $$AIRecommendationFeedbackTableOrderingComposer,
    $$AIRecommendationFeedbackTableAnnotationComposer,
    $$AIRecommendationFeedbackTableCreateCompanionBuilder,
    $$AIRecommendationFeedbackTableUpdateCompanionBuilder,
    (AIRecommendationFeedbackData, $$AIRecommendationFeedbackTableReferences),
    AIRecommendationFeedbackData,
    PrefetchHooks Function(
        {bool recommendationId, bool userId, bool placeId})> {
  $$AIRecommendationFeedbackTableTableManager(
      _$AppDatabase db, $AIRecommendationFeedbackTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AIRecommendationFeedbackTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$AIRecommendationFeedbackTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AIRecommendationFeedbackTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> recommendationId = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> placeId = const Value.absent(),
            Value<int> rating = const Value.absent(),
            Value<String?> feedbackText = const Value.absent(),
            Value<bool> wasSelected = const Value.absent(),
            Value<DateTime> submittedAt = const Value.absent(),
          }) =>
              AIRecommendationFeedbackCompanion(
            id: id,
            recommendationId: recommendationId,
            userId: userId,
            placeId: placeId,
            rating: rating,
            feedbackText: feedbackText,
            wasSelected: wasSelected,
            submittedAt: submittedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String recommendationId,
            required int userId,
            required String placeId,
            required int rating,
            Value<String?> feedbackText = const Value.absent(),
            Value<bool> wasSelected = const Value.absent(),
            Value<DateTime> submittedAt = const Value.absent(),
          }) =>
              AIRecommendationFeedbackCompanion.insert(
            id: id,
            recommendationId: recommendationId,
            userId: userId,
            placeId: placeId,
            rating: rating,
            feedbackText: feedbackText,
            wasSelected: wasSelected,
            submittedAt: submittedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AIRecommendationFeedbackTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {recommendationId = false, userId = false, placeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (recommendationId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recommendationId,
                    referencedTable: $$AIRecommendationFeedbackTableReferences
                        ._recommendationIdTable(db),
                    referencedColumn: $$AIRecommendationFeedbackTableReferences
                        ._recommendationIdTable(db)
                        .id,
                  ) as T;
                }
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable: $$AIRecommendationFeedbackTableReferences
                        ._userIdTable(db),
                    referencedColumn: $$AIRecommendationFeedbackTableReferences
                        ._userIdTable(db)
                        .id,
                  ) as T;
                }
                if (placeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.placeId,
                    referencedTable: $$AIRecommendationFeedbackTableReferences
                        ._placeIdTable(db),
                    referencedColumn: $$AIRecommendationFeedbackTableReferences
                        ._placeIdTable(db)
                        .placeId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AIRecommendationFeedbackTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $AIRecommendationFeedbackTable,
        AIRecommendationFeedbackData,
        $$AIRecommendationFeedbackTableFilterComposer,
        $$AIRecommendationFeedbackTableOrderingComposer,
        $$AIRecommendationFeedbackTableAnnotationComposer,
        $$AIRecommendationFeedbackTableCreateCompanionBuilder,
        $$AIRecommendationFeedbackTableUpdateCompanionBuilder,
        (
          AIRecommendationFeedbackData,
          $$AIRecommendationFeedbackTableReferences
        ),
        AIRecommendationFeedbackData,
        PrefetchHooks Function(
            {bool recommendationId, bool userId, bool placeId})>;
typedef $$AIUsageMetricsTableCreateCompanionBuilder = AIUsageMetricsCompanion
    Function({
  Value<int> id,
  required int userId,
  required String requestType,
  Value<int> tokensUsed,
  Value<double> costInCents,
  Value<int?> responseTimeMs,
  Value<bool> wasSuccessful,
  Value<String?> errorMessage,
  Value<DateTime> timestamp,
});
typedef $$AIUsageMetricsTableUpdateCompanionBuilder = AIUsageMetricsCompanion
    Function({
  Value<int> id,
  Value<int> userId,
  Value<String> requestType,
  Value<int> tokensUsed,
  Value<double> costInCents,
  Value<int?> responseTimeMs,
  Value<bool> wasSuccessful,
  Value<String?> errorMessage,
  Value<DateTime> timestamp,
});

final class $$AIUsageMetricsTableReferences
    extends BaseReferences<_$AppDatabase, $AIUsageMetricsTable, AIUsageMetric> {
  $$AIUsageMetricsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) => db.users
      .createAlias($_aliasNameGenerator(db.aIUsageMetrics.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AIUsageMetricsTableFilterComposer
    extends Composer<_$AppDatabase, $AIUsageMetricsTable> {
  $$AIUsageMetricsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requestType => $composableBuilder(
      column: $table.requestType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tokensUsed => $composableBuilder(
      column: $table.tokensUsed, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get costInCents => $composableBuilder(
      column: $table.costInCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get responseTimeMs => $composableBuilder(
      column: $table.responseTimeMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wasSuccessful => $composableBuilder(
      column: $table.wasSuccessful, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AIUsageMetricsTableOrderingComposer
    extends Composer<_$AppDatabase, $AIUsageMetricsTable> {
  $$AIUsageMetricsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requestType => $composableBuilder(
      column: $table.requestType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tokensUsed => $composableBuilder(
      column: $table.tokensUsed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get costInCents => $composableBuilder(
      column: $table.costInCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get responseTimeMs => $composableBuilder(
      column: $table.responseTimeMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wasSuccessful => $composableBuilder(
      column: $table.wasSuccessful,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AIUsageMetricsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AIUsageMetricsTable> {
  $$AIUsageMetricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get requestType => $composableBuilder(
      column: $table.requestType, builder: (column) => column);

  GeneratedColumn<int> get tokensUsed => $composableBuilder(
      column: $table.tokensUsed, builder: (column) => column);

  GeneratedColumn<double> get costInCents => $composableBuilder(
      column: $table.costInCents, builder: (column) => column);

  GeneratedColumn<int> get responseTimeMs => $composableBuilder(
      column: $table.responseTimeMs, builder: (column) => column);

  GeneratedColumn<bool> get wasSuccessful => $composableBuilder(
      column: $table.wasSuccessful, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AIUsageMetricsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AIUsageMetricsTable,
    AIUsageMetric,
    $$AIUsageMetricsTableFilterComposer,
    $$AIUsageMetricsTableOrderingComposer,
    $$AIUsageMetricsTableAnnotationComposer,
    $$AIUsageMetricsTableCreateCompanionBuilder,
    $$AIUsageMetricsTableUpdateCompanionBuilder,
    (AIUsageMetric, $$AIUsageMetricsTableReferences),
    AIUsageMetric,
    PrefetchHooks Function({bool userId})> {
  $$AIUsageMetricsTableTableManager(
      _$AppDatabase db, $AIUsageMetricsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AIUsageMetricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AIUsageMetricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AIUsageMetricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> requestType = const Value.absent(),
            Value<int> tokensUsed = const Value.absent(),
            Value<double> costInCents = const Value.absent(),
            Value<int?> responseTimeMs = const Value.absent(),
            Value<bool> wasSuccessful = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
          }) =>
              AIUsageMetricsCompanion(
            id: id,
            userId: userId,
            requestType: requestType,
            tokensUsed: tokensUsed,
            costInCents: costInCents,
            responseTimeMs: responseTimeMs,
            wasSuccessful: wasSuccessful,
            errorMessage: errorMessage,
            timestamp: timestamp,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int userId,
            required String requestType,
            Value<int> tokensUsed = const Value.absent(),
            Value<double> costInCents = const Value.absent(),
            Value<int?> responseTimeMs = const Value.absent(),
            Value<bool> wasSuccessful = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
          }) =>
              AIUsageMetricsCompanion.insert(
            id: id,
            userId: userId,
            requestType: requestType,
            tokensUsed: tokensUsed,
            costInCents: costInCents,
            responseTimeMs: responseTimeMs,
            wasSuccessful: wasSuccessful,
            errorMessage: errorMessage,
            timestamp: timestamp,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AIUsageMetricsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable:
                        $$AIUsageMetricsTableReferences._userIdTable(db),
                    referencedColumn:
                        $$AIUsageMetricsTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AIUsageMetricsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AIUsageMetricsTable,
    AIUsageMetric,
    $$AIUsageMetricsTableFilterComposer,
    $$AIUsageMetricsTableOrderingComposer,
    $$AIUsageMetricsTableAnnotationComposer,
    $$AIUsageMetricsTableCreateCompanionBuilder,
    $$AIUsageMetricsTableUpdateCompanionBuilder,
    (AIUsageMetric, $$AIUsageMetricsTableReferences),
    AIUsageMetric,
    PrefetchHooks Function({bool userId})>;
typedef $$PhotosTableCreateCompanionBuilder = PhotosCompanion Function({
  required String id,
  required int userId,
  required String fileName,
  required String localPath,
  Value<String?> cloudUrl,
  required int fileSizeBytes,
  Value<int?> width,
  Value<int?> height,
  Value<String> contentType,
  required String photoType,
  Value<String?> associatedEntityId,
  Value<String> metadata,
  Value<DateTime> createdAt,
  Value<DateTime?> uploadedAt,
  Value<bool> isUploaded,
  Value<bool> isDeleted,
  Value<int> rowid,
});
typedef $$PhotosTableUpdateCompanionBuilder = PhotosCompanion Function({
  Value<String> id,
  Value<int> userId,
  Value<String> fileName,
  Value<String> localPath,
  Value<String?> cloudUrl,
  Value<int> fileSizeBytes,
  Value<int?> width,
  Value<int?> height,
  Value<String> contentType,
  Value<String> photoType,
  Value<String?> associatedEntityId,
  Value<String> metadata,
  Value<DateTime> createdAt,
  Value<DateTime?> uploadedAt,
  Value<bool> isUploaded,
  Value<bool> isDeleted,
  Value<int> rowid,
});

final class $$PhotosTableReferences
    extends BaseReferences<_$AppDatabase, $PhotosTable, Photo> {
  $$PhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) =>
      db.users.createAlias($_aliasNameGenerator(db.photos.userId, db.users.id));

  $$UsersTableProcessedTableManager? get userId {
    if ($_item.userId == null) return null;
    final manager = $$UsersTableTableManager($_db, $_db.users)
        .filter((f) => f.id($_item.userId!));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PhotosTableFilterComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cloudUrl => $composableBuilder(
      column: $table.cloudUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoType => $composableBuilder(
      column: $table.photoType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get associatedEntityId => $composableBuilder(
      column: $table.associatedEntityId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isUploaded => $composableBuilder(
      column: $table.isUploaded, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableFilterComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cloudUrl => $composableBuilder(
      column: $table.cloudUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoType => $composableBuilder(
      column: $table.photoType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get associatedEntityId => $composableBuilder(
      column: $table.associatedEntityId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isUploaded => $composableBuilder(
      column: $table.isUploaded, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableOrderingComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get cloudUrl =>
      $composableBuilder(column: $table.cloudUrl, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
      column: $table.contentType, builder: (column) => column);

  GeneratedColumn<String> get photoType =>
      $composableBuilder(column: $table.photoType, builder: (column) => column);

  GeneratedColumn<String> get associatedEntityId => $composableBuilder(
      column: $table.associatedEntityId, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get uploadedAt => $composableBuilder(
      column: $table.uploadedAt, builder: (column) => column);

  GeneratedColumn<bool> get isUploaded => $composableBuilder(
      column: $table.isUploaded, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userId,
        referencedTable: $db.users,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersTableAnnotationComposer(
              $db: $db,
              $table: $db.users,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PhotosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PhotosTable,
    Photo,
    $$PhotosTableFilterComposer,
    $$PhotosTableOrderingComposer,
    $$PhotosTableAnnotationComposer,
    $$PhotosTableCreateCompanionBuilder,
    $$PhotosTableUpdateCompanionBuilder,
    (Photo, $$PhotosTableReferences),
    Photo,
    PrefetchHooks Function({bool userId})> {
  $$PhotosTableTableManager(_$AppDatabase db, $PhotosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<String?> cloudUrl = const Value.absent(),
            Value<int> fileSizeBytes = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<String> contentType = const Value.absent(),
            Value<String> photoType = const Value.absent(),
            Value<String?> associatedEntityId = const Value.absent(),
            Value<String> metadata = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> uploadedAt = const Value.absent(),
            Value<bool> isUploaded = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PhotosCompanion(
            id: id,
            userId: userId,
            fileName: fileName,
            localPath: localPath,
            cloudUrl: cloudUrl,
            fileSizeBytes: fileSizeBytes,
            width: width,
            height: height,
            contentType: contentType,
            photoType: photoType,
            associatedEntityId: associatedEntityId,
            metadata: metadata,
            createdAt: createdAt,
            uploadedAt: uploadedAt,
            isUploaded: isUploaded,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int userId,
            required String fileName,
            required String localPath,
            Value<String?> cloudUrl = const Value.absent(),
            required int fileSizeBytes,
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<String> contentType = const Value.absent(),
            required String photoType,
            Value<String?> associatedEntityId = const Value.absent(),
            Value<String> metadata = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> uploadedAt = const Value.absent(),
            Value<bool> isUploaded = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PhotosCompanion.insert(
            id: id,
            userId: userId,
            fileName: fileName,
            localPath: localPath,
            cloudUrl: cloudUrl,
            fileSizeBytes: fileSizeBytes,
            width: width,
            height: height,
            contentType: contentType,
            photoType: photoType,
            associatedEntityId: associatedEntityId,
            metadata: metadata,
            createdAt: createdAt,
            uploadedAt: uploadedAt,
            isUploaded: isUploaded,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PhotosTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (userId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userId,
                    referencedTable: $$PhotosTableReferences._userIdTable(db),
                    referencedColumn:
                        $$PhotosTableReferences._userIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PhotosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PhotosTable,
    Photo,
    $$PhotosTableFilterComposer,
    $$PhotosTableOrderingComposer,
    $$PhotosTableAnnotationComposer,
    $$PhotosTableCreateCompanionBuilder,
    $$PhotosTableUpdateCompanionBuilder,
    (Photo, $$PhotosTableReferences),
    Photo,
    PrefetchHooks Function({bool userId})>;
typedef $$UserRestaurantInteractionsTableCreateCompanionBuilder
    = UserRestaurantInteractionsCompanion Function({
  Value<int> id,
  required int userId,
  required String restaurantPlaceId,
  Value<String?> restaurantName,
  required String interactionType,
  required DateTime interactionDate,
  Value<String?> context,
});
typedef $$UserRestaurantInteractionsTableUpdateCompanionBuilder
    = UserRestaurantInteractionsCompanion Function({
  Value<int> id,
  Value<int> userId,
  Value<String> restaurantPlaceId,
  Value<String?> restaurantName,
  Value<String> interactionType,
  Value<DateTime> interactionDate,
  Value<String?> context,
});

class $$UserRestaurantInteractionsTableFilterComposer
    extends Composer<_$AppDatabase, $UserRestaurantInteractionsTable> {
  $$UserRestaurantInteractionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get restaurantPlaceId => $composableBuilder(
      column: $table.restaurantPlaceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get restaurantName => $composableBuilder(
      column: $table.restaurantName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get interactionType => $composableBuilder(
      column: $table.interactionType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get interactionDate => $composableBuilder(
      column: $table.interactionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get context => $composableBuilder(
      column: $table.context, builder: (column) => ColumnFilters(column));
}

class $$UserRestaurantInteractionsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserRestaurantInteractionsTable> {
  $$UserRestaurantInteractionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get restaurantPlaceId => $composableBuilder(
      column: $table.restaurantPlaceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get restaurantName => $composableBuilder(
      column: $table.restaurantName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get interactionType => $composableBuilder(
      column: $table.interactionType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get interactionDate => $composableBuilder(
      column: $table.interactionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get context => $composableBuilder(
      column: $table.context, builder: (column) => ColumnOrderings(column));
}

class $$UserRestaurantInteractionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserRestaurantInteractionsTable> {
  $$UserRestaurantInteractionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get restaurantPlaceId => $composableBuilder(
      column: $table.restaurantPlaceId, builder: (column) => column);

  GeneratedColumn<String> get restaurantName => $composableBuilder(
      column: $table.restaurantName, builder: (column) => column);

  GeneratedColumn<String> get interactionType => $composableBuilder(
      column: $table.interactionType, builder: (column) => column);

  GeneratedColumn<DateTime> get interactionDate => $composableBuilder(
      column: $table.interactionDate, builder: (column) => column);

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);
}

class $$UserRestaurantInteractionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserRestaurantInteractionsTable,
    UserRestaurantInteraction,
    $$UserRestaurantInteractionsTableFilterComposer,
    $$UserRestaurantInteractionsTableOrderingComposer,
    $$UserRestaurantInteractionsTableAnnotationComposer,
    $$UserRestaurantInteractionsTableCreateCompanionBuilder,
    $$UserRestaurantInteractionsTableUpdateCompanionBuilder,
    (
      UserRestaurantInteraction,
      BaseReferences<_$AppDatabase, $UserRestaurantInteractionsTable,
          UserRestaurantInteraction>
    ),
    UserRestaurantInteraction,
    PrefetchHooks Function()> {
  $$UserRestaurantInteractionsTableTableManager(
      _$AppDatabase db, $UserRestaurantInteractionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserRestaurantInteractionsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$UserRestaurantInteractionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserRestaurantInteractionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> restaurantPlaceId = const Value.absent(),
            Value<String?> restaurantName = const Value.absent(),
            Value<String> interactionType = const Value.absent(),
            Value<DateTime> interactionDate = const Value.absent(),
            Value<String?> context = const Value.absent(),
          }) =>
              UserRestaurantInteractionsCompanion(
            id: id,
            userId: userId,
            restaurantPlaceId: restaurantPlaceId,
            restaurantName: restaurantName,
            interactionType: interactionType,
            interactionDate: interactionDate,
            context: context,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int userId,
            required String restaurantPlaceId,
            Value<String?> restaurantName = const Value.absent(),
            required String interactionType,
            required DateTime interactionDate,
            Value<String?> context = const Value.absent(),
          }) =>
              UserRestaurantInteractionsCompanion.insert(
            id: id,
            userId: userId,
            restaurantPlaceId: restaurantPlaceId,
            restaurantName: restaurantName,
            interactionType: interactionType,
            interactionDate: interactionDate,
            context: context,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserRestaurantInteractionsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $UserRestaurantInteractionsTable,
        UserRestaurantInteraction,
        $$UserRestaurantInteractionsTableFilterComposer,
        $$UserRestaurantInteractionsTableOrderingComposer,
        $$UserRestaurantInteractionsTableAnnotationComposer,
        $$UserRestaurantInteractionsTableCreateCompanionBuilder,
        $$UserRestaurantInteractionsTableUpdateCompanionBuilder,
        (
          UserRestaurantInteraction,
          BaseReferences<_$AppDatabase, $UserRestaurantInteractionsTable,
              UserRestaurantInteraction>
        ),
        UserRestaurantInteraction,
        PrefetchHooks Function()>;
typedef $$MealOutcomesTableCreateCompanionBuilder = MealOutcomesCompanion
    Function({
  Value<int> id,
  required int mealId,
  required int userId,
  Value<String?> restaurantPlaceId,
  Value<int?> rating,
  Value<bool> wouldRevisit,
  Value<String?> feedback,
  required DateTime recordedAt,
});
typedef $$MealOutcomesTableUpdateCompanionBuilder = MealOutcomesCompanion
    Function({
  Value<int> id,
  Value<int> mealId,
  Value<int> userId,
  Value<String?> restaurantPlaceId,
  Value<int?> rating,
  Value<bool> wouldRevisit,
  Value<String?> feedback,
  Value<DateTime> recordedAt,
});

class $$MealOutcomesTableFilterComposer
    extends Composer<_$AppDatabase, $MealOutcomesTable> {
  $$MealOutcomesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mealId => $composableBuilder(
      column: $table.mealId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get restaurantPlaceId => $composableBuilder(
      column: $table.restaurantPlaceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wouldRevisit => $composableBuilder(
      column: $table.wouldRevisit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get feedback => $composableBuilder(
      column: $table.feedback, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));
}

class $$MealOutcomesTableOrderingComposer
    extends Composer<_$AppDatabase, $MealOutcomesTable> {
  $$MealOutcomesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mealId => $composableBuilder(
      column: $table.mealId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get restaurantPlaceId => $composableBuilder(
      column: $table.restaurantPlaceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wouldRevisit => $composableBuilder(
      column: $table.wouldRevisit,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get feedback => $composableBuilder(
      column: $table.feedback, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));
}

class $$MealOutcomesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealOutcomesTable> {
  $$MealOutcomesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get restaurantPlaceId => $composableBuilder(
      column: $table.restaurantPlaceId, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<bool> get wouldRevisit => $composableBuilder(
      column: $table.wouldRevisit, builder: (column) => column);

  GeneratedColumn<String> get feedback =>
      $composableBuilder(column: $table.feedback, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);
}

class $$MealOutcomesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealOutcomesTable,
    MealOutcome,
    $$MealOutcomesTableFilterComposer,
    $$MealOutcomesTableOrderingComposer,
    $$MealOutcomesTableAnnotationComposer,
    $$MealOutcomesTableCreateCompanionBuilder,
    $$MealOutcomesTableUpdateCompanionBuilder,
    (
      MealOutcome,
      BaseReferences<_$AppDatabase, $MealOutcomesTable, MealOutcome>
    ),
    MealOutcome,
    PrefetchHooks Function()> {
  $$MealOutcomesTableTableManager(_$AppDatabase db, $MealOutcomesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealOutcomesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealOutcomesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealOutcomesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> mealId = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String?> restaurantPlaceId = const Value.absent(),
            Value<int?> rating = const Value.absent(),
            Value<bool> wouldRevisit = const Value.absent(),
            Value<String?> feedback = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
          }) =>
              MealOutcomesCompanion(
            id: id,
            mealId: mealId,
            userId: userId,
            restaurantPlaceId: restaurantPlaceId,
            rating: rating,
            wouldRevisit: wouldRevisit,
            feedback: feedback,
            recordedAt: recordedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int mealId,
            required int userId,
            Value<String?> restaurantPlaceId = const Value.absent(),
            Value<int?> rating = const Value.absent(),
            Value<bool> wouldRevisit = const Value.absent(),
            Value<String?> feedback = const Value.absent(),
            required DateTime recordedAt,
          }) =>
              MealOutcomesCompanion.insert(
            id: id,
            mealId: mealId,
            userId: userId,
            restaurantPlaceId: restaurantPlaceId,
            rating: rating,
            wouldRevisit: wouldRevisit,
            feedback: feedback,
            recordedAt: recordedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MealOutcomesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealOutcomesTable,
    MealOutcome,
    $$MealOutcomesTableFilterComposer,
    $$MealOutcomesTableOrderingComposer,
    $$MealOutcomesTableAnnotationComposer,
    $$MealOutcomesTableCreateCompanionBuilder,
    $$MealOutcomesTableUpdateCompanionBuilder,
    (
      MealOutcome,
      BaseReferences<_$AppDatabase, $MealOutcomesTable, MealOutcome>
    ),
    MealOutcome,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$MealsTableTableManager get meals =>
      $$MealsTableTableManager(_db, _db.meals);
  $$BudgetTrackingsTableTableManager get budgetTrackings =>
      $$BudgetTrackingsTableTableManager(_db, _db.budgetTrackings);
  $$RestaurantsTableTableManager get restaurants =>
      $$RestaurantsTableTableManager(_db, _db.restaurants);
  $$RestaurantCacheTableTableManager get restaurantCache =>
      $$RestaurantCacheTableTableManager(_db, _db.restaurantCache);
  $$DietaryCompatibilityTableTableManager get dietaryCompatibility =>
      $$DietaryCompatibilityTableTableManager(_db, _db.dietaryCompatibility);
  $$UserDiscoveryHistoryTableTableManager get userDiscoveryHistory =>
      $$UserDiscoveryHistoryTableTableManager(_db, _db.userDiscoveryHistory);
  $$AIRecommendationsTableTableManager get aIRecommendations =>
      $$AIRecommendationsTableTableManager(_db, _db.aIRecommendations);
  $$AIRecommendationFeedbackTableTableManager get aIRecommendationFeedback =>
      $$AIRecommendationFeedbackTableTableManager(
          _db, _db.aIRecommendationFeedback);
  $$AIUsageMetricsTableTableManager get aIUsageMetrics =>
      $$AIUsageMetricsTableTableManager(_db, _db.aIUsageMetrics);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db, _db.photos);
  $$UserRestaurantInteractionsTableTableManager
      get userRestaurantInteractions =>
          $$UserRestaurantInteractionsTableTableManager(
              _db, _db.userRestaurantInteractions);
  $$MealOutcomesTableTableManager get mealOutcomes =>
      $$MealOutcomesTableTableManager(_db, _db.mealOutcomes);
}
