import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/animations/fade_slide_in.dart';
import '../../../../shared/widgets/lesson_topic_artwork.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../progress/providers/progress_providers.dart';
import '../../providers/lesson_providers.dart';

class LessonListScreen extends ConsumerStatefulWidget {
  const LessonListScreen({super.key});

  @override
  ConsumerState<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends ConsumerState<LessonListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsProvider);
    final progressAsync = ref.watch(learnerProgressProvider);
    final searchText = ref.watch(lessonSearchProvider);
    final filter = ref.watch(lessonFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lessons',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.menu_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              const SizedBox(height: 4),
              TextField(
                controller: _searchController,
                onChanged: (value) =>
                    ref.read(lessonSearchProvider.notifier).state = value,
                decoration: InputDecoration(
                  hintText: 'Search lessons...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _FilterTabs(
                selected: filter,
                onChange: (value) =>
                    ref.read(lessonFilterProvider.notifier).state = value,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: lessonsAsync.when(
                  data: (lessons) {
                    final filtered = lessons.where((lesson) {
                      final matchesSearch =
                          lesson.title.toLowerCase().contains(
                            searchText.toLowerCase(),
                          ) ||
                          lesson.topic.toLowerCase().contains(
                            searchText.toLowerCase(),
                          );
                      final matchesFilter =
                          filter == 'All' || lesson.difficulty == filter;
                      return matchesSearch && matchesFilter;
                    }).toList();

                    final progress = progressAsync.value;

                    if (filtered.isEmpty) {
                      return const Center(child: Text('No lessons found.'));
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final lesson = filtered[index];
                        final lessonProgress =
                            progress?.quizScores[lesson.lessonId] ??
                            (0.8 - (index * 0.15)).clamp(0.2, 0.9);
                        final locked = index > 1;

                        return FadeSlideIn(
                          delayMs: 40 + (index * 30),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: locked
                                ? null
                                : () => context.push(
                                    '/lesson/${lesson.lessonId}',
                                  ),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE7ECF3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 58,
                                    height: 58,
                                    child: LessonTopicArtwork(
                                      lessonId: lesson.lessonId,
                                      borderRadius: 14,
                                      showLabel: false,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lesson.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          lesson.difficulty,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                child: LinearProgressIndicator(
                                                  value: lessonProgress,
                                                  minHeight: 4,
                                                  backgroundColor: const Color(
                                                    0xFFE7ECF3,
                                                  ),
                                                  valueColor:
                                                      const AlwaysStoppedAnimation(
                                                        Color(0xFF16A34A),
                                                      ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${(lessonProgress * 100).toInt()}%',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    locked
                                        ? Icons.lock_outline_rounded
                                        : Icons.chevron_right_rounded,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const LoadingWidget(label: 'Loading lessons...'),
                  error: (_, __) =>
                      const Center(child: Text('Unable to load lessons.')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onChange});

  final String selected;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    final options = ['All', 'Beginner', 'Intermediate', 'Advanced'];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options
          .map(
            (option) => ChoiceChip(
              label: Text(option, style: const TextStyle(fontSize: 11)),
              selected: selected == option,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected == option
                    ? Colors.white
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: const Color(0xFFF1F4F8),
              side: BorderSide.none,
              onSelected: (_) => onChange(option),
            ),
          )
          .toList(),
    );
  }
}
