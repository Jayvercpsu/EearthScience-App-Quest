import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/animations/fade_slide_in.dart';
import '../../providers/offline_providers.dart';

class OfflineGamesScreen extends ConsumerWidget {
  const OfflineGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(offlineProgressProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Earth Science Game Hub',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 4),
          const Text(
            'Static offline game list for students. No teacher account sync needed.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: progressAsync.when(
                data: (progress) => ListView.separated(
                  key: const ValueKey('offline_games_loaded'),
                  itemCount: _offlineGames.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final game = _offlineGames[index];
                    final score = game.lessonId == null
                        ? null
                        : ((progress.quizScores[game.lessonId] ?? 0.0).clamp(
                            0.0,
                            1.0,
                          )).toDouble();
                    return FadeSlideIn(
                      delayMs: index * 45,
                      child: _GameCard(
                        game: game,
                        score: score,
                        onPlay: () => context.push(game.route),
                      ),
                    );
                  },
                ),
                loading: () => const _GamesLoadingShell(
                  key: ValueKey('offline_games_loading'),
                ),
                error: (_, __) => const Center(
                  key: ValueKey('offline_games_error'),
                  child: Text(
                    'Unable to load offline game progress right now.',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GamesLoadingShell extends StatelessWidget {
  const _GamesLoadingShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F8FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDCE6F8)),
          ),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.onPlay, this.score});

  final _OfflineGame game;
  final double? score;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final progressPercent = score == null
        ? null
        : '${((score ?? 0) * 100).toInt()}%';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            game.accent.withValues(alpha: 0.15),
            game.accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: game.accent.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: game.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(game.icon, color: game.accent, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  game.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: game.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  game.difficulty,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            game.description,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
          if (score != null) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: score,
                      minHeight: 5,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(game.accent),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  progressPercent ?? '0%',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onPlay,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(game.actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineGame {
  const _OfflineGame({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.route,
    required this.icon,
    required this.accent,
    required this.difficulty,
    this.lessonId,
  });

  final String title;
  final String description;
  final String actionLabel;
  final String route;
  final IconData icon;
  final Color accent;
  final String difficulty;
  final String? lessonId;
}

const _offlineGames = <_OfflineGame>[
  _OfflineGame(
    title: 'Rock Cycle Memory',
    description:
        'Match Rock Cycle terms and clues across 7 levels from Pebble to Epic.',
    actionLabel: 'Play Levels',
    route: '/offline-mini-game',
    icon: Icons.memory_rounded,
    accent: Color(0xFF0EA5E9),
    difficulty: 'Easy',
  ),
  _OfflineGame(
    title: 'Plate Boundary Sort',
    description:
        'Drag tectonic clues into Convergent, Divergent, and Transform zones.',
    actionLabel: 'Play Sort',
    route: '/offline-plate-boundary-game',
    icon: Icons.swap_horiz_rounded,
    accent: Color(0xFF7C3AED),
    difficulty: 'Medium',
  ),
  _OfflineGame(
    title: 'Earth Layers Stack',
    description:
        'Reorder layers from crust to inner core and check your arrangement.',
    actionLabel: 'Play Stack',
    route: '/offline-earth-layers-game',
    icon: Icons.layers_rounded,
    accent: Color(0xFF2563EB),
    difficulty: 'Medium',
  ),
  _OfflineGame(
    title: 'Earth Layers Sprint',
    description:
        'Quick quiz about crust, mantle, and core. Build speed and accuracy.',
    actionLabel: 'Play Quiz',
    route: '/offline-quiz/earth_crust_layers',
    lessonId: 'earth_crust_layers',
    icon: Icons.public_rounded,
    accent: Color(0xFF0F766E),
    difficulty: 'Easy',
  ),
  _OfflineGame(
    title: 'Plate Boundary Blitz',
    description:
        'Identify convergent, divergent, and transform boundaries in fast rounds.',
    actionLabel: 'Play Quiz',
    route: '/offline-quiz/earth_overview',
    lessonId: 'earth_overview',
    icon: Icons.travel_explore_rounded,
    accent: Color(0xFF2563EB),
    difficulty: 'Medium',
  ),
  _OfflineGame(
    title: 'Weather Signals Challenge',
    description:
        'Read weather tools and air-mass clues to predict short-term conditions.',
    actionLabel: 'Play Quiz',
    route: '/offline-quiz/weather_systems',
    lessonId: 'weather_systems',
    icon: Icons.cloud_queue_rounded,
    accent: Color(0xFF0284C7),
    difficulty: 'Medium',
  ),
  _OfflineGame(
    title: 'Seismic Waves Challenge',
    description:
        'Answer seismic wave clues and earthquake terms in a timed quiz format.',
    actionLabel: 'Play Quiz',
    route: '/offline-quiz/earthquake_basics',
    lessonId: 'earthquake_basics',
    icon: Icons.graphic_eq_rounded,
    accent: Color(0xFF0F766E),
    difficulty: 'Medium',
  ),
  _OfflineGame(
    title: 'Volcano Hazard Dash',
    description:
        'Test what you know about eruptions, magma, and volcanic risk zones.',
    actionLabel: 'Play Quiz',
    route: '/offline-quiz/volcano_dynamics',
    lessonId: 'volcano_dynamics',
    icon: Icons.terrain_rounded,
    accent: Color(0xFFB45309),
    difficulty: 'Hard',
  ),
];
