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
    required this.createdBy,
    required this.createdAt,
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
  final String createdBy;
  final DateTime createdAt;

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
    String? createdBy,
    DateTime? createdAt,
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
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
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
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
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
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
