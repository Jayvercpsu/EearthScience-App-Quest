import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/models/progress.dart';
import '../data/repositories/progress_repository.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository();
});

final learnerProgressProvider = FutureProvider<LearnerProgress>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  final userId = user?.uid ?? 'local_student';
  return ref.read(progressRepositoryProvider).getProgress(userId);
});
