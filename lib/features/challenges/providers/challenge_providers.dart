import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/challenge.dart';
import '../data/repositories/challenge_repository.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository();
});

final challengesProvider = FutureProvider<List<Challenge>>((ref) {
  return ref.read(challengeRepositoryProvider).fetchChallenges();
});
