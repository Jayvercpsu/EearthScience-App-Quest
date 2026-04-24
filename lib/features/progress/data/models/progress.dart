class LearnerProgress {
  const LearnerProgress({
    required this.userId,
    required this.completedLessons,
    required this.quizScores,
    required this.masteryPercentage,
    required this.vocabularyProgress,
    required this.conceptualProgress,
    required this.engagementStats,
  });

  final String userId;
  final List<String> completedLessons;
  final Map<String, double> quizScores;
  final double masteryPercentage;
  final double vocabularyProgress;
  final double conceptualProgress;
  final Map<String, dynamic> engagementStats;

  LearnerProgress copyWith({
    String? userId,
    List<String>? completedLessons,
    Map<String, double>? quizScores,
    double? masteryPercentage,
    double? vocabularyProgress,
    double? conceptualProgress,
    Map<String, dynamic>? engagementStats,
  }) {
    return LearnerProgress(
      userId: userId ?? this.userId,
      completedLessons: completedLessons ?? this.completedLessons,
      quizScores: quizScores ?? this.quizScores,
      masteryPercentage: masteryPercentage ?? this.masteryPercentage,
      vocabularyProgress: vocabularyProgress ?? this.vocabularyProgress,
      conceptualProgress: conceptualProgress ?? this.conceptualProgress,
      engagementStats: engagementStats ?? this.engagementStats,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'completedLessons': completedLessons,
      'quizScores': quizScores,
      'masteryPercentage': masteryPercentage,
      'vocabularyProgress': vocabularyProgress,
      'conceptualProgress': conceptualProgress,
      'engagementStats': engagementStats,
    };
  }

  factory LearnerProgress.fromMap(Map<String, dynamic> map) {
    return LearnerProgress(
      userId: map['userId'] as String? ?? '',
      completedLessons: (map['completedLessons'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      quizScores: (map['quizScores'] as Map<String, dynamic>? ?? const {}).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      masteryPercentage: (map['masteryPercentage'] as num?)?.toDouble() ?? 0,
      vocabularyProgress: (map['vocabularyProgress'] as num?)?.toDouble() ?? 0,
      conceptualProgress: (map['conceptualProgress'] as num?)?.toDouble() ?? 0,
      engagementStats:
          map['engagementStats'] as Map<String, dynamic>? ?? const {},
    );
  }
}
