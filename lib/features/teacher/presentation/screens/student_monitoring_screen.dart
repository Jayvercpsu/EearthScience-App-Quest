import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/animated_progress_bar.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../providers/teacher_providers.dart';

class StudentMonitoringScreen extends ConsumerStatefulWidget {
  const StudentMonitoringScreen({super.key});

  @override
  ConsumerState<StudentMonitoringScreen> createState() =>
      _StudentMonitoringScreenState();
}

class _StudentMonitoringScreenState
    extends ConsumerState<StudentMonitoringScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshotsAsync = ref.watch(teacherSnapshotsProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: snapshotsAsync.when(
        data: (snapshots) {
          final filtered = snapshots.where((item) {
            final key = _search.toLowerCase();
            if (key.isEmpty) {
              return true;
            }
            return item.studentName.toLowerCase().contains(key);
          }).toList();

          if (filtered.isEmpty) {
            return Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _search = value.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Search student...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Expanded(
                  child: Center(child: Text('No student records yet.')),
                ),
              ],
            );
          }

          return Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search student...',
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
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final snapshot = filtered[index];
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
                            Text(
                              'Lessons completed: ${snapshot.completedLessons}',
                            ),
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
                ),
              ),
            ],
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
