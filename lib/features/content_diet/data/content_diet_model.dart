enum DietCategory { learning, entertainment, junk, social }

class ContentDietEntry {
  final String id;
  final String uid;
  final DateTime date;
  final DietCategory category;
  final int minutes;
  final String? notes;

  ContentDietEntry({
    required this.id,
    required this.uid,
    required this.date,
    required this.category,
    required this.minutes,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'date': date.toIso8601String(),
      'category': category.name,
      'minutes': minutes,
      'notes': notes,
    };
  }

  factory ContentDietEntry.fromMap(Map<String, dynamic> data, String id) {
    return ContentDietEntry(
      id: id,
      uid: data['uid'] ?? '',
      date: data['date'] != null
          ? DateTime.tryParse(data['date']) ?? DateTime.now()
          : DateTime.now(),
      category: DietCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => DietCategory.junk,
      ),
      minutes: data['minutes'] ?? 0,
      notes: data['notes'],
    );
  }
}
