import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/dialogs/confirmation_dialog.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../quiz/data/models/quiz.dart';
import '../../../quiz/providers/quiz_providers.dart';

class ManageQuizzesScreen extends ConsumerWidget {
  const ManageQuizzesScreen({super.key});

  Future<void> _openQuizSheet(
    BuildContext context,
    WidgetRef ref, {
    Quiz? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final lessonIdController = TextEditingController(
      text: existing?.lessonId ?? '',
    );
    final questionController = TextEditingController(
      text: existing?.questions.firstOrNull?.questionText ?? '',
    );
    final choicesController = TextEditingController(
      text: existing?.questions.firstOrNull?.choices.join(', ') ?? '',
    );
    final answerIndexController = TextEditingController(
      text: '${existing?.questions.firstOrNull?.correctAnswerIndex ?? 0}',
    );
    final explanationController = TextEditingController(
      text: existing?.questions.firstOrNull?.explanation ?? '',
    );
    final tagController = TextEditingController(
      text: existing?.questions.firstOrNull?.tag ?? 'concept',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Create Quiz' : 'Edit Quiz',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: titleController,
                  label: 'Quiz Title',
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: lessonIdController,
                  label: 'Lesson ID',
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: questionController,
                  label: 'Question Text',
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: choicesController,
                  label: 'Choices (comma separated)',
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: answerIndexController,
                  label: 'Correct Answer Index (0-based)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: explanationController,
                  label: 'Explanation',
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(controller: tagController, label: 'Tag'),
                const SizedBox(height: AppSpacing.md),
                CustomButton(
                  label: existing == null ? 'Save Quiz' : 'Update Quiz',
                  onPressed: () async {
                    final quizId =
                        existing?.quizId ??
                        'quiz_${DateTime.now().millisecondsSinceEpoch}';
                    final choices = choicesController.text
                        .split(',')
                        .map((item) => item.trim())
                        .where((item) => item.isNotEmpty)
                        .toList();

                    final question = QuizQuestion(
                      questionId:
                          existing?.questions.firstOrNull?.questionId ??
                          'q_${DateTime.now().millisecondsSinceEpoch}',
                      questionText: questionController.text.trim(),
                      choices: choices,
                      correctAnswerIndex:
                          int.tryParse(answerIndexController.text.trim()) ?? 0,
                      explanation: explanationController.text.trim(),
                      tag: tagController.text.trim(),
                    );

                    final quiz = Quiz(
                      quizId: quizId,
                      lessonId: lessonIdController.text.trim(),
                      title: titleController.text.trim(),
                      questions: [question],
                      totalPoints: 1,
                      createdBy: existing?.createdBy ?? 'teacher_local',
                    );

                    await ref.read(quizRepositoryProvider).upsertQuiz(quiz);
                    ref.invalidate(quizzesProvider);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    titleController.dispose();
    lessonIdController.dispose();
    questionController.dispose();
    choicesController.dispose();
    answerIndexController.dispose();
    explanationController.dispose();
    tagController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(quizzesProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: quizzesAsync.when(
        data: (quizzes) {
          return Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _openQuizSheet(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Quiz'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  itemCount: quizzes.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    return Card(
                      child: ListTile(
                        title: Text(quiz.title),
                        subtitle: Text(
                          'Lesson: ${quiz.lessonId} • Questions: ${quiz.questions.length}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  _openQuizSheet(context, ref, existing: quiz),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () => ConfirmationDialog.show(
                                context,
                                title: 'Delete Quiz',
                                message: 'Delete ${quiz.title}?',
                                confirmLabel: 'Delete',
                                onConfirm: () async {
                                  await ref
                                      .read(quizRepositoryProvider)
                                      .deleteQuiz(quiz.quizId);
                                  ref.invalidate(quizzesProvider);
                                },
                              ),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(label: 'Loading quizzes...'),
        error: (_, __) => const Center(child: Text('Unable to load quizzes.')),
      ),
    );
  }
}

extension _ListX<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
