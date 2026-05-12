import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_sfx_service.dart';

class OfflineMiniGameScreen extends StatefulWidget {
  const OfflineMiniGameScreen({super.key});

  @override
  State<OfflineMiniGameScreen> createState() => _OfflineMiniGameScreenState();
}

class _OfflineMiniGameScreenState extends State<OfflineMiniGameScreen> {
  final Random _random = Random();
  late final ConfettiController _confettiController;
  bool _didPrecacheImages = false;

  static const List<_GameLevel> _levels = [
    _GameLevel(id: 'pebble', label: 'Pebble', pairCount: 3, timeSeconds: 0),
    _GameLevel(id: 'gravel', label: 'Gravel', pairCount: 4, timeSeconds: 150),
    _GameLevel(id: 'boulder', label: 'Boulder', pairCount: 5, timeSeconds: 130),
    _GameLevel(id: 'outcrop', label: 'Outcrop', pairCount: 6, timeSeconds: 115),
    _GameLevel(
      id: 'geologist',
      label: 'Geologist',
      pairCount: 7,
      timeSeconds: 100,
    ),
    _GameLevel(id: 'master', label: 'Master', pairCount: 8, timeSeconds: 85),
    _GameLevel(id: 'epic', label: 'Epic', pairCount: 8, timeSeconds: 72),
  ];

  static const List<_RockCyclePair> _rockPairs = [
    _RockCyclePair(
      id: 'magma',
      term: 'Magma',
      clue: 'Molten rock below Earth\'s surface',
      color: Color(0xFFB45309),
      imagePath: 'assets/games/rock-cycle/lava.jpg',
    ),
    _RockCyclePair(
      id: 'igneous',
      term: 'Igneous Rock',
      clue: 'Rock formed from cooled magma or lava',
      color: Color(0xFF2563EB),
      imagePath: 'assets/games/rock-cycle/basalt.jpg',
    ),
    _RockCyclePair(
      id: 'weathering',
      term: 'Weathering',
      clue: 'Breakdown of rocks at Earth\'s surface',
      color: Color(0xFF0F766E),
      imagePath: 'assets/games/rock-cycle/granite.jpg',
    ),
    _RockCyclePair(
      id: 'erosion',
      term: 'Erosion',
      clue: 'Transport of sediments by wind, water, or ice',
      color: Color(0xFF0EA5E9),
      imagePath: 'assets/games/rock-cycle/schist.jpg',
    ),
    _RockCyclePair(
      id: 'deposition',
      term: 'Deposition',
      clue: 'Sediments settle in a new location',
      color: Color(0xFF7C3AED),
      imagePath: 'assets/games/rock-cycle/sandstone_card.jpg',
    ),
    _RockCyclePair(
      id: 'sedimentary',
      term: 'Sedimentary Rock',
      clue: 'Rock formed by compacted and cemented sediments',
      color: Color(0xFF0D9488),
      imagePath: 'assets/games/rock-cycle/iron_sandstone.jpg',
    ),
    _RockCyclePair(
      id: 'metamorphism',
      term: 'Heat and Pressure',
      clue: 'Forces that transform existing rocks',
      color: Color(0xFFDC2626),
      imagePath: 'assets/games/rock-cycle/gabbro.jpg',
    ),
    _RockCyclePair(
      id: 'metamorphic',
      term: 'Metamorphic Rock',
      clue: 'Rock changed by heat and pressure',
      color: Color(0xFF9333EA),
      imagePath: 'assets/games/rock-cycle/metamorphic.jpg',
    ),
  ];

