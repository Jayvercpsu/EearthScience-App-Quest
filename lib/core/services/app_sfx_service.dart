import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AppSfxService {
  AppSfxService._();

  static final AppSfxService instance = AppSfxService._();

  AudioPlayer? _tapPlayer;
  AudioPlayer? _gamePlayer;
  bool _enabled = true;
  DateTime _lastTapPlayedAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> init() async {
    // Keep lazy to avoid MissingPluginException during hot restart.
  }

  Future<void> playTap() async {
    if (!_enabled) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastTapPlayedAt).inMilliseconds < 90) {
      return;
    }
    _lastTapPlayedAt = now;
    final player = await _ensureTapPlayer();
    if (player == null) {
      return;
    }
    await _playWithFallback(
      player: player,
      primary: 'sound-fx/drop.mp3',
      fallback: 'sound-fx/drop.mp3',
    );
  }

  Future<void> playCorrect() async {
    if (!_enabled) {
      return;
    }
    final player = await _ensureGamePlayer();
    if (player == null) {
      return;
    }
    await _playWithFallback(
      player: player,
      primary: 'sound-fx/correct.mp3',
      fallback: 'sound-fx/correct.mp3',
    );
  }

  Future<void> playApplause() async {
    if (!_enabled) {
      return;
    }
    final player = await _ensureGamePlayer();
    if (player == null) {
      return;
    }
    await _playWithFallback(
      player: player,
      primary: 'sound-fx/applause_youdid.mp3',
      fallback: 'sound-fx/applause_youdid.mp3',
    );
  }

  Future<AudioPlayer?> _ensureTapPlayer() async {
    if (_tapPlayer != null) {
      return _tapPlayer;
    }
    return _createPlayer(isTap: true);
  }

  Future<AudioPlayer?> _ensureGamePlayer() async {
    if (_gamePlayer != null) {
      return _gamePlayer;
    }
    return _createPlayer(isTap: false);
  }

  Future<AudioPlayer?> _createPlayer({required bool isTap}) async {
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(isTap ? 0.7 : 0.9);
      if (isTap) {
        _tapPlayer = player;
      } else {
        _gamePlayer = player;
      }
      return player;
    } on MissingPluginException {
      // Plugin not fully loaded yet (common right after adding plugin + hot restart).
      _enabled = false;
      return null;
    } catch (_) {
      _enabled = false;
      return null;
    }
  }

  Future<void> _playWithFallback({
    required AudioPlayer player,
    required String primary,
    required String fallback,
  }) async {
    try {
      await player.stop();
      await player.play(AssetSource(primary));
      return;
    } on MissingPluginException {
      _enabled = false;
      return;
    } catch (_) {
      try {
        await player.stop();
        await player.play(AssetSource(fallback));
      } on MissingPluginException {
        _enabled = false;
      } catch (_) {
        // Ignore asset failures silently.
      }
    }
  }
}
