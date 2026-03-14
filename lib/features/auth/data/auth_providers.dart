import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import 'user_repository.dart';
import 'user_model.dart';

export 'auth_repository.dart';
export 'user_repository.dart';
export 'user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    ref.read(userRepositoryProvider),
  );
});

final authStateProvider = StreamProvider<UserModel?>((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  return authRepo.authStateChanges();
});

final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return Stream.value(null);

  final repo = ref.watch(userRepositoryProvider);
  return repo.watchUser(user.uid);
});
