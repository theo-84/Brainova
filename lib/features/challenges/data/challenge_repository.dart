import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/challenge_model.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class ChallengeRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ChallengeRepository({
    required this.firestore,
    required this.auth,
  });

  String get _uid {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      throw Exception(
          "User not logged in. Need uid to store real participation.");
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> challengeDoc(String challengeId) {
    return firestore.collection('challenges').doc(challengeId);
  }

  DocumentReference<Map<String, dynamic>> participantDoc(String challengeId) {
    return challengeDoc(challengeId).collection('participants').doc(_uid);
  }

  Stream<int> watchParticipantsCount(String challengeId) {
    return challengeDoc(challengeId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return 0;
      return (data['participantsCount'] as int?) ?? 0;
    });
  }

  Stream<List<Challenge>> watchActiveChallenges() {
    return firestore.collection('challenges').snapshots().map((snap) =>
        snap.docs.map((doc) => Challenge.fromFirestore(doc)).toList());
  }

  Future<ChallengeUserStatus> getMyStatus(String challengeId) async {
    print("DEBUG: Getting status for challenge: $challengeId");
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      return const ChallengeUserStatus(joined: false, endTime: null);
    }

    try {
      // 1. Check if the user is in the activeUsers array of the main challenge doc
      final cSnap = await challengeDoc(challengeId).get();
      final cData = cSnap.data();
      final activeUsers = (cData?['activeUsers'] as List?) ?? [];

      if (!activeUsers.contains(uid)) {
        print("DEBUG: User $uid not in activeUsers list");
        return const ChallengeUserStatus(joined: false, endTime: null);
      }

      // 2. If present, fetch the specific endTime from the participant's doc
      final snap = await participantDoc(challengeId).get();
      if (!snap.exists) {
        print("DEBUG: Participant doc missing despite being in activeUsers");
        return const ChallengeUserStatus(joined: false, endTime: null);
      }

      final data = snap.data()!;
      final ts = data['endTime'] as Timestamp?;
      return ChallengeUserStatus(
        joined: true,
        endTime: ts?.toDate(),
      );
    } catch (e) {
      print("DEBUG: Error getting my status: $e");
      return const ChallengeUserStatus(joined: false, endTime: null);
    }
  }

  Future<void> joinChallenge({
    required String challengeId,
    required Duration duration,
  }) async {
    print("DEBUG: Joining challenge: $challengeId with duration: $duration");
    final cRef = challengeDoc(challengeId);
    final pRef = participantDoc(challengeId);
    final uid = _uid;

    try {
      await firestore.runTransaction((tx) async {
        final pSnap = await tx.get(pRef);
        final cSnap = await tx.get(cRef);

        if (pSnap.exists) {
          print("DEBUG: Already joined");
          return;
        }

        final now = DateTime.now();
        final end = now.add(duration);

        tx.set(pRef, {
          'joinedAt': Timestamp.fromDate(now),
          'endTime': Timestamp.fromDate(end),
        });

        if (!cSnap.exists) {
          tx.set(cRef, {
            'participantsCount': 1,
            'activeUsers': [uid],
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          tx.update(cRef, {
            'participantsCount': FieldValue.increment(1),
            'activeUsers': FieldValue.arrayUnion([uid]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print("DEBUG: Error in joinChallenge transaction: $e");
      rethrow;
    }
  }

  Future<void> leaveChallenge(String challengeId) async {
    print("DEBUG: Leaving challenge: $challengeId");
    final cRef = challengeDoc(challengeId);
    final pRef = participantDoc(challengeId);
    final uid = _uid;

    try {
      await firestore.runTransaction((tx) async {
        final pSnap = await tx.get(pRef);
        if (!pSnap.exists) {
          print("DEBUG: Not in challenge");
          return;
        }

        tx.delete(pRef);
        tx.update(cRef, {
          'participantsCount': FieldValue.increment(-1),
          'activeUsers': FieldValue.arrayRemove([uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print("DEBUG: Error in leaveChallenge: $e");
      rethrow;
    }
  }
}
