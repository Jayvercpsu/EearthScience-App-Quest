import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/models/app_user.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/models/app_notification.dart';
import '../data/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) {
    return const Stream<List<AppNotification>>.empty();
  }
  return ref
      .read(notificationRepositoryProvider)
      .streamNotifications(userId: user.uid, role: user.role.value);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications =
      ref.watch(notificationsProvider).valueOrNull ?? const [];
  return notifications.where((item) => !item.isRead).length;
});

final notificationActionProvider =
    StateNotifierProvider<NotificationActionController, AsyncValue<void>>(
      (ref) => NotificationActionController(
        ref.read(notificationRepositoryProvider),
      ),
    );

class NotificationActionController extends StateNotifier<AsyncValue<void>> {
  NotificationActionController(this._repository) : super(const AsyncData(null));

  final NotificationRepository _repository;

  Future<void> markAsRead(String notificationId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.markAsRead(notificationId),
    );
  }

  Future<void> markAllReadForRole(String role, {String userId = ''}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.markAllReadForRole(role, userId: userId),
    );
  }
}
