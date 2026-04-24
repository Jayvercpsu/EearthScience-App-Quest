import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/animations/fade_slide_in.dart';
import '../../../../shared/widgets/lesson_topic_artwork.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../providers/home_providers.dart';
import '../../../lessons/providers/lesson_providers.dart';
import '../../../progress/providers/progress_providers.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({required this.onOpenLessons, super.key});

  final VoidCallback onOpenLessons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greetingAsync = ref.watch(homeGreetingProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final lessonsAsync = ref.watch(lessonsProvider);
    final progressAsync = ref.watch(learnerProgressProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(homeGreetingProvider)
              ..invalidate(dashboardSummaryProvider)
              ..invalidate(lessonsProvider)
              ..invalidate(learnerProgressProvider);
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: greetingAsync.when(
                            data: (greeting) => Text(
                              greeting
                                  .replaceFirst(
                                    'Keep exploring, ',
                                    'Good morning,\n',
                                  )
                                  .replaceFirst(',', '!'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.3,
                              ),
                            ),
                            loading: () => const SizedBox(
                              height: 36,
                              child: LoadingWidget(),
                            ),
                            error: (_, __) => const Text(
                              'Good morning,\nExplorer!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.public_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    summaryAsync.when(
                      data: (summary) => Row(
                        children: [
                          Expanded(
                            child: _MiniStatCard(
                              title: 'Daily Streak',
                              value: '${summary['streak']} Days',
                              trailing: const Icon(
                                Icons.local_fire_department_rounded,
                                color: Color(0xFFF97316),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MiniStatCard(
                              title: 'XP',
                              value: '${summary['xp']}',
                              trailing: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFFEAB308),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      loading: () =>
                          const SizedBox(height: 78, child: LoadingWidget()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    lessonsAsync.when(
                      data: (lessons) {
                        final lesson = lessons.isNotEmpty
                            ? lessons.first
                            : null;
                        return FadeSlideIn(
                          delayMs: 40,
                          child: Container(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Continue Learning',
                                        style: TextStyle(
                                          color: Color(0xFF1F2A37),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lesson?.title ?? 'Earth Science',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 17,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        lesson?.topic ??
                                            'Start your next visual learning module.',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child:
                                                  const LinearProgressIndicator(
                                                    minHeight: 7,
                                                    value: 0.6,
                                                    backgroundColor:
                                                        Colors.white,
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                          AppColors.secondary,
                                                        ),
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            '60%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        height: 34,
                                        child: ElevatedButton(
                                          onPressed: lesson == null
                                              ? onOpenLessons
                                              : () => context.push(
                                                  '/lesson/${lesson.lessonId}',
                                                ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.secondary,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                            ),
                                            minimumSize: const Size(0, 34),
                                          ),
                                          child: const Text(
                                            'Resume',
                                            style: TextStyle(fontSize: 12),
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
                                    lessonId:
                                        lesson?.lessonId ?? 'plate_tectonics',
                                    borderRadius: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () =>
                          const SizedBox(height: 160, child: LoadingWidget()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Learning Modules',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: onOpenLessons,
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    lessonsAsync.when(
                      data: (lessons) {
                        final progress = progressAsync.value;
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 390;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: lessons.length.clamp(0, 6),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: compact ? 2 : 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: compact ? 1.08 : 0.92,
                                  ),
                              itemBuilder: (context, index) {
                                final lesson = lessons[index];
                                final score =
                                    progress?.quizScores[lesson.lessonId] ??
                                    (0.8 - (index * 0.1)).clamp(0.2, 0.85);
                                return FadeSlideIn(
                                  delayMs: 80 + (index * 35),
                                  child: _ModuleCard(
                                    title: lesson.title,
                                    lessonId: lesson.lessonId,
                                    progress: score,
                                    onTap: () => context.push(
                                      '/lesson/${lesson.lessonId}',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () =>
                          const SizedBox(height: 160, child: LoadingWidget()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.trailing,
  });

  final String title;
  final String value;
  final Widget trailing;

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
          trailing,
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

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.lessonId,
    required this.progress,
    required this.onTap,
  });

  final String title;
  final String lessonId;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = '${(progress * 100).toInt()}%';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7ECF3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                height: 68,
                child: LessonTopicArtwork(
                  lessonId: lessonId,
                  borderRadius: 14,
                  showLabel: false,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: progress,
                  backgroundColor: const Color(0xFFE8ECF3),
                  valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                ),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  percent,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
