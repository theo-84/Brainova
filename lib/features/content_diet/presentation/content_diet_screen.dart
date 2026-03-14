import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../data/content_diet_repository.dart';
import '../data/content_diet_model.dart';
import '../../auth/data/auth_providers.dart';
import '../../reality_check/domain/reality_check_service.dart';
import '../../tracking/data/activity_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ContentDietScreen extends ConsumerStatefulWidget {
  const ContentDietScreen({super.key});

  @override
  ConsumerState<ContentDietScreen> createState() => _ContentDietScreenState();
}

class _ContentDietScreenState extends ConsumerState<ContentDietScreen> {
  final _minutesController = TextEditingController();
  final _notesController = TextEditingController();
  DietCategory _selectedCategory = DietCategory.learning;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _minutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addEntry() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null || _minutesController.text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final entry = ContentDietEntry(
        id: '',
        uid: user.uid,
        date: DateTime.now(),
        category: _selectedCategory,
        minutes: int.parse(_minutesController.text),
        notes: _notesController.text,
      );

      await ref.read(contentDietRepositoryProvider).addEntry(entry);

      _minutesController.clear();
      _notesController.clear();
      ref.invalidate(recentDietEntriesProvider);
      ref.invalidate(weeklyBreakdownProvider(user.uid));
      ref.invalidate(realityCheckProvider(user.uid));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry Added!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentEntriesAsync = ref.watch(recentDietEntriesProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;
    final weeklyBreakdownAsync =
        user != null ? ref.watch(weeklyBreakdownProvider(user.uid)) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Content'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (weeklyBreakdownAsync != null)
                weeklyBreakdownAsync.when(
                  data: (data) => _WeeklySummaryCard(data)
                      .animate()
                      .fadeIn()
                      .scale(begin: const Offset(0.9, 0.9)),
                  loading: () => Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                ),
              const SizedBox(height: 24),
              Text(
                "How did you spend your time?",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildInputForm(),
              const SizedBox(height: 32),
              Text(
                'Recent Logs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              recentEntriesAsync.when(
                data: (entries) {
                  if (entries.isEmpty) return const Text('No entries yet.');
                  return Column(
                    children: entries.map((e) => _EntryCard(entry: e)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error loading history: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputForm() {
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DietCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getColorForCategory(cat)
                          : AppTheme.surfaceHighlight,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getIcon(cat),
                          size: 20,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _minutesController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              prefixIcon: Icon(LucideIcons.clock),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              prefixIcon: Icon(LucideIcons.fileText),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _addEntry,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text('Save Entry'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForCategory(DietCategory cat) {
    switch (cat) {
      case DietCategory.learning:
        return const Color(0xFF00E676);
      case DietCategory.entertainment:
        return const Color(0xFF2196F3);
      case DietCategory.junk:
        return const Color(0xFFFF5252);
      case DietCategory.social:
        return const Color(0xFF7C4DFF);
    }
  }

  IconData _getIcon(DietCategory cat) {
    switch (cat) {
      case DietCategory.learning:
        return LucideIcons.bookOpen;
      case DietCategory.entertainment:
        return LucideIcons.tv;
      case DietCategory.junk:
        return LucideIcons.trash2;
      case DietCategory.social:
        return LucideIcons.share2;
    }
  }
}

class _EntryCard extends StatelessWidget {
  final ContentDietEntry entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getColor(entry.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIcon(entry.category),
              color: _getColor(entry.category),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.minutes} min - ${entry.category.name.toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (entry.notes != null && entry.notes!.isNotEmpty)
                  Text(
                    entry.notes!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            '${entry.date.day}/${entry.date.month}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getColor(DietCategory cat) {
    switch (cat) {
      case DietCategory.learning:
        return const Color(0xFF00E676);
      case DietCategory.entertainment:
        return const Color(0xFF2196F3);
      case DietCategory.junk:
        return const Color(0xFFFF5252);
      case DietCategory.social:
        return const Color(0xFF7C4DFF);
    }
  }

  IconData _getIcon(DietCategory cat) {
    switch (cat) {
      case DietCategory.learning:
        return LucideIcons.bookOpen;
      case DietCategory.entertainment:
        return LucideIcons.tv;
      case DietCategory.junk:
        return LucideIcons.trash2;
      case DietCategory.social:
        return LucideIcons.share2;
    }
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final Map<ActivityType, double> data;
  const _WeeklySummaryCard(this.data);

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = data.isEmpty;

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF52AF), Color(0xFF9F7AEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF52AF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text('Weekly Summary',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                    Icon(LucideIcons.barChart2, color: Colors.white, size: 18),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  height: 90,
                  width: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(100, 100),
                        painter: PieChartPainter(data: data),
                      ),
                      if (isEmpty)
                        const Text(
                          "No Data",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <ActivityType>[
                ActivityType.learning,
                ActivityType.entertainment,
                ActivityType.junk,
                ActivityType.social,
              ].map((type) {
                final percentage = (data[type] ?? 0) * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: _getLabelColor(type),
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${_getLabelText(type)} ${percentage.toStringAsFixed(0)}%",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getLabelText(ActivityType type) {
    switch (type) {
      case ActivityType.learning:
        return "Learning";
      case ActivityType.entertainment:
        return "Entert.";
      case ActivityType.junk:
        return "Junk";
      case ActivityType.social:
        return "Social";
      default:
        return "";
    }
  }

  Color _getLabelColor(ActivityType type) {
    switch (type) {
      case ActivityType.learning:
        return const Color(0xFF00E676);
      case ActivityType.entertainment:
        return const Color(0xFF2196F3);
      case ActivityType.junk:
        return const Color(0xFFFF5252);
      case ActivityType.social:
        return const Color(0xFF7C4DFF);
      default:
        return Colors.grey;
    }
  }
}

class PieChartPainter extends CustomPainter {
  final Map<ActivityType, double> data;
  PieChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      final Paint bgPaint = Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
          Offset(size.width / 2, size.height / 2), size.width / 2, bgPaint);
      return;
    }

    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -3.14159 / 2;

    for (var entry in data.entries) {
      if (entry.value <= 0) continue;
      final double sweepAngle = 2 * 3.14159 * entry.value;

      final Paint paint = Paint()
        ..color = _getColor(entry.key)
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      startAngle += sweepAngle;
    }
  }

  Color _getColor(ActivityType type) {
    switch (type) {
      case ActivityType.learning:
        return const Color(0xFF00E676);
      case ActivityType.entertainment:
        return const Color(0xFF2196F3);
      case ActivityType.junk:
        return const Color(0xFFFF5252);
      case ActivityType.social:
        return const Color(0xFF7C4DFF);
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
