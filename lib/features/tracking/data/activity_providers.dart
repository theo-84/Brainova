import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'activity_repository.dart';
import 'activity_model.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/brain_rot_service.dart';

// ---------------------------
// Brain Rot Score (Rolling 24h)
// ---------------------------

final brainRotScoreProvider = FutureProvider<int>((ref) async {
  final auth = ref.watch(authRepositoryProvider);
  final user = auth.currentUser;
  if (user == null) return 0;
  final uid = user.uid;

  final service = ref.read(brainRotServiceProvider);
  return service.calculateRollingScore(uid);
});

// ---------------------------
// Social Activities
// ---------------------------

final socialActivitiesProvider =
    FutureProvider<List<ActivityLogModel>>((ref) async {
  final auth = ref.watch(authRepositoryProvider);
  final user = auth.currentUser;
  if (user == null) return [];
  final uid = user.uid;

  final repo = ref.read(activityRepositoryProvider);
  return repo.getActivitiesByType(uid, ActivityType.social);
});

// ---------------------------
// Learning Activities
// ---------------------------

final learningActivitiesProvider =
    FutureProvider<List<ActivityLogModel>>((ref) async {
  final auth = ref.watch(authRepositoryProvider);
  final user = auth.currentUser;
  if (user == null) return [];
  final uid = user.uid;

  final repo = ref.read(activityRepositoryProvider);
  return repo.getActivitiesByType(uid, ActivityType.learning);
});

// ---------------------------
// Real Data Permission
// ---------------------------

final realDataAvailableProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(activityRepositoryProvider);
  return repo.checkRealDataAvailability();
});
