import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../providers/offline_providers.dart';

class OfflineProgressScreen extends ConsumerWidget {
  const OfflineProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(offlineProgressProvider);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: progressAsync.when(
        data: (progress) {
          final mastery = progress.masteryPercentage.clamp(0.0, 1.0);
          final vocabulary = progress.vocabularyProgress.clamp(0.0, 1.0);
          final conceptual = progress.conceptualProgress.clamp(0.0, 1.0);
          return ListView(
            children: [
              _ProgressCard(
                label: 'Mastery',
                value: mastery,
                color: AppColors.primary,
              ),
              const SizedBox(height: 10),
              _ProgressCard(
                label: 'Vocabulary',
                value: vocabulary,
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(height: 10),
              _ProgressCard(
                label: 'Conceptual',
                value: conceptual,
                color: const Color(0xFFF97316),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6ECF4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Completed Lessons',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (progress.completedLessons.isEmpty)
                      const Text(
                        'No completed lessons yet. Start an offline quiz game.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    else
                      ...progress.completedLessons.map(
                        (lessonId) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF16A34A),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(child: Text(lessonId)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () =>
            const LoadingWidget(label: 'Loading offline progress...'),
        error: (_, __) => const Center(child: Text('Unable to load progress.')),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6ECF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: const Color(0xFFE8ECF3),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(value * 100).toInt()}%',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
