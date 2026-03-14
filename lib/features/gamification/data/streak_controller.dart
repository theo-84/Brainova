import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_providers.dart';
import 'streak_service.dart';

final streakControllerProvider =
    StateNotifierProvider<StreakController, UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRepo = ref.read(userRepositoryProvider);
  final streakService = ref.read(streakServiceProvider);

  return StreakController(
    authState.value?.uid,
    userRepo,
    streakService,
  );
});

class StreakController extends StateNotifier<UserModel?> {
  final String? _uid;
  final UserRepository _userRepo;
  final StreakService _streakService;

  StreakController(this._uid, this._userRepo, this._streakService)
      : super(null) {
    if (_uid != null) {
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    if (_uid == null) return;
    final user = await _userRepo.getUser(_uid);
    state = user;

    // Check for streak reset on load
    await _streakService.checkAndResetStreak(_uid);

    // Refresh state after potential reset
    state = await _userRepo.getUser(_uid);
  }

  Future<void> completeDailyTask() async {
    if (_uid == null) return;
    await _streakService.completeDailyTask(_uid);

    // Refresh state
    state = await _userRepo.getUser(_uid);
  }
}
