import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/dialogs/confirmation_dialog.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/lesson_exemplar.dart';
import '../../providers/teacher_providers.dart';

class LessonExemplarsScreen extends ConsumerStatefulWidget {
  const LessonExemplarsScreen({super.key});

  @override
  ConsumerState<LessonExemplarsScreen> createState() =>
      _LessonExemplarsScreenState();
}

class _LessonExemplarsScreenState extends ConsumerState<LessonExemplarsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openExemplarSheet(
    BuildContext context, {
    LessonExemplar? existing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ExemplarEditorSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exemplarsAsync = ref.watch(lessonExemplarsProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: exemplarsAsync.when(
        data: (exemplars) {
          final filtered = exemplars.where((item) {
            final key = _search.toLowerCase();
            if (key.isEmpty) {
              return true;
            }
            return item.title.toLowerCase().contains(key) ||
                item.topic.toLowerCase().contains(key);
          }).toList();

          return Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search exemplars...',
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
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _openExemplarSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Exemplar'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No exemplars found.'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final exemplar = filtered[index];
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
                                            .deleteExemplar(
                                              exemplar.exemplarId,
                                            );
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

class _ExemplarEditorSheet extends ConsumerStatefulWidget {
  const _ExemplarEditorSheet({this.existing});

  final LessonExemplar? existing;

  @override
  ConsumerState<_ExemplarEditorSheet> createState() =>
      _ExemplarEditorSheetState();
}

class _ExemplarEditorSheetState extends ConsumerState<_ExemplarEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _topicController;
  late final TextEditingController _objectivesController;
  late final TextEditingController _flowController;
  late final TextEditingController _linkedController;
  late final TextEditingController _recommendationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _topicController = TextEditingController(text: existing?.topic ?? '');
    _objectivesController = TextEditingController(
      text: existing?.objectives.join('\n') ?? '',
    );
    _flowController = TextEditingController(text: existing?.teachingFlow ?? '');
    _linkedController = TextEditingController(
      text: existing?.linkedLessons.join(', ') ?? '',
    );
    _recommendationController = TextEditingController(
      text: existing?.recommendations ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _objectivesController.dispose();
    _flowController.dispose();
    _linkedController.dispose();
    _recommendationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSaving = true);
    try {
      final existing = widget.existing;
      final exemplar = LessonExemplar(
        exemplarId:
            existing?.exemplarId ??
            'exemplar_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        topic: _topicController.text.trim(),
        objectives: _objectivesController.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList(),
        teachingFlow: _flowController.text.trim(),
        linkedLessons: _linkedController.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        recommendations: _recommendationController.text.trim(),
      );
      await ref.read(teacherRepositoryProvider).saveExemplar(exemplar);
      ref.invalidate(lessonExemplarsProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
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
            CustomTextField(controller: _titleController, label: 'Title'),
            const SizedBox(height: AppSpacing.sm),
            CustomTextField(controller: _topicController, label: 'Topic'),
            const SizedBox(height: AppSpacing.sm),
            CustomTextField(
              controller: _objectivesController,
              label: 'Objectives (one per line)',
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.sm),
            CustomTextField(
              controller: _flowController,
              label: 'Teaching Flow',
              maxLines: 5,
            ),
            const SizedBox(height: AppSpacing.sm),
            CustomTextField(
              controller: _linkedController,
              label: 'Linked Lessons (IDs, comma separated)',
            ),
            const SizedBox(height: AppSpacing.sm),
            CustomTextField(
              controller: _recommendationController,
              label: 'Recommendations',
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.md),
            CustomButton(
              label: existing == null ? 'Save Exemplar' : 'Update Exemplar',
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
