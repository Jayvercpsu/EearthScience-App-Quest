import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_sfx_service.dart';

class OfflinePlateBoundaryGameScreen extends StatefulWidget {
  const OfflinePlateBoundaryGameScreen({super.key});

  @override
  State<OfflinePlateBoundaryGameScreen> createState() =>
      _OfflinePlateBoundaryGameScreenState();
}

class _OfflinePlateBoundaryGameScreenState
    extends State<OfflinePlateBoundaryGameScreen> {
  final Random _random = Random();
  late final ConfettiController _confettiController;

  static const List<_BoundaryPrompt> _allPrompts = [
    _BoundaryPrompt(
      id: 'c1',
      text: 'One plate sinks below another and forms a trench.',
      type: _BoundaryType.convergent,
    ),
    _BoundaryPrompt(
      id: 'c2',
      text: 'Mountain building from plate collision.',
      type: _BoundaryType.convergent,
    ),
    _BoundaryPrompt(
      id: 'c3',
      text: 'Subduction zones are common here.',
      type: _BoundaryType.convergent,
    ),
    _BoundaryPrompt(
      id: 'd1',
      text: 'Mid-ocean ridges form as plates move apart.',
      type: _BoundaryType.divergent,
    ),
    _BoundaryPrompt(
      id: 'd2',
      text: 'New crust is created from rising magma.',
      type: _BoundaryType.divergent,
    ),
    _BoundaryPrompt(
      id: 'd3',
      text: 'Rift valleys can form on continents.',
      type: _BoundaryType.divergent,
    ),
    _BoundaryPrompt(
      id: 't1',
      text: 'Plates slide horizontally past each other.',
      type: _BoundaryType.transform,
    ),
    _BoundaryPrompt(
      id: 't2',
      text: 'Frequent strike-slip fault movement.',
      type: _BoundaryType.transform,
    ),
    _BoundaryPrompt(
      id: 't3',
      text: 'Crust is neither created nor destroyed.',
      type: _BoundaryType.transform,
    ),
  ];

  late final Map<_BoundaryType, List<_BoundaryPrompt>> _placedByType;
  late List<_BoundaryPrompt> _deck;
  final Set<String> _placedIds = <String>{};
  int _attempts = 0;
  int _score = 0;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _placedByType = {
      for (final type in _BoundaryType.values) type: <_BoundaryPrompt>[],
    };
    _resetGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _resetGame() {
    setState(() {
      _deck = [..._allPrompts]..shuffle(_random);
      for (final type in _BoundaryType.values) {
        _placedByType[type]!.clear();
      }
      _placedIds.clear();
      _attempts = 0;
      _score = 0;
      _celebrated = false;
    });
    _confettiController.stop();
  }

  Future<void> _onDrop(_BoundaryPrompt card, _BoundaryType targetType) async {
    if (_placedIds.contains(card.id)) {
      return;
    }
    final correct = card.type == targetType;
    setState(() {
      _attempts += 1;
      if (correct) {
        _placedIds.add(card.id);
        _placedByType[targetType]!.add(card);
        _score += 12;
      } else {
        _score = max(0, _score - 3);
      }
    });

    if (correct) {
      await AppSfxService.instance.playCorrect();
      if (_placedIds.length == _deck.length && !_celebrated) {
        _celebrated = true;
        _confettiController.play();
        await AppSfxService.instance.playApplause();
      }
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 850),
        content: Text(
          correct ? 'Nice! Correct boundary.' : 'Try again, wrong boundary.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _deck
        .where((item) => !_placedIds.contains(item.id))
        .toList();
    final completed = _placedIds.length == _deck.length;
    final progress = _deck.isEmpty ? 0.0 : (_placedIds.length / _deck.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plate Boundary Sort'),
        actions: [
          IconButton(
            onPressed: _resetGame,
            tooltip: 'Reset game',
            icon: const Icon(Icons.refresh_rounded),
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
                const Text(
                  'Drag each clue card into the correct plate boundary zone.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score: $_score   Attempts: $_attempts   Sorted: ${_placedIds.length}/${_deck.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE5EAF1),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF16A34A)),
                  ),
                ),
                if (completed) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAFBF1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Great sorting! Final score: $_score',
                            style: const TextStyle(
                              color: Color(0xFF166534),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Image.asset('assets/games/trophy.gif', height: 30),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: remaining
                              .map((card) => _DragPromptChip(card: card))
                              .toList(),
                        ),
                        const SizedBox(height: 14),
                        _DropZone(
                          title: 'Convergent',
                          subtitle: 'Collision / subduction',
                          color: _BoundaryType.convergent.color,
                          placed: _placedByType[_BoundaryType.convergent]!,
                          onAccept: (card) =>
                              _onDrop(card, _BoundaryType.convergent),
                        ),
                        const SizedBox(height: 10),
                        _DropZone(
                          title: 'Divergent',
                          subtitle: 'Moving apart / new crust',
                          color: _BoundaryType.divergent.color,
                          placed: _placedByType[_BoundaryType.divergent]!,
                          onAccept: (card) =>
                              _onDrop(card, _BoundaryType.divergent),
                        ),
                        const SizedBox(height: 10),
                        _DropZone(
                          title: 'Transform',
                          subtitle: 'Sliding past each other',
                          color: _BoundaryType.transform.color,
                          placed: _placedByType[_BoundaryType.transform]!,
                          onAccept: (card) =>
                              _onDrop(card, _BoundaryType.transform),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.07,
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

class _DragPromptChip extends StatelessWidget {
  const _DragPromptChip({required this.card});

  final _BoundaryPrompt card;

  @override
  Widget build(BuildContext context) {
    return Draggable<_BoundaryPrompt>(
      data: card,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: _PromptBody(text: card.text, elevated: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _PromptBody(text: card.text),
      ),
      child: _PromptBody(text: card.text),
    );
  }
}

class _PromptBody extends StatelessWidget {
  const _PromptBody({required this.text, this.elevated = false});

  final String text;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E2F1)),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, height: 1.3)),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.placed,
    required this.onAccept,
  });

  final String title;
  final String subtitle;
  final Color color;
  final List<_BoundaryPrompt> placed;
  final ValueChanged<_BoundaryPrompt> onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_BoundaryPrompt>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, rejected) {
        final active = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.14)
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: active ? 0.58 : 0.34),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (placed.isEmpty)
                const Text(
                  'Drop cards here',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: placed
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: color.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            item.text,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BoundaryPrompt {
  const _BoundaryPrompt({
    required this.id,
    required this.text,
    required this.type,
  });

  final String id;
  final String text;
  final _BoundaryType type;
}

enum _BoundaryType { convergent, divergent, transform }

extension on _BoundaryType {
  Color get color {
    switch (this) {
      case _BoundaryType.convergent:
        return const Color(0xFFDC2626);
      case _BoundaryType.divergent:
        return const Color(0xFF0EA5E9);
      case _BoundaryType.transform:
        return const Color(0xFF7C3AED);
    }
  }
}
