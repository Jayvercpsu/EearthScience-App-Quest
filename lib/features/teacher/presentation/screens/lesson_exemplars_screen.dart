import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/dialogs/confirmation_dialog.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/lesson_exemplar.dart';
import '../../providers/teacher_providers.dart';

class LessonExemplarsScreen extends ConsumerWidget {
  const LessonExemplarsScreen({super.key});

  Future<void> _openExemplarSheet(
    BuildContext context,
    WidgetRef ref, {
    LessonExemplar? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final topicController = TextEditingController(text: existing?.topic ?? '');
    final objectivesController = TextEditingController(
      text: existing?.objectives.join('\n') ?? '',
    );
    final flowController = TextEditingController(
      text: existing?.teachingFlow ?? '',
    );
    final linkedController = TextEditingController(
      text: existing?.linkedLessons.join(', ') ?? '',
    );
    final recommendationController = TextEditingController(
      text: existing?.recommendations ?? '',
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
                  existing == null ? 'Create Exemplar' : 'Edit Exemplar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(controller: titleController, label: 'Title'),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(controller: topicController, label: 'Topic'),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: objectivesController,
                  label: 'Objectives (one per line)',
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: flowController,
                  label: 'Teaching Flow',
                  maxLines: 5,
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: linkedController,
                  label: 'Linked Lessons (IDs, comma separated)',
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomTextField(
                  controller: recommendationController,
                  label: 'Recommendations',
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomButton(
                  label: existing == null ? 'Save Exemplar' : 'Update Exemplar',
                  onPressed: () async {
                    final exemplar = LessonExemplar(
                      exemplarId:
                          existing?.exemplarId ??
                          'exemplar_${DateTime.now().millisecondsSinceEpoch}',
                      title: titleController.text.trim(),
                      topic: topicController.text.trim(),
                      objectives: objectivesController.text
                          .split('\n')
                          .map((line) => line.trim())
                          .where((line) => line.isNotEmpty)
                          .toList(),
                      teachingFlow: flowController.text.trim(),
                      linkedLessons: linkedController.text
                          .split(',')
                          .map((item) => item.trim())
                          .where((item) => item.isNotEmpty)
                          .toList(),
                      recommendations: recommendationController.text.trim(),
                    );

                    await ref
                        .read(teacherRepositoryProvider)
                        .saveExemplar(exemplar);
                    ref.invalidate(lessonExemplarsProvider);
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
    topicController.dispose();
    objectivesController.dispose();
    flowController.dispose();
    linkedController.dispose();
    recommendationController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exemplarsAsync = ref.watch(lessonExemplarsProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: exemplarsAsync.when(
        data: (exemplars) {
          return Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _openExemplarSheet(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Exemplar'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  itemCount: exemplars.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final exemplar = exemplars[index];
                    return Card(
                      child: ListTile(
                        title: Text(exemplar.title),
                        subtitle: Text(
                          '${exemplar.topic}\nLinked: ${exemplar.linkedLessons.join(', ')}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _openExemplarSheet(
                                context,
                                ref,
                                existing: exemplar,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () => ConfirmationDialog.show(
                                context,
                                title: 'Delete Exemplar',
                                message: 'Delete ${exemplar.title}?',
                                confirmLabel: 'Delete',
                                onConfirm: () async {
                                  await ref
                                      .read(teacherRepositoryProvider)
                                      .deleteExemplar(exemplar.exemplarId);
                                  ref.invalidate(lessonExemplarsProvider);
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
        loading: () => const LoadingWidget(label: 'Loading exemplars...'),
        error: (_, __) =>
            const Center(child: Text('Unable to load exemplars.')),
      ),
    );
  }
}
