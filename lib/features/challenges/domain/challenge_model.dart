import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final String id;
  final String title;
  final String description;
  final int duration; // Days
  final int points;
  final DateTime startDate;
  final DateTime endDate;
  final String category;
  final bool isActive;
  final int participantsCount;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.points,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.isActive,
    this.participantsCount = 0,
  });

  factory Challenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    return Challenge(
      id: doc.id,
      title: data['title'] ?? 'Untitled Challenge',
      description: data['description'] ?? '',
      duration: data['duration'] ?? 7,
      points: data['points'] ?? 50,
      startDate: parseDate(data['startDate']),
      endDate: parseDate(data['endDate']),
      category: data['category'] ?? 'General',
      isActive: data['isActive'] ?? true,
      participantsCount: data['participantsCount'] ?? 0,
    );
  }
}

class ChallengeUserStatus {
  final bool joined;
  final DateTime? endTime;

  const ChallengeUserStatus({
    required this.joined,
    required this.endTime,
  });

  bool get isActive =>
      joined && endTime != null && endTime!.isAfter(DateTime.now());
  bool get isCompleted =>
      joined && endTime != null && !endTime!.isAfter(DateTime.now());
}
