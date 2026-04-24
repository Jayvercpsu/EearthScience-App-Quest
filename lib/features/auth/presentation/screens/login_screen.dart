import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/illustration_assets.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validators.dart';
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
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
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

  Future<void> _googleLogin() async {
    if (_googleLoading) {
      return;
    }

    final selection = await _showGoogleSignupSheet();
    if (selection == null || !mounted) {
      return;
    }

    final preferredRole = selection.role;
    final teacherAccessCode = selection.teacherAccessCode;

    if (!mounted) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (!mounted) {
      return;
    }

    setState(() => _googleLoading = true);
    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .loginWithGoogle(
            preferredRole: preferredRole,
            teacherAccessCode: teacherAccessCode,
          )
          .timeout(const Duration(seconds: 45));

      if (!mounted) {
        return;
      }

      if (user == null) {
        final state = ref.read(authControllerProvider);
        final message = state.hasError
            ? state.error.toString().replaceFirst('Exception: ', '')
            : 'Google sign-in cancelled.';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
        return;
      }

      if (mounted) {
        context.go(user.role.homeRoute);
      }
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google sign-in took too long. Please check your internet and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _googleLoading = false);
      }
    }
  }

  Future<_GoogleSignupSelection?> _showGoogleSignupSheet() async {
    AppRole selectedRole = AppRole.student;
    String? inlineError;

    return showDialog<_GoogleSignupSelection>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        final codeController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isCompact = MediaQuery.of(context).size.width < 380;
            final teacherSelected = selectedRole == AppRole.teacher;

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              title: const Text('Choose account type'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Required for first Google sign-up.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    if (isCompact)
                      Column(
                        children: [
                          _RoleButton(
                            title: 'Student',
                            subtitle: 'Learn lessons and quizzes',
                            isSelected: selectedRole == AppRole.student,
                            onTap: () {
                              setDialogState(() {
                                selectedRole = AppRole.student;
                                inlineError = null;
                                codeController.clear();
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          _RoleButton(
                            title: 'Teacher',
                            subtitle: 'Manage lessons and class',
                            isSelected: teacherSelected,
                            onTap: () {
                              setDialogState(() {
                                selectedRole = AppRole.teacher;
                                inlineError = null;
                              });
                            },
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _RoleButton(
                              title: 'Student',
                              subtitle: 'Learn lessons and quizzes',
                              isSelected: selectedRole == AppRole.student,
                              onTap: () {
                                setDialogState(() {
                                  selectedRole = AppRole.student;
                                  inlineError = null;
                                  codeController.clear();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _RoleButton(
                              title: 'Teacher',
                              subtitle: 'Manage lessons and class',
                              isSelected: teacherSelected,
                              onTap: () {
                                setDialogState(() {
                                  selectedRole = AppRole.teacher;
                                  inlineError = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: teacherSelected
                          ? Padding(
                              key: const ValueKey('teacher_code_field'),
                              padding: const EdgeInsets.only(top: 12),
                              child: TextField(
                                controller: codeController,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  hintText: 'Teacher invite code',
                                  prefixIcon: Icon(
                                    Icons.verified_user_outlined,
                                  ),
                                ),
                                onSubmitted: (_) {
                                  final code = codeController.text.trim();
                                  if (code.isEmpty) {
                                    setDialogState(() {
                                      inlineError =
                                          'Teacher invite code is required.';
                                    });
                                    return;
                                  }

                                  FocusManager.instance.primaryFocus?.unfocus();

                                  Navigator.of(dialogContext).pop(
                                    _GoogleSignupSelection(
                                      role: AppRole.teacher,
                                      teacherAccessCode: code,
                                    ),
                                  );
                                },
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('teacher_code_empty'),
                            ),
                    ),
                    if (inlineError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        inlineError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();

                    if (selectedRole == AppRole.teacher) {
                      final code = codeController.text.trim();

                      if (code.isEmpty) {
                        setDialogState(() {
                          inlineError = 'Teacher invite code is required.';
                        });
                        return;
                      }

                      Navigator.of(dialogContext).pop(
                        _GoogleSignupSelection(
                          role: AppRole.teacher,
                          teacherAccessCode: code,
                        ),
                      );
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(const _GoogleSignupSelection(role: AppRole.student));
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 16),
                FadeSlideIn(
                  delayMs: 30,
                  child: Container(
                    height: 68,
                    width: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A3F9B), Color(0xFF0E63F4)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        IllustrationAssets.splashEarth,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const FadeSlideIn(
                  delayMs: 80,
                  child: Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 34 / 2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const FadeSlideIn(
                  delayMs: 110,
                  child: Text(
                    'Let\'s continue your\nlearning journey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delayMs: 150,
                  child: TextFormField(
                    controller: _emailController,
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FadeSlideIn(
                  delayMs: 180,
                  child: PasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    validator: Validators.password,
                  ),
                ),
                const SizedBox(height: 10),
                FadeSlideIn(
                  delayMs: 210,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 360;
                      final rememberRow = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _remember,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (value) =>
                                setState(() => _remember = value ?? false),
                          ),
                          const Text(
                            'Remember me',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );

                      final forgotButton = TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(fontSize: 12),
                        ),
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            rememberRow,
                            const SizedBox(height: 2),
                            Align(
                              alignment: Alignment.centerRight,
                              child: forgotButton,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [rememberRow, const Spacer(), forgotButton],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                FadeSlideIn(
                  delayMs: 240,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                  ),
                ),
                const SizedBox(height: 16),
                const FadeSlideIn(
                  delayMs: 260,
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'or',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delayMs: 280,
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFDDE3EE)),
                      ),
                      onPressed: _googleLoading ? null : _googleLogin,
                      child: _googleLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/google_g.png',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 10),
                                const Text('Sign Up / Continue with Google'),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Don\'t have an account?',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('Register'),
                    ),
                  ],
                ),
                if (authState.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      authState.error.toString().replaceFirst(
                        'Exception: ',
                        '',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSignupSelection {
  const _GoogleSignupSelection({required this.role, this.teacherAccessCode});

  final AppRole role;
  final String? teacherAccessCode;
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isSelected = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF5B98FF)
                  : const Color(0xFFDCE3EE),
              width: isSelected ? 1.4 : 1,
            ),
            color: isSelected ? const Color(0xFFEFF5FF) : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
