import 'package:shared_preferences/shared_preferences.dart';

class ProfilePreferences {
  const ProfilePreferences({
    this.notificationsEnabled = true,
    this.soundEffectsEnabled = true,
    this.reduceMotion = false,
  });

  final bool notificationsEnabled;
  final bool soundEffectsEnabled;
  final bool reduceMotion;

  ProfilePreferences copyWith({
    bool? notificationsEnabled,
    bool? soundEffectsEnabled,
    bool? reduceMotion,
  }) {
    return ProfilePreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }
}

class ProfilePreferencesService {
  static const _notificationsKey = 'profile_notifications_enabled';
  static const _soundEffectsKey = 'profile_sound_effects_enabled';
  static const _reduceMotionKey = 'profile_reduce_motion';

  Future<ProfilePreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ProfilePreferences(
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      soundEffectsEnabled: prefs.getBool(_soundEffectsKey) ?? true,
      reduceMotion: prefs.getBool(_reduceMotionKey) ?? false,
    );
  }

  Future<ProfilePreferences> updateNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
    return load();
  }

  Future<ProfilePreferences> updateSoundEffectsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEffectsKey, value);
    return load();
  }

  Future<ProfilePreferences> updateReduceMotion(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceMotionKey, value);
    return load();
  }
}
