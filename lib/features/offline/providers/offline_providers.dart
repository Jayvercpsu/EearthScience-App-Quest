import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lessons/data/models/lesson.dart';
import '../../lessons/providers/lesson_providers.dart';
import '../../progress/data/models/progress.dart';
import '../../quiz/data/models/quiz.dart';
import '../../quiz/providers/quiz_providers.dart';
import '../data/repositories/offline_session_repository.dart';

final offlineSessionRepositoryProvider = Provider<OfflineSessionRepository>((
  ref,
) {
  return OfflineSessionRepository();
});

final offlineNicknameProvider = FutureProvider<String?>((ref) async {
  return ref.read(offlineSessionRepositoryProvider).loadNickname();
});

final offlineLessonsProvider = FutureProvider<List<Lesson>>((ref) {
  return ref.read(lessonRepositoryProvider).fetchOfflineSyncedLessons();
});

final offlineQuizzesProvider = FutureProvider<List<Quiz>>((ref) {
  return ref.read(quizRepositoryProvider).fetchOfflineSyncedQuizzes();
});

final offlineQuizByLessonProvider = FutureProvider.family<Quiz?, String>((
  ref,
  lessonId,
) async {
  final quizzes = await ref.watch(offlineQuizzesProvider.future);
  for (final quiz in quizzes) {
    if (quiz.lessonId == lessonId) {
      return quiz;
    }
  }
  return null;
});

final offlineProgressProvider = FutureProvider<LearnerProgress>((ref) async {
  final nickname = await ref.watch(offlineNicknameProvider.future);
  final safe = (nickname?.trim().isNotEmpty ?? false)
      ? nickname!.trim()
      : 'Guest';
  return ref.read(offlineSessionRepositoryProvider).loadProgress(safe);
});
