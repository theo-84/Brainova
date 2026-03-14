import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/badge_service.dart';

class BadgeUnlockCelebration extends ConsumerStatefulWidget {
  const BadgeUnlockCelebration({super.key});

  @override
  ConsumerState<BadgeUnlockCelebration> createState() =>
      _BadgeUnlockCelebrationState();
}

class _BadgeUnlockCelebrationState
    extends ConsumerState<BadgeUnlockCelebration> {
  String? _lastShownBadgeId;

  @override
  Widget build(BuildContext context) {
    final lastBadge = ref.watch(lastUnlockedBadgeProvider);

    if (lastBadge != null) {
      print(
          'DEBUG: BadgeUnlockCelebration built with badge: ${lastBadge.title}');
    }

    if (lastBadge == null) {
      _lastShownBadgeId = null;
      return const SizedBox.shrink();
    }

    if (_lastShownBadgeId != lastBadge.id) {
      _lastShownBadgeId = lastBadge.id;
      HapticFeedback.heavyImpact();
    }

    return Stack(
      children: [
        // Full screen particles/confetti
        Positioned.fill(
          child: CustomPaint(
            painter: ConfettiPainter(),
          ),
        ).animate().fadeIn(),

        Material(
          color: Colors.black.withOpacity(0.85),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Burst effect background
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.4),
                              blurRadius: 100,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.2, 1.2),
                              duration: 2.seconds)
                          .blurXY(begin: 20, end: 40),

                      // The Badge Icon
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.medal,
                          size: 100,
                          color: Colors.white,
                        ),
                      )
                          .animate()
                          .scale(
                            duration: 800.ms,
                            curve: Curves.elasticOut,
                          )
                          .rotate(begin: -0.1, end: 0, duration: 800.ms),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // "NEW ACHIEVEMENT" Text with Sparkle
                  const Text(
                    'NEW ACHIEVEMENT',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                  const SizedBox(height: 16),

                  // Badge Title with Shimmer
                  Text(
                    lastBadge.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 600.ms)
                      .scale(begin: const Offset(0.9, 0.9))
                      .shimmer(duration: 2.seconds),

                  const SizedBox(height: 16),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      lastBadge.description,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.8),
                        fontSize: 18,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 60),

                  // Action Button
                  ElevatedButton(
                    onPressed: () {
                      ref.read(badgeServiceProvider).dismissCelebration();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 60, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 10,
                      shadowColor: AppTheme.primary.withOpacity(0.4),
                    ),
                    child: const Text(
                      'AWESOME!',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                  ).animate().fadeIn(delay: 1.seconds).scale(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final List<Particle> particles = List.generate(50, (index) => Particle());
  final double randomValue = Random().nextDouble();

  @override
  void paint(Canvas canvas, Size size) {
    // This is a simplified static-frame confetti for demonstration
    // In a real app, you'd want this to be animated over time
    final random = Random(42);
    for (int i = 0; i < 60; i++) {
      final paint = Paint()
        ..color = [
          Colors.blue,
          Colors.purple,
          Colors.amber,
          Colors.pink,
          Colors.green
        ][random.nextInt(5)]
            .withOpacity(0.6);

      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 8 + 2;

      if (random.nextBool()) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      } else {
        canvas.drawRect(Rect.fromLTWH(x, y, radius * 2, radius * 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class Particle {
  double x = 0, y = 0, size = 0;
  Color color = Colors.white;
}
