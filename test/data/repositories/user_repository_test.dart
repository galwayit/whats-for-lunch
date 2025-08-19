import 'package:flutter_test/flutter_test.dart';
import 'package:what_we_have_for_lunch/data/database/database.dart';
import 'package:what_we_have_for_lunch/data/repositories/user_repository_impl.dart';
import 'package:what_we_have_for_lunch/domain/entities/user.dart' as entity;
import 'package:what_we_have_for_lunch/domain/entities/user_preferences.dart';
import 'package:what_we_have_for_lunch/domain/repositories/user_repository.dart';

void main() {
  late AppDatabase database;
  late UserRepository userRepository;

  setUp(() {
    database = AppDatabase.testInstance();
    userRepository = UserRepositoryImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('UserRepository', () {
    test('should create user successfully', () async {
      // Arrange
      final preferences = const UserPreferences(
        budgetLevel: 2,
        maxTravelDistance: 8.0,
        includeChains: true,
      );

      final user = entity.UserEntity(
        name: 'Alice Smith',
        preferences: preferences.toJson(),
        createdAt: DateTime.now(),
      );

      // Act
      final userId = await userRepository.createUser(user);

      // Assert
      expect(userId, isA<int>());
      expect(userId, greaterThan(0));
    });

    test('should retrieve user by id', () async {
      // Arrange
      final preferences = const UserPreferences(
        budgetLevel: 3,
        maxTravelDistance: 12.0,
        includeChains: false,
      );

      final user = entity.UserEntity(
        name: 'Bob Johnson',
        preferences: preferences.toJson(),
        createdAt: DateTime.now(),
      );

      final userId = await userRepository.createUser(user);

      // Act
      final retrievedUser = await userRepository.getUserById(userId);

      // Assert
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.id, equals(userId));
      expect(retrievedUser.name, equals('Bob Johnson'));
      
      final retrievedPreferences = UserPreferences.fromJson(retrievedUser.preferences);
      expect(retrievedPreferences.budgetLevel, equals(3));
      expect(retrievedPreferences.maxTravelDistance, equals(12.0));
      expect(retrievedPreferences.includeChains, isFalse);
    });

    test('should return null for non-existent user', () async {
      // Act
      final retrievedUser = await userRepository.getUserById(999);

      // Assert
      expect(retrievedUser, isNull);
    });

    test('should get all users', () async {
      // Arrange
      final user1 = entity.UserEntity(
        name: 'User 1',
        preferences: const UserPreferences().toJson(),
        createdAt: DateTime.now(),
      );

      final user2 = entity.UserEntity(
        name: 'User 2',
        preferences: const UserPreferences().toJson(),
        createdAt: DateTime.now(),
      );

      await userRepository.createUser(user1);
      await userRepository.createUser(user2);

      // Act
      final allUsers = await userRepository.getAllUsers();

      // Assert
      expect(allUsers, hasLength(2));
      expect(allUsers.map((u) => u.name), containsAll(['User 1', 'User 2']));
    });

    test('should update user successfully', () async {
      // Arrange
      final initialPreferences = const UserPreferences(budgetLevel: 1);
      final user = entity.UserEntity(
        name: 'Charlie Brown',
        preferences: initialPreferences.toJson(),
        createdAt: DateTime.now(),
      );

      final userId = await userRepository.createUser(user);
      final createdUser = await userRepository.getUserById(userId);

      // Act
      final updatedPreferences = const UserPreferences(budgetLevel: 4);
      final updatedUser = createdUser!.copyWith(
        preferences: updatedPreferences.toJson(),
      );

      final success = await userRepository.updateUser(updatedUser);

      // Assert
      expect(success, isTrue);

      final retrievedUser = await userRepository.getUserById(userId);
      final retrievedPreferences = UserPreferences.fromJson(retrievedUser!.preferences);
      expect(retrievedPreferences.budgetLevel, equals(4));
    });

    test('should fail to update user without id', () async {
      // Arrange
      final user = entity.UserEntity(
        name: 'Invalid User',
        preferences: const UserPreferences().toJson(),
        createdAt: DateTime.now(),
      );

      // Act
      final success = await userRepository.updateUser(user);

      // Assert
      expect(success, isFalse);
    });

    test('should delete user successfully', () async {
      // Arrange
      final user = entity.UserEntity(
        name: 'Delete Me',
        preferences: const UserPreferences().toJson(),
        createdAt: DateTime.now(),
      );

      final userId = await userRepository.createUser(user);

      // Act
      final success = await userRepository.deleteUser(userId);

      // Assert
      expect(success, isTrue);

      final retrievedUser = await userRepository.getUserById(userId);
      expect(retrievedUser, isNull);
    });

    test('should return false when deleting non-existent user', () async {
      // Act
      final success = await userRepository.deleteUser(999);

      // Assert
      expect(success, isFalse);
    });
  });
}