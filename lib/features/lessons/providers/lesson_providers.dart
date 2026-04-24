import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/lesson.dart';
import '../data/repositories/lesson_repository.dart';

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepository();
});

final lessonsProvider = FutureProvider<List<Lesson>>((ref) {
  return ref.read(lessonRepositoryProvider).fetchLessons();
});

final lessonsStreamProvider = StreamProvider<List<Lesson>>((ref) {
  return ref.read(lessonRepositoryProvider).streamLessons();
});

final lessonByIdProvider = FutureProvider.family<Lesson?, String>((
  ref,
  lessonId,
) {
  return ref.read(lessonRepositoryProvider).getLessonById(lessonId);
});

final lessonSearchProvider = StateProvider<String>((ref) => '');
final lessonFilterProvider = StateProvider<String>((ref) => 'All');
