import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_strings.dart';

class OnboardingService {
  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppStrings.onboardingDoneKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppStrings.onboardingDoneKey, true);
  }
}
