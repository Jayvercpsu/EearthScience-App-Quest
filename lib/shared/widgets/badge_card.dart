import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import 'app_card.dart';

class BadgeCard extends StatelessWidget {
  const BadgeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final tone = unlocked ? AppColors.accent : const Color(0xFF94A3B8);

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tone),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(description),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
            color: tone,
          ),
        ],
      ),
    );
  }
}
