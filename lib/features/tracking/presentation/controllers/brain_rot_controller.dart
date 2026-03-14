import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_providers.dart';
import '../../data/activity_model.dart';
import '../../data/activity_repository.dart';

final brainRotControllerProvider =
    StateNotifierProvider<BrainRotController, int>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRepo = ref.read(userRepositoryProvider);
  final activityRepo = ref.read(activityRepositoryProvider);

  return BrainRotController(
    authState.value?.uid,
    userRepo,
    activityRepo,
    initialScore: authState.value?.currentBrainRotScore ?? 0,
  );
});

class BrainRotController extends StateNotifier<int> {
  final String? _uid;
  final UserRepository _userRepo;
  final ActivityRepository _activityRepo;
  Timer? _timer;

  BrainRotController(
    this._uid,
    this._userRepo,
    this._activityRepo, {
    int initialScore = 0,
  }) : super(initialScore) {
    if (_uid != null) {
      _startTracking();
    }
  }

  void _startTracking() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _incrementBasedOnTime();
    });
  }

  void _incrementBasedOnTime() {
    if (_uid == null) return;

    // Logic: Increase "Brain Rot" by 1% every 5 minutes of low-value digital activity.
    // This is a simplified logic. In a real app, we'd detect foreground app or activity type.
    // For now, let's assume "Idle/Undefined" activity increases it slowly.

    final newScore = (state + 1).clamp(0, 100);
    if (newScore != state) {
      state = newScore;
      _syncToFirestore();

      if (state >= 90) {
        // Trigger intervention logic (handled by UI listening to this controller)
      }
    }
  }

  Future<void> logActivity(
      ActivityType type, int durationSeconds, int impact) async {
    if (_uid == null) return;

    final activity = ActivityLogModel(
      id: '', // Firestore will generate
      uid: _uid,
      type: type,
      timestamp: DateTime.now(),
      durationSeconds: durationSeconds,
      impactScore: impact,
    );

    await _activityRepo.addActivity(activity);

    final newScore = (state + impact).clamp(0, 100);
    if (newScore != state) {
      state = newScore;
      await _syncToFirestore();
    }
  }

  Future<void> _syncToFirestore() async {
    if (_uid == null) return;
    final user = await _userRepo.getUser(_uid);
    if (user != null) {
      await _userRepo.updateUser(user.copyWith(currentBrainRotScore: state));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
