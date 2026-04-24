import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/profile_preferences_service.dart';

final profilePreferencesServiceProvider = Provider<ProfilePreferencesService>((
  ref,
) {
  return ProfilePreferencesService();
});

final profilePreferencesProvider =
    StateNotifierProvider<
      ProfilePreferencesController,
      AsyncValue<ProfilePreferences>
    >((ref) {
      return ProfilePreferencesController(
        ref.read(profilePreferencesServiceProvider),
      );
    });

class ProfilePreferencesController
    extends StateNotifier<AsyncValue<ProfilePreferences>> {
  ProfilePreferencesController(this._service)
    : super(const AsyncValue.loading()) {
    unawaited(load());
  }

  final ProfilePreferencesService _service;

  Future<void> load() async {
    state = await AsyncValue.guard(_service.load);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final current = state.valueOrNull ?? const ProfilePreferences();
    state = AsyncValue.data(current.copyWith(notificationsEnabled: value));
    try {
      final updated = await _service.updateNotificationsEnabled(value);
      state = AsyncValue.data(updated);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      await load();
    }
  }

  Future<void> setSoundEffectsEnabled(bool value) async {
    final current = state.valueOrNull ?? const ProfilePreferences();
    state = AsyncValue.data(current.copyWith(soundEffectsEnabled: value));
    try {
      final updated = await _service.updateSoundEffectsEnabled(value);
      state = AsyncValue.data(updated);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      await load();
    }
  }

  Future<void> setReduceMotion(bool value) async {
    final current = state.valueOrNull ?? const ProfilePreferences();
    state = AsyncValue.data(current.copyWith(reduceMotion: value));
    try {
      final updated = await _service.updateReduceMotion(value);
      state = AsyncValue.data(updated);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      await load();
    }
  }
}
