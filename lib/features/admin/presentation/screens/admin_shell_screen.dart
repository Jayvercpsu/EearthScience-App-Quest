import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/illustration_assets.dart';
import '../../../../shared/animations/fade_slide_in.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/admin_providers.dart';

enum _AdminSection { invites, users }

enum _UserFilter { all, students, teachers, admins }

enum _AdminMenuAction { editProfile, changePassword, logout }

class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({super.key});

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  _AdminSection _section = _AdminSection.invites;
  _UserFilter _userFilter = _UserFilter.all;
  final _dateFormat = DateFormat('MMM d, yyyy h:mm a');
  final _usersScrollController = ScrollController();
  final _invitesScrollController = ScrollController();
  bool _accountActionBusy = false;
  String? _adminNameOverride;

  @override
  void initState() {
    super.initState();
    _usersScrollController.addListener(_onUsersScroll);
    _invitesScrollController.addListener(_onInvitesScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapData();
    });
  }

  @override
  void dispose() {
    _usersScrollController
      ..removeListener(_onUsersScroll)
      ..dispose();
    _invitesScrollController
      ..removeListener(_onInvitesScroll)
      ..dispose();
    super.dispose();
  }

  void _bootstrapData() {
    ref.invalidate(adminStatsProvider);
    unawaited(
      ref
          .read(adminUsersProvider.notifier)
          .loadInitial(roleFilter: _mapUserFilterToRole(_userFilter)),
    );
    unawaited(ref.read(adminInviteCodesProvider.notifier).loadInitial());
  }

  void _onUsersScroll() {
    if (!_usersScrollController.hasClients || _section != _AdminSection.users) {
      return;
    }
    final threshold = _usersScrollController.position.maxScrollExtent - 280;
    if (_usersScrollController.position.pixels >= threshold) {
      unawaited(ref.read(adminUsersProvider.notifier).loadMore());
    }
  }

  void _onInvitesScroll() {
    if (!_invitesScrollController.hasClients ||
        _section != _AdminSection.invites) {
      return;
    }
    final threshold = _invitesScrollController.position.maxScrollExtent - 280;
    if (_invitesScrollController.position.pixels >= threshold) {
      unawaited(ref.read(adminInviteCodesProvider.notifier).loadMore());
    }
  }

  AppRole? _mapUserFilterToRole(_UserFilter filter) {
    switch (filter) {
      case _UserFilter.all:
        return null;
      case _UserFilter.students:
        return AppRole.student;
      case _UserFilter.teachers:
        return AppRole.teacher;
      case _UserFilter.admins:
        return AppRole.admin;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUserAsync = ref.watch(currentUserProvider);

    return authUserAsync.when(
      loading: () => const Scaffold(body: _AdminBootLoader()),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Unable to load admin account.')),
      ),
      data: (authUser) {
        if (authUser == null) {
          return _AccessNotice(
            title: 'Not signed in',
            subtitle: 'Please login as admin to continue.',
            actionLabel: 'Go to Login',
            onAction: () => context.go('/login'),
          );
        }
        if (authUser.role != AppRole.admin) {
          return _AccessNotice(
            title: 'Admin access only',
            subtitle: 'Your account is not authorized for admin console.',
            actionLabel: 'Back to Login',
            onAction: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          );
        }

        final usersState = ref.watch(adminUsersProvider);
        final invitesState = ref.watch(adminInviteCodesProvider);
        final actionState = ref.watch(adminActionProvider);
        final statsAsync = ref.watch(adminStatsProvider);
        final stats = statsAsync.valueOrNull;

        final displayName = _adminNameOverride ?? authUser.name;
        final headerUserCount = stats?.totalUsers ?? usersState.users.length;
        final headerTeacherCount =
            stats?.teacherUsers ??
            usersState.users
                .where((user) => user.role == AppRole.teacher)
                .length;
        final headerInviteCount =
            stats?.totalInvites ?? invitesState.invites.length;
        final headerActiveInvites =
            stats?.activeInvites ??
            invitesState.invites
                .where((invite) => invite.isActive && !invite.isUsed)
                .length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            actions: [
              IconButton(
                tooltip: 'Account options',
                onPressed: () =>
                    _openAccountActionSheet(currentName: displayName),
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          body: Column(
            children: [
              FadeSlideIn(
                delayMs: 10,
                child: _AdminHeader(
                  adminName: displayName,
                  userCount: headerUserCount,
                  teacherCount: headerTeacherCount,
                  inviteCount: headerInviteCount,
                  activeInviteCount: headerActiveInvites,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _SectionButton(
                        icon: Icons.verified_user_outlined,
                        label: 'Teacher Invites',
                        isActive: _section == _AdminSection.invites,
                        onTap: () =>
                            setState(() => _section = _AdminSection.invites),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SectionButton(
                        icon: Icons.groups_rounded,
                        label: 'All Users',
                        isActive: _section == _AdminSection.users,
                        onTap: () =>
                            setState(() => _section = _AdminSection.users),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: _section == _AdminSection.invites
                      ? _InviteCodesView(
                          key: const ValueKey('invites'),
                          state: invitesState,
                          isBusy: actionState.isLoading || _accountActionBusy,
                          dateFormat: _dateFormat,
                          controller: _invitesScrollController,
                          onCreateInvite: () => _createInviteCode(
                            adminUserId: authUser.uid,
                            adminName: displayName,
                          ),
                          onDeactivateInvite: _deactivateInvite,
                          onCopyInvite: _copyInviteCode,
                          onRetry: () {
                            ref.invalidate(adminStatsProvider);
                            unawaited(
                              ref
                                  .read(adminInviteCodesProvider.notifier)
                                  .refresh(),
                            );
                          },
                        )
                      : _UsersView(
                          key: const ValueKey('users'),
                          state: usersState,
                          userFilter: _userFilter,
                          controller: _usersScrollController,
                          dateFormat: _dateFormat,
                          onFilterChanged: (value) {
                            setState(() => _userFilter = value);
                            unawaited(
                              ref
                                  .read(adminUsersProvider.notifier)
                                  .loadInitial(
                                    roleFilter: _mapUserFilterToRole(value),
                                  ),
                            );
                          },
                          onRetry: () {
                            unawaited(
                              ref.read(adminUsersProvider.notifier).refresh(),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createInviteCode({
    required String adminUserId,
    required String adminName,
  }) async {
    try {
      final code = await ref
          .read(adminActionProvider.notifier)
          .createInviteCode(adminUserId: adminUserId, adminName: adminName);
      if (!mounted) return;

      await ref.read(adminInviteCodesProvider.notifier).refresh();
      ref.invalidate(adminStatsProvider);
      if (!mounted) return;

      final buttonStyle = ElevatedButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

      await _showRootDialog<void>(
        builder: (context) {
          return AlertDialog(
            title: const Text('Invite Created'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Share this code with the teacher:'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        code,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy code',
                      onPressed: () => _copyInviteCode(code),
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: buttonStyle,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handlePopupAction({
    required _AdminMenuAction action,
    required String currentName,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) {
      return;
    }

    switch (action) {
      case _AdminMenuAction.editProfile:
        await _showEditProfileDialog(currentName: currentName);
        break;
      case _AdminMenuAction.changePassword:
        await _showChangePasswordDialog();
        break;
      case _AdminMenuAction.logout:
        await _logoutAdmin();
        break;
    }
  }

  Future<void> _openAccountActionSheet({required String currentName}) async {
    if (_accountActionBusy || !mounted) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    final action = await showModalBottomSheet<_AdminMenuAction>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit Profile'),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_AdminMenuAction.editProfile),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_reset_rounded),
                  title: const Text('Change Password'),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_AdminMenuAction.changePassword),
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Logout'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_AdminMenuAction.logout),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null || !mounted) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) {
      return;
    }
    await _handlePopupAction(action: action, currentName: currentName);
  }

  Future<T?> _showRootDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) async {
    if (!mounted) {
      return null;
    }
    return showDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }

  Future<void> _deactivateInvite(String inviteId) async {
    await ref.read(adminActionProvider.notifier).deactivateInviteCode(inviteId);
    if (!mounted) return;

    await ref.read(adminInviteCodesProvider.notifier).refresh();
    if (!mounted) return;
    ref.invalidate(adminStatsProvider);
    _showSnackBar('Invite code deactivated.');
  }

  Future<void> _copyInviteCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    _showSnackBar('Invite code copied.');
  }

  Future<void> _logoutAdmin() async {
    if (_accountActionBusy) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    final confirm = await _showLogoutConfirmation();
    if (!confirm) {
      return;
    }

    setState(() => _accountActionBusy = true);
    try {
      await ref.read(authControllerProvider.notifier).signOut();
      ref.invalidate(currentUserProvider);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _accountActionBusy = false);
      }
    }
  }

  Future<bool> _showLogoutConfirmation() async {
    if (!mounted) {
      return false;
    }

    final textStyle = TextButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final elevatedStyle = ElevatedButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    final result = await _showRootDialog<bool>(
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout admin account?'),
          actions: [
            TextButton(
              style: textStyle,
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: elevatedStyle,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _showEditProfileDialog({required String currentName}) async {
    if (!mounted) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();
    final textStyle = TextButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final elevatedStyle = ElevatedButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    final newName = await _showRootDialog<String>(
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Admin Profile'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Admin name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'Name is required';
                }
                if (text.length < 2) {
                  return 'Name is too short';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              style: textStyle,
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: elevatedStyle,
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (newName == null || newName.isEmpty) {
      return;
    }

    setState(() => _accountActionBusy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfileName(newName);
      if (!mounted) return;
      setState(() => _adminNameOverride = newName);
      _showSnackBar('Admin profile updated.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _accountActionBusy = false);
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    if (!mounted) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final textStyle = TextButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final elevatedStyle = ElevatedButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    final newPassword = await _showRootDialog<String>(
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'New password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'New password is required';
                    }
                    if (text.length < 6) {
                      return 'Minimum 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_person_outlined),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Confirm your password';
                    }
                    if (text != passwordController.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: textStyle,
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: elevatedStyle,
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                Navigator.of(context).pop(passwordController.text.trim());
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    passwordController.dispose();
    confirmController.dispose();

    if (newPassword == null || newPassword.isEmpty) {
      return;
    }

    setState(() => _accountActionBusy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(newPassword);
      if (!mounted) return;
      _showSnackBar('Admin password updated successfully.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _accountActionBusy = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.adminName,
    required this.userCount,
    required this.teacherCount,
    required this.inviteCount,
    required this.activeInviteCount,
  });

  final String adminName;
  final int userCount;
  final int teacherCount;
  final int inviteCount;
  final int activeInviteCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF032864), Color(0xFF0A4BC2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            bottom: -4,
            child: Opacity(
              opacity: 0.16,
              child: Image.asset(
                IllustrationAssets.heroLandscape,
                width: 140,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Welcome, $adminName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage users and teacher invitation access.',
                style: TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniStatChip(
                    icon: Icons.groups_rounded,
                    label: 'Users',
                    value: '$userCount',
                  ),
                  _MiniStatChip(
                    icon: Icons.school_rounded,
                    label: 'Teachers',
                    value: '$teacherCount',
                  ),
                  _MiniStatChip(
                    icon: Icons.vpn_key_rounded,
                    label: 'Invites',
                    value: '$inviteCount',
                  ),
                  _MiniStatChip(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Active',
                    value: '$activeInviteCount',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  const _MiniStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionButton extends StatelessWidget {
  const _SectionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive ? const Color(0xFF0A4BC2) : Colors.white,
          border: Border.all(
            color: isActive ? const Color(0xFF0A4BC2) : const Color(0xFFD9E1EE),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCodesView extends StatelessWidget {
  const _InviteCodesView({
    super.key,
    required this.state,
    required this.isBusy,
    required this.dateFormat,
    required this.controller,
    required this.onCreateInvite,
    required this.onDeactivateInvite,
    required this.onCopyInvite,
    required this.onRetry,
  });

  final AdminInviteCodesState state;
  final bool isBusy;
  final DateFormat dateFormat;
  final ScrollController controller;
  final VoidCallback onCreateInvite;
  final ValueChanged<String> onDeactivateInvite;
  final ValueChanged<String> onCopyInvite;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.invites.isEmpty) {
      return const _CoolLoadingList();
    }

    if (state.error != null && state.invites.isEmpty) {
      return _InlineError(
        label: 'Unable to load invite codes.',
        onRetry: onRetry,
      );
    }

    final items = state.invites;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : onCreateInvite,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Generate Teacher Invite'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No invite codes yet.'))
              : ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  itemCount: items.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final invite = items[index];
                    final status = invite.isUsed
                        ? 'Used'
                        : (invite.isActive ? 'Active' : 'Inactive');
                    final statusColor = invite.isUsed
                        ? const Color(0xFF128A3C)
                        : (invite.isActive
                              ? const Color(0xFF0A4BC2)
                              : const Color(0xFF697586));

                    return FadeSlideIn(
                      delayMs: 20 * (index % 5),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDEE5F1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    invite.code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Copy code',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => onCopyInvite(invite.code),
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 18,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Created: ${dateFormat.format(invite.createdAt)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (invite.usedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Used: ${dateFormat.format(invite.usedAt!)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (invite.isActive && !invite.isUsed) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: isBusy
                                      ? null
                                      : () => onDeactivateInvite(invite.id),
                                  icon: const Icon(
                                    Icons.block_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Deactivate'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView({
    super.key,
    required this.state,
    required this.userFilter,
    required this.controller,
    required this.dateFormat,
    required this.onFilterChanged,
    required this.onRetry,
  });

  final AdminUsersState state;
  final _UserFilter userFilter;
  final ScrollController controller;
  final DateFormat dateFormat;
  final ValueChanged<_UserFilter> onFilterChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.users.isEmpty) {
      return const _CoolLoadingList();
    }

    if (state.error != null && state.users.isEmpty) {
      return _InlineError(label: 'Unable to load users.', onRetry: onRetry);
    }

    final users = state.users;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChipButton(
                label: 'All',
                isSelected: userFilter == _UserFilter.all,
                onTap: () => onFilterChanged(_UserFilter.all),
              ),
              _FilterChipButton(
                label: 'Students',
                isSelected: userFilter == _UserFilter.students,
                onTap: () => onFilterChanged(_UserFilter.students),
              ),
              _FilterChipButton(
                label: 'Teachers',
                isSelected: userFilter == _UserFilter.teachers,
                onTap: () => onFilterChanged(_UserFilter.teachers),
              ),
              _FilterChipButton(
                label: 'Admins',
                isSelected: userFilter == _UserFilter.admins,
                onTap: () => onFilterChanged(_UserFilter.admins),
              ),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: users.isEmpty
              ? const Center(child: Text('No users in this filter.'))
              : ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  itemCount: users.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= users.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final user = users[index];

                    return FadeSlideIn(
                      delayMs: 18 * (index % 6),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDEE5F1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFE9F2FF),
                                  child: Text(
                                    user.name.isEmpty
                                        ? 'U'
                                        : user.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        user.email,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _RoleBadge(role: user.role),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Created: ${dateFormat.format(user.createdAt)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (user.role == AppRole.teacher) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'Teacher account requires invite validation.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CoolLoadingList extends StatelessWidget {
  const _CoolLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      itemCount: 6,
      itemBuilder: (_, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDEE5F1)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PulseBar(height: 14, width: 190),
              SizedBox(height: 8),
              _PulseBar(height: 11, width: 220),
              SizedBox(height: 12),
              _PulseBar(height: 10, width: 130),
            ],
          ),
        );
      },
    );
  }
}

class _PulseBar extends StatefulWidget {
  const _PulseBar({required this.height, required this.width});

  final double height;
  final double width;

  @override
  State<_PulseBar> createState() => _PulseBarState();
}

class _PulseBarState extends State<_PulseBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alpha = 0.16 + (_controller.value * 0.2);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFF8EA3C2).withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      },
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.label, required this.onRetry});

  final String label;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminBootLoader extends StatelessWidget {
  const _AdminBootLoader();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(padding: EdgeInsets.all(12), child: _CoolLoadingList()),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isSelected ? const Color(0xFF0A4BC2) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0A4BC2)
                : const Color(0xFFD8E2F2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      AppRole.student => ('Student', const Color(0xFF0B7A3F)),
      AppRole.teacher => ('Teacher', const Color(0xFF0A4BC2)),
      AppRole.admin => ('Admin', const Color(0xFF9A3412)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _AccessNotice extends StatelessWidget {
  const _AccessNotice({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 52,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
