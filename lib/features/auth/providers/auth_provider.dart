import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/auth_repository.dart';
import '../models/user_model.dart';
import '../../../core/exceptions.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  return ref.watch(authRepositoryProvider).getCurrentUser();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> signInWithGoogle() async {
    try {
      state = const AsyncValue.loading();
      final user = await _repository.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    Map<String, String>? preferences,
  }) async {
    try {
      await _repository.updateUserProfile(
        uid: uid,
        displayName: displayName,
        photoUrl: photoUrl,
        preferences: preferences,
      );

      // Refresh current user
      final updatedUser = await _repository.getCurrentUser();
      state = AsyncValue.data(updatedUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> verifyAge({
    required String uid,
    required DateTime dateOfBirth,
    String? parentEmail,
  }) async {
    try {
      await _repository.verifyAgeAndConsent(
        uid: uid,
        dateOfBirth: dateOfBirth,
        parentEmail: parentEmail,
      );

      // Refresh current user
      final updatedUser = await _repository.getCurrentUser();
      state = AsyncValue.data(updatedUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> storeSensitiveData({
    required String uid,
    required Map<String, String> data,
  }) async {
    try {
      await _repository.storeSensitiveData(
        uid: uid,
        data: data,
      );

      // Refresh current user
      final updatedUser = await _repository.getCurrentUser();
      state = AsyncValue.data(updatedUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
