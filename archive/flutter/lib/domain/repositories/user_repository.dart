import '../entities/user.dart';

abstract class UserRepository {
  Future<int> createUser(UserEntity user);
  Future<UserEntity?> getUserById(int id);
  Future<List<UserEntity>> getAllUsers();
  Future<bool> updateUser(UserEntity user);
  Future<bool> deleteUser(int id);
}