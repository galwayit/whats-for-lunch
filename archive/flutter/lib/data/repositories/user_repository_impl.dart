import '../../domain/entities/user.dart' as domain;
import '../../domain/repositories/user_repository.dart';
import '../database/database.dart';
import '../mappers/entity_mappers.dart';

class UserRepositoryImpl implements UserRepository {
  final AppDatabase _database;

  UserRepositoryImpl(this._database);

  @override
  Future<int> createUser(domain.UserEntity user) async {
    final companion = EntityMappers.userToCompanion(user);
    return await _database.insertUser(companion);
  }

  @override
  Future<domain.UserEntity?> getUserById(int id) async {
    final user = await _database.getDatabaseUserById(id);
    if (user == null) return null;
    return EntityMappers.userFromDatabase(user);
  }

  @override
  Future<List<domain.UserEntity>> getAllUsers() async {
    final users = await _database.getAllDatabaseUsers();
    return users.map((user) => EntityMappers.userFromDatabase(user)).toList();
  }

  @override
  Future<bool> updateUser(domain.UserEntity user) async {
    if (user.id == null) return false;
    final companion = EntityMappers.userToCompanion(user);
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