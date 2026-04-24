import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_paths.dart';
import '../models/lesson.dart';

class LessonRepository {
  LessonRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  final List<Lesson> _fallbackLessons = [
    Lesson(
      lessonId: 'earth_structure',
      title: "Earth's Structure",
      topic: 'Earth Layers',
      difficulty: 'Beginner',
      objectives: const [
        'Identify crust, mantle, outer core, and inner core.',
        'Differentiate physical and chemical layers of Earth.',
      ],
      content:
          'The Earth is composed of concentric layers with distinct properties. The crust is thin and rigid, the mantle behaves plastically over long periods, the outer core is liquid iron-nickel, and the inner core is solid due to immense pressure.',
      vocabularyTerms: const [
        'Crust',
        'Mantle',
        'Outer Core',
        'Inner Core',
        'Lithosphere',
      ],
      competencyTag: 'Conceptual Understanding',
      bannerUrl: '',
      createdBy: 'teacher_seed',
      createdAt: DateTime.now(),
    ),
    Lesson(
      lessonId: 'plate_tectonics',
      title: 'Plate Tectonics and Boundaries',
      topic: 'Plate Dynamics',
      difficulty: 'Intermediate',
      objectives: const [
        'Explain divergent, convergent, and transform boundaries.',
        'Connect tectonic boundaries to earthquakes and volcanoes.',
      ],
      content:
          'Lithospheric plates move slowly over the asthenosphere. Their interactions create trenches, ridges, mountains, volcanic arcs, and seismic activity. Boundary type determines the geologic features that form.',
      vocabularyTerms: const [
        'Convergent',
        'Divergent',
        'Transform',
        'Subduction',
        'Fault',
      ],
      competencyTag: 'Earth Process Analysis',
      bannerUrl: '',
      createdBy: 'teacher_seed',
      createdAt: DateTime.now(),
    ),
    Lesson(
      lessonId: 'weather_systems',
      title: 'Weather Systems and Climate',
      topic: 'Atmospheric Processes',
      difficulty: 'Intermediate',
      objectives: const [
        'Describe weather variables and measurement tools.',
        'Compare weather and climate through temporal scale.',
      ],
      content:
          'Weather describes atmospheric conditions over short periods, while climate captures long-term trends. Air masses, pressure systems, humidity, and topography shape local weather patterns and extremes.',
      vocabularyTerms: const [
        'Climate',
        'Humidity',
        'Air Mass',
        'Barometer',
        'Front',
      ],
      competencyTag: 'Data Interpretation',
      bannerUrl: '',
      createdBy: 'teacher_seed',
      createdAt: DateTime.now(),
    ),
  ];

  Stream<List<Lesson>> streamLessons() {
    try {
      return _firestore
          .collection(FirestorePaths.lessons)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Lesson.fromMap(doc.data()))
                .toList(growable: false),
          );
    } catch (_) {
      return Stream.value(_fallbackLessons);
    }
  }

  Future<List<Lesson>> fetchLessons() async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.lessons)
          .get();
      if (snapshot.docs.isEmpty) {
        return _fallbackLessons;
      }
      return snapshot.docs
          .map((doc) => Lesson.fromMap(doc.data()))
          .toList(growable: false);
    } catch (_) {
      return _fallbackLessons;
    }
  }

  Future<Lesson?> getLessonById(String lessonId) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.lessons)
          .doc(lessonId)
          .get();
      if (doc.exists && doc.data() != null) {
        return Lesson.fromMap(doc.data()!);
      }
    } catch (_) {
      // fallback below
    }

    try {
      return _fallbackLessons.firstWhere((item) => item.lessonId == lessonId);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertLesson(Lesson lesson) async {
    try {
      await _firestore
          .collection(FirestorePaths.lessons)
          .doc(lesson.lessonId)
          .set(lesson.toMap());
      return;
    } catch (_) {
      final index = _fallbackLessons.indexWhere(
        (l) => l.lessonId == lesson.lessonId,
      );
      if (index >= 0) {
        _fallbackLessons[index] = lesson;
      } else {
        _fallbackLessons.add(lesson);
      }
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    try {
      await _firestore
          .collection(FirestorePaths.lessons)
          .doc(lessonId)
          .delete();
      return;
    } catch (_) {
      _fallbackLessons.removeWhere((l) => l.lessonId == lessonId);
    }
  }
}
