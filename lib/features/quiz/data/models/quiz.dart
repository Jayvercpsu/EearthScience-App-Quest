class QuizQuestion {
  const QuizQuestion({
    required this.questionId,
    required this.questionText,
    required this.choices,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.tag,
  });

  final String questionId;
  final String questionText;
  final List<String> choices;
  final int correctAnswerIndex;
  final String explanation;
  final String tag;

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'choices': choices,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'tag': tag,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      questionId: map['questionId'] as String? ?? '',
      questionText: map['questionText'] as String? ?? '',
      choices: (map['choices'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      correctAnswerIndex: (map['correctAnswerIndex'] as num?)?.toInt() ?? 0,
      explanation: map['explanation'] as String? ?? '',
      tag: map['tag'] as String? ?? 'concept',
    );
  }
}

class Quiz {
  const Quiz({
    required this.quizId,
    required this.lessonId,
    required this.title,
    required this.questions,
    required this.totalPoints,
    required this.createdBy,
  });

  final String quizId;
  final String lessonId;
  final String title;
  final List<QuizQuestion> questions;
  final int totalPoints;
  final String createdBy;

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'lessonId': lessonId,
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
      'totalPoints': totalPoints,
      'createdBy': createdBy,
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      quizId: map['quizId'] as String? ?? '',
      lessonId: map['lessonId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      questions: (map['questions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(QuizQuestion.fromMap)
          .toList(),
      totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 0,
      createdBy: map['createdBy'] as String? ?? '',
    );
  }
}
