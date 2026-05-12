import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/custom_bottom_nav_bar.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../challenges/presentation/screens/challenges_screen.dart';
import '../../../lessons/presentation/screens/lesson_list_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/providers/profile_preferences_provider.dart';
import '../../../progress/presentation/screens/progress_screen.dart';
import '../../../quiz/providers/quiz_providers.dart';
import 'student_dashboard_screen.dart';

class StudentShellScreen extends ConsumerStatefulWidget {
  const StudentShellScreen({super.key});

  @override
  ConsumerState<StudentShellScreen> createState() => _StudentShellScreenState();
}

class _StudentShellScreenState extends ConsumerState<StudentShellScreen> {
  late final PageController _pageController;
  int _index = 0;
  bool _isSigningOut = false;

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

  List<Widget> get _pages => [
    StudentDashboardScreen(
      onOpenLessons: () => _changeTab(1),
      onLogout: _logout,
      isSigningOut: _isSigningOut,
    ),
    const LessonListScreen(),
    const ChallengesScreen(),
    const ProgressScreen(),
    const ProfileScreen(),
  ];

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
            'Are you sure you want to logout from your student account?',
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
    // Trigger quiz fetch so offline cache stays synced when student is online.
    ref.watch(quizzesProvider);

    return Scaffold(
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
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book_rounded),
            label: 'Lessons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            activeIcon: Icon(Icons.flag_rounded),
            label: 'Challenges',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights_rounded),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
