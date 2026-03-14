import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'content_diet_model.dart';
import '../../auth/data/auth_providers.dart';
import '../../tracking/data/activity_repository.dart';
import '../../tracking/data/activity_model.dart';

final contentDietRepositoryProvider = Provider<ContentDietRepository>((ref) {
  return ContentDietRepository(
    ref.read(activityRepositoryProvider),
    FirebaseFirestore.instance,
  );
});

final recentDietEntriesProvider =
    FutureProvider.autoDispose<List<ContentDietEntry>>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return [];
  return ref.watch(contentDietRepositoryProvider).getRecentEntries(user.uid);
});

class ContentDietRepository {
  final ActivityRepository _activityRepo;
  final FirebaseFirestore _firestore;

  ContentDietRepository(this._activityRepo, this._firestore);

  Future<void> addEntry(ContentDietEntry entry) async {
    // Log as activity for persistence and score calculation
    await _activityRepo.logActivity(
      uid: entry.uid,
      type: _mapCategoryToActivityType(entry.category),
      durationSeconds: entry.minutes * 60,
      impactScore: _calculateImpactScore(entry.category, entry.minutes),
      notes: entry.notes,
    );

    // 2. Increment global diet count in UserModel
    try {
      await _firestore.collection('users').doc(entry.uid).update({
        'contentDietCount': FieldValue.increment(1),
      });
      debugPrint("Content Diet count incremented in Firestore");
    } catch (e) {
      debugPrint("Error incrementing contentDietCount: $e");
    }
  }

  Future<List<ContentDietEntry>> getRecentEntries(String uid) async {
    // Use centralized repository to fetch activities
    final activities = await _activityRepo.getRecentActivities(uid,
        limit: 20, includeAuto: false);

    return activities.map((activity) {
      return ContentDietEntry(
        id: activity.id,
        uid: uid,
        date: activity.timestamp,
        category: _mapActivityTypeToCategory(activity.type),
        minutes: activity.durationSeconds ~/ 60,
        notes: activity.notes,
      );
    }).toList();
  }

  ActivityType _mapCategoryToActivityType(DietCategory cat) {
    switch (cat) {
      case DietCategory.learning:
        return ActivityType.learning;
      case DietCategory.entertainment:
        return ActivityType.entertainment;
      case DietCategory.social:
        return ActivityType.social;
      case DietCategory.junk:
        return ActivityType.junk;
    }
  }

  DietCategory _mapActivityTypeToCategory(ActivityType type) {
    switch (type) {
      case ActivityType.learning:
      case ActivityType.rewire:
      case ActivityType.mindReset:
        return DietCategory.learning;
      case ActivityType.entertainment:
        return DietCategory.entertainment;
      case ActivityType.social:
        return DietCategory.social;
      case ActivityType.junk:
        return DietCategory.junk;
      default:
        return DietCategory.junk;
    }
  }

  int _calculateImpactScore(DietCategory type, int minutes) {
    switch (type) {
      case DietCategory.social:
        return (minutes * 2.0).round();
      case DietCategory.junk:
        return (minutes * 2.2).round();
      case DietCategory.entertainment:
        return (minutes * 1.5).round();
      case DietCategory.learning:
        return -(minutes * 0.5).round();
    }
  }
}
