import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/badge_repository.dart';
import 'badge_card.dart';

class AchievementsSection extends ConsumerWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(badgesStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Row(
              children: [
                achievementsAsync.when(
                  data: (badges) {
                    final unlockedCount =
                        badges.where((b) => b.isUnlocked).length;
                    return Text(
                      '$unlockedCount / ${badges.length} Unlocked',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 210,
          child: achievementsAsync.when(
            data: (badges) {
              if (badges.isEmpty) {
                return const Center(child: Text('No badges available yet.'));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: badges.length,
                padding: const EdgeInsets.only(right: 16),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: BadgeCard(badge: badges[index]),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}
