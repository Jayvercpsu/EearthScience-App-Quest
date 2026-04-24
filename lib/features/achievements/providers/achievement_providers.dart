import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/achievement.dart';
import '../data/repositories/achievement_repository.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository();
});

final achievementsProvider = FutureProvider<List<Achievement>>((ref) {
  return ref.read(achievementRepositoryProvider).fetchAchievements();
});
