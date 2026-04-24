import 'package:flutter/material.dart';

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    required this.child,
    this.delayMs = 0,
    this.durationMs = 420,
    this.offset = const Offset(0, 14),
    super.key,
  });

  final Widget child;
  final int delayMs;
  final int durationMs;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: durationMs + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final t = ((value * (durationMs + delayMs) - delayMs) / durationMs)
            .clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(offset.dx * (1 - t), offset.dy * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
