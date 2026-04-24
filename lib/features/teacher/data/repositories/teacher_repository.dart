import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_paths.dart';
import '../../../lessons/data/models/lesson.dart';
import '../../../quiz/data/models/quiz.dart';
import '../models/lesson_exemplar.dart';
import '../models/student_performance_snapshot.dart';

class TeacherRepository {
  TeacherRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  final List<StudentPerformanceSnapshot> _fallbackSnapshots = const [
    StudentPerformanceSnapshot(
      userId: 's1',
      studentName: 'Aira Santos',
      averageScore: 0.82,
      completedLessons: 6,
      vocabularyPerformance: 0.79,
      conceptualPerformance: 0.84,
      engagementLevel: 0.88,
    ),
    StudentPerformanceSnapshot(
      userId: 's2',
      studentName: 'Miguel Cruz',
      averageScore: 0.67,
      completedLessons: 4,
      vocabularyPerformance: 0.71,
      conceptualPerformance: 0.63,
      engagementLevel: 0.73,
    ),
  ];

  final List<LessonExemplar> _fallbackExemplars = [
    LessonExemplar(
      exemplarId: 'ex1',
      title: 'Plate Boundary Simulation Exemplar',
      topic: 'Plate Tectonics',
      objectives: [
        'Describe three major plate boundaries.',
        'Predict geologic events from boundary interactions.',
      ],
      teachingFlow:
          'Engage with map prompts, explore boundary simulations in-app, then run concept check and reflection.',
      linkedLessons: ['plate_tectonics'],
      recommendations:
          'Use peer explanation rounds after each quiz feedback section.',
    ),
  ];

  Future<List<StudentPerformanceSnapshot>> fetchStudentSnapshots() async {
    try {
      final progressSnapshot = await _firestore
          .collection(FirestorePaths.progress)
          .get();
      final userSnapshot = await _firestore
          .collection(FirestorePaths.users)
          .get();

      if (progressSnapshot.docs.isEmpty || userSnapshot.docs.isEmpty) {
        return _fallbackSnapshots;
      }

      final userMap = {
        for (final user in userSnapshot.docs)
          user.id: (user.data()['name'] as String? ?? 'Student'),
      };

      return progressSnapshot.docs.map((doc) {
        final map = doc.data();
        final quizScores =
            (map['quizScores'] as Map<String, dynamic>? ?? const {}).values
                .map((value) => (value as num).toDouble())
                .toList();

        final average = quizScores.isEmpty
            ? 0.0
            : quizScores.reduce((a, b) => a + b) / quizScores.length;

        return StudentPerformanceSnapshot(
          userId: doc.id,
          studentName: userMap[doc.id] ?? 'Student',
          averageScore: average,
          completedLessons:
              (map['completedLessons'] as List<dynamic>? ?? const []).length,
          vocabularyPerformance:
              (map['vocabularyProgress'] as num?)?.toDouble() ?? average,
          conceptualPerformance:
              (map['conceptualProgress'] as num?)?.toDouble() ?? average,
          engagementLevel:
              (((map['engagementStats'] as Map<String, dynamic>? ??
                              const {})['weeklySessions']
                          as num?) ??
                      0)
                  .toDouble() /
              7.0,
        );
      }).toList();
    } catch (_) {
      return _fallbackSnapshots;
    }
  }

  Future<List<LessonExemplar>> fetchExemplars() async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.lessonExemplars)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => LessonExemplar.fromMap(doc.data()))
            .toList();
      }
    } catch (_) {
      // fallback below
    }
    return _fallbackExemplars;
  }

  Future<void> saveExemplar(LessonExemplar exemplar) async {
    try {
      await _firestore
          .collection(FirestorePaths.lessonExemplars)
          .doc(exemplar.exemplarId)
          .set(exemplar.toMap());
      return;
    } catch (_) {
      final index = _fallbackExemplars.indexWhere(
        (e) => e.exemplarId == exemplar.exemplarId,
      );
      if (index >= 0) {
        _fallbackExemplars[index] = exemplar;
      } else {
        _fallbackExemplars.add(exemplar);
      }
    }
  }

  Future<void> deleteExemplar(String exemplarId) async {
    try {
      await _firestore
          .collection(FirestorePaths.lessonExemplars)
          .doc(exemplarId)
          .delete();
      return;
    } catch (_) {
      _fallbackExemplars.removeWhere((e) => e.exemplarId == exemplarId);
    }
  }

  Future<void> upsertLesson(Lesson lesson) async {
    try {
      await _firestore
          .collection(FirestorePaths.lessons)
          .doc(lesson.lessonId)
          .set(lesson.toMap());
    } catch (_) {
      // offline mode handled at lesson repository layer
    }
  }

  Future<void> upsertQuiz(Quiz quiz) async {
    try {
      await _firestore
          .collection(FirestorePaths.quizzes)
          .doc(quiz.quizId)
          .set(quiz.toMap());
    } catch (_) {
      // offline mode handled at quiz repository layer
    }
  }
}
