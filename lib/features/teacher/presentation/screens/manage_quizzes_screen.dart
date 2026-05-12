import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/animations/fade_slide_in.dart';
import '../../../../shared/animations/tap_scale.dart';
import '../../../../shared/dialogs/confirmation_dialog.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../lessons/providers/lesson_providers.dart';
import '../../../notifications/providers/notification_providers.dart';
import '../../../quiz/data/models/quiz.dart';
import '../../../quiz/providers/quiz_providers.dart';

class ManageQuizzesScreen extends ConsumerStatefulWidget {
  const ManageQuizzesScreen({super.key});

  @override
  ConsumerState<ManageQuizzesScreen> createState() =>
      _ManageQuizzesScreenState();
}

class _ManageQuizzesScreenState extends ConsumerState<ManageQuizzesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openQuizSheet(BuildContext context, {Quiz? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuizComposerSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizzesAsync = ref.watch(quizzesProvider);
    final lessonsAsync = ref.watch(lessonsStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: quizzesAsync.when(
        data: (quizzes) {
          final filtered = quizzes.where((quiz) {
            final key = _search.toLowerCase();
            if (key.isEmpty) {
              return true;
            }
            return quiz.title.toLowerCase().contains(key) ||
                quiz.lessonId.toLowerCase().contains(key) ||
                quiz.questions.any(
                  (question) =>
                      question.questionText.toLowerCase().contains(key),
                );
          }).toList();

          final lessonMap = {
            for (final lesson in lessonsAsync.valueOrNull ?? const [])
              lesson.lessonId: lesson.title,
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF19135F), Color(0xFF2659DD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interactive Quiz Builder',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Create your own fast-paced question sets for students.',
                        style: TextStyle(
                          color: Color(0xFFE1E8FF),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search quizzes...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    'Quiz Sets',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _openQuizSheet(context),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Create Quiz'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No quizzes found.'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final quiz = filtered[index];
                          final lessonName =
                              lessonMap[quiz.lessonId] ?? quiz.lessonId;

                          return FadeSlideIn(
                            delayMs: 45 + (index * 30),
                            child: Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFECF1FF),
                                  child: Text(
                                    '${quiz.questions.length}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(quiz.title),
                                subtitle: Text(
                                  '$lessonName - ${quiz.questions.length} questions - ${quiz.secondsPerQuestion}s each',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _openQuizSheet(
                                        context,
                                        existing: quiz,
                                      ),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      onPressed: () => ConfirmationDialog.show(
                                        context,
                                        title: 'Delete Quiz',
                                        message:
                                            'Delete ${quiz.title}? Students will no longer access this game set.',
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

class _QuizComposerSheet extends ConsumerStatefulWidget {
  const _QuizComposerSheet({this.existing});

  final Quiz? existing;

  @override
  ConsumerState<_QuizComposerSheet> createState() => _QuizComposerSheetState();
}

class _QuizComposerSheetState extends ConsumerState<_QuizComposerSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _lessonIdController;
  late final TextEditingController _secondsController;
  final List<_QuestionDraft> _questions = [];
  String _lessonId = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _lessonIdController = TextEditingController(text: existing?.lessonId ?? '');
    _secondsController = TextEditingController(
      text: '${existing?.secondsPerQuestion ?? 30}',
    );
    _lessonId = existing?.lessonId ?? '';
    if (existing != null && existing.questions.isNotEmpty) {
      _questions.addAll(
        existing.questions.map(_QuestionDraft.fromQuizQuestion),
      );
    } else {
      _questions.add(_QuestionDraft.empty());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lessonIdController.dispose();
    _secondsController.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() => _questions.add(_QuestionDraft.empty()));
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) {
      return;
    }
    final removed = _questions[index];
    setState(() {
      _questions.removeAt(index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removed.dispose();
    });
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final title = _titleController.text.trim();
    final secondsPerQuestion =
        int.tryParse(_secondsController.text.trim()) ?? 30;

    if (title.isEmpty || _lessonId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set quiz title and lesson.')),
      );
      return;
    }

    final builtQuestions = <QuizQuestion>[];
    for (var index = 0; index < _questions.length; index++) {
      final draft = _questions[index];
      final text = draft.questionController.text.trim();
      final explanation = draft.explanationController.text.trim();
      final tag = draft.tagController.text.trim();
      final choices = draft.choiceControllers
          .map((controller) => controller.text.trim())
          .toList();
      final hasEmptyChoice = choices.any((choice) => choice.isEmpty);

      if (text.isEmpty || hasEmptyChoice) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question ${index + 1} is incomplete.')),
        );
        return;
      }

      builtQuestions.add(
        QuizQuestion(
          questionId: draft.questionId.isEmpty
              ? 'q_${DateTime.now().millisecondsSinceEpoch}_$index'
              : draft.questionId,
          questionText: text,
          choices: choices,
          correctAnswerIndex: draft.correctAnswerIndex,
          explanation: explanation,
          tag: tag.isEmpty ? 'concept' : tag,
        ),
      );
    }

    final existing = widget.existing;
    final teacherId = ref.read(currentUserProvider).valueOrNull?.uid;
    final quiz = Quiz(
      quizId:
          existing?.quizId ??
          'quiz_${_lessonId}_${DateTime.now().millisecondsSinceEpoch}',
      lessonId: _lessonId.trim(),
      title: title,
      questions: builtQuestions,
      totalPoints: builtQuestions.length,
      secondsPerQuestion: secondsPerQuestion.clamp(10, 120),
      createdBy: teacherId ?? existing?.createdBy ?? 'teacher_local',
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    setState(() => _isSaving = true);
    await ref.read(quizRepositoryProvider).upsertQuiz(quiz);
    await ref
        .read(notificationRepositoryProvider)
        .createRoleNotification(
          role: 'student',
          title: existing == null ? 'New Quiz Available' : 'Quiz Updated',
          message: '$title is ready to play. Check your lesson game now.',
          createdBy: teacherId ?? 'teacher_local',
        );
    ref.invalidate(quizzesProvider);
    ref.invalidate(notificationsProvider);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final isEdit = existing != null;
    final lessons = ref.watch(lessonsStreamProvider).valueOrNull ?? const [];
    final hasLessonChoices = lessons.isNotEmpty;

    return FractionallySizedBox(
      heightFactor: 0.95,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF4F7FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 62,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      (AppSpacing.lg * 5) +
                          MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Quiz Set' : 'Create Quiz Set',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Build your own questions for your quiz flow.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomTextField(
                          controller: _titleController,
                          label: 'Quiz Title *',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (hasLessonChoices) ...[
                          const Text(
                            'Quick select lesson',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: lessons
                                .map(
                                  (lesson) => ChoiceChip(
                                    label: Text(lesson.title),
                                    selected: _lessonId == lesson.lessonId,
                                    onSelected: (_) {
                                      setState(() {
                                        _lessonId = lesson.lessonId;
                                        _lessonIdController.text = _lessonId;
                                      });
                                    },
                                    showCheckmark: false,
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        CustomTextField(
                          controller: _lessonIdController,
                          label: 'Lesson ID *',
                          onChanged: (value) => _lessonId = value.trim(),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        CustomTextField(
                          controller: _secondsController,
                          label: 'Seconds per question (10-120)',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Questions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Use the fixed Add Question button while scrolling.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...List.generate(_questions.length, (index) {
                          final draft = _questions[index];
                          return FadeSlideIn(
                            delayMs: 25 + (index * 20),
                            child: _QuestionCard(
                              key: ValueKey(draft.localId),
                              index: index,
                              draft: draft,
                              canRemove: _questions.length > 1,
                              onRemove: () => _removeQuestion(index),
                              onCorrectAnswerChanged: (value) {
                                setState(() {
                                  draft.correctAnswerIndex = value;
                                });
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: TapScale(
                            onTap: _isSaving ? null : _save,
                            child: FilledButton.icon(
                              onPressed: _isSaving ? null : _save,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      isEdit
                                          ? Icons.check_circle_rounded
                                          : Icons.auto_awesome_rounded,
                                    ),
                              label: Text(
                                _isSaving
                                    ? 'Saving...'
                                    : (isEdit ? 'Update Quiz' : 'Save Quiz'),
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: AppSpacing.lg,
                    bottom:
                        AppSpacing.lg +
                        MediaQuery.of(context).viewInsets.bottom,
                    child: SafeArea(
                      top: false,
                      child: FloatingActionButton.extended(
                        heroTag: 'add_question_fab',
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Question'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
    required this.onCorrectAnswerChanged,
    super.key,
  });

  final int index;
  final _QuestionDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<int> onCorrectAnswerChanged;

  @override
  Widget build(BuildContext context) {
    final optionLabels = ['A', 'B', 'C', 'D'];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Question ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: canRemove ? onRemove : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Remove question',
                ),
              ],
            ),
            CustomTextField(
              controller: draft.questionController,
              label: 'Question Text *',
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 540;
                return GridView.builder(
                  shrinkWrap: true,
                  itemCount: draft.choiceControllers.length,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: compact ? 1 : 2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: compact ? 4.1 : 3.2,
                  ),
                  itemBuilder: (context, optionIndex) {
                    return CustomTextField(
                      controller: draft.choiceControllers[optionIndex],
                      label: 'Choice ${optionLabels[optionIndex]} *',
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<int>(
              value: draft.correctAnswerIndex,
              decoration: const InputDecoration(
                labelText: 'Correct Answer *',
                prefixIcon: Icon(Icons.check_circle_outline_rounded),
              ),
              items: optionLabels.asMap().entries.map((entry) {
                final option = entry.key;
                final label = entry.value;
                return DropdownMenuItem<int>(
                  value: option,
                  child: Text('Option $label'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onCorrectAnswerChanged(value);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            CustomTextField(
              controller: draft.explanationController,
              label: 'Explanation (optional)',
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            CustomTextField(
              controller: draft.tagController,
              label: 'Tag (optional)',
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionDraft {
  _QuestionDraft({
    required this.localId,
    required this.questionId,
    required this.questionController,
    required this.choiceControllers,
    required this.correctAnswerIndex,
    required this.explanationController,
    required this.tagController,
  });

  factory _QuestionDraft.empty() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _QuestionDraft(
      localId: 'local_$now',
      questionId: '',
      questionController: TextEditingController(),
      choiceControllers: List.generate(4, (_) => TextEditingController()),
      correctAnswerIndex: 0,
      explanationController: TextEditingController(),
      tagController: TextEditingController(text: 'concept'),
    );
  }

  factory _QuestionDraft.fromQuizQuestion(QuizQuestion question) {
    final filledChoices = [...question.choices];
    while (filledChoices.length < 4) {
      filledChoices.add('');
    }
    return _QuestionDraft(
      localId: question.questionId,
      questionId: question.questionId,
      questionController: TextEditingController(text: question.questionText),
      choiceControllers: filledChoices
          .take(4)
          .map((item) => TextEditingController(text: item))
          .toList(),
      correctAnswerIndex: question.correctAnswerIndex.clamp(0, 3),
      explanationController: TextEditingController(text: question.explanation),
      tagController: TextEditingController(text: question.tag),
    );
  }

  final String localId;
  final String questionId;
  final TextEditingController questionController;
  final List<TextEditingController> choiceControllers;
  int correctAnswerIndex;
  final TextEditingController explanationController;
  final TextEditingController tagController;

  void dispose() {
    questionController.dispose();
    for (final controller in choiceControllers) {
      controller.dispose();
    }
    explanationController.dispose();
    tagController.dispose();
  }
}
