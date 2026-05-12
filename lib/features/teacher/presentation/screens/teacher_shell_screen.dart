import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/custom_bottom_nav_bar.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../notifications/providers/notification_providers.dart';
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
  bool _isSigningOut = false;

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

  Future<void> _logout() async {
    if (_isSigningOut) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout Account'),
          content: const Text(
            'Are you sure you want to logout from your teacher account?',
          ),
          actionsAlignment: MainAxisAlignment.end,
          actionsOverflowAlignment: OverflowBarAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) {
      return;
    }

    setState(() => _isSigningOut = true);
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (!mounted) {
        return;
      }
      context.go('/login');
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageView = PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (value) => setState(() => _index = value),
      children: _pages,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wideLayout = constraints.maxWidth >= 1000;
        final unread = ref.watch(unreadNotificationCountProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Teacher Module'),
            actions: [
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded),
                    if (unread > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Notifications',
              ),
              IconButton(
                onPressed: _isSigningOut ? null : _logout,
                icon: _isSigningOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: wideLayout
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          right: BorderSide(
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      child: NavigationRail(
                        selectedIndex: _index,
                        groupAlignment: -0.8,
                        onDestinationSelected: _changeTab,
                        selectedIconTheme: const IconThemeData(
                          color: AppColors.primary,
                        ),
                        selectedLabelTextStyle: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            selectedIcon: Icon(Icons.dashboard_rounded),
                            label: Text('Dashboard'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.menu_book_outlined),
                            selectedIcon: Icon(Icons.menu_book_rounded),
                            label: Text('Lessons'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.quiz_outlined),
                            selectedIcon: Icon(Icons.quiz_rounded),
                            label: Text('Quizzes'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.analytics_outlined),
                            selectedIcon: Icon(Icons.analytics_rounded),
                            label: Text('Monitoring'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.lightbulb_outline),
                            selectedIcon: Icon(Icons.lightbulb_rounded),
                            label: Text('Exemplars'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: pageView),
                  ],
                )
              : pageView,
          bottomNavigationBar: wideLayout
              ? null
              : CustomBottomNavBar(
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
      },
    );
  }
}
