import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';
import '../../data/admin_logger.dart';

final usersFutureProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).getAllUsers();
});

class UserManagementView extends ConsumerStatefulWidget {
  const UserManagementView({super.key});

  @override
  ConsumerState<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends ConsumerState<UserManagementView> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersFutureProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: TextField(
            onChanged: (val) => setState(() => searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by Email or Name...',
              prefixIcon: const Icon(LucideIcons.search),
              fillColor: AppTheme.surface,
              filled: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: usersAsync.when(
            data: (users) {
              final filtered = users.where((u) {
                final email = (u['email'] ?? '').toString().toLowerCase();
                final name = (u['displayName'] ?? '').toString().toLowerCase();
                return email.contains(searchQuery.toLowerCase()) ||
                    name.contains(searchQuery.toLowerCase());
              }).toList();

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = filtered[index];
                  return _UserCard(user: user);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class _UserCard extends ConsumerWidget {
  final Map<String, dynamic> user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text(
                  (user['displayName'] ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['displayName'] ?? 'Unknown User',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(user['email'] ?? 'No Email',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.moreHorizontal,
                    color: AppTheme.textSecondary),
                onPressed: () => _showUserOptions(context, user, ref),
              ),
              if (user['isRestricted'] == true)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(LucideIcons.ban, color: AppTheme.error, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _UserStat(
                  label: 'Streak',
                  value: '${user['currentStreak'] ?? 0}d',
                  icon: LucideIcons.flame,
                  color: AppTheme.warning),
              _UserStat(
                  label: 'Activity',
                  value: '${user['calculatedDailyActivity'] ?? 0}',
                  icon: LucideIcons.activity,
                  color: AppTheme.info),
              _UserStat(
                  label: 'Points',
                  value: '${user['calculatedDailyPoints'] ?? 0}',
                  icon: LucideIcons.gem,
                  color: AppTheme.success),
            ],
          ),
        ],
      ),
    );
  }

  void _showUserOptions(
      BuildContext context, Map<String, dynamic> user, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                  user['isRestricted'] == true
                      ? LucideIcons.unlock
                      : LucideIcons.ban,
                  color: AppTheme.warning),
              title: Text(user['isRestricted'] == true
                  ? 'Remove Restriction'
                  : 'Restrict User'),
              onTap: () async {
                final restrict = !(user['isRestricted'] == true);
                await ref
                    .read(adminRepositoryProvider)
                    .toggleUserRestriction(user['uid'], restrict);
                AdminLogger.logAction(
                    restrict ? 'Restricted User' : 'Unrestricted User',
                    metadata: {'uid': user['uid']});
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(usersFutureProvider);
                }
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: AppTheme.error),
              title: const Text('Delete User Account'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    title: const Text('Delete User?'),
                    content: const Text(
                        'This will permanently delete the user data from Firestore. This action cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await ref
                      .read(adminRepositoryProvider)
                      .deleteUserAccount(user['uid']);
                  AdminLogger.logAction('Deleted User Account',
                      metadata: {'uid': user['uid']});
                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(usersFutureProvider);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UserStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _UserStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}
