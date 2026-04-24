import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_paths.dart';
import '../models/quiz.dart';

class QuizRepository {
  QuizRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  final List<Quiz> _fallbackQuizzes = [
    Quiz(
      quizId: 'quiz_earth_structure',
      lessonId: 'earth_structure',
      title: 'Earth Structure Mastery Quiz',
      totalPoints: 3,
      createdBy: 'teacher_seed',
      questions: [
        QuizQuestion(
          questionId: 'q1',
          questionText:
              'Which layer of Earth is mostly liquid iron and nickel?',
          choices: ['Crust', 'Mantle', 'Outer Core', 'Inner Core'],
          correctAnswerIndex: 2,
          explanation:
              'The outer core is liquid and composed mostly of iron and nickel.',
          tag: 'vocabulary',
        ),
        QuizQuestion(
          questionId: 'q2',
          questionText: 'What is the thinnest Earth layer?',
          choices: ['Crust', 'Mantle', 'Outer Core', 'Inner Core'],
          correctAnswerIndex: 0,
          explanation: 'The crust is Earth\'s thinnest outer layer.',
          tag: 'concept',
        ),
        QuizQuestion(
          questionId: 'q3',
          questionText: 'Lithosphere includes crust and upper ______.',
          choices: ['inner core', 'mantle', 'outer core', 'hydrosphere'],
          correctAnswerIndex: 1,
          explanation:
              'The lithosphere is made of crust and rigid upper mantle.',
          tag: 'vocabulary',
        ),
      ],
    ),
    Quiz(
      quizId: 'quiz_plate_tectonics',
      lessonId: 'plate_tectonics',
      title: 'Plate Tectonics Checkpoint',
      totalPoints: 3,
      createdBy: 'teacher_seed',
      questions: [
        QuizQuestion(
          questionId: 'q4',
          questionText: 'At divergent boundaries, plates move:',
          choices: [
            'Toward each other',
            'Away from each other',
            'Past each other',
            'Randomly',
          ],
          correctAnswerIndex: 1,
          explanation: 'Divergent boundaries form where plates move apart.',
          tag: 'concept',
        ),
        QuizQuestion(
          questionId: 'q5',
          questionText: 'Subduction most commonly happens at:',
          choices: [
            'Convergent boundaries',
            'Divergent boundaries',
            'Transform boundaries',
            'Hot spots only',
          ],
          correctAnswerIndex: 0,
          explanation:
              'Subduction occurs at convergent boundaries when one plate sinks.',
          tag: 'vocabulary',
        ),
        QuizQuestion(
          questionId: 'q6',
          questionText: 'Transform boundaries are associated with:',
          choices: [
            'Mid-ocean ridges',
            'Ocean trenches',
            'Strike-slip faults',
            'Volcanic arcs only',
          ],
          correctAnswerIndex: 2,
          explanation:
              'Transform boundaries involve lateral movement along faults.',
          tag: 'concept',
        ),
      ],
    ),
    Quiz(
      quizId: 'quiz_weather_systems',
      lessonId: 'weather_systems',
      title: 'Weather Systems Skill Check',
      totalPoints: 3,
      createdBy: 'teacher_seed',
      questions: [
        QuizQuestion(
          questionId: 'q7',
          questionText: 'Which instrument measures air pressure?',
          choices: ['Thermometer', 'Barometer', 'Anemometer', 'Rain gauge'],
          correctAnswerIndex: 1,
          explanation: 'A barometer is used to measure atmospheric pressure.',
          tag: 'instrument',
        ),
        QuizQuestion(
          questionId: 'q8',
          questionText: 'Weather refers to atmospheric conditions over:',
          choices: [
            'A very long geologic era',
            'A short period of time',
            'Only one season',
            'Only one climate zone',
          ],
          correctAnswerIndex: 1,
          explanation:
              'Weather describes short-term atmospheric conditions in a place.',
          tag: 'concept',
        ),
        QuizQuestion(
          questionId: 'q9',
          questionText: 'A boundary between two air masses is called a:',
          choices: ['Current', 'Plate', 'Front', 'Core'],
          correctAnswerIndex: 2,
          explanation:
              'A front is the boundary where different air masses meet.',
          tag: 'vocabulary',
        ),
      ],
    ),
  ];

  Future<Quiz?> getQuizByLesson(String lessonId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.quizzes)
          .where('lessonId', isEqualTo: lessonId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return Quiz.fromMap(snapshot.docs.first.data());
      }
    } catch (_) {
      // fallback below
    }

    try {
      return _fallbackQuizzes.firstWhere((quiz) => quiz.lessonId == lessonId);
    } catch (_) {
      return null;
    }
  }

  Future<List<Quiz>> fetchQuizzes() async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.quizzes)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Quiz.fromMap(doc.data())).toList();
      }
    } catch (_) {
      // fallback below
    }

    return _fallbackQuizzes;
  }

  Future<void> upsertQuiz(Quiz quiz) async {
    try {
      await _firestore
          .collection(FirestorePaths.quizzes)
          .doc(quiz.quizId)
          .set(quiz.toMap());
      return;
    } catch (_) {
      final index = _fallbackQuizzes.indexWhere((q) => q.quizId == quiz.quizId);
      if (index >= 0) {
        _fallbackQuizzes[index] = quiz;
      } else {
        _fallbackQuizzes.add(quiz);
      }
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    try {
      await _firestore.collection(FirestorePaths.quizzes).doc(quizId).delete();
      return;
    } catch (_) {
      _fallbackQuizzes.removeWhere((q) => q.quizId == quizId);
    }
  }
}
