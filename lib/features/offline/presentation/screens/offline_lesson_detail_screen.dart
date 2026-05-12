import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../lessons/data/models/lesson.dart';
import '../../../../shared/widgets/lesson_topic_artwork.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../providers/offline_providers.dart';

class OfflineLessonDetailScreen extends ConsumerWidget {
  const OfflineLessonDetailScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(offlineLessonsProvider);

    return Scaffold(
      body: lessonsAsync.when(
        data: (lessons) {
          Lesson? lesson;
          for (final item in lessons) {
            if (item.lessonId == lessonId) {
              lesson = item;
              break;
            }
          }
          if (lesson == null) {
            return const Center(child: Text('Lesson not found.'));
          }
          final resolvedLesson = lesson;

          return Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/galaxy.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Color(0x9E0B3C8A),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 80, 18, 18),
                      child: LessonTopicArtwork(
                        lessonId: resolvedLesson.lessonId,
                        imageUrl: resolvedLesson.bannerUrl,
                        borderRadius: 28,
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 4,
                    left: 10,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  transform: Matrix4.translationValues(0, -14, 0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                    children: [
                      Text(
                        resolvedLesson.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resolvedLesson.content,
                        style: const TextStyle(height: 1.45),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Learning Objectives',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      ...resolvedLesson.objectives.map(
                        (objective) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.secondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  objective,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => context.push(
                          '/offline-quiz/${resolvedLesson.lessonId}',
                        ),
                        child: const Text('Play Offline Quiz'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(label: 'Loading offline lesson...'),
        error: (_, __) =>
            const Center(child: Text('Unable to load offline lesson.')),
      ),
    );
  }
}
