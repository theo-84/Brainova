import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(FirebaseFirestore.instance);
});

class AdminRepository {
  final FirebaseFirestore _firestore;
  AdminRepository(this._firestore);

  bool isAdminUser(String? email) {
    return email == 'erer40464@gmail.com';
  }

  Stream<Map<String, dynamic>> watchAnalyticsSummary() {
    final now = DateTime.now();

    return _firestore.collection('users').snapshots().asyncMap((snap) async {
      final dietData = {
        'Social': 0.0,
        'Learning': 0.0,
        'Entertainment': 0.0,
        'Junk': 0.0,
        'Neutral': 0.0,
      };

      for (var doc in snap.docs) {
        final data = doc.data();
        final userDiet = data['dailyDiet'] as Map<String, dynamic>?;

        if (userDiet != null) {
          dietData['Social'] =
              dietData['Social']! + (userDiet['social'] ?? 0.0);
          dietData['Learning'] =
              dietData['Learning']! + (userDiet['learning'] ?? 0.0);
          dietData['Entertainment'] =
              dietData['Entertainment']! + (userDiet['entertainment'] ?? 0.0);
          dietData['Junk'] = dietData['Junk']! + (userDiet['junk'] ?? 0.0);
          dietData['Neutral'] =
              dietData['Neutral']! + (userDiet['neutral'] ?? 0.0);
        }
      }

      // Convert seconds to a relative value for the pie chart
      final totalDuration = dietData.values.fold(0.0, (a, b) => a + b);
      if (totalDuration == 0) {
        dietData['Other'] = 1.0; // Avoid empty chart
      }

      // 2. Brain Rot Distribution (Weekly Trend)
      double avgToday = 0;
      if (snap.docs.isNotEmpty) {
        final sum = snap.docs.fold<double>(
          0,
          (prev, doc) => prev + (doc.data()['currentBrainRotScore'] ?? 0),
        );
        avgToday = sum / snap.docs.length;
      }

      // Save today's average to daily_system_stats
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      await _firestore.collection('daily_system_stats').doc(todayStr).set({
        'avgBrainRot': avgToday,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Fetch last 7 days from daily_system_stats
      final weeklyTrend = List<double>.filled(7, 0.0);
      final weeklyDaysList = <String>[];
      final daysInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        final docSnap = await _firestore
            .collection('daily_system_stats')
            .doc(dateStr)
            .get();

        if (docSnap.exists) {
          weeklyTrend[6 - i] =
              (docSnap.data()!['avgBrainRot'] as num?)?.toDouble() ?? 0.0;
        }

        // Add correct day initial
        weeklyDaysList.add(daysInitials[date.weekday - 1]);
      }

      // 3. Most Used Mind Reset
      // We look at all time activities for this one as requested by the "stats" context
      final allResetsSnap = await _firestore
          .collection('activities')
          .where('type', isEqualTo: 'mindReset')
          .get();

      final resetCounts = <String, int>{};
      for (var doc in allResetsSnap.docs) {
        final name = doc.data()['notes'] as String? ?? 'Unknown';
        resetCounts[name] = (resetCounts[name] ?? 0) + 1;
      }

      String topReset = 'None';
      int maxResetCount = 0;
      resetCounts.forEach((name, count) {
        if (count > maxResetCount) {
          maxResetCount = count;
          topReset = name;
        }
      });
      final mostUsedReset =
          maxResetCount > 0 ? '$topReset ($maxResetCount times)' : 'None';

      // 4. Top Active Challenge
      final challengesSnap = await _firestore.collection('challenges').get();
      String topChallenge = 'None';
      int maxParticipants = -1;

      for (var doc in challengesSnap.docs) {
        final data = doc.data();
        final count = (data['participantsCount'] as int?) ?? 0;
        if (count > maxParticipants) {
          maxParticipants = count;
          topChallenge = data['title'] as String? ?? 'Untitled';
        }
      }

      return {
        'contentDiet': dietData,
        'weeklyBrainRot': weeklyTrend,
        'mostUsedReset': mostUsedReset,
        'topChallenge': topChallenge,
      };
    });
  }

  Stream<Map<String, dynamic>> watchSystemMetrics() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return _firestore.collection('users').snapshots().asyncMap((snap) async {
      final totalUsers = snap.docs.length;

      double avgBrainRot = 0;
      if (snap.docs.isNotEmpty) {
        final sum = snap.docs.fold<double>(
          0,
          (prev, doc) => prev + (doc.data()['currentBrainRotScore'] ?? 0),
        );
        avgBrainRot = sum / snap.docs.length;
      }

      final activeTodaySnap = await _firestore
          .collection('users')
          .where('lastLoginAt',
              isGreaterThanOrEqualTo: startOfToday.toIso8601String())
          .get();

      final resetsSnap = await _firestore
          .collection('activities')
          .where('type', isEqualTo: 'mindReset')
          .get();

      final resetsTodayCount = resetsSnap.docs.where((doc) {
        final ts = doc.data()['timestamp'];
        if (ts is Timestamp) {
          return ts.toDate().isAfter(startOfToday);
        }
        return false;
      }).length;

      final challengesSnap = await _firestore.collection('challenges').get();

      return {
        'totalUsers': totalUsers,
        'activeToday': activeTodaySnap.docs.length,
        'avgBrainRot': avgBrainRot.round(),
        'mindResetsCompleted': resetsTodayCount,
        'activeChallenges': challengesSnap.docs.length,
      };
    });
  }

