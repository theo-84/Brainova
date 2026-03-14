import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_providers.dart';
import '../data/activity_repository.dart';
import '../data/activity_model.dart';
import '../../../core/service/smart_notification_service.dart';

final brainRotServiceProvider = Provider<BrainRotService>((ref) {
  return BrainRotService(
    ref.read(activityRepositoryProvider),
    ref.read(authRepositoryProvider),
    ref.read(userRepositoryProvider),
    ref.read(smartNotificationServiceProvider),
  );
});

class BrainRotService {
  final ActivityRepository _activityRepo;
  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final SmartNotificationService _notificationService;

  static int? _lastScore;

  BrainRotService(this._activityRepo, this._authRepo, this._userRepo,
      this._notificationService);

  // ===== WEIGHTS =====
  static const double socialWeight = 2.0;
  static const double entertainmentWeight = 1.5;
  static const double neutralWeight = 1.0;
  static const double learningWeight =
      -0.5; // Changed to negative to reduce rot

  static const double normalizationConstant = 600.0;

  // ===== TODAY'S SCORE (midnight → now) =====
  Future<int> calculateRollingScore(String uid) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day); // midnight today

    final activities =
        await _activityRepo.getActivitiesInRange(uid, start, now);

    debugPrint(
        "DEBUG: BrainRotService: Found ${activities.length} activities for calculation");

    double positiveImpact = 0;
    double negativeImpact = 0;

    for (final activity in activities) {
      final pkg = activity.metadata?['packageName'] as String?;
      if (pkg == 'com.example.brainova' ||
          pkg == 'com.sec.android.app.launcher' ||
          pkg == 'com.google.android.apps.nexuslauncher' ||
          pkg == 'com.android.systemui') {
        continue;
      }

      final minutes = activity.durationSeconds / 60;
      double impact = 0;

      switch (activity.type) {
        case ActivityType.social:
          impact = minutes * socialWeight;
          break;
        case ActivityType.entertainment:
          impact = minutes * entertainmentWeight;
          break;
        case ActivityType.neutral:
          impact = minutes * neutralWeight;
          break;
        case ActivityType.learning:
          impact = minutes * learningWeight;
          break;
        case ActivityType.mindReset:
          impact = -20;
          break;
        case ActivityType.rewire:
          impact = -10;
          break;
        case ActivityType.junk:
          impact = minutes * 2.2;
          break;
      }

      if (impact > 0) {
        positiveImpact += impact;
      } else {
        negativeImpact += impact;
      }
    }

    double rawImpact = positiveImpact + negativeImpact;
    double scoreValue = (rawImpact / normalizationConstant) * 100;

    debugPrint("DEBUG: BrainRot Calculation Breakdown:");
    debugPrint("  - Positive (Usage): +${positiveImpact.toStringAsFixed(2)}");
    debugPrint(
        "  - Negative (Recovery/Learning): ${negativeImpact.toStringAsFixed(2)}");
    debugPrint("  - Net Raw Impact: ${rawImpact.toStringAsFixed(2)}");
    debugPrint("  - Score Before Clamp: ${scoreValue.toStringAsFixed(2)}%");

    if (scoreValue < 0) scoreValue = 0;
    if (scoreValue > 100) scoreValue = 100;

    final currentScore = scoreValue.round();

    // Sync daily data to Firestore for Admin Analytics
    final user = await _userRepo.getUser(uid);
    if (user != null) {
      final breakdown = await getCategoryBreakdown(uid, activities: activities);
      await _userRepo.updateUser(user.copyWith(
        currentBrainRotScore: currentScore,
        dailyDiet: breakdown,
      ));
    }

    // Trigger notifications based on score changes
    if (_lastScore != null) {
      if (currentScore > _lastScore! && currentScore >= 60) {
        await _notificationService.sendBrainRotWarning(currentScore);
      } else if (currentScore < _lastScore!) {
        await _notificationService.sendPositiveReinforcement(
            _lastScore!, currentScore);
      }
    } else if (currentScore >= 60) {
      // First time check and score is high
      await _notificationService.sendBrainRotWarning(currentScore);
    }

    _lastScore = currentScore;
    return currentScore;
  }

  // ===== TODAY'S CATEGORY BREAKDOWN (midnight → now) =====
  Future<Map<String, double>> getCategoryBreakdown(String uid,
      {List<ActivityLogModel>? activities}) async {
    final List<ActivityLogModel> finalActivities;

    if (activities != null) {
      finalActivities = activities;
    } else {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day); // midnight today
      finalActivities =
          await _activityRepo.getActivitiesInRange(uid, start, now);
    }

    double totalMinutes = 0;
    double social = 0;
    double entertainment = 0;
    double neutral = 0;
    double learning = 0;
    double junk = 0;

    for (final activity in finalActivities) {
      final minutes = activity.durationSeconds / 60;
      totalMinutes += minutes;

      switch (activity.type) {
        case ActivityType.social:
          social += minutes;
          break;

        case ActivityType.entertainment:
          entertainment += minutes;
          break;

        case ActivityType.neutral:
          neutral += minutes;
          break;

        case ActivityType.learning:
          learning += minutes;
          break;

        case ActivityType.junk:
          junk += minutes;
          break;

        default:
          break;
      }
    }

    if (totalMinutes == 0) {
      return {
        'social': 0,
        'entertainment': 0,
        'neutral': 0,
        'learning': 0,
        'junk': 0,
      };
    }

    double round(double value) => double.parse(value.toStringAsFixed(1));

    return {
      'social': round((social / totalMinutes) * 100),
      'entertainment': round((entertainment / totalMinutes) * 100),
      'neutral': round((neutral / totalMinutes) * 100),
      'learning': round((learning / totalMinutes) * 100),
      'junk': round((junk / totalMinutes) * 100),
    };
  }

  // ===== COMPLETE REWIRE =====
  Future<void> completeRewire(String taskTitle, {int points = 10}) async {
    final userAuth = _authRepo.currentUser;
    if (userAuth == null) return;

    // Log through repository
    await _activityRepo.logActivity(
      uid: userAuth.uid,
      type: ActivityType.rewire,
      durationSeconds: 60,
      impactScore: -points,
      notes: taskTitle,
    );

    // Update User Stats
    final user = await _userRepo.getUser(userAuth.uid);
    if (user != null) {
      await _userRepo.updateUser(user.copyWith(
        points: user.points + points,
        dailyPoints: user.dailyPoints + points,
        totalSessions: user.totalSessions + 1,
        dailySessions: user.dailySessions + 1,
      ));
    }
  }

  // ===== COMPLETE MIND RESET =====
  Future<void> completeMindReset(String activityTitle,
      {int points = 20, int durationSeconds = 60}) async {
    final userAuth = _authRepo.currentUser;
    if (userAuth == null) return;

    // Log through repository
    await _activityRepo.logActivity(
      uid: userAuth.uid,
      type: ActivityType.mindReset,
      durationSeconds: durationSeconds,
      impactScore: -points,
      notes: activityTitle,
    );

    // Update User Stats
    final user = await _userRepo.getUser(userAuth.uid);
    if (user != null) {
      await _userRepo.updateUser(user.copyWith(
        points: user.points + points,
        dailyPoints: user.dailyPoints + points,
        totalSessions: user.totalSessions + 1,
        dailySessions: user.dailySessions + 1,
      ));
    }
  }
}
