import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_paths.dart';
import '../models/challenge.dart';

class ChallengeRepository {
  ChallengeRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  final List<Challenge> _fallback = const [
    Challenge(
      challengeId: 'daily_vocab',
      title: 'Daily Vocabulary Drill',
      description: 'Answer 5 vocabulary-focused quiz items today.',
      rewardXp: 40,
      type: 'Daily',
      progressTarget: 5,
      currentProgress: 3,
    ),
    Challenge(
      challengeId: 'weekly_consistency',
      title: 'Weekly Learning Streak',
      description: 'Complete 4 lessons this week.',
      rewardXp: 120,
      type: 'Weekly',
      progressTarget: 4,
      currentProgress: 2,
    ),
  ];

  Future<List<Challenge>> fetchChallenges() async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.challenges)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => Challenge.fromMap(doc.data()))
            .toList();
      }
    } catch (_) {
      // fallback below
    }

    return _fallback;
  }
}
