import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1564E8);
  static const Color secondary = Color(0xFF1FA867);
  static const Color accent = Color(0xFFFF8A1F);
  static const Color background = Color(0xFFF3F5F9);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF10224C);
  static const Color textSecondary = Color(0xFF667085);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0284C7);
  static const Color navy = Color(0xFF001E5A);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF02296E), Color(0xFF003D96)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient rewardGradient = LinearGradient(
    colors: [Color(0xFFFFA726), Color(0xFFFFC107)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF01133E), Color(0xFF02296E), Color(0xFF001546)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
