import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tracking/data/activity_repository.dart';
import 'reality_check_result.dart';
import '../../tracking/data/activity_model.dart';

final realityCheckServiceProvider = Provider<RealityCheckService>((ref) {
  return RealityCheckService(
    ref.read(activityRepositoryProvider),
  );
});

final realityCheckProvider =
    FutureProvider.family<RealityCheckResult, String>((ref, uid) async {
  final service = ref.read(realityCheckServiceProvider);
  return service.runRealityCheck(uid);
});

final weeklyBreakdownProvider =
    FutureProvider.family<Map<ActivityType, double>, String>((ref, uid) async {
  return ref.read(activityRepositoryProvider).getWeeklyBreakdown(uid);
});

final recentLogsProvider =
    FutureProvider.family<List<ActivityLogModel>, String>((ref, uid) async {
  return ref.read(activityRepositoryProvider).getRecentActivities(uid);
});

class RealityCheckService {
  final ActivityRepository _activityRepo;

  RealityCheckService(this._activityRepo);

  Future<RealityCheckResult> runRealityCheck(String uid) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day); // midnight today

    final activities = await _activityRepo.getActivitiesInRange(
      uid,
      start,
      now,
    );

    double totalMinutes = 0;
    double social = 0;
    double junk = 0;
    double learning = 0;
    double entertainment = 0;
    double neutral = 0;

    for (final activity in activities) {
      final pkg =
          activity.metadata?['packageName']?.toString().toLowerCase() ?? '';

      // Ignore our own app and common launchers/system UI in breakdown
      if (pkg.contains('brainova') ||
          pkg.contains('launcher') ||
          pkg.contains('systemui') ||
          pkg.contains('settings') ||
          pkg.isEmpty && activity.type == ActivityType.neutral) {
        continue;
      }

      final minutes = activity.durationSeconds / 60;
      totalMinutes += minutes;

      switch (activity.type) {
        case ActivityType.social:
          social += minutes;
          break;
        case ActivityType.junk:
          junk += minutes;
          break;
        case ActivityType.learning:
          learning += minutes;
          debugPrint(
              "DEBUG: Learning activity found: ${activity.metadata?['packageName']} - ${activity.durationSeconds}s");
          break;
        case ActivityType.entertainment:
          entertainment += minutes;
          break;
        case ActivityType.neutral:
          neutral += minutes;
          break;
        case ActivityType.rewire:
          learning += minutes;
          debugPrint(
              "DEBUG: Rewire activity found: ${activity.notes} - ${activity.durationSeconds}s");
          break;
        case ActivityType.mindReset:
          break;
      }
    }

    if (totalMinutes == 0) {
      return RealityCheckResult(
        brainRotScore: 0,
        categoryPercentages: {},
        status: "Healthy",
        message: "No significant activity detected.",
        shouldSuggestReset: false,
      );
    }

    print('DEBUG: Reality Check Breakdown (Minutes):');
    print('  - Social: ${social.toStringAsFixed(2)}');
    print('  - Junk: ${junk.toStringAsFixed(2)}');
    print('  - Learning: ${learning.toStringAsFixed(2)}');
    print('  - Entertainment: ${entertainment.toStringAsFixed(2)}');
    print('  - Neutral: ${neutral.toStringAsFixed(2)}');
    print('  - Total: ${totalMinutes.toStringAsFixed(2)}');

    double round(double value) => double.parse(value.toStringAsFixed(1));

    final breakdown = {
      "social": round((social / totalMinutes) * 100),
      "junk": round((junk / totalMinutes) * 100),
      "learning": round((learning / totalMinutes) * 100),
      "entertainment": round((entertainment / totalMinutes) * 100),
      "neutral": round((neutral / totalMinutes) * 100),
    };

    // Reality Check scoring different from Brain Rot Meter

    double stimulationScore =
        junk * 1.2 + social * 1.0 + entertainment * 0.8 + neutral * 0.0;

    double recoveryScore = learning * 1.0;

    double rawScore = stimulationScore - recoveryScore;

    double normalized = (rawScore / totalMinutes) * 100;

    int score = normalized.clamp(0, 100).round();

    print('DEBUG: Reality Check Score calculated: $score');

    String status;
    String message;
    bool suggestReset = false;

    if (score >= 80) {
      status = "Danger";
      message =
          "High stimulation detected. Your digital habits may be affecting focus.";
      suggestReset = true;
    } else if (score >= 60) {
      status = "Caution";
      message = "You are leaning toward heavy stimulation. Consider a reset.";
      suggestReset = true;
    } else {
      status = "Healthy";
      message = "Your digital balance looks stable. Keep it up.";
    }

    return RealityCheckResult(
      brainRotScore: score,
      categoryPercentages: breakdown,
      status: status,
      message: message,
      shouldSuggestReset: suggestReset,
    );
  }
}
