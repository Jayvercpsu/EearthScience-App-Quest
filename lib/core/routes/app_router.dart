import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/screens/achievement_screen.dart';
import '../../features/admin/presentation/screens/admin_shell_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/evaluation/presentation/screens/evaluation_form_screen.dart';
import '../../features/home/presentation/screens/student_shell_screen.dart';
import '../../features/lessons/presentation/screens/lesson_detail_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/quiz/presentation/screens/quiz_result_screen.dart';
import '../../features/quiz/presentation/screens/quiz_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/teacher/presentation/screens/teacher_shell_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentShellScreen(),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherShellScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminShellScreen(),
      ),
      GoRoute(
        path: '/lesson/:lessonId',
        builder: (context, state) => LessonDetailScreen(
          lessonId: state.pathParameters['lessonId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/quiz/:lessonId',
        builder: (context, state) =>
            QuizScreen(lessonId: state.pathParameters['lessonId'] ?? ''),
      ),
      GoRoute(
        path: '/quiz-result',
        builder: (context, state) {
          final args = state.extra;
          if (args is! QuizResultArgs) {
            return const QuizResultScreen(
              args: QuizResultArgs(
                lessonId: 'earth_structure',
                score: 0,
                total: 0,
                xpGained: 0,
              ),
            );
          }
          return QuizResultScreen(args: args);
        },
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementScreen(),
      ),
      GoRoute(
        path: '/evaluation',
        builder: (context, state) => const EvaluationFormScreen(),
      ),
    ],
  );
});
