import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_paths.dart';
import '../models/progress.dart';

class ProgressRepository {
  ProgressRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  LearnerProgress _fallbackProgress = const LearnerProgress(
    userId: 'local_student',
    completedLessons: ['earth_structure'],
    quizScores: {'earth_structure': 0.67, 'plate_tectonics': 0.33},
    masteryPercentage: 0.56,
    vocabularyProgress: 0.62,
    conceptualProgress: 0.51,
    engagementStats: {'dailyStreak': 3, 'activeDays': 10, 'weeklySessions': 5},
  );

  Future<LearnerProgress> getProgress(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.progress)
          .doc(userId)
          .get();
      if (doc.exists && doc.data() != null) {
        return LearnerProgress.fromMap(doc.data()!);
      }
    } catch (_) {
      // fallback below
    }

    return _fallbackProgress.copyWith(userId: userId);
  }

  Future<void> saveProgress(LearnerProgress progress) async {
    try {
      await _firestore
          .collection(FirestorePaths.progress)
          .doc(progress.userId)
          .set(progress.toMap());
      return;
    } catch (_) {
      _fallbackProgress = progress;
    }
  }

  Future<LearnerProgress> updateAfterQuiz({
    required String userId,
    required String lessonId,
    required double score,
  }) async {
    final current = await getProgress(userId);
    final updatedScores = Map<String, double>.from(current.quizScores)
      ..[lessonId] = score;

    final completed = [...current.completedLessons];
    if (!completed.contains(lessonId)) {
      completed.add(lessonId);
    }

    final average = updatedScores.values.isEmpty
        ? 0.0
        : updatedScores.values.reduce((a, b) => a + b) / updatedScores.length;

    final updated = current.copyWith(
      completedLessons: completed,
      quizScores: updatedScores,
      masteryPercentage: average,
      vocabularyProgress: (current.vocabularyProgress + score) / 2,
      conceptualProgress: (current.conceptualProgress + score) / 2,
      engagementStats: {
        ...current.engagementStats,
        'weeklySessions':
            ((current.engagementStats['weeklySessions'] as int? ?? 0) + 1),
      },
    );

    await saveProgress(updated);
    return updated;
  }
}
