import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'mind_reset_model.dart';

final mindResetRepositoryProvider = Provider<MindResetRepository>((ref) {
  return MindResetRepository();
});

class MindResetRepository {
  final List<MindResetActivity> _activities = [
    MindResetActivity(
      id: '1',
      title: 'Box Breathing',
      description:
          'A powerful breathing technique used to quickly calm the mind and reset your nervous system.',
      type: MindResetType.breathing,
      durationSeconds: 300,
      assetPath: 'assets/lottie/box_breathing.json',
      pointsReward: 15,
      cardGradient: AppTheme.healingGradient,
      steps: [
        'Inhale through your nose for 4 seconds.',
        'Hold your breath for 4 seconds.',
        'Exhale slowly for 4 seconds.',
        'Hold empty for 4 seconds. Repeat.',
      ],
    ),
    MindResetActivity(
      id: '2',
      title: 'Neck & Shoulder Reset',
      description:
          'Release tension in your neck and shoulders after long periods of screen time.',
      type: MindResetType.stretch,
      durationSeconds: 300,
      assetPath: 'assets/neck_stretch.json',
      pointsReward: 15,
      cardGradient: AppTheme.energyGradient,
      steps: [
        'Sit up straight, shoulders relaxed.',
        'Drop right ear to right shoulder. Hold 10s.',
        'Roll head forward to chest. Hold 10s.',
        'Drop left ear to left shoulder. Hold 10s.',
        'Roll both shoulders backward 5 times.',
        'Stretch arms above your head.',
      ],
    ),
    MindResetActivity(
      id: '3',
      title: 'Rain Sounds',
      description: 'Let the sound of rain wash away mental noise.',
      type: MindResetType.audio,
      durationSeconds: 300,
      assetPath: 'assets/audio/rain3.mp3',
      pointsReward: 15,
      cardGradient: const LinearGradient(
        colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      steps: [
        'Put on headphones.',
        'Close your eyes or soften your gaze.',
        'Let the sound fill your attention completely.',
        'Whenever your mind drifts, come back to the sound of the rain.'
      ],
    ),
    MindResetActivity(
      id: '4',
      title: 'Eye Workout',
      description:
          'Refresh tired eyes and reduce strain after long sessions of screen use.',
      type: MindResetType.stretch,
      durationSeconds: 300,
      assetPath: 'assets/images/eye_rest.png',
      pointsReward: 15,
      cardGradient: const LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      steps: [
        'Look up and hold 3s, look down and hold 3s. Repeat 3 times.',
        'Look right and hold 3s, look left and hold 3s. Repeat 3 times.',
        'Look top-left 3s, look top-right 3s. Repeat 3 times.',
        'Rotate eyeballs 3 times right, then 3 times left. Blink to relax.',
        'Close eyes tight and hold for 10 seconds. Relax.',
        'Open eyes wide and hold 10 seconds. Blink repeatedly to finish.',
      ],
    ),
    MindResetActivity(
      id: '5',
      title: 'Brain Dump',
      description:
          'Unload your thoughts onto paper to clear your mind and regain focus.',
      type: MindResetType.journaling,
      durationSeconds: 300,
      assetPath: 'assets/images/journal.png',
      pointsReward: 15,
      cardGradient: const LinearGradient(
        colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      steps: [
        'Open a notes app or grab paper.',
        'Write every thought, worry, or task.',
        'Do not filter or judge just write.',
        'Cross out things you cannot control.',
        'Circle the one thing that matters most.',
      ],
    ),
    MindResetActivity(
      id: '6',
      title: 'Digital Detox',
      description: 'Put your phone down and reconnect with reality.',
      type: MindResetType.meditation,
      durationSeconds: 300,
      assetPath: 'assets/lottie/digital_detox.json',
      pointsReward: 15,
      cardGradient: const LinearGradient(
        colors: [Color(0xFF1a1a2e), Color(0xFF2d1b69)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      steps: [
        'Put your phone face down and step away from the screen.',
        'Take a slow deep breath and relax your body.',
        'Look around and notice your surroundings.',
        'Focus on the present moment instead of your device.',
        'Enjoy a short break from digital stimulation.',
      ],
    ),
  ];

  Future<List<MindResetActivity>> getActivities() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _activities;
  }
}
