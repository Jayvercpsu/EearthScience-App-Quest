import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/firestore_paths.dart';
import '../models/quiz.dart';

class QuizRepository {
  QuizRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _cachedQuizzesKey = 'offline_cached_quizzes_v1';

  final List<Quiz> _fallbackQuizzes = [
    Quiz(
      quizId: 'quiz_earth_structure',
      lessonId: 'earth_crust_layers',
      title: 'Earth Structure Mastery Quiz',
      totalPoints: 3,
      secondsPerQuestion: 30,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
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
      lessonId: 'earth_overview',
      title: 'Plate Tectonics Checkpoint',
      totalPoints: 3,
      secondsPerQuestion: 30,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
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
      secondsPerQuestion: 30,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
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
    Quiz(
      quizId: 'quiz_climate_change_basics',
      lessonId: 'climate_change_basics',
      title: 'Climate Change Fundamentals Quiz',
      totalPoints: 3,
      secondsPerQuestion: 30,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      questions: [
        QuizQuestion(
          questionId: 'q10',
          questionText: 'Climate describes conditions over:',
          choices: [
            'Minutes to hours',
            'Days only',
            'Many years to decades',
            'Only one storm event',
          ],
          correctAnswerIndex: 2,
          explanation:
              'Climate is the long-term average and variation of weather.',
          tag: 'concept',
        ),
        QuizQuestion(
          questionId: 'q11',
          questionText: 'Which gas is a major greenhouse gas?',
          choices: ['Nitrogen', 'Carbon dioxide', 'Argon', 'Neon'],
          correctAnswerIndex: 1,
          explanation:
              'Carbon dioxide traps heat and contributes to greenhouse warming.',
          tag: 'vocabulary',
        ),
        QuizQuestion(
          questionId: 'q12',
          questionText: 'Planting trees is commonly an example of:',
          choices: ['Mitigation', 'Plate motion', 'Weathering', 'Erosion'],
          correctAnswerIndex: 0,
          explanation:
              'Tree planting can reduce atmospheric CO2, a mitigation action.',
          tag: 'application',
        ),
      ],
    ),
    Quiz(
      quizId: 'quiz_volcano_dynamics',
      lessonId: 'volcano_dynamics',
      title: 'Volcano Dynamics Quick Quiz',
      totalPoints: 3,
      secondsPerQuestion: 30,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      questions: [
        QuizQuestion(
          questionId: 'q13',
          questionText: 'Magma that reaches Earth\'s surface is called:',
          choices: ['Ash', 'Lava', 'Basalt', 'Core melt'],
          correctAnswerIndex: 1,
          explanation: 'Magma is called lava once it erupts onto the surface.',
          tag: 'vocabulary',
        ),
        QuizQuestion(
          questionId: 'q14',
          questionText: 'Explosive eruptions are often linked to:',
          choices: [
            'Low gas and low viscosity',
            'High gas and high viscosity',
            'No magma movement',
            'Calm weather only',
          ],
          correctAnswerIndex: 1,
          explanation:
              'Gas-rich, viscous magma traps pressure and can erupt explosively.',
          tag: 'concept',
        ),
        QuizQuestion(
          questionId: 'q15',
          questionText: 'A fast, hot cloud of ash and gas is called:',
          choices: ['Lahar', 'Pyroclastic flow', 'Tsunami', 'Fault creep'],
          correctAnswerIndex: 1,
          explanation:
              'Pyroclastic flows are among the most dangerous volcanic hazards.',
          tag: 'hazard',
        ),
      ],
    ),
    Quiz(
      quizId: 'quiz_earthquake_basics',
      lessonId: 'earthquake_basics',
      title: 'Seismic Waves Challenge',
      totalPoints: 3,
      secondsPerQuestion: 30,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      questions: [
        QuizQuestion(
          questionId: 'q16',
          questionText: 'Which wave arrives first at a station?',
          choices: ['S-wave', 'P-wave', 'Surface wave', 'Love wave'],
          correctAnswerIndex: 1,
          explanation: 'P-waves travel faster, so they arrive first.',
          tag: 'concept',
        ),
        QuizQuestion(
          questionId: 'q17',
          questionText: 'The point inside Earth where rupture begins is:',
          choices: ['Epicenter', 'Focus', 'Fault trace', 'Hotspot'],
          correctAnswerIndex: 1,
          explanation: 'The focus (hypocenter) is the origin of rupture.',
          tag: 'vocabulary',
        ),
        QuizQuestion(
          questionId: 'q18',
          questionText: 'Epicenter is located:',
          choices: [
            'At Earth\'s core',
            'Directly above the focus on the surface',
            'At the mantle-crust boundary',
            'Only in oceans',
          ],
          correctAnswerIndex: 1,
          explanation: 'The epicenter is the surface location above the focus.',
          tag: 'concept',
        ),
      ],
    ),
    Quiz(
      quizId: 'quiz_rocks_and_minerals',
      lessonId: 'rocks_and_minerals',
      title: 'Rocks and Minerals Practice Quiz',
      totalPoints: 3,
      secondsPerQuestion: 30,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      questions: [
        QuizQuestion(
          questionId: 'q19',
          questionText: 'Which rock type forms from cooled magma?',
          choices: ['Sedimentary', 'Metamorphic', 'Igneous', 'Organic'],
          correctAnswerIndex: 2,
          explanation: 'Igneous rocks form when magma or lava cools.',
          tag: 'classification',
        ),
        QuizQuestion(
          questionId: 'q20',
          questionText: 'Hardness of minerals is tested by:',
          choices: ['Smell', 'Color only', 'Scratch test', 'Temperature'],
          correctAnswerIndex: 2,
          explanation:
              'The scratch test compares a mineral against known standards.',
          tag: 'instrument',
        ),
        QuizQuestion(
          questionId: 'q21',
          questionText:
              'Rock formed from compressed sediments is usually called:',
          choices: ['Igneous', 'Sedimentary', 'Metamorphic', 'Molten'],
          correctAnswerIndex: 1,
          explanation:
              'Sedimentary rocks form through deposition and compaction.',
          tag: 'concept',
        ),
      ],
    ),
    Quiz(
      quizId: 'quiz_earth_from_space',
      lessonId: 'earth_from_space',
      title: 'Remote Sensing Starter Quiz',
      totalPoints: 3,
      secondsPerQuestion: 30,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      questions: [
        QuizQuestion(
          questionId: 'q22',
          questionText: 'Remote sensing data is primarily collected by:',
          choices: [
            'Thermometers only',
            'Satellites and sensors',
            'Compasses',
            'Rock hammers',
          ],
          correctAnswerIndex: 1,
          explanation: 'Remote sensing commonly uses satellite-borne sensors.',
          tag: 'vocabulary',
        ),
        QuizQuestion(
          questionId: 'q23',
          questionText: 'A higher image resolution means:',
          choices: [
            'Less detail visible',
            'More detail visible',
            'No cloud data',
            'Only nighttime images',
          ],
          correctAnswerIndex: 1,
          explanation:
              'Higher resolution allows smaller features to be distinguished.',
          tag: 'data',
        ),
        QuizQuestion(
          questionId: 'q24',
          questionText: 'Satellites help in typhoon tracking by observing:',
          choices: [
            'Cloud patterns',
            'Only earthquake faults',
            'Underground magma chambers',
            'Rock hardness',
          ],
          correctAnswerIndex: 0,
          explanation:
              'Satellite images monitor cloud development and storm movement.',
          tag: 'application',
        ),
      ],
    ),
  ];

  Future<Quiz?> getQuizByLesson(String lessonId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.quizzes)
          .where('lessonId', isEqualTo: lessonId)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final quizzes = snapshot.docs
            .map((doc) => Quiz.fromMap(doc.data()))
            .toList();
        quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        unawaited(_cacheQuizzes(quizzes));
        return quizzes.first;
      }
    } catch (_) {
      // fallback below
    }

    final cached = await _loadCachedQuizzes();
    try {
      final fromCache = cached
          .where((quiz) => quiz.lessonId == lessonId)
          .toList();
      if (fromCache.isNotEmpty) {
        fromCache.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return fromCache.first;
      }
    } catch (_) {
      // fallback below
    }

    try {
      final quizzes = _fallbackQuizzes
          .where((quiz) => quiz.lessonId == lessonId)
          .toList();
      quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return quizzes.first;
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
        final quizzes = snapshot.docs
            .map((doc) => Quiz.fromMap(doc.data()))
            .toList();
        quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        unawaited(_cacheQuizzes(quizzes));
        return quizzes;
      }
    } catch (_) {
      // fallback below
    }
    final cached = await _loadCachedQuizzes();
    if (cached.isNotEmpty) {
      return _mergeWithFallbackQuizzes(cached);
    }
    return [..._fallbackQuizzes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> upsertQuiz(Quiz quiz) async {
    try {
      await _firestore
          .collection(FirestorePaths.quizzes)
          .doc(quiz.quizId)
          .set(quiz.toMap());
      final current = await fetchQuizzes();
      unawaited(_cacheQuizzes(current));
      return;
    } catch (_) {
      final index = _fallbackQuizzes.indexWhere((q) => q.quizId == quiz.quizId);
      if (index >= 0) {
        _fallbackQuizzes[index] = quiz;
      } else {
        _fallbackQuizzes.add(quiz);
      }
      unawaited(_cacheQuizzes(_fallbackQuizzes));
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    try {
      await _firestore.collection(FirestorePaths.quizzes).doc(quizId).delete();
      final current = await fetchQuizzes();
      unawaited(_cacheQuizzes(current));
      return;
    } catch (_) {
      _fallbackQuizzes.removeWhere((q) => q.quizId == quizId);
      unawaited(_cacheQuizzes(_fallbackQuizzes));
    }
  }

  Future<List<Quiz>> fetchOfflineSyncedQuizzes() async {
    final cached = await _loadCachedQuizzes();
    if (cached.isNotEmpty) {
      return _mergeWithFallbackQuizzes(cached);
    }
    return [..._fallbackQuizzes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Quiz> _mergeWithFallbackQuizzes(List<Quiz> quizzes) {
    final mergedById = <String, Quiz>{
      for (final quiz in quizzes) quiz.quizId: quiz,
    };
    for (final sample in _fallbackQuizzes) {
      mergedById.putIfAbsent(sample.quizId, () => sample);
    }
    final merged = mergedById.values.toList(growable: false);
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  Future<void> _cacheQuizzes(List<Quiz> quizzes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(quizzes.map((item) => item.toMap()).toList());
      await prefs.setString(_cachedQuizzesKey, encoded);
    } catch (_) {
      // ignore cache failures
    }
  }

  Future<List<Quiz>> _loadCachedQuizzes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedQuizzesKey);
      if (raw == null || raw.trim().isEmpty) {
        return const <Quiz>[];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <Quiz>[];
      }
      final quizzes = <Quiz>[];
      for (final item in decoded) {
        if (item is Map) {
          quizzes.add(Quiz.fromMap(Map<String, dynamic>.from(item)));
        }
      }
      quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return quizzes;
    } catch (_) {
      return const <Quiz>[];
    }
  }
}
