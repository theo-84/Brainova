import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_providers.dart';
import '../data/activity_repository.dart';

final dailyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final auth = ref.watch(authStateProvider);
  final uid = auth.value?.uid;
  if (uid == null) return {'points': 0, 'sessions': 0};

  final repo = ref.read(activityRepositoryProvider);
  return await repo.getDailyStats(uid);
});
