import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/onboarding_service.dart';

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

final onboardingStatusProvider = FutureProvider<bool>((ref) {
  return ref.read(onboardingServiceProvider).isOnboardingDone();
});

final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  return OnboardingController(ref.read(onboardingServiceProvider));
});

class OnboardingController {
  OnboardingController(this._service);

  final OnboardingService _service;

  Future<void> complete() => _service.completeOnboarding();
}
