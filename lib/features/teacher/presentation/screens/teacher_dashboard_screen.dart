import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../lessons/providers/lesson_providers.dart';
import '../../../quiz/providers/quiz_providers.dart';
import '../../providers/teacher_providers.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsProvider);
    final quizzesAsync = ref.watch(quizzesProvider);
    final snapshotsAsync = ref.watch(teacherSnapshotsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/galaxy.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Color(0x9E0B3C8A),
                    BlendMode.darken,
                  ),
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Monitor student learning, manage content, and refine lesson exemplars.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: lessonsAsync.when(
                    data: (lessons) => StatCard(
                      label: 'Total Lessons',
                      value: '${lessons.length}',
                      icon: Icons.menu_book_rounded,
                      color: AppColors.primary,
                    ),
                    loading: () =>
                        const SizedBox(height: 90, child: LoadingWidget()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: quizzesAsync.when(
                    data: (quizzes) => StatCard(
                      label: 'Total Quizzes',
                      value: '${quizzes.length}',
                      icon: Icons.quiz_rounded,
                      color: AppColors.accent,
                    ),
                    loading: () =>
                        const SizedBox(height: 90, child: LoadingWidget()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            snapshotsAsync.when(
              data: (snapshots) {
                final average = snapshots.isEmpty
                    ? 0.0
                    : snapshots
                              .map((item) => item.averageScore)
                              .reduce((a, b) => a + b) /
                          snapshots.length;
                return StatCard(
                  label: 'Student Performance Avg',
                  value: '${(average * 100).toStringAsFixed(0)}%',
                  icon: Icons.analytics_rounded,
                  color: AppColors.secondary,
                );
              },
              loading: () => const SizedBox(height: 90, child: LoadingWidget()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
