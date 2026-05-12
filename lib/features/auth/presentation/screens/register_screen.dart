import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/illustration_assets.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/animations/fade_slide_in.dart';
import '../../../../shared/widgets/password_field.dart';
import '../../data/models/app_user.dart';
import '../../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _teacherCodeController = TextEditingController();
  AppRole _selectedRole = AppRole.student;

  bool get _isTeacherSelected => _selectedRole == AppRole.teacher;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _teacherCodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = await ref
        .read(authControllerProvider.notifier)
        .register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
          teacherAccessCode: _teacherCodeController.text.trim(),
        );

    if (!mounted) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 50));

    if (!mounted) {
      return;
    }

    if (user != null) {
      context.go(user.role.homeRoute);
    }
  }

  void _updateRole(AppRole role) {
    if (_selectedRole == role) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedRole = role;
      if (role != AppRole.teacher) {
        _teacherCodeController.clear();
      }
    });
  }

  Widget _buildRoleSecurityField() {
    if (_isTeacherSelected) {
      return Padding(
        key: const ValueKey('teacher_code'),
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _teacherCodeController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Teacher invite code',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
              validator: (value) {
                if (!_isTeacherSelected) {
                  return null;
                }
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Teacher invite code is required';
                }
                if (text.length < 4) {
                  return 'Enter a valid invite code';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCFE0FF)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only approved teachers can create teacher accounts.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink(key: ValueKey('no_security_code'));
  }

  String _buttonLabelForRole(AppRole role) {
    switch (role) {
      case AppRole.student:
        return 'Create Student Account';
      case AppRole.teacher:
        return 'Create Teacher Account';
      case AppRole.admin:
        return 'Create Student Account';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          const _RegisterBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton.filledTonal(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                                IllustrationAssets.appLogo,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Create Your Earth Passport',
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
                            'Student accounts are open.\nTeacher accounts need an invite code.',
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
                              'Registration Details',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _nameController,
                              validator: (value) => Validators.requiredField(
                                value,
                                field: 'Full name',
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
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
                            const SizedBox(height: AppSpacing.sm),
                            PasswordField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              validator: (value) => Validators.confirmPassword(
                                value,
                                _passwordController.text,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Account Type',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _RoleSelectorCard(
                                    title: 'Student',
                                    subtitle: 'Open for everyone',
                                    icon: Icons.school_rounded,
                                    isSelected:
                                        _selectedRole == AppRole.student,
                                    onTap: () => _updateRole(AppRole.student),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _RoleSelectorCard(
                                    title: 'Teacher',
                                    subtitle: 'Invite code required',
                                    icon: Icons.menu_book_rounded,
                                    isSelected:
                                        _selectedRole == AppRole.teacher,
                                    onTap: () => _updateRole(AppRole.teacher),
                                  ),
                                ),
                              ],
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 240),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeOutCubic,
                              child: _buildRoleSecurityField(),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: authState.isLoading ? null : _register,
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
                                  : Text(_buttonLabelForRole(_selectedRole)),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account?',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/login'),
                                  child: const Text('Login'),
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

class _RoleSelectorCard extends StatelessWidget {
  const _RoleSelectorCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF77A7FF)
                : const Color(0xFFDCE4F2),
            width: isSelected ? 1.6 : 1,
          ),
          color: isSelected ? const Color(0xFFEFF5FF) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? const Color(0xFF0E63F4)
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterBackdrop extends StatelessWidget {
  const _RegisterBackdrop();

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
