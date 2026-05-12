import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  const Lesson({
    required this.lessonId,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.objectives,
    required this.content,
    required this.vocabularyTerms,
    required this.competencyTag,
    required this.bannerUrl,
    required this.estimatedMinutes,
    required this.resourceLinks,
    required this.isPublished,
    required this.createdBy,
    required this.createdAt,
    this.supplementFileUrl = '',
    this.supplementFileName = '',
    this.supplementFileType = '',
  });

  final String lessonId;
  final String title;
  final String topic;
  final String difficulty;
  final List<String> objectives;
  final String content;
  final List<String> vocabularyTerms;
  final String competencyTag;
  final String bannerUrl;
  final int estimatedMinutes;
  final List<String> resourceLinks;
  final bool isPublished;
  final String createdBy;
  final DateTime createdAt;
  final String supplementFileUrl;
  final String supplementFileName;
  final String supplementFileType;

  Lesson copyWith({
    String? lessonId,
    String? title,
    String? topic,
    String? difficulty,
    List<String>? objectives,
    String? content,
    List<String>? vocabularyTerms,
    String? competencyTag,
    String? bannerUrl,
    int? estimatedMinutes,
    List<String>? resourceLinks,
    bool? isPublished,
    String? createdBy,
    DateTime? createdAt,
    String? supplementFileUrl,
    String? supplementFileName,
    String? supplementFileType,
  }) {
    return Lesson(
      lessonId: lessonId ?? this.lessonId,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      objectives: objectives ?? this.objectives,
      content: content ?? this.content,
      vocabularyTerms: vocabularyTerms ?? this.vocabularyTerms,
      competencyTag: competencyTag ?? this.competencyTag,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      resourceLinks: resourceLinks ?? this.resourceLinks,
      isPublished: isPublished ?? this.isPublished,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      supplementFileUrl: supplementFileUrl ?? this.supplementFileUrl,
      supplementFileName: supplementFileName ?? this.supplementFileName,
      supplementFileType: supplementFileType ?? this.supplementFileType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'title': title,
      'topic': topic,
      'difficulty': difficulty,
      'objectives': objectives,
      'content': content,
      'vocabularyTerms': vocabularyTerms,
      'competencyTag': competencyTag,
      'bannerUrl': bannerUrl,
      'estimatedMinutes': estimatedMinutes,
      'resourceLinks': resourceLinks,
      'isPublished': isPublished,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'supplementFileUrl': supplementFileUrl,
      'supplementFileName': supplementFileName,
      'supplementFileType': supplementFileType,
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      lessonId: map['lessonId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      topic: map['topic'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? 'Beginner',
      objectives: (map['objectives'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      content: map['content'] as String? ?? '',
      vocabularyTerms: (map['vocabularyTerms'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      competencyTag: map['competencyTag'] as String? ?? 'Concept Mastery',
      bannerUrl: map['bannerUrl'] as String? ?? '',
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 40,
      resourceLinks: (map['resourceLinks'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      isPublished: map['isPublished'] as bool? ?? true,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      supplementFileUrl: map['supplementFileUrl'] as String? ?? '',
      supplementFileName: map['supplementFileName'] as String? ?? '',
      supplementFileType: map['supplementFileType'] as String? ?? '',
    );
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
