import '../../domain/entities/user.dart' as entity;
import '../../domain/repositories/user_repository.dart';
import '../database/database.dart';

class UserRepositoryImpl implements UserRepository {
  final AppDatabase _database;

  UserRepositoryImpl(this._database);

  @override
  Future<int> createUser(entity.UserEntity user) async {
    final companion = _database.userToCompanion(user);
    return await _database.insertUser(companion);
  }

  @override
  Future<entity.UserEntity?> getUserById(int id) async {
    final user = await _database.getDatabaseUserById(id);
    if (user == null) return null;
    return _database.userFromTable(user);
  }

  @override
  Future<List<entity.UserEntity>> getAllUsers() async {
    final users = await _database.getAllDatabaseUsers();
    return users.map((user) => _database.userFromTable(user)).toList();
  }

  @override
  Future<bool> updateUser(entity.UserEntity user) async {
    if (user.id == null) return false;
    final companion = _database.userToCompanion(user);
    return await _database.updateUser(companion);
  }

  @override
  Future<bool> deleteUser(int id) async {
    final deletedRows = await (_database.delete(_database.users)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
    return deletedRows > 0;
  }
}