import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/lesson_topic_artwork.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../providers/offline_providers.dart';

class OfflineLessonsScreen extends ConsumerStatefulWidget {
  const OfflineLessonsScreen({super.key});

  @override
  ConsumerState<OfflineLessonsScreen> createState() =>
      _OfflineLessonsScreenState();
}

class _OfflineLessonsScreenState extends ConsumerState<OfflineLessonsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(offlineLessonsProvider);
    final progressAsync = ref.watch(offlineProgressProvider);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _search = value.trim()),
            decoration: InputDecoration(
              hintText: 'Search offline lessons...',
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
          const SizedBox(height: 10),
          Expanded(
            child: lessonsAsync.when(
              data: (lessons) {
                final key = _search.toLowerCase();
                final filtered = lessons.where((lesson) {
                  if (key.isEmpty) {
                    return true;
                  }
                  return lesson.title.toLowerCase().contains(key) ||
                      lesson.topic.toLowerCase().contains(key);
                }).toList();

                final progress = progressAsync.valueOrNull;

                if (filtered.isEmpty) {
                  return const Center(child: Text('No offline lessons found.'));
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final lesson = filtered[index];
                    final lessonProgress =
                        ((progress?.quizScores[lesson.lessonId] ?? 0.0).clamp(
                          0.0,
                          1.0,
                        )).toDouble();
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () =>
                          context.push('/offline-lesson/${lesson.lessonId}'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE7ECF3)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 58,
                              height: 58,
                              child: LessonTopicArtwork(
                                lessonId: lesson.lessonId,
                                imageUrl: lesson.bannerUrl,
                                borderRadius: 14,
                                showLabel: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
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
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const LoadingWidget(label: 'Loading offline lessons...'),
              error: (_, __) =>
                  const Center(child: Text('Unable to load offline lessons.')),
            ),
          ),
        ],
      ),
    );
  }
}
