import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/animated_progress_bar.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../providers/teacher_providers.dart';

class StudentMonitoringScreen extends ConsumerWidget {
  const StudentMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotsAsync = ref.watch(teacherSnapshotsProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: snapshotsAsync.when(
        data: (snapshots) {
          if (snapshots.isEmpty) {
            return const Center(child: Text('No student records yet.'));
          }

          return ListView.separated(
            itemCount: snapshots.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final snapshot = snapshots[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snapshot.studentName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Lessons completed: ${snapshot.completedLessons}'),
                      const SizedBox(height: AppSpacing.sm),
                      _MetricBar(
                        label: 'Overall Score',
                        value: snapshot.averageScore,
                        color: AppColors.primary,
                      ),
                      _MetricBar(
                        label: 'Vocabulary Performance',
                        value: snapshot.vocabularyPerformance,
                        color: AppColors.secondary,
                      ),
                      _MetricBar(
                        label: 'Conceptual Understanding',
                        value: snapshot.conceptualPerformance,
                        color: AppColors.accent,
                      ),
                      _MetricBar(
                        label: 'Engagement Level',
                        value: snapshot.engagementLevel,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () =>
            const LoadingWidget(label: 'Loading student monitoring data...'),
        error: (_, __) => const Center(
          child: Text('Unable to load student monitoring data.'),
        ),
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('${(clamped * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedProgressBar(value: clamped, color: color),
        ],
      ),
    );
  }
}
