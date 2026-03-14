import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_providers.dart';
import '../../gamification/data/streak_controller.dart';
import '../../gamification/presentation/widgets/streak_widget.dart';
import '../../tracking/domain/daily_stats_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final streakUser = ref.watch(streakControllerProvider);
    final dailyStatsAsync = ref.watch(dailyStatsProvider);
    final currentStreak = streakUser?.currentStreak ?? 0;

    return SafeArea(
      child: userProfileAsync.when(
        data: (user) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // User Header
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHighlight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary, width: 2),
                      ),
                      child: _buildAvatarPlaceholder(user?.displayName),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? 'User',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'user@brainova.app',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    const StreakWidget(),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => ref
                          .read(streakControllerProvider.notifier)
                          .completeDailyTask(),
                      icon: const Icon(LucideIcons.checkCircle, size: 18),
                      label: const Text('Complete Daily Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Your Statistics
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your Statistics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: dailyStatsAsync.when(
                    data: (stats) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatColumn(
                          value: (stats['resets'] ?? 0).toString(),
                          label: 'Resets',
                          color: AppTheme.primary,
                          icon: LucideIcons.brainCircuit,
                        ),
                        _StatColumn(
                          value: currentStreak.toString(),
                          label: 'Day Streak',
                          color: AppTheme.warning,
                          icon: LucideIcons.flame,
                        ),
                        _StatColumn(
                          value: (stats['points'] ?? 0).toString(),
                          label: 'Points Today',
                          color: AppTheme.pink,
                          icon: LucideIcons.award,
                        ),
                        _StatColumn(
                          value: (stats['tasks'] ?? 0).toString(),
                          label: 'Tasks Done',
                          color: AppTheme.success,
                          icon: LucideIcons.checkSquare,
                        ),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),
                ),
                const SizedBox(height: 32),

                // Mood Tracker
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Track Your Daily Mood',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                const _MoodTracker(),
                const SizedBox(height: 32),

                // Settings Groups
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Account',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.user,
                        title: 'Personal Information',
                        onTap: () => context.push('/profile/personal-info'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'More',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: LucideIcons.shield,
                        title: 'Privacy & Security',
                        onTap: () => context.push('/profile/privacy'),
                      ),
                      const Divider(
                        height: 1,
                        indent: 60,
                        color: AppTheme.surfaceHighlight,
                      ),
                      _SettingsTile(
                        icon: LucideIcons.helpCircle,
                        title: 'Help & Support',
                        onTap: () => context.push('/profile/help'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(LucideIcons.logOut, color: AppTheme.error),
                  label: const Text('Sign Out',
                      style: TextStyle(color: AppTheme.error)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String? name) {
    return Center(
      child: Text(
        (name ?? 'U').substring(0, 1).toUpperCase(),
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHighlight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: const Icon(LucideIcons.chevronRight,
          color: AppTheme.textSecondary, size: 18),
      onTap: onTap,
    );
  }
}

class _MoodTracker extends StatefulWidget {
  const _MoodTracker();

  @override
  State<_MoodTracker> createState() => _MoodTrackerState();
}

class _MoodTrackerState extends State<_MoodTracker> {
  int? _selectedIndex;

  final List<IconData> _moods = [
    LucideIcons.frown,
    LucideIcons.meh,
    LucideIcons.smile,
    LucideIcons.laugh,
    LucideIcons.partyPopper,
  ];

  final List<Color> _colors = [
    AppTheme.error,
    Colors.orange,
    Colors.yellow,
    Colors.lightGreen,
    AppTheme.success,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_moods.length, (index) {
          final isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? _colors[index].withOpacity(0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: _colors[index], width: 2)
                    : null,
              ),
              child: Icon(
                _moods[index],
                color: isSelected ? _colors[index] : Colors.grey,
                size: 32,
              ),
            ),
          );
        }),
      ),
    );
  }
}
