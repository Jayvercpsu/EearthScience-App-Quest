import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/custom_bottom_nav_bar.dart';
import '../../../profile/providers/profile_preferences_provider.dart';
import 'lesson_exemplars_screen.dart';
import 'manage_lessons_screen.dart';
import 'manage_quizzes_screen.dart';
import 'student_monitoring_screen.dart';
import 'teacher_dashboard_screen.dart';

class TeacherShellScreen extends ConsumerStatefulWidget {
  const TeacherShellScreen({super.key});

  @override
  ConsumerState<TeacherShellScreen> createState() => _TeacherShellScreenState();
}

class _TeacherShellScreenState extends ConsumerState<TeacherShellScreen> {
  late final PageController _pageController;
  int _index = 0;

  final List<Widget> _pages = const [
    TeacherDashboardScreen(),
    ManageLessonsScreen(),
    ManageQuizzesScreen(),
    StudentMonitoringScreen(),
    LessonExemplarsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _changeTab(int nextIndex) async {
    if (_index == nextIndex || !_pageController.hasClients) {
      setState(() => _index = nextIndex);
      return;
    }

    final reduceMotion =
        ref.read(profilePreferencesProvider).valueOrNull?.reduceMotion ?? false;

    setState(() => _index = nextIndex);

    if (reduceMotion) {
      _pageController.jumpToPage(nextIndex);
      return;
    }

    await _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Module'),
        actions: [
          IconButton(
            onPressed: () => context.push('/evaluation'),
            icon: const Icon(Icons.fact_check_outlined),
            tooltip: 'Evaluation Form',
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (value) => setState(() => _index = value),
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _index,
        onTap: _changeTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book_rounded),
            label: 'Lessons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            activeIcon: Icon(Icons.quiz_rounded),
            label: 'Quizzes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics_rounded),
            label: 'Monitoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            activeIcon: Icon(Icons.lightbulb_rounded),
            label: 'Exemplars',
          ),
        ],
      ),
    );
  }
}
