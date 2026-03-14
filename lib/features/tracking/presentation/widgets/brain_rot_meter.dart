import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/gamification/data/streak_controller.dart';
import '../../domain/daily_stats_provider.dart';

class BrainRotMeterWidget extends ConsumerStatefulWidget {
  final int score; // 0 to 100

  const BrainRotMeterWidget({super.key, required this.score});

  @override
  ConsumerState<BrainRotMeterWidget> createState() =>
      _BrainRotMeterWidgetState();
}

class _BrainRotMeterWidgetState extends ConsumerState<BrainRotMeterWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _countController;
  late Animation<int> _countAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _setupCountAnimation();
    _countController.forward();
  }

  void _setupCountAnimation() {
    _countAnimation = IntTween(
      begin: 0,
      end: widget.score,
    ).animate(
      CurvedAnimation(
        parent: _countController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(BrainRotMeterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _setupCountAnimation();
      _countController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streakUser = ref.watch(streakControllerProvider);
    final dailyStatsAsync = ref.watch(dailyStatsProvider);
    final currentStreak = streakUser?.currentStreak ?? 0;

    Color meterColor;
    String statusText;

    if (widget.score < 40) {
      meterColor = AppTheme.success;
      statusText = "Healthy";
    } else if (widget.score < 70) {
      meterColor = AppTheme.warning;
      statusText = "Caution";
    } else {
      meterColor = AppTheme.error;
      statusText = "Danger";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: meterColor.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceHighlight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bubble_chart,
                        size: 20,
                        color: AppTheme.primaryVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Brain Rot Meter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: meterColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: meterColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                return SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _LiquidPainter(
                      progress: widget.score / 100,
                      wavePhase: _waveController.value * 2 * pi,
                      particlePhase: _waveController.value,
                      color: meterColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _countAnimation,
              builder: (context, _) {
                return Text(
                  '${_countAnimation.value}',
                  style: TextStyle(
                    fontFamily: 'MontserratAlt',
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: meterColor,
                    letterSpacing: 1.5,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Mini Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(
                  label: 'Current Streak',
                  value: '$currentStreak days',
                  icon: Icons.local_fire_department,
                  color: AppTheme.warning,
                ),
                dailyStatsAsync.when(
                  data: (stats) => _MiniStat(
                    label: 'Mind Resets',
                    value: (stats['resets'] ?? 0).toString(),
                    icon: Icons.emoji_events,
                    color: AppTheme.success,
                  ),
                  loading: () => const _MiniStat(
                    label: 'Mind Resets',
                    value: '...',
                    icon: Icons.emoji_events,
                    color: AppTheme.success,
                  ),
                  error: (_, __) => const _MiniStat(
                    label: 'Mind Resets',
                    value: '!',
                    icon: Icons.emoji_events,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighlight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final double particlePhase;
  final Color color;

  _LiquidPainter({
    required this.progress,
    required this.wavePhase,
    required this.particlePhase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);

    // OUTER GLOW
    final glowPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);

    canvas.drawCircle(center, radius - 4, glowPaint);

    // BORDER
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.white24;

    canvas.drawCircle(center, radius - 3, borderPaint);

    // CLIP
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius - 6));

    canvas.save();
    canvas.clipPath(clipPath);

    // LIQUID WAVE
    const waveHeight = 14.0;
    final baseHeight = size.height * (1 - progress);

    final wavePath = Path()..moveTo(0, baseHeight);

    for (double x = 0; x <= size.width; x++) {
      final y =
          waveHeight * sin((x / size.width * 2 * pi) + wavePhase) + baseHeight;
      wavePath.lineTo(x, y);
    }

    wavePath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final liquidPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.95),
          color.withOpacity(0.75),
          color.withOpacity(0.6),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(wavePath, liquidPaint);

    // PARTICLES
    final particlePaint = Paint()..color = Colors.white.withOpacity(0.35);

    final random = Random(1);
    for (int i = 0; i < 18; i++) {
      final x = random.nextDouble() * size.width;
      final speed = 0.15 + random.nextDouble() * 0.3;

      final y = baseHeight +
          size.height *
              (1 - ((particlePhase * speed + random.nextDouble()) % 1));

      if (y > baseHeight) {
        canvas.drawCircle(
          Offset(x, y),
          1.5 + random.nextDouble() * 2,
          particlePaint,
        );
      }
    }

    // GLASS REFLECTION
    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final reflectionPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(
            center.dx - radius * 0.25,
            center.dy - radius * 0.35,
          ),
          radius: radius * 0.9,
        ),
      );

    canvas.drawPath(reflectionPath, reflectionPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) => true;
}
