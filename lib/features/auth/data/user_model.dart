class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? country;
  final List<String> badges;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int currentBrainRotScore;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final int points;
  final int dailyPoints;
  final int totalSessions;
  final int dailySessions;
  final int contentDietCount;
  final String role; // 'user' or 'admin'
  final DateTime?
      lastDailyResetDate; // tracks the last date daily counters were reset
  final bool isRestricted;
  final bool isEmailVerified;
  final Map<String, double> dailyDiet; // Stores the % breakdown for today

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.country,
    this.badges = const [],
    required this.createdAt,
    required this.lastLoginAt,
    this.currentBrainRotScore = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.points = 0,
    this.dailyPoints = 0,
    this.totalSessions = 0,
    this.dailySessions = 0,
    this.contentDietCount = 0,
    this.role = 'user',
    this.isRestricted = false,
    this.isEmailVerified = false,
    this.lastDailyResetDate,
    this.dailyDiet = const {},
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      phoneNumber: data['phoneNumber'],
      dateOfBirth: data['dateOfBirth'] != null
          ? DateTime.tryParse(data['dateOfBirth'])
          : null,
      gender: data['gender'],
      country: data['country'],
      badges: List<String>.from(data['badges'] ?? []),
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? DateTime.tryParse(data['lastLoginAt']) ?? DateTime.now()
          : DateTime.now(),
      currentBrainRotScore:
          data['currentBrainRotScore'] ?? data['currentBrainRotLevel'] ?? 0,
      currentStreak: data['currentStreak'] ?? data['streakDays'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      lastActiveDate: data['lastActiveDate'] != null
          ? DateTime.tryParse(data['lastActiveDate'])
          : null,
      points: data['points'] ?? 0,
      dailyPoints: data['dailyPoints'] ?? 0,
      totalSessions: data['totalSessions'] ?? 0,
      dailySessions: data['dailySessions'] ?? 0,
      contentDietCount: data['contentDietCount'] ?? 0,
      role: data['role'] ?? 'user',
      isRestricted: data['isRestricted'] ?? false,
      isEmailVerified: data['isEmailVerified'] ?? false,
      lastDailyResetDate: data['lastDailyResetDate'] != null
          ? DateTime.tryParse(data['lastDailyResetDate'])
          : null,
      dailyDiet: data['dailyDiet'] != null
          ? Map<String, double>.from(data['dailyDiet'])
          : const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'country': country,
      'badges': badges,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'currentBrainRotScore': currentBrainRotScore,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'points': points,
      'dailyPoints': dailyPoints,
      'totalSessions': totalSessions,
      'dailySessions': dailySessions,
      'contentDietCount': contentDietCount,
      'role': role,
      'isRestricted': isRestricted,
      'isEmailVerified': isEmailVerified,
      'lastDailyResetDate': lastDailyResetDate?.toIso8601String(),
      'dailyDiet': dailyDiet,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? country,
    List<String>? badges,
    DateTime? lastLoginAt,
    int? currentBrainRotScore,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? points,
    int? dailyPoints,
    int? totalSessions,
    int? dailySessions,
    int? contentDietCount,
    bool? isRestricted,
    bool? isEmailVerified,
    DateTime? lastDailyResetDate,
    Map<String, double>? dailyDiet,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      country: country ?? this.country,
      badges: badges ?? this.badges,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      currentBrainRotScore: currentBrainRotScore ?? this.currentBrainRotScore,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      points: points ?? this.points,
      dailyPoints: dailyPoints ?? this.dailyPoints,
      totalSessions: totalSessions ?? this.totalSessions,
      dailySessions: dailySessions ?? this.dailySessions,
      contentDietCount: contentDietCount ?? this.contentDietCount,
      role: role,
      isRestricted: isRestricted ?? this.isRestricted,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      lastDailyResetDate: lastDailyResetDate ?? this.lastDailyResetDate,
      dailyDiet: dailyDiet ?? this.dailyDiet,
    );
  }
}
