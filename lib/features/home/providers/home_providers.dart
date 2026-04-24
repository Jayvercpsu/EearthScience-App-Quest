import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../achievements/providers/achievement_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../challenges/providers/challenge_providers.dart';
import '../../progress/providers/progress_providers.dart';

final homeGreetingProvider = FutureProvider<String>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  final name = user?.name ?? 'Learner';
  final firstName = name.split(' ').first;
  return 'Keep exploring, $firstName';
});

final dashboardSummaryProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  final progress = await ref.watch(learnerProgressProvider.future);
  final challenges = await ref.watch(challengesProvider.future);
  final achievements = await ref.watch(achievementsProvider.future);

  return {
    'xp': user?.xp ?? 120,
    'level': user?.level ?? 2,
    'streak': user?.streak ?? 3,
    'mastery': progress.masteryPercentage,
    'vocabulary': progress.vocabularyProgress,
    'conceptual': progress.conceptualProgress,
    'challengeCount': challenges.length,
    'badgeCount': achievements.where((badge) => badge.unlocked).length,
  };
});
