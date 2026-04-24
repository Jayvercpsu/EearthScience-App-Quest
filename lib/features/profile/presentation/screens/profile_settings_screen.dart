import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/profile_preferences_service.dart';
import '../../providers/profile_preferences_provider.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(profilePreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: settingsAsync.when(
          data: (settings) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              _SettingsHero(settings: settings),
              const SizedBox(height: 16),
              _SettingsSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: 'Study Notifications',
                subtitle: 'Reminders for lessons, quizzes, and progress.',
                value: settings.notificationsEnabled,
                onChanged: (value) {
                  ref
                      .read(profilePreferencesProvider.notifier)
                      .setNotificationsEnabled(value);
                },
              ),
              _SettingsSwitchTile(
                icon: Icons.graphic_eq_rounded,
                title: 'Sound Effects',
                subtitle: 'Feedback sounds for actions and achievements.',
                value: settings.soundEffectsEnabled,
                onChanged: (value) {
                  ref
                      .read(profilePreferencesProvider.notifier)
                      .setSoundEffectsEnabled(value);
                },
              ),
              _SettingsSwitchTile(
                icon: Icons.motion_photos_off_outlined,
                title: 'Reduce Motion',
                subtitle: 'Use simpler transitions when moving around the app.',
                value: settings.reduceMotion,
                onChanged: (value) {
                  ref
                      .read(profilePreferencesProvider.notifier)
                      .setReduceMotion(value);
                },
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Unable to load settings.')),
        ),
      ),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.settings});

  final ProfilePreferences settings;

  @override
  Widget build(BuildContext context) {
    final activeCount = [
      settings.notificationsEnabled,
      settings.soundEffectsEnabled,
      !settings.reduceMotion,
    ].where((enabled) => enabled).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF08357A), Color(0xFF0C6BE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App Preferences',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$activeCount of 3 experience features are active.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EBF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
