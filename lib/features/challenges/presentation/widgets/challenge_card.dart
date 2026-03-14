import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/challenge_model.dart';
import '../providers/challenge_provider.dart';

class ChallengeCard extends ConsumerWidget {
  final Challenge challenge;
  const ChallengeCard({super.key, required this.challenge});

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  double _progress(Duration remaining) {
    final totalSeconds = challenge.duration * 24 * 60 * 60;
    final rem = remaining.inSeconds.clamp(0, totalSeconds);
    final completed = totalSeconds - rem;
    return (completed / totalSeconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeId = challenge.id;

    final state = ref.watch(challengeControllerProvider(challengeId));
    final controller =
        ref.read(challengeControllerProvider(challengeId).notifier);

    final joined = state.joined;
    final isCompleted = state.isCompleted;
    final remaining = state.remaining;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            challenge.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${challenge.duration} Days • ${challenge.description}",
            style: const TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (joined) ...[
            SizedBox(
              height: 160,
              width: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(160, 160),
                    painter: _CirclePainter(
                      _progress(remaining),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isCompleted ? "DONE" : _format(remaining),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${(_progress(remaining) * 100).toInt()}% Done",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_alt,
                      size: 18, color: Colors.orangeAccent),
                  const SizedBox(width: 8),
                  Text(
                    "🔥 ${state.participants} People Joined",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: state.loading
                      ? null
                      : (joined
                          ? null
                          : () => controller
                              .join(Duration(days: challenge.duration))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: joined
                        ? Colors.white.withOpacity(0.1)
                        : AppTheme.primary,
                    foregroundColor: joined ? Colors.white70 : Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    !joined
                        ? "Join Challenge"
                        : isCompleted
                            ? "Completed"
                            : "Challenge Active",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (joined && !isCompleted) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: state.loading
                        ? null
                        : () => _showLeaveConfirmation(context, controller),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text(
                      "Leave Challenge",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmation(
      BuildContext context, ChallengeController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Leave Challenge",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to leave the challenge?",
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.leave();
            },
            child:
                const Text("Leave", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;

  _CirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.primary, Color(0xFF9D50BB)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
