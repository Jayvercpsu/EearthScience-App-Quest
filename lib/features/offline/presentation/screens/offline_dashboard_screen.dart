import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/lesson_topic_artwork.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../providers/offline_providers.dart';

class OfflineDashboardScreen extends ConsumerWidget {
  const OfflineDashboardScreen({required this.onOpenLessons, super.key});

  final VoidCallback onOpenLessons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nicknameAsync = ref.watch(offlineNicknameProvider);
    final lessonsAsync = ref.watch(offlineLessonsProvider);
    final progressAsync = ref.watch(offlineProgressProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(offlineNicknameProvider)
          ..invalidate(offlineLessonsProvider)
          ..invalidate(offlineProgressProvider)
          ..invalidate(offlineQuizzesProvider);
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/galaxy.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Color(0x9E0B3C8A),
                  BlendMode.darken,
                ),
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    color: Color(0xFFD6E7FF),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  nicknameAsync.when(
                    data: (nick) => 'Good morning,\n${nick ?? 'Student'}!',
                    loading: () => 'Good morning,\nStudent!',
                    error: (_, __) => 'Good morning,\nStudent!',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                progressAsync.when(
                  data: (progress) {
                    final xp = (progress.masteryPercentage * 1000).round();
                    final streak =
                        progress.engagementStats['dailyStreak'] as int? ?? 0;
                    return Row(
                      children: [
                        Expanded(
                          child: _MiniStatCard(
                            title: 'Daily Streak',
                            value: '$streak Days',
                            icon: Icons.local_fire_department_rounded,
                            iconColor: const Color(0xFFF97316),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStatCard(
                            title: 'XP',
                            value: '$xp',
                            icon: Icons.auto_awesome_rounded,
                            iconColor: const Color(0xFFEAB308),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const SizedBox(height: 80, child: LoadingWidget()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: lessonsAsync.when(
              data: (lessons) {
                final progress = progressAsync.valueOrNull;
                final completed =
                    progress?.completedLessons ?? const <String>[];
                final nextLesson = lessons
                    .where((lesson) => !completed.contains(lesson.lessonId))
                    .firstOrNull;
                final completedCount = completed.length;
                final totalCount = lessons.length;
                final completionRatio = totalCount == 0
                    ? 0.0
                    : (completedCount / totalCount).clamp(0.0, 1.0);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0F2FE), Color(0xFFDCFCE7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Offline Learning Focus',
                              style: TextStyle(
                                color: Color(0xFF1F2A37),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextLesson?.title ?? 'All Lessons Completed',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 7,
                                value: completionRatio,
                                backgroundColor: Colors.white,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(completionRatio * 100).toInt()}% complete',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 34,
                              child: ElevatedButton(
                                onPressed: nextLesson == null
                                    ? onOpenLessons
                                    : () => context.push(
                                        '/offline-lesson/${nextLesson.lessonId}',
                                      ),
                                child: Text(
                                  nextLesson == null
                                      ? 'Review Lessons'
                                      : 'Continue',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 108,
                        height: 102,
                        child: LessonTopicArtwork(
                          lessonId: nextLesson?.lessonId ?? 'weather_systems',
                          imageUrl: nextLesson?.bannerUrl ?? '',
                          borderRadius: 18,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () =>
                  const SizedBox(height: 180, child: LoadingWidget()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
