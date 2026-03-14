import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

final adminAnalyticsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.read(adminRepositoryProvider).watchAnalyticsSummary();
});

class AnalyticsReportsView extends ConsumerWidget {
  const AnalyticsReportsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);

    return analyticsAsync.when(
      data: (data) {
        final dietData = Map<String, double>.from(data['contentDiet']);
        final weeklyTrend = List<double>.from(data['weeklyBrainRot']);
        final weeklyDays = List<String>.from(
            data['weeklyDays'] ?? ['M', 'T', 'W', 'T', 'F', 'S', 'S']);

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(adminAnalyticsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'In-Depth Analytics',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 24),
                _ReportCard(
                  title: 'Content Diet Distribution',
                  subtitle: 'User engagement by category (Today)',
                  chart: _PieChart(data: dietData),
                ),
                const SizedBox(height: 24),
                _ReportCard(
                  title: 'Brain Rot Distribution',
                  subtitle: 'Weekly average per day',
                  chart: Container(
                    height: 200,
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 24),
                    child: CustomPaint(
                      painter: _UsageBarPainter(
                        data: weeklyTrend,
                        days: weeklyDays,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SimpleMetricRow(
                  label: 'Most Used Mind Reset:',
                  value: data['mostUsedReset'] ?? 'None',
                  icon: Icons.auto_awesome,
                ),
                const SizedBox(height: 12),
                _SimpleMetricRow(
                  label: 'Top Active Challenge:',
                  value: data['topChallenge'] ?? 'None',
                  icon: Icons.bolt,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget chart;

  const _ReportCard(
      {required this.title, required this.subtitle, required this.chart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(subtitle,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          chart,
        ],
      ),
    );
  }
}

class _SimpleMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SimpleMetricRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighlight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  final Map<String, double> data;
  const _PieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(painter: _PieChartPainter(data)),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.entries
                .map((e) => _LegendItem(label: e.key, color: _getColor(e.key)))
                .toList(),
          ),
        ),
      ],
    );
  }

  Color _getColor(String label) {
    switch (label) {
      case 'Social':
        return AppTheme.error;
      case 'Learning':
        return AppTheme.success;
      case 'Entertainment':
        return AppTheme.warning;
      case 'Junk':
        return Colors.deepPurple;
      case 'Neutral':
        return AppTheme.info;
      case 'Other':
      default:
        return AppTheme.primary;
    }
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  _PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final double total = data.values.fold(0, (a, b) => a + b);
    double startAngle = -pi / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    data.forEach((label, value) {
      final sweepAngle = (value / total) * 2 * pi;
      paint.color = _getColor(label);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 10),
          startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    });
  }

  Color _getColor(String label) {
    switch (label) {
      case 'Social':
        return AppTheme.error;
      case 'Learning':
        return AppTheme.success;
      case 'Entertainment':
        return AppTheme.warning;
      case 'Junk':
        return Colors.deepPurple;
      case 'Neutral':
        return AppTheme.info;
      default:
        return AppTheme.primary;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UsageBarPainter extends CustomPainter {
  final List<double> data;
  final List<String> days;
  _UsageBarPainter({required this.data, required this.days});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce(max);
    final barWidth = size.width / data.length * 0.6;
    final spacing = size.width / data.length * 0.4;

    final paint = Paint()
      ..color = AppTheme.primary.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < data.length; i++) {
      final h = maxVal > 0 ? (data[i] / maxVal) * (size.height - 30) : 0.0;
      final x = i * (barWidth + spacing) + spacing / 2;

      final rect = Rect.fromLTWH(x, size.height - 25 - h, barWidth, h);
      canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
          ),
          paint);

      // Draw top highlight line
      canvas.drawLine(
        Offset(x, size.height - 25 - h + 1),
        Offset(x + barWidth, size.height - 25 - h + 1),
        highlightPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
            text: days[i],
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas,
          Offset(x + barWidth / 2 - textPainter.width / 2, size.height - 15));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
