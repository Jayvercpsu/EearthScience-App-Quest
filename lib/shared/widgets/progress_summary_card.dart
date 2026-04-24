import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import 'animated_progress_bar.dart';
import 'app_card.dart';

class ProgressSummaryCard extends StatelessWidget {
  const ProgressSummaryCard({
    required this.title,
    required this.value,
    required this.progress,
    this.subtitle,
    super.key,
  });

  final String title;
  final String value;
  final double progress;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          AnimatedProgressBar(value: progress, color: AppColors.primary),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle!),
          ],
        ],
      ),
    );
  }
}