  late List<_RockMemoryCard> _cards;
  final Set<String> _matchedPairIds = <String>{};
  final Set<int> _revealedIndexes = <int>{};
  _GameLevel _level = _levels.first;
  Timer? _timer;
  int _secondsLeft = 0;
  int? _firstPickIndex;
  int _moves = 0;
  bool _busy = false;
  bool _timeUp = false;
  int _streak = 0;
  int _bestStreak = 0;
  bool _victoryTriggered = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _setupGame(initial: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheImages) {
      return;
    }
    for (final pair in _rockPairs) {
      precacheImage(AssetImage(pair.imagePath), context);
    }
    _didPrecacheImages = true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _setupGame({bool initial = false}) {
    final pairPool = [..._rockPairs]..shuffle(_random);
    final selectedPairs = pairPool
        .take(_level.pairCount)
        .toList(growable: false);

    final deck = <_RockMemoryCard>[
      for (final pair in selectedPairs) ...[
        _RockMemoryCard(
          pairId: pair.id,
          text: pair.term,
          isTerm: true,
          color: pair.color,
          imagePath: pair.imagePath,
        ),
        _RockMemoryCard(
          pairId: pair.id,
          text: pair.clue,
          isTerm: false,
          color: pair.color,
          imagePath: pair.imagePath,
        ),
      ],
    ]..shuffle(_random);

    _timer?.cancel();
    _confettiController.stop();
    final levelSeconds = _level.timeSeconds;

    if (initial) {
      _cards = deck;
      _matchedPairIds.clear();
      _revealedIndexes.clear();
      _firstPickIndex = null;
      _moves = 0;
      _busy = false;
      _timeUp = false;
      _streak = 0;
      _bestStreak = 0;
      _secondsLeft = levelSeconds;
      _victoryTriggered = false;
    } else {
      setState(() {
        _cards = deck;
        _matchedPairIds.clear();
        _revealedIndexes.clear();
        _firstPickIndex = null;
        _moves = 0;
        _busy = false;
        _timeUp = false;
        _streak = 0;
        _bestStreak = 0;
        _secondsLeft = levelSeconds;
        _victoryTriggered = false;
      });
    }

    if (levelSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_secondsLeft <= 1) {
          timer.cancel();
          setState(() {
            _secondsLeft = 0;
            _timeUp = true;
          });
          return;
        }
        setState(() => _secondsLeft -= 1);
      });
    }
  }

  void _changeLevel(_GameLevel nextLevel) {
    if (_level.id == nextLevel.id) {
      return;
    }
    setState(() => _level = nextLevel);
    _setupGame();
  }

  Future<void> _triggerVictoryEffects() async {
    if (_victoryTriggered) {
      return;
    }
    _victoryTriggered = true;
    _confettiController.play();
    await AppSfxService.instance.playApplause();
  }

  Future<void> _onCardTap(int index) async {
    if (_busy || _timeUp || _revealedIndexes.contains(index)) {
      return;
    }
    final tapped = _cards[index];
    if (_matchedPairIds.contains(tapped.pairId)) {
      return;
    }

    setState(() => _revealedIndexes.add(index));

    if (_firstPickIndex == null) {
      setState(() => _firstPickIndex = index);
      return;
    }

    final firstIndex = _firstPickIndex!;
    final firstCard = _cards[firstIndex];
    _moves++;

    if (firstCard.pairId == tapped.pairId) {
      setState(() {
        _matchedPairIds.add(tapped.pairId);
        _firstPickIndex = null;
        _streak += 1;
        if (_streak > _bestStreak) {
          _bestStreak = _streak;
        }
      });
      await AppSfxService.instance.playCorrect();
      if (_matchedPairIds.length == _cards.length ~/ 2) {
        _timer?.cancel();
        await _triggerVictoryEffects();
      }
      return;
    }

    setState(() {
      _busy = true;
      _streak = 0;
    });

    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) {
      return;
    }
    setState(() {
      _revealedIndexes.remove(firstIndex);
      _revealedIndexes.remove(index);
      _firstPickIndex = null;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPairs = _cards.length ~/ 2;
    final matchedPairs = _matchedPairIds.length;
    final completed = matchedPairs == totalPairs;
    final hasTimer = _level.timeSeconds > 0;
    final progress = totalPairs == 0 ? 0.0 : matchedPairs / totalPairs;
    final timeProgress = hasTimer
        ? (_secondsLeft / _level.timeSeconds).clamp(0.0, 1.0)
        : 1.0;
    final crossAxisCount = _cards.length <= 8 ? 2 : 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rock Cycle Memory'),
        actions: [
          IconButton(
            onPressed: _setupGame,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _levels
                      .map(
                        (level) => ChoiceChip(
                          label: Text(level.label),
                          selected: level.id == _level.id,
                          onSelected: (_) => _changeLevel(level),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  hasTimer
                      ? 'Match Rock Cycle cards before the timer ends.'
                      : 'Match each Rock Cycle image-term pair.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Matched: $matchedPairs/$totalPairs   Moves: $_moves   Streak: $_streak${hasTimer ? '   Time: ${_secondsLeft}s' : ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: hasTimer ? timeProgress : progress,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE5EAF1),
                    valueColor: AlwaysStoppedAnimation(
                      hasTimer
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_timeUp && !completed)
                  _StatusBanner(
                    color: const Color(0xFFFFF1F2),
                    borderColor: const Color(0xFFFDA4AF),
                    textColor: const Color(0xFF9F1239),
                    message:
                        'Time is up. Retry this level and beat your streak.',
                    actionLabel: 'Retry',
                    onPressed: _setupGame,
                  ),
                if (completed)
                  _StatusBanner(
                    color: const Color(0xFFEAFBF1),
                    borderColor: const Color(0xFF86EFAC),
                    textColor: const Color(0xFF166534),
                    message:
                        'Great run! Level cleared in $_moves moves. Best streak: $_bestStreak.',
                    actionLabel: 'Play Again',
                    onPressed: _setupGame,
                    trailing: Image.asset(
                      'assets/games/trophy.gif',
                      height: 28,
                    ),
                  ),
                Expanded(
                  child: GridView.builder(
                    itemCount: _cards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: crossAxisCount == 2 ? 0.82 : 0.76,
                    ),
                    itemBuilder: (context, index) {
                      final card = _cards[index];
                      final revealed =
                          _revealedIndexes.contains(index) ||
                          _matchedPairIds.contains(card.pairId);

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _onCardTap(index),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFD9E2F1)),
                            color: _timeUp
                                ? const Color(0xFFF8FAFC)
                                : Colors.white,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: revealed
                                ? _MemoryCardFace(
                                    key: ValueKey('show_$index'),
                                    card: card,
                                  )
                                : const _MemoryCardBack(key: ValueKey('hide')),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.08,
            numberOfParticles: 18,
            colors: const [
              AppColors.primary,
              AppColors.secondary,
              AppColors.accent,
              Color(0xFFF59E0B),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.color,
    required this.borderColor,
    required this.textColor,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
    this.trailing,
  });

  final Color color;
  final Color borderColor;
  final Color textColor;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
          TextButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _MemoryCardBack extends StatelessWidget {
  const _MemoryCardBack({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('back'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF2FF), Color(0xFFDCEBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.question_mark_rounded,
          size: 34,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _MemoryCardFace extends StatelessWidget {
  const _MemoryCardFace({required this.card, super.key});

  final _RockMemoryCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(card.text),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: card.color.withValues(alpha: 0.12),
        border: Border.all(color: card.color.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: card.color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              card.isTerm ? 'TERM' : 'CLUE',
              style: TextStyle(
                fontSize: 10,
                color: card.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              height: 82,
              width: double.infinity,
              child: Image.asset(
                card.imagePath,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                cacheWidth: 260,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: const Text(
                    'Image missing',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Center(
              child: Text(
                card.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.2,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RockMemoryCard {
  const _RockMemoryCard({
    required this.pairId,
    required this.text,
    required this.isTerm,
    required this.color,
    required this.imagePath,
  });

  final String pairId;
  final String text;
  final bool isTerm;
  final Color color;
  final String imagePath;
}

class _RockCyclePair {
  const _RockCyclePair({
    required this.id,
    required this.term,
    required this.clue,
    required this.color,
    required this.imagePath,
  });

  final String id;
  final String term;
  final String clue;
  final Color color;
  final String imagePath;
}

class _GameLevel {
  const _GameLevel({
    required this.id,
    required this.label,
    required this.pairCount,
    required this.timeSeconds,
  });

  final String id;
  final String label;
  final int pairCount;
  final int timeSeconds;
}
