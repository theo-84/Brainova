import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/admin_overview_view.dart';
import 'widgets/challenge_management_view.dart';
import 'widgets/user_management_view.dart';
import 'widgets/analytics_reports_view.dart';
import 'widgets/badge_management_view.dart';
import 'widgets/app_settings_view.dart';

final adminViewProvider = StateProvider<int>((ref) => 0);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedView = ref.watch(adminViewProvider);

    final List<Widget> views = [
      const AdminOverviewView(),
      const ChallengeManagementView(),
      const UserManagementView(),
      const AnalyticsReportsView(),
      const BadgeManagementView(),
      const AppSettingsView(),
    ];

    final List<String> titles = [
      'Dashboard Overview',
      'Challenge Management',
      'User Management',
      'Analytics & Reports',
      'Badge Management',
      'Brainova Information Center',
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          titles[selectedView],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () => context.go('/home'),
            tooltip: 'Exit Admin',
          ),
          if (selectedView != 0)
            IconButton(
              icon: const Icon(LucideIcons.layoutDashboard),
              onPressed: () => ref.read(adminViewProvider.notifier).state = 0,
              tooltip: 'Back to Overview',
            ),
        ],
      ),
      body: SafeArea(
        child: views[selectedView],
      ),
      bottomNavigationBar: _AdminMiniNav(selectedView: selectedView),
    );
  }
}

class _AdminMiniNav extends ConsumerWidget {
  final int selectedView;
  const _AdminMiniNav({required this.selectedView});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
              child: _NavIcon(
                  index: 0, icon: LucideIcons.layoutDashboard, label: 'Home')),
          Expanded(
              child: _NavIcon(
                  index: 1, icon: LucideIcons.trophy, label: 'Challenges')),
          Expanded(
              child:
                  _NavIcon(index: 2, icon: LucideIcons.users, label: 'Users')),
          Expanded(
              child: _NavIcon(
                  index: 3, icon: LucideIcons.barChart, label: 'Stats')),
          Expanded(
              child:
                  _NavIcon(index: 4, icon: LucideIcons.award, label: 'Badges')),
          Expanded(
              child: _NavIcon(index: 5, icon: LucideIcons.info, label: 'Info')),
        ],
      ),
    );
  }
}

class _NavIcon extends ConsumerWidget {
  final int index;
  final IconData icon;
  final String label;

  const _NavIcon(
      {required this.index, required this.icon, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(adminViewProvider);
    final isSelected = current == index;

    return GestureDetector(
      onTap: () => ref.read(adminViewProvider.notifier).state = index,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
