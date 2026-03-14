import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_providers.dart';

final dailyResetServiceProvider = Provider<DailyResetService>((ref) {
  return DailyResetService(
    ref.read(userRepositoryProvider),
    ref.read(authRepositoryProvider),
  );
});

/// Checks once per app start whether the calendar day has changed since the
/// last recorded reset, and if so, zeroes out all "daily" counters on the
/// user document in Firestore.
class DailyResetService {
  final UserRepository _userRepo;
  final AuthRepository _authRepo;

  DailyResetService(this._userRepo, this._authRepo);

  /// Call this early in the app lifecycle (e.g. in main.dart or the root widget).
  Future<void> checkAndResetIfNeeded() async {
    final firebaseUser = _authRepo.currentUser;
    if (firebaseUser == null) {
      debugPrint('DailyResetService: no logged-in user, skipping reset check.');
      return;
    }

    final user = await _userRepo.getUser(firebaseUser.uid);
    if (user == null) {
      debugPrint('DailyResetService: could not fetch user document.');
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Determine if we need a reset
    final lastReset = user.lastDailyResetDate;
    final lastResetDay = lastReset != null
        ? DateTime(lastReset.year, lastReset.month, lastReset.day)
        : null;

    if (lastResetDay == null || lastResetDay.isBefore(today)) {
      debugPrint(
          'DailyResetService: New day detected. Last reset: $lastResetDay, today: $today. Resetting daily counters…');

      await _userRepo.updateUser(user.copyWith(
        dailyPoints: 0,
        dailySessions: 0,
        lastDailyResetDate: today,
      ));

      debugPrint('DailyResetService: Daily counters reset successfully.');
    } else {
      debugPrint('DailyResetService: Already reset today ($today). Skipping.');
    }
  }
}
