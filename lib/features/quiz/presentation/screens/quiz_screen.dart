import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_sfx_service.dart';
import '../../../../shared/animations/fade_slide_in.dart';
import '../../../../shared/widgets/lesson_topic_artwork.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../lessons/providers/lesson_providers.dart';
import '../../../notifications/providers/notification_providers.dart';
import '../../../offline/providers/offline_providers.dart';
import '../../../progress/providers/progress_providers.dart';
import '../../data/models/quiz.dart';
import '../../providers/quiz_providers.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({
    required this.lessonId,
    this.offlineMode = false,
    super.key,
  });

  final String lessonId;
  final bool offlineMode;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  bool _started = false;
  bool _showResult = false;
  bool _submitted = false;
  bool _usedFiftyFifty = false;
  bool _usedSkip = false;
  final Map<int, Set<int>> _hiddenChoicesByQuestion = <int, Set<int>>{};

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
          .start(seconds: quiz.questions.length * quiz.secondsPerQuestion);
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
      _handleQuizSubmit(score, quiz, _buildReviewItems(quiz));
    });
  }

  List<ReviewAnswerItem> _buildReviewItems(Quiz quiz) {
    final answers = ref.read(quizSessionControllerProvider).selectedAnswers;
    return List.generate(quiz.questions.length, (index) {
      final question = quiz.questions[index];
      final selectedIndex = answers[index];
      final safeSelected = (selectedIndex ?? -1);
      final selectedAnswer =
          safeSelected >= 0 && safeSelected < question.choices.length
          ? question.choices[safeSelected]
          : 'No Answer';
      final safeCorrect = question.correctAnswerIndex.clamp(
        0,
        question.choices.length - 1,
      );

      return ReviewAnswerItem(
        question: question.questionText,
        selectedAnswer: selectedAnswer,
        correctAnswer: question.choices[safeCorrect],
        explanation: question.explanation,
        isCorrect: selectedIndex == question.correctAnswerIndex,
      );
    });
  }

  Future<void> _handleQuizSubmit(
    int score,
    Quiz quiz,
    List<ReviewAnswerItem> reviewItems,
  ) async {
    await AppSfxService.instance.playApplause();

    if (widget.offlineMode) {
      final sessionRepo = ref.read(offlineSessionRepositoryProvider);
      final nickname = (await sessionRepo.loadNickname()) ?? 'Guest';
      await sessionRepo.updateAfterQuiz(
        nickname: nickname,
        lessonId: widget.lessonId,
        score: score / quiz.questions.length,
      );
      ref.invalidate(offlineProgressProvider);
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
          reviewItems: reviewItems,
          continueRoute: '/offline',
        ),
      );
      return;
    }

    final progressRepo = ref.read(progressRepositoryProvider);
    final userId = ref.read(currentUserProvider).valueOrNull?.uid;

    await progressRepo.updateAfterQuiz(
      userId: userId ?? 'local_student',
      lessonId: widget.lessonId,
      score: score / quiz.questions.length,
    );
    final studentName =
        ref.read(currentUserProvider).valueOrNull?.name ?? 'Student';
    await ref
        .read(notificationRepositoryProvider)
        .createRoleNotification(
          role: 'teacher',
          title: 'Quiz Completed',
          message:
              '$studentName scored $score/${quiz.questions.length} on ${quiz.title}.',
          createdBy: userId ?? 'local_student',
        );
    ref.invalidate(learnerProgressProvider);
    ref.invalidate(notificationsProvider);

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
        reviewItems: reviewItems,
        continueRoute: '/student',
      ),
    );
  }

  void _useFiftyFifty(Quiz quiz, int questionIndex) {
    if (_usedFiftyFifty) {
      return;
    }
    final selectedAnswer = ref
        .read(quizSessionControllerProvider)
        .selectedAnswers[questionIndex];
    if (selectedAnswer != null) {
      return;
    }

    final question = quiz.questions[questionIndex];
    final wrongIndexes = List<int>.generate(question.choices.length, (i) => i)
      ..removeWhere((index) => index == question.correctAnswerIndex)
      ..shuffle();

    final hideCount = (question.choices.length - 2).clamp(
      0,
      wrongIndexes.length,
    );

    setState(() {
      _usedFiftyFifty = true;
      _hiddenChoicesByQuestion[questionIndex] = wrongIndexes
          .take(hideCount)
          .toSet();
    });
  }

  void _skipQuestion(Quiz quiz) {
    if (_usedSkip) {
      return;
    }
    final currentQuestionIndex = ref
        .read(quizSessionControllerProvider)
        .currentIndex;
    setState(() {
      _usedSkip = true;
      _showResult = false;
      _hiddenChoicesByQuestion.remove(currentQuestionIndex);
    });
    ref
        .read(quizSessionControllerProvider.notifier)
        .next(quiz.questions.length);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Question skipped.')));
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = widget.offlineMode
        ? ref.watch(offlineQuizByLessonProvider(widget.lessonId))
        : ref.watch(quizByLessonProvider(widget.lessonId));
    final lessonAsync = ref.watch(lessonByIdProvider(widget.lessonId));
    final session = ref.watch(quizSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          'Live Quiz',
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
          final revealAnswer = _showResult || selectedAnswer != null;
          final lessonImageUrl = lessonAsync.valueOrNull?.bannerUrl ?? '';
          final hiddenChoices =
              _hiddenChoicesByQuestion[questionIndex] ?? const <int>{};
          final visibleChoiceIndexes =
              List<int>.generate(question.choices.length, (i) => i)
                  .where((index) => !hiddenChoices.contains(index))
                  .toList(growable: false);
          final percent = (questionIndex + 1) / quiz.questions.length;
          final minutes = (session.remainingSeconds ~/ 60).toString().padLeft(
            2,
            '0',
          );
          final seconds = (session.remainingSeconds % 60).toString().padLeft(
            2,
            '0',
          );

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEEF4FF), Color(0xFFF8FBFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuizHeader(
                      progress: percent,
                      questionIndex: questionIndex,
                      totalQuestions: quiz.questions.length,
                      minutes: minutes,
                      seconds: seconds,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: KeyedSubtree(
                          key: ValueKey(question.questionId),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeSlideIn(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFDDE4F0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        question.questionText,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 120,
                                        width: double.infinity,
                                        child: LessonTopicArtwork(
                                          lessonId: widget.lessonId,
                                          imageUrl: lessonImageUrl,
                                          borderRadius: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _TopicChip(
                                            icon: Icons.sports_esports_rounded,
                                            label: quiz.title,
                                          ),
                                          _TopicChip(
                                            icon: Icons.sell_outlined,
                                            label: question.tag,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _LifelineChip(
                                    icon: Icons.filter_2_rounded,
                                    label: _usedFiftyFifty
                                        ? '50/50 Used'
                                        : 'Use 50/50',
                                    enabled:
                                        !_usedFiftyFifty &&
                                        !revealAnswer &&
                                        question.choices.length > 2,
                                    onTap: () =>
                                        _useFiftyFifty(quiz, questionIndex),
                                  ),
                                  _LifelineChip(
                                    icon: Icons.skip_next_rounded,
                                    label: _usedSkip
                                        ? 'Skip Used'
                                        : 'Skip Question',
                                    enabled: !_usedSkip && !revealAnswer,
                                    onTap: () => _skipQuestion(quiz),
                                  ),
                                ],
                              ),
                              if (hiddenChoices.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  '50/50 active: two wrong choices removed for this question.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: visibleChoiceIndexes.length,
                                  itemBuilder: (context, index) {
                                    final choiceIndex =
                                        visibleChoiceIndexes[index];
                                    final isSelected =
                                        selectedAnswer == choiceIndex;
                                    final isCorrect =
                                        question.correctAnswerIndex ==
                                        choiceIndex;

                                    return _AnswerOptionTile(
                                      label: String.fromCharCode(
                                        65 + choiceIndex,
                                      ),
                                      text: question.choices[choiceIndex],
                                      revealAnswer: revealAnswer,
                                      isSelected: isSelected,
                                      isCorrect: isCorrect,
                                      onTap: selectedAnswer != null
                                          ? null
                                          : () {
                                              final isCorrect =
                                                  question.correctAnswerIndex ==
                                                  choiceIndex;
                                              ref
                                                  .read(
                                                    quizSessionControllerProvider
                                                        .notifier,
                                                  )
                                                  .selectAnswer(
                                                    questionIndex,
                                                    choiceIndex,
                                                  );
                                              setState(() {
                                                _showResult = true;
                                              });
                                              if (isCorrect) {
                                                AppSfxService.instance
                                                    .playCorrect();
                                              }
                                            },
                                    );
                                  },
                                ),
                              ),
                              if (revealAnswer)
                                FadeSlideIn(
                                  delayMs: 30,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF4FF),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFCFDAF0),
                                      ),
                                    ),
                                    child: Text(
                                      question.explanation.trim().isEmpty
                                          ? 'Nice try. Keep going to the next question.'
                                          : question.explanation,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                            minimumSize: const Size.fromHeight(50),
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
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: Text(
                            questionIndex == quiz.questions.length - 1
                                ? 'Finish Quiz'
                                : 'Next Question',
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
            ),
          );
        },
        loading: () => const LoadingWidget(label: 'Loading quiz...'),
        error: (_, __) => const Center(child: Text('Unable to load quiz.')),
      ),
    );
  }
}

