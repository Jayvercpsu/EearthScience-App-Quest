import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/firestore_paths.dart';
import '../models/lesson.dart';

class LessonRepository {
  LessonRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _cachedLessonsKey = 'offline_cached_lessons_v1';
  static const Map<String, String> _fixedBannerByLessonId = {
    'earth_crust_layers': 'assets/images/eart-crust.jpg',
    'earth_overview': 'assets/images/earth.jpg',
    'weather_systems': 'assets/images/weather.png',
    'climate_change_basics': 'assets/images/weather.png',
    'volcano_dynamics': 'assets/images/volcanoes.png',
    'earthquake_basics': 'assets/images/earthquake.png',
    'rocks_and_minerals': 'assets/images/rocks-and-minirals.jpg',
    'earth_from_space': 'assets/images/galaxy.jpg',
  };

  final List<Lesson> _fallbackLessons = [
    Lesson(
      lessonId: 'earth_crust_layers',
      title: 'Earth Crust and Layers',
      topic: 'Earth Structure',
      difficulty: 'Beginner',
      objectives: const [
        'Identify the crust, mantle, outer core, and inner core.',
        'Describe how temperature and pressure change with depth.',
      ],
      content:
          'Earth has layered parts. The crust is the outer solid shell. Below it is the mantle, then the liquid outer core, and the solid inner core. These layers help explain earthquakes, volcanoes, and plate movement.',
      vocabularyTerms: const [
        'Crust',
        'Mantle',
        'Outer Core',
        'Inner Core',
        'Lithosphere',
      ],
      competencyTag: 'Layer Identification',
      bannerUrl: 'assets/images/eart-crust.jpg',
      estimatedMinutes: 35,
      resourceLinks: const [],
      isPublished: true,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now(),
    ),
    Lesson(
      lessonId: 'earth_overview',
      title: 'Planet Earth Overview',
      topic: 'Earth as a System',
      difficulty: 'Beginner',
      objectives: const [
        'Recognize Earth as an interconnected system.',
        'Identify the major Earth spheres and their interactions.',
      ],
      content:
          'Earth is made of connected systems: geosphere, hydrosphere, atmosphere, and biosphere. Changes in one part of Earth can affect the others, which helps explain weather, climate, and natural hazards.',
      vocabularyTerms: const [
        'Geosphere',
        'Hydrosphere',
        'Atmosphere',
        'Biosphere',
        'System',
      ],
      competencyTag: 'Systems Thinking',
      bannerUrl: 'assets/images/earth.jpg',
      estimatedMinutes: 30,
      resourceLinks: const [],
      isPublished: true,
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
      bannerUrl: 'assets/images/weather.png',
      estimatedMinutes: 40,
      resourceLinks: const [],
      isPublished: true,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now(),
    ),
    Lesson(
      lessonId: 'climate_change_basics',
      title: 'Climate Change Basics',
      topic: 'Climate Science',
      difficulty: 'Intermediate',
      objectives: const [
        'Differentiate climate variability from long-term climate change.',
        'Identify major human and natural drivers of climate patterns.',
      ],
      content:
          'Climate change refers to long-term shifts in average weather patterns. Scientists study temperature records, greenhouse gas concentrations, and ice-core data to understand trends and impacts on ecosystems, oceans, and communities.',
      vocabularyTerms: const [
        'Greenhouse Effect',
        'Climate Variability',
        'Carbon Cycle',
        'Mitigation',
        'Adaptation',
      ],
      competencyTag: 'Evidence-Based Reasoning',
      bannerUrl: 'assets/images/weather.png',
      estimatedMinutes: 38,
      resourceLinks: const [],
      isPublished: true,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now(),
    ),
    Lesson(
      lessonId: 'volcano_dynamics',
      title: 'Volcanoes and Hazards',
      topic: 'Volcanology',
      difficulty: 'Intermediate',
      objectives: const [
        'Identify major volcano types and eruption styles.',
        'Relate magma properties to eruption strength.',
      ],
      content:
          'Volcanoes form when magma rises to the surface. Eruptions can be gentle or explosive depending on viscosity and gas. Understanding hazards helps communities prepare and respond safely.',
      vocabularyTerms: const ['Magma', 'Lava', 'Viscosity', 'Pyroclastic Flow'],
      competencyTag: 'Hazard Awareness',
      bannerUrl: 'assets/images/volcanoes.png',
      estimatedMinutes: 42,
      resourceLinks: const [],
      isPublished: true,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now(),
    ),
    Lesson(
      lessonId: 'earth_from_space',
      title: 'Earth from Space',
      topic: 'Remote Sensing',
      difficulty: 'Beginner',
      objectives: const [
        'Explain how satellites observe weather, land, and oceans.',
        'Interpret simple Earth observation images for patterns.',
      ],
      content:
          'Satellites provide continuous images and measurements of Earth. Remote sensing helps scientists track typhoons, monitor vegetation, map coastlines, and detect changes in temperature and clouds over time.',
      vocabularyTerms: const [
        'Remote Sensing',
        'Satellite',
        'Sensor',
        'Resolution',
        'Orbit',
      ],
      competencyTag: 'Data Literacy',
      bannerUrl: 'assets/images/galaxy.jpg',
      estimatedMinutes: 32,
      resourceLinks: const [],
      isPublished: true,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now(),
    ),
    Lesson(
      lessonId: 'earthquake_basics',
      title: 'Earthquakes and Seismic Waves',
      topic: 'Seismology',
      difficulty: 'Intermediate',
      objectives: const [
        'Explain the difference between P-waves and S-waves.',
        'Describe how epicenters are identified.',
      ],
      content:
          'Earthquakes result from sudden fault movement. Seismic waves travel through Earth and provide evidence about Earth interior structure and earthquake location.',
      vocabularyTerms: const ['Epicenter', 'Focus', 'Seismic Wave', 'Fault'],
      competencyTag: 'Scientific Investigation',
      bannerUrl: 'assets/images/earthquake.png',
      estimatedMinutes: 38,
      resourceLinks: const [],
      isPublished: true,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now(),
    ),
    Lesson(
      lessonId: 'rocks_and_minerals',
      title: 'Rocks and Minerals Classification',
      topic: 'Geology Basics',
      difficulty: 'Beginner',
      objectives: const [
        'Classify igneous, sedimentary, and metamorphic rocks.',
        'Distinguish mineral properties used for identification.',
      ],
      content:
          'Rocks are aggregates of minerals. Mineral identification uses hardness, luster, streak, cleavage, and crystal form. Rock cycle processes continuously transform materials.',
      vocabularyTerms: const [
        'Igneous',
        'Sedimentary',
        'Metamorphic',
        'Hardness',
      ],
      competencyTag: 'Classification Skills',
      bannerUrl: 'assets/images/rocks-and-minirals.jpg',
      estimatedMinutes: 36,
      resourceLinks: const [],
      isPublished: true,
      createdBy: 'teacher_seed',
      createdAt: DateTime.now(),
    ),
  ];

