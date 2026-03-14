import 'package:flutter/material.dart';

enum MindResetType { breathing, audio, stretch, journaling, meditation }

class MindResetActivity {
  final String id;
  final String title;
  final String description;
  final MindResetType type;
  final int durationSeconds;
  final String assetPath;
  final int pointsReward;
  final List<String> steps;
  final String? audioUrl;
  final Gradient? cardGradient;

  MindResetActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.durationSeconds,
    required this.assetPath,
    this.pointsReward = 15,
    this.steps = const [],
    this.audioUrl,
    this.cardGradient,
  });
}
