class EvaluationFeedback {
  const EvaluationFeedback({
    required this.feedbackId,
    required this.userId,
    required this.role,
    required this.engagement,
    required this.functionality,
    required this.aesthetics,
    required this.information,
    required this.perceivedImpact,
    required this.comments,
    required this.testType,
    required this.createdAt,
  });

  final String feedbackId;
  final String userId;
  final String role;
  final int engagement;
  final int functionality;
  final int aesthetics;
  final int information;
  final int perceivedImpact;
  final String comments;
  final String testType;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'feedbackId': feedbackId,
      'userId': userId,
      'role': role,
      'engagement': engagement,
      'functionality': functionality,
      'aesthetics': aesthetics,
      'information': information,
      'perceivedImpact': perceivedImpact,
      'comments': comments,
      'testType': testType,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