  Stream<List<Lesson>> streamLessons() async* {
    try {
      await for (final snapshot
          in _firestore.collection(FirestorePaths.lessons).snapshots()) {
        final lessons = _withFallbackLessons(_sortLessons(snapshot.docs));
        unawaited(_cacheLessons(lessons));
        yield lessons;
      }
    } catch (_) {
      final cached = await _loadCachedLessons();
      if (cached.isNotEmpty) {
        yield _withFallbackLessons(cached);
      } else {
        yield _fallbackLessons;
      }
    }
  }

  Stream<List<Lesson>> streamPublishedLessons() {
    return streamLessons().map(_withGuaranteedPublishedSamples);
  }

  Future<List<Lesson>> fetchLessons() async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.lessons)
          .get();
      final lessons = _withFallbackLessons(_sortLessons(snapshot.docs));
      unawaited(_cacheLessons(lessons));
      return lessons;
    } catch (_) {
      final cached = await _loadCachedLessons();
      if (cached.isNotEmpty) {
        return _withFallbackLessons(cached);
      }
      return _fallbackLessons;
    }
  }

  Future<List<Lesson>> fetchPublishedLessons() async {
    final lessons = await fetchLessons();
    return _withGuaranteedPublishedSamples(lessons);
  }

  Future<Lesson?> getLessonById(String lessonId) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.lessons)
          .doc(lessonId)
          .get();
      if (doc.exists && doc.data() != null) {
        return _enforceSampleLessonImage(Lesson.fromMap(doc.data()!));
      }
    } catch (_) {
      // fallback below
    }

    final cached = await _loadCachedLessons();
    for (final item in cached) {
      if (item.lessonId == lessonId) {
        return _enforceSampleLessonImage(item);
      }
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

  Future<List<Lesson>> fetchOfflineSyncedLessons() async {
    final cached = await _loadCachedLessons();
    if (cached.isNotEmpty) {
      return _withFallbackLessons(cached);
    }
    return _fallbackLessons;
  }

  List<Lesson> _sortLessons(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final lessons = <Lesson>[];
    for (final doc in docs) {
      try {
        lessons.add(_enforceSampleLessonImage(Lesson.fromMap(doc.data())));
      } catch (_) {
        // Skip malformed lesson documents.
      }
    }
    lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return lessons;
  }

  List<Lesson> _withFallbackLessons(List<Lesson> lessons) {
    if (lessons.isEmpty) {
      return _fallbackLessons;
    }
    final mergedById = <String, Lesson>{
      for (final lesson in lessons)
        lesson.lessonId: _enforceSampleLessonImage(lesson),
    };
    for (final sample in _fallbackLessons) {
      mergedById.putIfAbsent(sample.lessonId, () => sample);
    }
    final merged = mergedById.values.toList(growable: false);
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  List<Lesson> _withGuaranteedPublishedSamples(List<Lesson> lessons) {
    final published = lessons
        .where((lesson) => lesson.isPublished)
        .toList(growable: true);
    final publishedById = <String>{
      for (final lesson in published) lesson.lessonId,
    };
    for (final sample in _fallbackLessons.where(
      (lesson) => lesson.isPublished,
    )) {
      if (!publishedById.contains(sample.lessonId)) {
        published.add(sample);
      }
    }
    published.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return published;
  }

  Lesson _enforceSampleLessonImage(Lesson lesson) {
    final fixed = _fixedBannerByLessonId[lesson.lessonId];
    if (fixed == null || lesson.bannerUrl == fixed) {
      return lesson;
    }
    return lesson.copyWith(bannerUrl: fixed);
  }

  Future<void> _cacheLessons(List<Lesson> lessons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(lessons.map((item) => item.toMap()).toList());
      await prefs.setString(_cachedLessonsKey, encoded);
    } catch (_) {
      // ignore cache failures
    }
  }

  Future<List<Lesson>> _loadCachedLessons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedLessonsKey);
      if (raw == null || raw.trim().isEmpty) {
        return const <Lesson>[];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <Lesson>[];
      }
      final lessons = <Lesson>[];
      for (final item in decoded) {
        if (item is Map) {
          lessons.add(
            _enforceSampleLessonImage(
              Lesson.fromMap(Map<String, dynamic>.from(item)),
            ),
          );
        }
      }
      lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return lessons;
    } catch (_) {
      return const <Lesson>[];
    }
  }
}
