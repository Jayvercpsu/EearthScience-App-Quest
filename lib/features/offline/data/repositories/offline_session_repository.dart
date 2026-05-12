import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../progress/data/models/progress.dart';

class OfflineSessionRepository {
  static const _offlineNicknameKey = 'offline_active_nickname';
  static const _offlineProgressPrefix = 'offline_progress_';

  Future<void> saveNickname(String nickname) async {
    final trimmed = nickname.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_offlineNicknameKey, trimmed);
  }

  Future<String?> loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_offlineNicknameKey)?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    return value;
  }

  Future<void> clearActiveNickname() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineNicknameKey);
  }

  Future<void> renameNickname({
    required String fromNickname,
    required String toNickname,
  }) async {
    final from = fromNickname.trim();
    final to = toNickname.trim();
    if (to.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (from.isNotEmpty && from != to) {
      final oldProgress = prefs.getString(_progressKey(from));
      if (oldProgress != null && oldProgress.trim().isNotEmpty) {
        await prefs.setString(_progressKey(to), oldProgress);
        await prefs.remove(_progressKey(from));
      }
    }
    await prefs.setString(_offlineNicknameKey, to);
  }

  Future<LearnerProgress> loadProgress(String nickname) async {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) {
      return _zeroProgress('offline_guest');
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_progressKey(trimmed));
    if (raw == null || raw.trim().isEmpty) {
      return _zeroProgress('offline_$trimmed');
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return LearnerProgress.fromMap(decoded);
      }
      if (decoded is Map) {
        return LearnerProgress.fromMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // fallback below
    }
    return _zeroProgress('offline_$trimmed');
  }

  Future<void> saveProgress({
    required String nickname,
    required LearnerProgress progress,
  }) async {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey(trimmed), jsonEncode(progress.toMap()));
  }

  Future<LearnerProgress> updateAfterQuiz({
    required String nickname,
    required String lessonId,
    required double score,
  }) async {
    final trimmed = nickname.trim();
    final current = await loadProgress(trimmed);
    final updatedScores = Map<String, double>.from(current.quizScores)
      ..[lessonId] = score;

    final completed = [...current.completedLessons];
    if (!completed.contains(lessonId)) {
      completed.add(lessonId);
    }

    final average = updatedScores.values.isEmpty
        ? 0.0
        : updatedScores.values.reduce((a, b) => a + b) / updatedScores.length;
    final weekly = (current.engagementStats['weeklySessions'] as int? ?? 0) + 1;
    final activeDays = (current.engagementStats['activeDays'] as int? ?? 0) + 1;

    final updated = current.copyWith(
      userId: current.userId.isEmpty ? 'offline_$trimmed' : current.userId,
      completedLessons: completed,
      quizScores: updatedScores,
      masteryPercentage: average,
      vocabularyProgress: updatedScores.values.isEmpty
          ? 0.0
          : updatedScores.values.reduce((a, b) => a + b) / updatedScores.length,
      conceptualProgress: average,
      engagementStats: {
        ...current.engagementStats,
        'weeklySessions': weekly,
        'activeDays': activeDays,
      },
    );

    await saveProgress(nickname: trimmed, progress: updated);
    return updated;
  }

  String _progressKey(String nickname) => '$_offlineProgressPrefix$nickname';

  LearnerProgress _zeroProgress(String userId) {
    return LearnerProgress(
      userId: userId,
      completedLessons: const [],
      quizScores: const {},
      masteryPercentage: 0.0,
      vocabularyProgress: 0.0,
      conceptualProgress: 0.0,
      engagementStats: const {
        'dailyStreak': 0,
        'activeDays': 0,
        'weeklySessions': 0,
      },
    );
  }
}