class _QuizHeader extends StatelessWidget {
  const _QuizHeader({
    required this.progress,
    required this.questionIndex,
    required this.totalQuestions,
    required this.minutes,
    required this.seconds,
  });

  final double progress;
  final int questionIndex;
  final int totalQuestions;
  final String minutes;
  final String seconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE5F2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Question ${questionIndex + 1} of $totalQuestions',
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE8ECF3),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2CC7B7)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerOptionTile extends StatelessWidget {
  const _AnswerOptionTile({
    required this.label,
    required this.text,
    required this.revealAnswer,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool revealAnswer;
  final bool isSelected;
  final bool isCorrect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    var border = const Color(0xFFD7DFEB);
    var background = Colors.white;
    var badge = const Color(0xFFE5E7EB);

    if (revealAnswer) {
      if (isCorrect) {
        border = const Color(0xFF2BB673);
        background = const Color(0xFFEAFBF1);
        badge = const Color(0xFF2BB673);
      } else if (isSelected) {
        border = const Color(0xFFEF4444);
        background = const Color(0xFFFEF2F2);
        badge = const Color(0xFFEF4444);
      }
    } else if (isSelected) {
      border = AppColors.primary;
      background = const Color(0xFFEFF5FF);
      badge = AppColors.primary;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: badge,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badge == const Color(0xFFE5E7EB)
                      ? AppColors.textSecondary
                      : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),
            ),
          ],
        ),
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

class _LifelineChip extends StatelessWidget {
  const _LifelineChip({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
