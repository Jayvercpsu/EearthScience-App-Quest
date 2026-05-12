import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../providers/offline_providers.dart';

class OfflineProfileScreen extends ConsumerWidget {
  const OfflineProfileScreen({required this.onQuitOffline, super.key});

  final VoidCallback onQuitOffline;

  Future<void> _editNickname(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(offlineSessionRepositoryProvider);
    final current = (await repo.loadNickname()) ?? '';
    if (!context.mounted) {
      return;
    }

    final updated = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _EditNicknameDialog(initialValue: current),
    );
    if (updated == null || updated.trim().isEmpty || !context.mounted) {
      return;
    }

    await repo.renameNickname(fromNickname: current, toNickname: updated);

    ref
      ..invalidate(offlineNicknameProvider)
      ..invalidate(offlineProgressProvider);

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nickname updated to ${updated.trim()}')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nicknameAsync = ref.watch(offlineNicknameProvider);
    final progressAsync = ref.watch(offlineProgressProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDBEAFE), Color(0xFFE0F2FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCFE1FF)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offline Learner',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nicknameAsync.valueOrNull ?? 'Student',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1E8F3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ProfileStat(
                  label: 'Completed',
                  value:
                      '${progressAsync.valueOrNull?.completedLessons.length ?? 0}',
                ),
              ),
              Expanded(
                child: _ProfileStat(
                  label: 'Mastery',
                  value:
                      '${(((progressAsync.valueOrNull?.masteryPercentage ?? 0.0) * 100).toInt())}%',
                ),
              ),
              Expanded(
                child: _ProfileStat(
                  label: 'Sessions',
                  value:
                      '${progressAsync.valueOrNull?.engagementStats['weeklySessions'] ?? 0}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 2,
          ),
          leading: const Icon(Icons.edit_rounded),
          title: const Text(
            'Edit Nickname',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: const Text('Change your offline player name'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _editNickname(context, ref),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE4EAF3)),
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 2,
          ),
          leading: const Icon(Icons.logout_rounded, color: Color(0xFFB91C1C)),
          title: const Text(
            'Quit Offline Mode',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: const Text('Return to login screen'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onQuitOffline,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE4EAF3)),
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _EditNicknameDialog extends StatefulWidget {
  const _EditNicknameDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_EditNicknameDialog> createState() => _EditNicknameDialogState();
}

class _EditNicknameDialogState extends State<_EditNicknameDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.length < 2) {
      setState(() => _error = 'Nickname must be at least 2 characters.');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Nickname'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_error != null) {
            setState(() => _error = null);
          }
        },
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'Enter new nickname',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
