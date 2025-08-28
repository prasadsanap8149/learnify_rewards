import 'package:learnify_rewards/shared/domain/entities/user.dart';

abstract class UserRepository {
  Future<User?> getUser(String uid);
  Future<void> createUser(User user);
  Future<void> updateUser(User user);
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields);
}
