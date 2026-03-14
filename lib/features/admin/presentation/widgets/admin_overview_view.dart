import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';
import '../admin_dashboard_screen.dart';

final adminMetricsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return ref.read(adminRepositoryProvider).watchSystemMetrics();
});

class AdminOverviewView extends ConsumerWidget {
  const AdminOverviewView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminMetricsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(adminMetricsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Health',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 24),
            metricsAsync.when(
              data: (metrics) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _StatCard(
                        title: 'Total Users',
                        value: metrics['totalUsers'].toString(),
                        icon: LucideIcons.users,
                        color: AppTheme.primary,
                      ),
                      _StatCard(
                        title: 'Active Today',
                        value: metrics['activeToday'].toString(),
                        icon: LucideIcons.activity,
                        color: AppTheme.success,
                      ),
                      _StatCard(
                        title: 'Avg. Brain Rot',
                        value: '${metrics['avgBrainRot']}%',
                        icon: LucideIcons.brainCircuit,
                        color: AppTheme.warning,
                      ),
                      _StatCard(
                        title: 'Resets Done',
                        value: metrics['mindResetsCompleted'].toString(),
                        icon: LucideIcons.checkSquare,
                        color: AppTheme.pink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Management Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          title: 'Challenges',
                          icon: LucideIcons.trophy,
                          color: AppTheme.primary,
                          onTap: () =>
                              ref.read(adminViewProvider.notifier).state = 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          title: 'Users',
                          icon: LucideIcons.users,
                          color: AppTheme.success,
                          onTap: () =>
                              ref.read(adminViewProvider.notifier).state = 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          title: 'Badges',
                          icon: LucideIcons.award,
                          color: AppTheme.warning,
                          onTap: () =>
                              ref.read(adminViewProvider.notifier).state = 4,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          title: 'Settings',
                          icon: LucideIcons.settings,
                          color: AppTheme.textSecondary,
                          onTap: () =>
                              ref.read(adminViewProvider.notifier).state = 5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHighlight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
