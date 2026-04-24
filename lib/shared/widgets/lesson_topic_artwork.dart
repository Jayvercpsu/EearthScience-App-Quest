import 'package:flutter/material.dart';

class LessonTopicArtwork extends StatelessWidget {
  const LessonTopicArtwork({
    required this.lessonId,
    this.height = 120,
    this.width = double.infinity,
    this.borderRadius = 22,
    this.showLabel = true,
    super.key,
  });

  final String lessonId;
  final double height;
  final double width;
  final double borderRadius;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = lessonTopicVisualFor(lessonId);
    final isCompact = height < 88;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: theme.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.gradient.last.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            Positioned(
              top: -26,
              right: -18,
              child: Container(
                width: height * 0.72,
                height: height * 0.72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -34,
              left: -10,
              child: Container(
                width: height * 0.86,
                height: height * 0.86,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 12,
              child: showLabel
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        theme.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: isCompact
                    ? Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          theme.primaryIcon,
                          color: Colors.white,
                          size: height * 0.36,
                        ),
                      )
                    : _TopicArtworkBody(lessonId: lessonId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LessonTopicVisual {
  const LessonTopicVisual({
    required this.label,
    required this.gradient,
    required this.accent,
    required this.primaryIcon,
    required this.secondaryIcon,
  });

  final String label;
  final List<Color> gradient;
  final Color accent;
  final IconData primaryIcon;
  final IconData secondaryIcon;
}

LessonTopicVisual lessonTopicVisualFor(String lessonId) {
  switch (lessonId) {
    case 'earth_structure':
      return const LessonTopicVisual(
        label: 'Earth Layers',
        gradient: [Color(0xFF123D8B), Color(0xFF0A6FD6)],
        accent: Color(0xFFFFB547),
        primaryIcon: Icons.public_rounded,
        secondaryIcon: Icons.layers_rounded,
      );
    case 'plate_tectonics':
      return const LessonTopicVisual(
        label: 'Plate Motion',
        gradient: [Color(0xFF7C2D12), Color(0xFFEA580C)],
        accent: Color(0xFFFFE082),
        primaryIcon: Icons.terrain_rounded,
        secondaryIcon: Icons.swap_horiz_rounded,
      );
    case 'weather_systems':
      return const LessonTopicVisual(
        label: 'Atmosphere',
        gradient: [Color(0xFF0F766E), Color(0xFF2DD4BF)],
        accent: Color(0xFFFDE68A),
        primaryIcon: Icons.cloud_queue_rounded,
        secondaryIcon: Icons.wb_sunny_rounded,
      );
    default:
      return const LessonTopicVisual(
        label: 'Earth Science',
        gradient: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
        accent: Color(0xFFFFD166),
        primaryIcon: Icons.explore_rounded,
        secondaryIcon: Icons.auto_awesome_rounded,
      );
  }
}

class _TopicArtworkBody extends StatelessWidget {
  const _TopicArtworkBody({required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    switch (lessonId) {
      case 'earth_structure':
        return const _EarthLayersArtwork();
      case 'plate_tectonics':
        return const _PlateTectonicsArtwork();
      case 'weather_systems':
        return const _WeatherSystemsArtwork();
      default:
        final theme = lessonTopicVisualFor(lessonId);
        return Align(
          alignment: Alignment.bottomRight,
          child: Icon(theme.primaryIcon, color: Colors.white, size: 58),
        );
    }
  }
}

class _EarthLayersArtwork extends StatelessWidget {
  const _EarthLayersArtwork();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _MiniSpecChip(icon: Icons.layers_clear_rounded, label: 'Crust'),
              const SizedBox(height: 6),
              _MiniSpecChip(icon: Icons.blur_circular_rounded, label: 'Mantle'),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFC04D),
              ),
            ),
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE07A24),
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFB91C1C),
              ),
            ),
            Positioned(
              right: -2,
              child: Container(
                width: 42,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFF11397B),
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(44),
                  ),
                ),
              ),
            ),
            const Positioned(
              bottom: 14,
              right: 3,
              child: Icon(Icons.public_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlateTectonicsArtwork extends StatelessWidget {
  const _PlateTectonicsArtwork();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 18,
          child: Row(
            children: [
              Expanded(
                child: Transform.rotate(
                  angle: -0.08,
                  child: _PlateBlock(
                    color: const Color(0xFFFFC078),
                    borderColor: const Color(0xFF7C2D12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Transform.rotate(
                  angle: 0.08,
                  child: _PlateBlock(
                    color: const Color(0xFFF9A8D4),
                    borderColor: const Color(0xFF7C2D12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          left: 22,
          top: 28,
          child: Icon(
            Icons.keyboard_double_arrow_left_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const Positioned(
          right: 22,
          top: 28,
          child: Icon(
            Icons.keyboard_double_arrow_right_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeatherSystemsArtwork extends StatelessWidget {
  const _WeatherSystemsArtwork();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          right: 18,
          top: 10,
          child: Icon(
            Icons.wb_sunny_rounded,
            color: Color(0xFFFDE68A),
            size: 34,
          ),
        ),
        Positioned(
          left: 6,
          top: 26,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.cloud_queue_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
        const Positioned(
          left: 24,
          bottom: 18,
          child: Icon(Icons.air_rounded, color: Colors.white, size: 28),
        ),
        const Positioned(
          left: 58,
          bottom: 16,
          child: Icon(Icons.air_rounded, color: Colors.white70, size: 22),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.thunderstorm_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlateBlock extends StatelessWidget {
  const _PlateBlock({required this.color, required this.borderColor});

  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withValues(alpha: 0.35)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 10,
            right: 10,
            child: Container(
              height: 4,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          Positioned(
            left: 16,
            top: 22,
            right: 18,
            child: Container(
              height: 4,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            left: 20,
            top: 34,
            right: 24,
            child: Container(
              height: 4,
              color: Colors.white.withValues(alpha: 0.32),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSpecChip extends StatelessWidget {
  const _MiniSpecChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
