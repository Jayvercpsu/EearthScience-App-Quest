import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/profile_preferences_service.dart';
import '../../../../shared/animations/fade_slide_in.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/profile_preferences_provider.dart';
import 'about_app_screen.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'profile_settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSigningOut = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final settingsAsync = ref.watch(profilePreferencesProvider);

    return Scaffold(
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            final display = user ?? _fallbackUser();
            final nextLevelXp = 2000;
            final progress = (display.xp / nextLevelXp).clamp(0, 1).toDouble();
            final settings = settingsAsync.valueOrNull;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: FadeSlideIn(
                    child: _ProfileHero(
                      user: display,
                      progress: progress,
                      nextLevelXp: nextLevelXp,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (settings != null)
                        FadeSlideIn(
                          delayMs: 40,
                          child: _QuickStatusStrip(settings: settings),
                        ),
                      if (settings != null) const SizedBox(height: 14),
                      FadeSlideIn(
                        delayMs: 80,
                        child: _ProfileActionCard(
                          icon: Icons.edit_outlined,
                          title: 'Edit Profile',
                          subtitle:
                              'Update your display name and account view.',
                          onTap: () =>
                              _openPage(EditProfileScreen(user: display)),
                        ),
                      ),
                      FadeSlideIn(
                        delayMs: 110,
                        child: _ProfileActionCard(
                          icon: Icons.emoji_events_outlined,
                          title: 'Achievements',
                          subtitle: 'Check the milestones you have unlocked.',
                          onTap: () => context.push('/achievements'),
                        ),
                      ),
                      FadeSlideIn(
                        delayMs: 140,
                        child: _ProfileActionCard(
                          icon: Icons.tune_rounded,
                          title: 'Settings',
                          subtitle:
                              'Control notifications, motion, and sounds.',
                          onTap: () => _openPage(const ProfileSettingsScreen()),
                        ),
                      ),
                      FadeSlideIn(
                        delayMs: 170,
                        child: _ProfileActionCard(
                          icon: Icons.support_agent_rounded,
                          title: 'Help & Support',
                          subtitle: 'Open FAQs and copy the support contact.',
                          onTap: () => _openPage(const HelpSupportScreen()),
                        ),
                      ),
                      FadeSlideIn(
                        delayMs: 200,
                        child: _ProfileActionCard(
                          icon: Icons.info_outline_rounded,
                          title: 'About App',
                          subtitle:
                              'See app purpose, version, and design notes.',
                          onTap: () => _openPage(const AboutAppScreen()),
                        ),
                      ),
                      FadeSlideIn(
                        delayMs: 230,
                        child: _ProfileActionCard(
                          icon: Icons.logout_rounded,
                          title: _isSigningOut ? 'Signing Out...' : 'Logout',
                          subtitle:
                              'Safely exit your account and return to login.',
                          danger: true,
                          onTap: _isSigningOut ? null : _confirmLogout,
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Unable to load profile.')),
        ),
      ),
    );
  }

  AppUser _fallbackUser() {
    return AppUser(
      uid: 'local_preview',
      name: 'Earth Learner',
      email: 'learner@earthscience.app',
      role: AppRole.student,
      xp: 1250,
      level: 8,
      streak: 4,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _openPage(Widget child) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => child));
  }

  Future<void> _confirmLogout() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
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
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted || _isSigningOut) {
      return;
    }

    setState(() => _isSigningOut = true);
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (!mounted) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.progress,
    required this.nextLevelXp,
  });

  final AppUser user;
  final double progress;
  final int nextLevelXp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF031F54), Color(0xFF0A4BC2), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: Center(
                  child: Text(
                    user.name.isEmpty ? 'E' : user.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        user.role.value.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 335;
              final progressBar = Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFF8D66D)),
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${user.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        progressBar,
                        const SizedBox(width: 10),
                        Text(
                          '${user.xp} / $nextLevelXp XP',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Text(
                    'Level ${user.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  progressBar,
                  const SizedBox(width: 10),
                  Text(
                    '${user.xp} / $nextLevelXp XP',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickStatusStrip extends StatelessWidget {
  const _QuickStatusStrip({required this.settings});

  final ProfilePreferences settings;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        label: settings.notificationsEnabled
            ? 'Notifications On'
            : 'Notifications Off',
        icon: settings.notificationsEnabled
            ? Icons.notifications_active_outlined
            : Icons.notifications_off_outlined,
      ),
      (
        label: settings.soundEffectsEnabled ? 'Sound On' : 'Sound Off',
        icon: settings.soundEffectsEnabled
            ? Icons.volume_up_rounded
            : Icons.volume_off_rounded,
      ),
      (
        label: settings.reduceMotion ? 'Reduced Motion' : 'Full Motion',
        icon: settings.reduceMotion
            ? Icons.motion_photos_off_outlined
            : Icons.auto_awesome_motion_rounded,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE5EBF3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? const Color(0xFFDC2626) : AppColors.primary;
    final accentBg = danger ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EBF3)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accentBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: danger ? const Color(0xFF991B1B) : AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
