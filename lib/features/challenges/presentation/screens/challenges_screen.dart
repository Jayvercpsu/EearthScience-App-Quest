import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/illustration_assets.dart';
import '../../../../shared/animations/fade_slide_in.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../notifications/providers/notification_providers.dart';
import '../../providers/challenge_providers.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  String _tab = 'Daily';

  Future<void> _logout() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout Account'),
          content: const Text(
            'Are you sure you want to logout from your student account?',
          ),
          actionsAlignment: MainAxisAlignment.end,
          actionsOverflowAlignment: OverflowBarAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) {
      return;
    }
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(challengesProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Challenges',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (unread > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  _tabChip('Daily'),
                  const SizedBox(width: 8),
                  _tabChip('Weekly'),
                  const SizedBox(width: 8),
                  _tabChip('Special'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: challengesAsync.when(
                  data: (challenges) {
                    if (challenges.isEmpty) {
                      return const Center(
                        child: Text('No challenges available yet.'),
                      );
                    }

                    final filtered = challenges.where((item) {
                      if (_tab == 'Special') return true;
                      return item.type.toLowerCase() == _tab.toLowerCase();
                    }).toList();

                    final display = filtered.isEmpty ? challenges : filtered;

                    return ListView.separated(
                      itemCount: display.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = display[index];
                        return FadeSlideIn(
                          delayMs: 40 + (index * 25),
                          child: _ChallengeTile(
                            title: item.title,
                            description: item.description,
                            reward: '+${item.rewardXp} XP',
                            progressText:
                                '${item.currentProgress}/${item.progressTarget}',
                            progress: item.progress,
                            color: index.isEven
                                ? const Color(0xFF2BB673)
                                : const Color(0xFF3B82F6),
                            image: _itemImage(index),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const LoadingWidget(label: 'Loading challenges...'),
                  error: (_, __) =>
                      const Center(child: Text('Unable to load challenges.')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabChip(String label) {
    final selected = _tab == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _tab = label),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF2F5FA),
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _itemImage(int index) {
    const images = [
      IllustrationAssets.onboardingRewards,
      IllustrationAssets.onboardingLearn,
      IllustrationAssets.onboardingProgress,
      IllustrationAssets.heroLandscape,
    ];
    return images[index % images.length];
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    required this.title,
    required this.description,
    required this.reward,
    required this.progressText,
    required this.progress,
    required this.color,
    required this.image,
  });

  final String title;
  final String description;
  final String reward;
  final String progressText;
  final double progress;
  final Color color;
  final String image;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6ECF4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: color.withValues(alpha: 0.18),
            backgroundImage: AssetImage(image),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reward,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          value: progress,
                          backgroundColor: const Color(0xFFE8ECF3),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(progressText, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF22C55E),
            size: 18,
          ),
        ],
      ),
    );
  }
}
