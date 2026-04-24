class StudentPerformanceSnapshot {
  const StudentPerformanceSnapshot({
    required this.userId,
    required this.studentName,
    required this.averageScore,
    required this.completedLessons,
    required this.vocabularyPerformance,
    required this.conceptualPerformance,
    required this.engagementLevel,
  });

  final String userId;
  final String studentName;
  final double averageScore;
  final int completedLessons;
  final double vocabularyPerformance;
  final double conceptualPerformance;
  final double engagementLevel;
}
