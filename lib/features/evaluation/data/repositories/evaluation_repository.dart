import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_paths.dart';
import '../models/evaluation_feedback.dart';

class EvaluationRepository {
  EvaluationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final List<EvaluationFeedback> _localBuffer = [];

  Future<void> submit(EvaluationFeedback feedback) async {
    try {
      await _firestore
          .collection(FirestorePaths.feedbackOrEvaluation)
          .doc(feedback.feedbackId)
          .set(feedback.toMap());
      return;
    } catch (_) {
      _localBuffer.add(feedback);
    }
  }

  Future<List<EvaluationFeedback>> fetchLocalBuffer() async => _localBuffer;
}
