import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AppUser?>>(
      (ref) => AuthController(ref, ref.read(authRepositoryProvider)),
    );

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges();
});

final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  ref.watch(authStateChangesProvider);
  return ref.read(authRepositoryProvider).currentAppUser();
});

class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  AuthController(this._ref, this._repository)
    : super(const AsyncValue.data(null));

  final Ref _ref;
  final AuthRepository _repository;

  Future<AppUser?> refreshCurrentUser() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.currentAppUser);
    _ref.invalidate(currentUserProvider);
    return state.valueOrNull;
  }

  Future<AppUser?> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.signInWithEmail(email: email, password: password),
    );
    final user = state.valueOrNull;
    if (user != null) {
      _ref.invalidate(currentUserProvider);
    }
    return user;
  }

  Future<AppUser?> register({
    required String name,
    required String email,
    required String password,
    required AppRole role,
    String? teacherAccessCode,
    String? adminAccessCode,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.registerWithEmail(
        name: name,
        email: email,
        password: password,
        role: role,
        teacherAccessCode: teacherAccessCode,
        adminAccessCode: adminAccessCode,
      ),
    );
    final user = state.valueOrNull;
    if (user != null) {
      _ref.invalidate(currentUserProvider);
    }
    return user;
  }

  Future<AppUser?> loginWithGoogle({
    AppRole? preferredRole,
    String? teacherAccessCode,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.signInWithGoogle(
        preferredRole: preferredRole,
        teacherAccessCode: teacherAccessCode,
      ),
    );
    final user = state.valueOrNull;
    if (user != null) {
      _ref.invalidate(currentUserProvider);
    }
    return user;
  }

  Future<void> resetPassword(String email) async {
    await _repository.sendPasswordReset(email);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncValue.data(null);
    _ref.invalidate(currentUserProvider);
  }

  Future<AppUser> updateProfileName(String name) async {
    final user = await _repository.updateCurrentUserName(name);
    _ref.invalidate(currentUserProvider);
    return user;
  }

  Future<void> changePassword(String newPassword) {
    return _repository.updateCurrentUserPassword(newPassword);
  }
}
