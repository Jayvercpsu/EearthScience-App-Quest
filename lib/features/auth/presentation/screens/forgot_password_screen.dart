import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _verifying = false;
  bool _updating = false;
  bool _verified = false;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_emailFormKey.currentState!.validate() || _verifying) {
      return;
    }

    setState(() => _verifying = true);
    final exists = await ref
        .read(authControllerProvider.notifier)
        .verifyRegisteredEmail(_emailController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() {
      _verifying = false;
      _verified = exists;
    });

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(exists ? 'Verified!' : 'Not Found'),
        content: Text(
          exists
              ? 'Email verified successfully. You can now set a new password.'
              : 'This email is not registered yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePassword() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_passwordFormKey.currentState!.validate() || _updating) {
      return;
    }

    setState(() => _updating = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPasswordWithoutEmailVerification(
            email: _emailController.text.trim(),
            newPassword: _newPasswordController.text.trim(),
          );
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Password has been updated successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'Verify Account Email',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Enter your registered email. No OTP is needed in this flow.',
            ),
            const SizedBox(height: AppSpacing.lg),
            Form(
              key: _emailFormKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: _emailController,
                    label: 'Registered Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomButton(
                    label: _verifying ? 'Verifying...' : 'Verify',
                    isLoading: _verifying,
                    onPressed: _verifyEmail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_verified) ...[
              Text(
                'Set New Password',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Form(
                key: _passwordFormKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _newPasswordController,
                      label: 'New Password',
                      obscureText: true,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      obscureText: true,
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _newPasswordController.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomButton(
                      label: _updating ? 'Updating...' : 'Save New Password',
                      isLoading: _updating,
                      onPressed: _updatePassword,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