  Future<Map<String, dynamic>> getSystemMetrics() async {
    return watchSystemMetrics().first;
  }

  // Challenge Management
  Stream<List<Map<String, dynamic>>> watchChallenges() {
    return _firestore.collection('challenges').snapshots().map(
          (snap) =>
              snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
        );
  }

  Future<void> addChallenge(Map<String, dynamic> data) async {
    await _firestore.collection('challenges').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateChallenge(String id, Map<String, dynamic> data) async {
    await _firestore.collection('challenges').doc(id).update(data);
  }

  Future<void> deleteChallenge(String id) async {
    await _firestore.collection('challenges').doc(id).delete();
  }

  // User Management
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final usersSnap = await _firestore.collection('users').get();

    // Fetch all activities from today across all users
    final activitiesSnap = await _firestore
        .collection('activities')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .get();

    // Map to store activity counts by UID
    final statsMap = <String, Map<String, int>>{};

    for (var doc in activitiesSnap.docs) {
      final data = doc.data();
      final uid = data['uid'] as String?;
      final typeString = data['type'] as String?;
      final impactScore = (data['impactScore'] ?? 0) as int;

      if (uid == null) continue;

      statsMap.putIfAbsent(uid, () => {'activity': 0, 'points': 0});

      // We count mindReset and rewire as the requested "activity"
      if (typeString == 'mindReset' || typeString == 'rewire') {
        statsMap[uid]!['activity'] = statsMap[uid]!['activity']! + 1;
        // Points for today is usually the inverse of negative impact for these types
        if (impactScore < 0) {
          statsMap[uid]!['points'] =
              statsMap[uid]!['points']! + impactScore.abs();
        }
      }
    }

    return usersSnap.docs.map((doc) {
      final data = doc.data();
      final uid = doc.id;
      final stats = statsMap[uid] ?? {'activity': 0, 'points': 0};

      return {
        ...data,
        'uid': uid,
        'calculatedDailyActivity': stats['activity'],
        'calculatedDailyPoints': stats['points'],
      };
    }).toList();
  }

  // Badge Management
  Stream<List<Map<String, dynamic>>> watchBadges() {
    return _firestore.collection('badges').snapshots().map(
          (snap) => snap.docs.map((doc) {
            final data = doc.data();
            return {
              ...data,
              'id': doc.id, // Explicitly use document ID
            };
          }).toList(),
        );
  }

  Future<void> addBadge(Map<String, dynamic> data, [String? id]) async {
    if (id != null) {
      await _firestore.collection('badges').doc(id).set(data);
    } else {
      await _firestore.collection('badges').add(data);
    }
  }

  Future<void> updateBadge(String id, Map<String, dynamic> data) async {
    await _firestore.collection('badges').doc(id).update(data);
  }

  Future<void> deleteBadge(String id) async {
    await _firestore.collection('badges').doc(id).delete();
  }

  // Activity Logs
  Stream<List<Map<String, dynamic>>> watchLogs() {
    return _firestore
        .collection('admin_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // Security Actions
  Future<void> toggleUserRestriction(String uid, bool restrict) async {
    await _firestore.collection('users').doc(uid).update({
      'isRestricted': restrict,
      'restrictedAt': restrict ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> deleteUserAccount(String uid) async {
    // Note: This only deletes the Firestore doc.
    // Real account deletion requires Firebase Admin SDK or Cloud Functions.
    await _firestore.collection('users').doc(uid).delete();
  }
}
