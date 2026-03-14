import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';
import '../../data/admin_logger.dart';

class ChallengeManagementView extends ConsumerWidget {
  const ChallengeManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesStreamProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Challenges',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              ElevatedButton.icon(
                onPressed: () => showChallengeDialog(context, ref),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('New Challenge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: challengesAsync.when(
            data: (challenges) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                return _ChallengeItem(challenge: challenge);
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  static void showChallengeDialog(BuildContext context, WidgetRef ref,
      [Map<String, dynamic>? challenge]) {
    final titleController = TextEditingController(text: challenge?['title']);
    final descController =
        TextEditingController(text: challenge?['description']);
    final durationController =
        TextEditingController(text: challenge?['duration']?.toString());
    final pointsController =
        TextEditingController(text: challenge?['points']?.toString());
    DateTime startDate =
        (challenge?['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    DateTime endDate = (challenge?['endDate'] as Timestamp?)?.toDate() ??
        DateTime.now().add(const Duration(days: 7));
    String selectedCategory = challenge?['category'] ?? 'General';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title:
              Text(challenge == null ? 'Create Challenge' : 'Edit Challenge'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 16),
                TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(startDate.toString().split(' ')[0]),
                  trailing: const Icon(LucideIcons.calendar),
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030));
                    if (picked != null) {
                      setState(() => startDate = picked);
                    }
                  },
                ),
                ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(endDate.toString().split(' ')[0]),
                  trailing: const Icon(LucideIcons.calendar),
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030));
                    if (picked != null) {
                      setState(() => endDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                    controller: durationController,
                    decoration:
                        const InputDecoration(labelText: 'Duration (Days)'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                TextField(
                    controller: pointsController,
                    decoration:
                        const InputDecoration(labelText: 'Points Reward'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  dropdownColor: AppTheme.surface,
                  items:
                      ['Dopamine Fast', 'Mental Reset', 'Physical', 'General']
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary)),
                              ))
                          .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedCategory = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'title': titleController.text,
                  'description': descController.text,
                  'duration': int.tryParse(durationController.text) ?? 7,
                  'points': int.tryParse(pointsController.text) ?? 50,
                  'startDate': Timestamp.fromDate(startDate),
                  'endDate': Timestamp.fromDate(endDate),
                  'category': selectedCategory,
                  'isActive': challenge?['isActive'] ?? true,
                };

                if (challenge == null) {
                  await ref.read(adminRepositoryProvider).addChallenge(data);
                  AdminLogger.logAction('Created Challenge',
                      metadata: {'title': data['title']});
                } else {
                  await ref
                      .read(adminRepositoryProvider)
                      .updateChallenge(challenge['id'], data);
                  AdminLogger.logAction('Updated Challenge',
                      metadata: {'id': challenge['id']});
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeItem extends ConsumerWidget {
  final Map<String, dynamic> challenge;
  const _ChallengeItem({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surfaceHighlight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(challenge['title'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${challenge['duration']} Days • ${challenge['points']} Points',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: challenge['isActive'] ?? true,
              onChanged: (val) {
                ref
                    .read(adminRepositoryProvider)
                    .updateChallenge(challenge['id'], {'isActive': val});
              },
              activeThumbColor: AppTheme.primary,
            ),
            IconButton(
              icon: const Icon(LucideIcons.edit2,
                  color: AppTheme.primary, size: 20),
              onPressed: () => ChallengeManagementView.showChallengeDialog(
                  context, ref, challenge),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2,
                  color: AppTheme.error, size: 20),
              onPressed: () {
                ref
                    .read(adminRepositoryProvider)
                    .deleteChallenge(challenge['id']);
                AdminLogger.logAction('Deleted Challenge',
                    metadata: {'id': challenge['id']});
              },
            ),
          ],
        ),
      ),
    );
  }
}

final challengesStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(adminRepositoryProvider).watchChallenges();
});
