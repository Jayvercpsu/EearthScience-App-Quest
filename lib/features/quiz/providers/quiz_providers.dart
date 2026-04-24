import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/quiz.dart';
import '../data/repositories/quiz_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository();
});

final quizzesProvider = FutureProvider<List<Quiz>>((ref) {
  return ref.read(quizRepositoryProvider).fetchQuizzes();
});

final quizByLessonProvider = FutureProvider.family<Quiz?, String>((
  ref,
  lessonId,
) {
  return ref.read(quizRepositoryProvider).getQuizByLesson(lessonId);
});

class QuizSessionState {
  const QuizSessionState({
    this.currentIndex = 0,
    this.remainingSeconds = 180,
    this.selectedAnswers = const {},
    this.isFinished = false,
  });

  final int currentIndex;
  final int remainingSeconds;
  final Map<int, int> selectedAnswers;
  final bool isFinished;

  QuizSessionState copyWith({
    int? currentIndex,
    int? remainingSeconds,
    Map<int, int>? selectedAnswers,
    bool? isFinished,
  }) {
    return QuizSessionState(
      currentIndex: currentIndex ?? this.currentIndex,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

class QuizSessionController extends StateNotifier<QuizSessionState> {
  QuizSessionController() : super(const QuizSessionState());

  Timer? _timer;

  void start({int seconds = 180}) {
    _timer?.cancel();
    state = QuizSessionState(remainingSeconds: seconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 1 || state.isFinished) {
        timer.cancel();
        state = state.copyWith(remainingSeconds: 0, isFinished: true);
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void selectAnswer(int questionIndex, int answerIndex) {
    final updated = Map<int, int>.from(state.selectedAnswers)
      ..[questionIndex] = answerIndex;
    state = state.copyWith(selectedAnswers: updated);
  }

  void next(int totalQuestions) {
    if (state.currentIndex < totalQuestions - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
      return;
    }
    finish();
  }

  void previous() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void finish() {
    _timer?.cancel();
    state = state.copyWith(isFinished: true);
  }

  int calculateScore(Quiz quiz) {
    int score = 0;
    for (var i = 0; i < quiz.questions.length; i++) {
      final selected = state.selectedAnswers[i];
      if (selected == quiz.questions[i].correctAnswerIndex) {
        score++;
      }
    }
    return score;
  }

  void reset() {
    _timer?.cancel();
    state = const QuizSessionState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final quizSessionControllerProvider =
    StateNotifierProvider.autoDispose<QuizSessionController, QuizSessionState>(
      (ref) => QuizSessionController(),
    );
