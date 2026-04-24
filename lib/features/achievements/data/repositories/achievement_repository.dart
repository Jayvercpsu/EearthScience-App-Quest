import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/firestore_paths.dart';
import '../models/achievement.dart';

class AchievementRepository {
  AchievementRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  List<Achievement> _fallback = const [
    Achievement(
      achievementId: 'first_quiz',
      title: 'First Explorer',
      description: 'Completed your first Earth Science quiz.',
      badgeIcon: Icons.rocket_launch_rounded,
      rewardXp: 20,
      unlocked: true,
    ),
    Achievement(
      achievementId: 'vocab_master',
      title: 'Vocab Builder',
      description: 'Scored 80%+ on vocabulary-tagged items.',
      badgeIcon: Icons.auto_stories_rounded,
      rewardXp: 60,
      unlocked: false,
    ),
    Achievement(
      achievementId: 'streak_7',
      title: '7-Day Streak',
      description: 'Stayed active for 7 straight days.',
      badgeIcon: Icons.local_fire_department_rounded,
      rewardXp: 100,
      unlocked: false,
    ),
  ];

  Future<List<Achievement>> fetchAchievements() async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.achievements)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => Achievement.fromMap(doc.data()))
            .toList();
      }
    } catch (_) {
      // fallback below
    }

    return _fallback;
  }

  Future<void> unlockAchievement(String achievementId) async {
    try {
      await _firestore
          .collection(FirestorePaths.achievements)
          .doc(achievementId)
          .set({'unlocked': true}, SetOptions(merge: true));
      return;
    } catch (_) {
      _fallback = _fallback
          .map(
            (item) => item.achievementId == achievementId
                ? item.copyWith(unlocked: true)
                : item,
          )
          .toList();
    }
  }
}
