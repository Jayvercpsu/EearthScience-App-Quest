import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/illustration_assets.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 2000));

    AppUser? user;
    try {
      user = await ref
          .read(authRepositoryProvider)
          .currentAppUser()
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      // Avoid getting stuck on splash in release builds when Firebase/Firestore
      // is temporarily unreachable or initialization fails.
      user = null;
    }

    if (!mounted) return;

    context.go(user?.role.homeRoute ?? '/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    Icons.nights_stay_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 28,
                  ),
                ),
                const Spacer(),
                ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: Container(
                    height: 210,
                    width: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0B4CB3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF63A9FF).withValues(alpha: 0.4),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        IllustrationAssets.appLogo,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOut,
                  ),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.extension_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'EARTH SCIENCE APP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          fontSize: 38 / 3,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Learn Earth Science\nthrough play.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(
                  height: 26,
                  child: Center(
                    child: Text(
                      'Loading app shell...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: null,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF3FA8FF)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
