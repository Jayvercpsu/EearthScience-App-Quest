import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/evaluation_feedback.dart';
import '../data/repositories/evaluation_repository.dart';

final evaluationRepositoryProvider = Provider<EvaluationRepository>((ref) {
  return EvaluationRepository();
});

final evaluationControllerProvider =
    StateNotifierProvider<EvaluationController, AsyncValue<void>>(
      (ref) => EvaluationController(ref.read(evaluationRepositoryProvider)),
    );

class EvaluationController extends StateNotifier<AsyncValue<void>> {
  EvaluationController(this._repository) : super(const AsyncValue.data(null));

  final EvaluationRepository _repository;

  Future<void> submit(EvaluationFeedback feedback) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.submit(feedback));
  }
}
