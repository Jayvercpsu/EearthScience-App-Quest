import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/animations/fade_slide_in.dart';
import '../../../../shared/widgets/lesson_topic_artwork.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../progress/providers/progress_providers.dart';
import '../../providers/lesson_providers.dart';

class LessonDetailScreen extends ConsumerWidget {
  const LessonDetailScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(lessonByIdProvider(lessonId));
    final progressAsync = ref.watch(learnerProgressProvider);

    return Scaffold(
      body: lessonAsync.when(
        data: (lesson) {
          if (lesson == null) {
            return const Center(child: Text('Lesson not found'));
          }
          final lessonProgress =
              ((progressAsync.valueOrNull?.quizScores[lesson.lessonId] ?? 0.0)
                      .clamp(0.0, 1.0))
                  .toDouble();

          return Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4EA1E8), Color(0xFF164B97)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 80, 18, 18),
                      child: LessonTopicArtwork(
                        lessonId: lesson.lessonId,
                        imageUrl: lesson.bannerUrl,
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
                      FadeSlideIn(
                        child: Text(
                          lesson.title,
                          style: const TextStyle(
                            fontSize: 30 / 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _InfoPill(
                            icon: Icons.workspace_premium_outlined,
                            label: lesson.difficulty,
                            color: AppColors.secondary,
                            background: const Color(0xFFE9F8EF),
                          ),
                          _InfoPill(
                            icon: Icons.schedule_rounded,
                            label: '${lesson.estimatedMinutes} min',
                            color: AppColors.textSecondary,
                            background: Color(0xFFF1F5F9),
                          ),
                          _InfoPill(
                            icon: Icons.auto_awesome_motion_rounded,
                            label: lesson.topic,
                            color: AppColors.primary,
                            background: const Color(0xFFEAF2FF),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Overview',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      FadeSlideIn(
                        delayMs: 60,
                        child: Text(
                          lesson.content,
                          style: const TextStyle(
                            height: 1.45,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Learning Objectives',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      ...lesson.objectives
                          .take(3)
                          .map(
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
                      const SizedBox(height: 8),
                      if (lesson.resourceLinks.isNotEmpty) ...[
                        const Text(
                          'References',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...lesson.resourceLinks.map(
                          (link) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFD),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE3E8F0),
                                ),
                              ),
                              child: Text(
                                link,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (lesson.supplementFileUrl.trim().isNotEmpty) ...[
                        const Text(
                          'Supplement File',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFD),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE3E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.supplementFileName.isEmpty
                                    ? 'Attached Lesson File'
                                    : lesson.supplementFileName,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Type: ${lesson.supplementFileType.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        '${(lessonProgress * 100).toInt()}% Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: lessonProgress,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFE7ECF3),
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => context.push('/quiz/$lessonId'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Play Quiz Game'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(label: 'Loading lesson details...'),
        error: (_, __) => const Center(child: Text('Failed to load lesson.')),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
