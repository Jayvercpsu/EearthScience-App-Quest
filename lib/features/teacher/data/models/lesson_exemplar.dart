class LessonExemplar {
  const LessonExemplar({
    required this.exemplarId,
    required this.title,
    required this.topic,
    required this.objectives,
    required this.teachingFlow,
    required this.linkedLessons,
    required this.recommendations,
  });

  final String exemplarId;
  final String title;
  final String topic;
  final List<String> objectives;
  final String teachingFlow;
  final List<String> linkedLessons;
  final String recommendations;

  Map<String, dynamic> toMap() {
    return {
      'exemplarId': exemplarId,
      'title': title,
      'topic': topic,
      'objectives': objectives,
      'teachingFlow': teachingFlow,
      'linkedLessons': linkedLessons,
      'recommendations': recommendations,
    };
  }

  factory LessonExemplar.fromMap(Map<String, dynamic> map) {
    return LessonExemplar(
      exemplarId: map['exemplarId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      topic: map['topic'] as String? ?? '',
      objectives: (map['objectives'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      teachingFlow: map['teachingFlow'] as String? ?? '',
      linkedLessons: (map['linkedLessons'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      recommendations: map['recommendations'] as String? ?? '',
    );
  }
}
