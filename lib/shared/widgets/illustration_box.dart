import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class IllustrationBox extends StatelessWidget {
  const IllustrationBox({
    required this.icon,
    required this.colors,
    this.height = 220,
    this.label,
    super.key,
  });

  final IconData icon;
  final List<Color> colors;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -20,
            child: Icon(
              Icons.blur_on_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            left: -12,
            bottom: -18,
            child: Icon(
              Icons.blur_circular,
              size: 100,
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  child: Icon(icon, size: 56, color: AppColors.navy),
                ),
                if (label != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
