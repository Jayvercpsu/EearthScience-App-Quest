import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/custom_bottom_nav_bar.dart';
import '../../providers/offline_providers.dart';
import 'offline_dashboard_screen.dart';
import 'offline_games_screen.dart';
import 'offline_lessons_screen.dart';
import 'offline_profile_screen.dart';
import 'offline_progress_screen.dart';

class OfflineShellScreen extends ConsumerStatefulWidget {
  const OfflineShellScreen({super.key});

  @override
  ConsumerState<OfflineShellScreen> createState() => _OfflineShellScreenState();
}

class _OfflineShellScreenState extends ConsumerState<OfflineShellScreen> {
  int _index = 0;

  Future<void> _changeTab(int nextIndex) async {
    setState(() => _index = nextIndex);
  }

  Future<void> _quitOffline() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quit Offline Mode'),
        content: const Text('Leave offline mode and return to login page?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final nicknameAsync = ref.watch(offlineNicknameProvider);
    final pages = <Widget>[
      OfflineDashboardScreen(onOpenLessons: () => _changeTab(1)),
      const OfflineLessonsScreen(),
      const OfflineGamesScreen(),
      const OfflineProgressScreen(),
      OfflineProfileScreen(onQuitOffline: _quitOffline),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          nicknameAsync.when(
            data: (nick) => 'Offline - ${(nick ?? 'Guest')}',
            loading: () => 'Offline Mode',
            error: (_, __) => 'Offline Mode',
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _quitOffline,
            icon: const Icon(Icons.exit_to_app_rounded),
            label: const Text('Quit'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
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
            icon: Icon(Icons.sports_esports_outlined),
            activeIcon: Icon(Icons.sports_esports_rounded),
            label: 'Games',
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
