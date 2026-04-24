import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    required this.option,
    required this.index,
    required this.selectedIndex,
    required this.isCorrect,
    required this.showResult,
    required this.onTap,
    super.key,
  });

  final String option;
  final int index;
  final int? selectedIndex;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    Color borderColor = const Color(0xFFD1D5DB);
    Color fillColor = Colors.white;

    if (showResult) {
      if (isCorrect) {
        borderColor = AppColors.success;
        fillColor = AppColors.success.withValues(alpha: 0.08);
      } else if (isSelected) {
        borderColor = AppColors.error;
        fillColor = AppColors.error.withValues(alpha: 0.08);
      }
    } else if (isSelected) {
      borderColor = AppColors.primary;
      fillColor = AppColors.primary.withValues(alpha: 0.08);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor, width: 1.3),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(option),
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(String.fromCharCode(65 + index)),
        ),
      ),
    );
  }
}
