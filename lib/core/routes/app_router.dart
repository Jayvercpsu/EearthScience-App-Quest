import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/presentation/screens/achievement_screen.dart';
import '../../features/admin/presentation/screens/admin_shell_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/student_shell_screen.dart';
import '../../features/lessons/presentation/screens/lesson_detail_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/offline/presentation/screens/offline_lesson_detail_screen.dart';
import '../../features/offline/presentation/screens/offline_earth_layers_game_screen.dart';
import '../../features/offline/presentation/screens/offline_mini_game_screen.dart';
import '../../features/offline/presentation/screens/offline_plate_boundary_game_screen.dart';
import '../../features/offline/presentation/screens/offline_shell_screen.dart';

import '../../features/quiz/presentation/screens/quiz_result_screen.dart';
import '../../features/quiz/presentation/screens/quiz_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/teacher/presentation/screens/teacher_shell_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
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
        path: '/offline',
        builder: (context, state) => const OfflineShellScreen(),
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
        path: '/offline-lesson/:lessonId',
        builder: (context, state) => OfflineLessonDetailScreen(
          lessonId: state.pathParameters['lessonId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/offline-quiz/:lessonId',
        builder: (context, state) => QuizScreen(
          lessonId: state.pathParameters['lessonId'] ?? '',
          offlineMode: true,
        ),
      ),
      GoRoute(
        path: '/offline-mini-game',
        builder: (context, state) => const OfflineMiniGameScreen(),
      ),
      GoRoute(
        path: '/offline-plate-boundary-game',
        builder: (context, state) => const OfflinePlateBoundaryGameScreen(),
      ),
      GoRoute(
        path: '/offline-earth-layers-game',
        builder: (context, state) => const OfflineEarthLayersGameScreen(),
      ),
      GoRoute(
        path: '/quiz-result',
        builder: (context, state) {
          final args = state.extra;
          if (args is! QuizResultArgs) {
            return const QuizResultScreen(
              args: QuizResultArgs(
                lessonId: 'earth_crust_layers',
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
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
