import 'package:cloud_firestore/cloud_firestore.dart';

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
    required this.secondsPerQuestion,
    required this.createdBy,
    required this.createdAt,
  });

  final String quizId;
  final String lessonId;
  final String title;
  final List<QuizQuestion> questions;
  final int totalPoints;
  final int secondsPerQuestion;
  final String createdBy;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'lessonId': lessonId,
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
      'totalPoints': totalPoints,
      'secondsPerQuestion': secondsPerQuestion,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
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
      secondsPerQuestion: (map['secondsPerQuestion'] as num?)?.toInt() ?? 30,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _parseDateTime(map['createdAt']),
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
