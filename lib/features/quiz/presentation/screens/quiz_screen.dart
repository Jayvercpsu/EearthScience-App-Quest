import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/animations/fade_slide_in.dart';
import '../../../../shared/widgets/lesson_topic_artwork.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../progress/providers/progress_providers.dart';
import '../../data/models/quiz.dart';
import '../../providers/quiz_providers.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _started = false;
  bool _showResult = false;
  bool _submitted = false;

  void _startQuizIfNeeded(Quiz quiz) {
    if (_started) {
      return;
    }
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(quizSessionControllerProvider.notifier)
          .start(seconds: quiz.questions.length * 75);
    });
  }

  void _submitResultsIfNeeded(Quiz quiz) {
    if (_submitted) {
      return;
    }
    _submitted = true;

    final score = ref
        .read(quizSessionControllerProvider.notifier)
        .calculateScore(quiz);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleQuizSubmit(score, quiz);
    });
  }

  Future<void> _handleQuizSubmit(int score, Quiz quiz) async {
    final progressRepo = ref.read(progressRepositoryProvider);
    const userId = 'local_student';
    await progressRepo.updateAfterQuiz(
      userId: userId,
      lessonId: widget.lessonId,
      score: score / quiz.questions.length,
    );
    ref.invalidate(learnerProgressProvider);

    if (!mounted) {
      return;
    }

    context.go(
      '/quiz-result',
      extra: QuizResultArgs(
        lessonId: widget.lessonId,
        score: score,
        total: quiz.questions.length,
        xpGained: score * 15,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizByLessonProvider(widget.lessonId));
    final session = ref.watch(quizSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          'Quiz',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: quizAsync.when(
        data: (quiz) {
          if (quiz == null || quiz.questions.isEmpty) {
            return const Center(
              child: Text('No quiz available for this lesson yet.'),
            );
          }

          _startQuizIfNeeded(quiz);

          if (session.isFinished) {
            _submitResultsIfNeeded(quiz);
            return const LoadingWidget(label: 'Calculating results...');
          }

          final questionIndex = session.currentIndex;
          final question = quiz.questions[questionIndex];
          final selectedAnswer = session.selectedAnswers[questionIndex];
          final percent = (questionIndex + 1) / quiz.questions.length;
          final minutes = (session.remainingSeconds ~/ 60).toString().padLeft(
            2,
            '0',
          );
          final seconds = (session.remainingSeconds % 60).toString().padLeft(
            2,
            '0',
          );

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Question ${questionIndex + 1} of ${quiz.questions.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.timer_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$minutes:$seconds',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE8ECF3),
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF2CC7B7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    child: Text(
                      question.questionText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delayMs: 70,
                    child: SizedBox(
                      height: 126,
                      width: double.infinity,
                      child: LessonTopicArtwork(
                        lessonId: widget.lessonId,
                        borderRadius: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TopicChip(
                        icon: Icons.category_outlined,
                        label: quiz.title,
                      ),
                      _TopicChip(
                        icon: Icons.sell_outlined,
                        label: question.tag,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: question.choices.length,
                      itemBuilder: (context, index) {
                        final isSelected = selectedAnswer == index;
                        final isCorrect = question.correctAnswerIndex == index;
                        Color border = const Color(0xFFD8DEE9);
                        Color bg = Colors.white;
                        Color chip = const Color(0xFFE5E7EB);

                        if (_showResult) {
                          if (isCorrect) {
                            border = const Color(0xFF2BB673);
                            bg = const Color(0xFFEAFBF1);
                            chip = const Color(0xFF2BB673);
                          } else if (isSelected) {
                            border = const Color(0xFFEF4444);
                            bg = const Color(0xFFFEF2F2);
                            chip = const Color(0xFFEF4444);
                          }
                        } else if (isSelected) {
                          border = AppColors.primary;
                          bg = const Color(0xFFEFF5FF);
                          chip = AppColors.primary;
                        }

                        return GestureDetector(
                          onTap: selectedAnswer != null
                              ? null
                              : () {
                                  ref
                                      .read(
                                        quizSessionControllerProvider.notifier,
                                      )
                                      .selectAnswer(questionIndex, index);
                                  setState(() => _showResult = true);
                                },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 9),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: chip,
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: chip == const Color(0xFFE5E7EB)
                                          ? AppColors.textSecondary
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    question.choices[index],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 360;

                      final previousButton = OutlinedButton(
                        onPressed: questionIndex == 0
                            ? null
                            : () {
                                ref
                                    .read(
                                      quizSessionControllerProvider.notifier,
                                    )
                                    .previous();
                                setState(() => _showResult = false);
                              },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Previous'),
                      );

                      final nextButton = ElevatedButton(
                        onPressed: selectedAnswer == null
                            ? null
                            : () {
                                setState(() => _showResult = false);
                                ref
                                    .read(
                                      quizSessionControllerProvider.notifier,
                                    )
                                    .next(quiz.questions.length);
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: Text(
                          questionIndex == quiz.questions.length - 1
                              ? 'Finish'
                              : 'Next',
                        ),
                      );

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            previousButton,
                            const SizedBox(height: 10),
                            nextButton,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: previousButton),
                          const SizedBox(width: 12),
                          Expanded(child: nextButton),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(label: 'Loading quiz...'),
        error: (_, __) => const Center(child: Text('Unable to load quiz.')),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5EBF3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
