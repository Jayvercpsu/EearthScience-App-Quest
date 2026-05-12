import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../notifications/providers/notification_providers.dart';
import '../../providers/progress_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(learnerProgressProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Progress',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (unread > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text('Logout Account'),
                    content: const Text(
                      'Are you sure you want to logout from your student account?',
                    ),
                    actionsAlignment: MainAxisAlignment.end,
                    actionsOverflowAlignment: OverflowBarAlignment.end,
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );

              if (confirm != true || !context.mounted) {
                return;
              }
              await ref.read(authControllerProvider.notifier).signOut();
              if (!context.mounted) {
                return;
              }
              context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: progressAsync.when(
          data: (progress) {
            final mastery = progress.masteryPercentage.clamp(0, 1).toDouble();
            final quizAverage = progress.quizScores.values.isEmpty
                ? 0.0
                : progress.quizScores.values.reduce((a, b) => a + b) /
                      progress.quizScores.length;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF011845), Color(0xFF023874)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Overall Mastery',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(mastery * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 36 / 2,
                              ),
                            ),
                            const Text(
                              'Keep going!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 82,
                            height: 82,
                            child: CircularProgressIndicator(
                              value: mastery,
                              strokeWidth: 9,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.17,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF24D6C4),
                              ),
                            ),
                          ),
                          Text(
                            '${(mastery * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE6ECF4)),
                  ),
                  child: Row(
                    children: [
                      _SummaryStat(
                        title: 'Lessons\nCompleted',
                        value: '${progress.completedLessons.length}',
                      ),
                      _divider(),
                      _SummaryStat(
                        title: 'Average\nQuiz Score',
                        value: '${(quizAverage * 100).toStringAsFixed(0)}%',
                      ),
                      _divider(),
                      _SummaryStat(
                        title: 'Current\nStreak',
                        value:
                            '${progress.engagementStats['dailyStreak'] ?? 0} Days',
                        highlight: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'Competency Breakdown',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    TextButton(onPressed: () {}, child: const Text('View All')),
                  ],
                ),
                _BreakdownBar(
                  title: 'Earth\'s Structure',
                  value: 0.8,
                  color: const Color(0xFF14B8A6),
                ),
                _BreakdownBar(
                  title: 'Plate Tectonics',
                  value: 0.6,
                  color: const Color(0xFF22C55E),
                ),
                _BreakdownBar(
                  title: 'Earthquakes',
                  value: 0.45,
                  color: const Color(0xFFF59E0B),
                ),
                _BreakdownBar(
                  title: 'Volcanoes',
                  value: 0.3,
                  color: const Color(0xFFEF4444),
                ),
                _BreakdownBar(
                  title: 'Weather Systems',
                  value: 0.75,
                  color: const Color(0xFF0EA5E9),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
          loading: () => const LoadingWidget(label: 'Loading progress...'),
          error: (_, __) =>
              const Center(child: Text('Failed to load progress.')),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 40,
      width: 1,
      color: const Color(0xFFE6ECF4),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.title,
    required this.value,
    this.highlight = false,
  });

  final String title;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(title, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: const Color(0xFFE8ECF3),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              '${(value * 100).toInt()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
