import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/illustration_assets.dart';

class QuizResultArgs {
  const QuizResultArgs({
    required this.lessonId,
    required this.score,
    required this.total,
    required this.xpGained,
    this.reviewItems = const [],
    this.continueRoute = '/student',
  });

  final String lessonId;
  final int score;
  final int total;
  final int xpGained;
  final List<ReviewAnswerItem> reviewItems;
  final String continueRoute;
}

class ReviewAnswerItem {
  const ReviewAnswerItem({
    required this.question,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.explanation,
    required this.isCorrect,
  });

  final String question;
  final String selectedAnswer;
  final String correctAnswer;
  final String explanation;
  final bool isCorrect;
}

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({required this.args, super.key});

  final QuizResultArgs args;

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 2));
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _performance =>
      widget.args.total == 0 ? 0 : widget.args.score / widget.args.total;

  @override
  Widget build(BuildContext context) {
    final accuracy = (_performance * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text(
          'Quiz Result',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                const SizedBox(height: 8),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      IllustrationAssets.onboardingRewards,
                      width: 94,
                      height: 94,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Great Job!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34 / 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'You scored',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.args.score} / ${widget.args.total}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 52 / 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ResultMetricCard(
                        label: 'XP Gained',
                        value: '+${widget.args.xpGained} XP',
                        valueColor: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ResultMetricCard(
                        label: 'Accuracy',
                        value: '$accuracy%',
                        valueColor: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE6ECF4)),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage(
                          IllustrationAssets.lessonCard,
                        ),
                        backgroundColor: Color(0xFF1E3A5F),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Badge Unlocked!',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tectonic Explorer',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: widget.args.reviewItems.isEmpty
                      ? null
                      : () => _openReviewAnswers(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Review Answers'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => context.go(widget.args.continueRoute),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ],
            ),
            ConfettiWidget(
              confettiController: _controller,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.06,
              numberOfParticles: 20,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.accent,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReviewAnswers(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        final items = widget.args.reviewItems;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Column(
              children: [
                Text(
                  'Review Answers',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: item.isCorrect
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Q${index + 1}: ${item.question}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your answer: ${item.selectedAnswer}',
                              style: TextStyle(
                                color: item.isCorrect
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFB91C1C),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Correct answer: ${item.correctAnswer}',
                              style: const TextStyle(color: Color(0xFF1D4ED8)),
                            ),
                            if (item.explanation.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                item.explanation,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResultMetricCard extends StatelessWidget {
  const _ResultMetricCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6ECF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: valueColor),
          ),
        ],
      ),
    );
  }
}
