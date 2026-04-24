import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/illustration_assets.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/animations/fade_slide_in.dart';
import '../../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const _items = [
    _OnboardingItem(
      title: 'Learn with Fun',
      titleColor: Color(0xFF17317A),
      description:
          'Explore Earth Science topics\nthrough interactive and\ngamified lessons.',
      image: IllustrationAssets.onboardingLearn,
      colors: [Color(0xFF7BC4FF), Color(0xFF2B80D6)],
    ),
    _OnboardingItem(
      title: 'Earn Rewards',
      titleColor: Color(0xFF1FA867),
      description:
          'Gain points, unlock badges,\nand complete missions\nas you learn.',
      image: IllustrationAssets.onboardingRewards,
      colors: [Color(0xFFFFCD63), Color(0xFFFF9E43)],
    ),
    _OnboardingItem(
      title: 'Track Your\nProgress',
      titleColor: Color(0xFFFF7A1A),
      description:
          'Monitor your mastery, quiz\nscores, and achievements\nin one place.',
      image: IllustrationAssets.onboardingProgress,
      colors: [Color(0xFFBFD6FF), Color(0xFF7AA4F7)],
    ),
  ];

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider).complete();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _items.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _items.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) =>
                      _OnboardingCard(item: _items[index]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (dot) => Container(
                    height: 8,
                    width: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: dot == _index
                          ? AppColors.primary
                          : const Color(0xFFB6BECF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: last
                            ? AppColors.accent
                            : (_index == 1
                                  ? AppColors.secondary
                                  : AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () {
                        if (last) {
                          _finish();
                          return;
                        }
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Text(last ? 'Get Started' : 'Next'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.item});

  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        FadeSlideIn(
          delayMs: 30,
          child: Text(
            item.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36 / 2,
              fontWeight: FontWeight.w700,
              color: item.titleColor,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FadeSlideIn(
          delayMs: 70,
          child: Text(
            item.description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delayMs: 110,
          child: Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(colors: item.colors),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(item.image, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.titleColor,
    required this.description,
    required this.image,
    required this.colors,
  });

  final String title;
  final Color titleColor;
  final String description;
  final String image;
  final List<Color> colors;
}
