import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_sfx_service.dart';

class OfflineEarthLayersGameScreen extends StatefulWidget {
  const OfflineEarthLayersGameScreen({super.key});

  @override
  State<OfflineEarthLayersGameScreen> createState() =>
      _OfflineEarthLayersGameScreenState();
}

class _OfflineEarthLayersGameScreenState
    extends State<OfflineEarthLayersGameScreen> {
  final Random _random = Random();
  late final ConfettiController _confettiController;

  static const List<_LayerItem> _correctOrder = [
    _LayerItem(
      id: 'crust',
      title: 'Crust',
      clue: 'Outermost solid layer',
      color: Color(0xFF16A34A),
    ),
    _LayerItem(
      id: 'upper_mantle',
      title: 'Upper Mantle',
      clue: 'Rigid to slowly flowing rock below the crust',
      color: Color(0xFF0284C7),
    ),
    _LayerItem(
      id: 'lower_mantle',
      title: 'Lower Mantle',
      clue: 'Hot, dense silicate layer',
      color: Color(0xFF2563EB),
    ),
    _LayerItem(
      id: 'outer_core',
      title: 'Outer Core',
      clue: 'Liquid iron-nickel layer',
      color: Color(0xFFB45309),
    ),
    _LayerItem(
      id: 'inner_core',
      title: 'Inner Core',
      clue: 'Solid iron-nickel center',
      color: Color(0xFFDC2626),
    ),
  ];

  late List<_LayerItem> _ordered;
  int _checks = 0;
  int _bestCorrectPositions = 0;
  String? _feedback;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _resetGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _resetGame() {
    final shuffled = [..._correctOrder]..shuffle(_random);
    if (shuffled.map((item) => item.id).join('|') ==
        _correctOrder.map((item) => item.id).join('|')) {
      shuffled.shuffle(_random);
    }
    setState(() {
      _ordered = shuffled;
      _checks = 0;
      _bestCorrectPositions = 0;
      _feedback = null;
      _solved = false;
    });
    _confettiController.stop();
  }

  Future<void> _checkOrder() async {
    final correctPositions = _ordered.asMap().entries.where((entry) {
      return entry.value.id == _correctOrder[entry.key].id;
    }).length;
    final solved = correctPositions == _correctOrder.length;
    final improved = correctPositions > _bestCorrectPositions;

    setState(() {
      _checks += 1;
      _solved = solved;
      if (solved) {
        _feedback = 'Perfect! You stacked Earth layers in the correct order.';
      } else {
        _feedback =
            '$correctPositions/${_correctOrder.length} layers are in the right position. Keep reordering.';
      }
      if (improved) {
        _bestCorrectPositions = correctPositions;
      }
    });

    if (solved) {
      _confettiController.play();
      await AppSfxService.instance.playApplause();
      return;
    }
    if (improved && correctPositions > 0) {
      await AppSfxService.instance.playCorrect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earth Layers Stack'),
        actions: [
          IconButton(
            onPressed: _resetGame,
            tooltip: 'Shuffle again',
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
                  'Hold the two-line drag handle to move each layer.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Checks: $_checks',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                if (_feedback != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _solved
                          ? const Color(0xFFEAFBF1)
                          : const Color(0xFFF5F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _solved
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _feedback!,
                            style: TextStyle(
                              color: _solved
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_solved)
                          Image.asset('assets/games/trophy.gif', height: 28),
                      ],
                    ),
                  ),
                Expanded(
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: _ordered.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = _ordered.removeAt(oldIndex);
                        _ordered.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _ordered[index];
                      return Container(
                        key: ValueKey(item.id),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: item.color.withValues(alpha: 0.38),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.color.withValues(alpha: 0.2),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: item.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            item.clue,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: ReorderableDelayedDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_indicator_rounded),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetGame,
                        child: const Text('Shuffle'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _checkOrder,
                        child: const Text('Check Order'),
                      ),
                    ),
                  ],
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

class _LayerItem {
  const _LayerItem({
    required this.id,
    required this.title,
    required this.clue,
    required this.color,
  });

  final String id;
  final String title;
  final String clue;
  final Color color;
}
