import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/dialogs/confirmation_dialog.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../lessons/data/models/lesson.dart';
import '../../../lessons/providers/lesson_providers.dart';

class ManageLessonsScreen extends ConsumerWidget {
  const ManageLessonsScreen({super.key});

  Future<void> _openLessonSheet(
    BuildContext context,
    WidgetRef ref, {
    Lesson? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final topicController = TextEditingController(text: existing?.topic ?? '');
    final difficultyController = TextEditingController(
      text: existing?.difficulty ?? 'Beginner',
    );
    final objectivesController = TextEditingController(
      text: existing?.objectives.join('\n') ?? '',
    );
    final contentController = TextEditingController(
      text: existing?.content ?? '',
    );
    final vocabController = TextEditingController(
      text: existing?.vocabularyTerms.join(', ') ?? '',
    );
    final competencyController = TextEditingController(
      text: existing?.competencyTag ?? 'Concept Mastery',
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
                  existing == null ? 'Create Lesson' : 'Edit Lesson',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(controller: titleController, label: 'Title'),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(controller: topicController, label: 'Topic'),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: difficultyController,
                  label: 'Difficulty',
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: objectivesController,
                  label: 'Objectives (one per line)',
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: contentController,
                  label: 'Content',
                  maxLines: 6,
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: vocabController,
                  label: 'Vocabulary (comma separated)',
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: competencyController,
                  label: 'Competency Tag',
                ),
                const SizedBox(height: AppSpacing.md),
                CustomButton(
                  label: existing == null ? 'Save Lesson' : 'Update Lesson',
                  onPressed: () async {
                    final lessonId =
                        existing?.lessonId ??
                        '${titleController.text.trim().toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';

                    final lesson = Lesson(
                      lessonId: lessonId,
                      title: titleController.text.trim(),
                      topic: topicController.text.trim(),
                      difficulty: difficultyController.text.trim(),
                      objectives: objectivesController.text
                          .split('\n')
                          .map((line) => line.trim())
                          .where((line) => line.isNotEmpty)
                          .toList(),
                      content: contentController.text.trim(),
                      vocabularyTerms: vocabController.text
                          .split(',')
                          .map((item) => item.trim())
                          .where((item) => item.isNotEmpty)
                          .toList(),
                      competencyTag: competencyController.text.trim(),
                      bannerUrl: existing?.bannerUrl ?? '',
                      createdBy: existing?.createdBy ?? 'teacher_local',
                      createdAt: existing?.createdAt ?? DateTime.now(),
                    );

                    await ref
                        .read(lessonRepositoryProvider)
                        .upsertLesson(lesson);
                    ref.invalidate(lessonsProvider);

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    titleController.dispose();
    topicController.dispose();
    difficultyController.dispose();
    objectivesController.dispose();
    contentController.dispose();
    vocabController.dispose();
    competencyController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: lessonsAsync.when(
        data: (lessons) {
          return Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _openLessonSheet(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Lesson'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  itemCount: lessons.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return Card(
                      child: ListTile(
                        title: Text(lesson.title),
                        subtitle: Text(
                          '${lesson.topic} • ${lesson.difficulty}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _openLessonSheet(
                                context,
                                ref,
                                existing: lesson,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () => ConfirmationDialog.show(
                                context,
                                title: 'Delete Lesson',
                                message:
                                    'Delete ${lesson.title}? This action cannot be undone.',
                                confirmLabel: 'Delete',
                                onConfirm: () async {
                                  await ref
                                      .read(lessonRepositoryProvider)
                                      .deleteLesson(lesson.lessonId);
                                  ref.invalidate(lessonsProvider);
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
        loading: () => const LoadingWidget(label: 'Loading lessons...'),
        error: (_, __) => const Center(child: Text('Failed to load lessons.')),
      ),
    );
  }
}
