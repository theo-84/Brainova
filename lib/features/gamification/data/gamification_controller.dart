import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/user_repository.dart';

final gamificationControllerProvider = Provider<GamificationController>((ref) {
  return GamificationController(
    ref.read(userRepositoryProvider),
  );
});

class GamificationController {
  final UserRepository _userRepo;

  GamificationController(this._userRepo);

  static const List<Map<String, dynamic>> availableBadges = [
    {
      'id': 'focus_master',
      'name': 'Focus Master',
      'description': 'Complete 5 Mind Resets in a day',
      'condition': 'mindResetsToday >= 5',
    },
    {
      'id': 'scroll_slayer',
      'name': 'Scroll Slayer',
      'description': 'Keep Brain Rot below 20% for 3 days',
      'condition': 'currentStreak >= 3 && currentBrainRotScore < 20',
    },
    {
      'id': 'digital_warrior',
      'name': 'Digital Warrior',
      'description': 'Join 3 Group Challenges',
      'condition': 'challengesJoined >= 3',
    },
  ];

  Future<void> checkBadges(String uid) async {
    final user = await _userRepo.getUser(uid);
    if (user == null) return;

    List<String> newBadges = List.from(user.badges);
    bool updated = false;

    // Simplified badge logic for MVP
    if (user.points >= 1000 && !newBadges.contains('focus_master')) {
      newBadges.add('focus_master');
      updated = true;
    }

    if (user.currentStreak >= 7 && !newBadges.contains('digital_warrior')) {
      newBadges.add('digital_warrior');
      updated = true;
    }

    if (updated) {
      await _userRepo.updateUser(user.copyWith(badges: newBadges));
    }
  }

  int calculateLevel(int points) {
    return (points / 500).floor() + 1;
  }

  double calculateLevelProgress(int points) {
    return (points % 500) / 500;
  }
}
