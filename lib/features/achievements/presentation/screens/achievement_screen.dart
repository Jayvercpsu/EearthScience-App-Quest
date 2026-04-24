import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/badge_card.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../providers/achievement_providers.dart';

class AchievementScreen extends ConsumerWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements & Badges')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: achievementsAsync.when(
            data: (items) => ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = items[index];
                return BadgeCard(
                  title: item.title,
                  description: '${item.description} (+${item.rewardXp} XP)',
                  icon: item.badgeIcon,
                  unlocked: item.unlocked,
                );
              },
            ),
            loading: () => const LoadingWidget(label: 'Loading badges...'),
            error: (_, __) =>
                const Center(child: Text('Unable to load achievements')),
          ),
        ),
      ),
    );
  }
}
