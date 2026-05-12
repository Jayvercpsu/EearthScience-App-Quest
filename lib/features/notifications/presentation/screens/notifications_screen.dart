import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final role = user?.role.value ?? 'student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref
                  .read(notificationActionProvider.notifier)
                  .markAllReadForRole(role, userId: user?.uid ?? '');
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search notifications...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: notificationsAsync.when(
                  data: (notifications) {
                    final filtered = notifications.where((item) {
                      final key = _search.toLowerCase();
                      if (key.isEmpty) return true;
                      return item.title.toLowerCase().contains(key) ||
                          item.message.toLowerCase().contains(key);
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No notifications found.'),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: item.isRead
                                  ? const Color(0xFFE5EBF3)
                                  : AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: item.isRead
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFFEFF5FF),
                            child: Icon(
                              item.isRead
                                  ? Icons.mark_email_read_outlined
                                  : Icons.mark_email_unread_outlined,
                              color: item.isRead
                                  ? AppColors.textSecondary
                                  : AppColors.primary,
                            ),
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            item.message,
                            style: const TextStyle(height: 1.35),
                          ),
                          trailing: item.isRead
                              ? const Text(
                                  'Read',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                )
                              : TextButton(
                                  onPressed: () async {
                                    await ref
                                        .read(
                                          notificationActionProvider.notifier,
                                        )
                                        .markAsRead(item.notificationId);
                                    ref.invalidate(notificationsProvider);
                                  },
                                  child: const Text('Mark Read'),
                                ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(
                    child: Text('Unable to load notifications.'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
