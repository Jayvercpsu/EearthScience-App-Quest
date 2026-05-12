import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/illustration_assets.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../offline/providers/offline_providers.dart';
import '../../../../shared/animations/fade_slide_in.dart';
import '../../../../shared/widgets/password_field.dart';
import '../../data/models/app_user.dart';
import '../../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _remember = true;
  bool _isOpeningOffline = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = await ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);

    if (!mounted) {
      return;
    }

    if (user != null) {
      context.go(user.role.homeRoute);
    }
  }

  Future<void> _openOfflineMode() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isOpeningOffline || !mounted) {
      return;
    }

    setState(() => _isOpeningOffline = true);
    try {
      final sessionRepo = ref.read(offlineSessionRepositoryProvider);
      var nickname = await sessionRepo.loadNickname();

      if (nickname == null || nickname.trim().isEmpty) {
        if (!mounted) {
          return;
        }
        nickname = await showDialog<String>(
          context: context,
          builder: (dialogContext) => const _OfflineNicknameDialog(),
        );
      }

      if (nickname == null || nickname.trim().isEmpty || !mounted) {
        return;
      }

      await sessionRepo.saveNickname(nickname);
      ref
        ..invalidate(offlineNicknameProvider)
        ..invalidate(offlineLessonsProvider)
        ..invalidate(offlineQuizzesProvider)
        ..invalidate(offlineProgressProvider);
      if (!mounted) {
        return;
      }
      context.go('/offline');
    } finally {
      if (mounted) {
        setState(() => _isOpeningOffline = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          const _LoginBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    FadeSlideIn(
                      delayMs: 20,
                      child: Column(
                        children: [
                          Container(
                            width: 94,
                            height: 94,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF74B0FF), Color(0xFF1F6DFF)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF61A7FF,
                                  ).withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                IllustrationAssets.splashEarth,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Welcome Back!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Log in to continue your\nlearning journey.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFD2E5FF),
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    FadeSlideIn(
                      delayMs: 90,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.98),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFD8E4F6),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0A2D7B,
                              ).withValues(alpha: 0.16),
                              blurRadius: 26,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Login Details',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              validator: Validators.email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            PasswordField(
                              controller: _passwordController,
                              label: 'Password',
                              validator: Validators.password,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: _remember,
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (value) => setState(
                                        () => _remember = value ?? false,
                                      ),
                                    ),
                                    const Text(
                                      'Remember me',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () =>
                                      context.push('/forgot-password'),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: authState.isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                backgroundColor: const Color(0xFF0A4BC2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Login'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed:
                                  authState.isLoading || _isOpeningOffline
                                  ? null
                                  : _openOfflineMode,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: _isOpeningOffline
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.offline_bolt_rounded),
                              label: Text(
                                _isOpeningOffline
                                    ? 'Opening Offline Mode...'
                                    : 'Play Offline (Student Only)',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Don\'t have an account?',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/register'),
                                  child: const Text('Register'),
                                ),
                              ],
                            ),
                            if (authState.hasError)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFFCCCC),
                                  ),
                                ),
                                child: Text(
                                  authState.error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineNicknameDialog extends StatefulWidget {
  const _OfflineNicknameDialog();

  @override
  State<_OfflineNicknameDialog> createState() => _OfflineNicknameDialogState();
}

class _OfflineNicknameDialogState extends State<_OfflineNicknameDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _errorText = 'Nickname is required.');
      return;
    }
    if (trimmed.length < 2) {
      setState(() => _errorText = 'Nickname must be at least 2 characters.');
      return;
    }
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Play Offline'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_errorText != null) {
            setState(() => _errorText = null);
          }
        },
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'Enter nickname',
          prefixIcon: const Icon(Icons.person_outline_rounded),
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Start')),
      ],
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF001D55), Color(0xFF05317D), Color(0xFF0D59CC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            left: -30,
            child: _GlowBlob(
              size: 220,
              color: const Color(0xFF58A1FF).withValues(alpha: 0.36),
            ),
          ),
          Positioned(
            top: 120,
            right: -70,
            child: _GlowBlob(
              size: 190,
              color: const Color(0xFF9ED3FF).withValues(alpha: 0.26),
            ),
          ),
          Positioned(
            bottom: -100,
            left: 30,
            child: _GlowBlob(
              size: 240,
              color: const Color(0xFF0E88FF).withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
