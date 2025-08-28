import 'package:flutter/material.dart';
import 'package:learnify_rewards/shared/data/repositories/user_repository_impl.dart';
import 'package:learnify_rewards/shared/domain/entities/user.dart';
import 'package:learnify_rewards/shared/domain/repositories/user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserRepository _userRepository = UserRepositoryImpl();
  late Future<User?> _user;

  @override
  void initState() {
    super.initState();
    // Replace 'user1' with the actual user ID
    _userRepository.createUser(User(
      uid: 'user1',
      displayName: 'Test User',
      email: 'test@example.com',
      role: UserRole.user,
      status: UserStatus.active,
      ageGroup: AgeGroup.eighteen_plus,
      verificationStatus: VerificationStatus.full,
    ));
    _user = _userRepository.getUser('user1');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: FutureBuilder<User?>(
        future: _user,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('User not found.'));
          }

          final user = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${user.displayName}'),
                Text('Email: ${user.email}'),
                Text('Role: ${user.role.toString().split('.').last}'),
                Text('Status: ${user.status.toString().split('.').last}'),
                Text('Age Group: ${user.ageGroup.toString().split('.').last}'),
                Text(
                    'Verification: ${user.verificationStatus.toString().split('.').last}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
