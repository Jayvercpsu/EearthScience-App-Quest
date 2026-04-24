import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lessons/data/models/lesson.dart';
import '../../quiz/data/models/quiz.dart';
import '../data/models/lesson_exemplar.dart';
import '../data/models/student_performance_snapshot.dart';
import '../data/repositories/teacher_repository.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository();
});

final teacherSnapshotsProvider =
    FutureProvider<List<StudentPerformanceSnapshot>>((ref) {
      return ref.read(teacherRepositoryProvider).fetchStudentSnapshots();
    });

final lessonExemplarsProvider = FutureProvider<List<LessonExemplar>>((ref) {
  return ref.read(teacherRepositoryProvider).fetchExemplars();
});

final teacherActionProvider =
    StateNotifierProvider<TeacherActionController, AsyncValue<void>>(
      (ref) => TeacherActionController(ref.read(teacherRepositoryProvider)),
    );

class TeacherActionController extends StateNotifier<AsyncValue<void>> {
  TeacherActionController(this._repository)
    : super(const AsyncValue.data(null));

  final TeacherRepository _repository;

  Future<void> saveLesson(Lesson lesson) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.upsertLesson(lesson));
  }

  Future<void> saveQuiz(Quiz quiz) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.upsertQuiz(quiz));
  }

  Future<void> saveExemplar(LessonExemplar exemplar) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.saveExemplar(exemplar));
  }

  Future<void> deleteExemplar(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deleteExemplar(id));
  }
}
