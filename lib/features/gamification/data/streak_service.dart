import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/user_repository.dart';

final streakServiceProvider = Provider<StreakService>((ref) {
  return StreakService(ref.read(userRepositoryProvider));
});

class StreakService {
  final UserRepository _userRepo;

  StreakService(this._userRepo);

  /// Normalizes a DateTime to midnight for date-only comparison.
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Updates the user's streak based on the required daily action.
  /// This should be called when the user completes their daily task.
  Future<void> completeDailyTask(String uid) async {
    final user = await _userRepo.getUser(uid);
    if (user == null) return;

    final now = DateTime.now();
    final today = _normalizeDate(now);

    final lastActiveValue = user.lastActiveDate;
    final lastActiveDate =
        lastActiveValue != null ? _normalizeDate(lastActiveValue) : null;

    int newStreak = user.currentStreak;
    int newLongestStreak = user.longestStreak;

    if (lastActiveDate == null) {
      // First time completing a task
      newStreak = 1;
    } else if (lastActiveDate == today) {
      // Already completed today, do nothing
      return;
    } else if (lastActiveDate == today.subtract(const Duration(days: 1))) {
      // Completed yesterday, increase streak
      newStreak += 1;
    } else {
      // Missed one or more days, reset to 1
      newStreak = 1;
    }

    // Update longest streak
    if (newStreak > newLongestStreak) {
      newLongestStreak = newStreak;
    }

    // Update user record
    await _userRepo.updateUser(user.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastActiveDate: now,
    ));
  }

  /// Checks if the streak should be reset because the user missed a day.
  /// This should be called on app startup or periodically.
  Future<void> checkAndResetStreak(String uid) async {
    final user = await _userRepo.getUser(uid);
    if (user == null) return;

    final now = DateTime.now();
    final today = _normalizeDate(now);
    final yesterday = today.subtract(const Duration(days: 1));

    final lastActiveValue = user.lastActiveDate;
    if (lastActiveValue == null) return;

    final lastActiveDate = _normalizeDate(lastActiveValue);

    // If last active was before yesterday, the streak is broken
    bool resetStreak = lastActiveDate.isBefore(yesterday);
    bool resetDailyStats = lastActiveDate.isBefore(today);

    if (resetStreak || resetDailyStats) {
      await _userRepo.updateUser(user.copyWith(
        currentStreak: resetStreak ? 0 : user.currentStreak,
        dailyPoints: resetDailyStats ? 0 : user.dailyPoints,
        dailySessions: resetDailyStats ? 0 : user.dailySessions,
      ));
    }
  }
}
