import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_paths.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  final List<AppNotification> _fallbackNotifications = [
    AppNotification(
      notificationId: 'n_welcome_student',
      title: 'Welcome Learner',
      message: 'You can now track your lessons and mark notifications as read.',
      recipientUserId: '',
      recipientRole: 'student',
      createdBy: 'system',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    AppNotification(
      notificationId: 'n_welcome_teacher',
      title: 'Welcome Teacher',
      message: 'Upload lessons and check student progress from your dashboard.',
      recipientUserId: '',
      recipientRole: 'teacher',
      createdBy: 'system',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
  ];

  Stream<List<AppNotification>> streamNotifications({
    required String userId,
    required String role,
  }) async* {
    try {
      await for (final snapshot
          in _firestore.collection(FirestorePaths.notifications).snapshots()) {
        final items = <AppNotification>[];
        for (final doc in snapshot.docs) {
          try {
            final item = AppNotification.fromMap(doc.data());
            final isDirect = item.recipientUserId == userId;
            final isRoleWide =
                item.recipientUserId.isEmpty && item.recipientRole == role;
            if (isDirect || isRoleWide) {
              items.add(item);
            }
          } catch (_) {
            // Skip malformed notification documents.
          }
        }
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        yield items.isEmpty ? _fallbackForRole(role) : items;
      }
    } catch (_) {
      yield _fallbackForRole(role);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(FirestorePaths.notifications)
          .doc(notificationId)
          .set({'isRead': true}, SetOptions(merge: true));
      return;
    } catch (_) {
      final index = _fallbackNotifications.indexWhere(
        (item) => item.notificationId == notificationId,
      );
      if (index >= 0) {
        _fallbackNotifications[index] = AppNotification(
          notificationId: _fallbackNotifications[index].notificationId,
          title: _fallbackNotifications[index].title,
          message: _fallbackNotifications[index].message,
          recipientUserId: _fallbackNotifications[index].recipientUserId,
          recipientRole: _fallbackNotifications[index].recipientRole,
          createdBy: _fallbackNotifications[index].createdBy,
          createdAt: _fallbackNotifications[index].createdAt,
          isRead: true,
        );
      }
    }
  }

  Future<void> markAllReadForRole(String role, {String userId = ''}) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.notifications)
          .where('recipientRole', isEqualTo: role)
          .where('recipientUserId', isEqualTo: '')
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.set({'isRead': true}, SetOptions(merge: true));
      }

      final targetUserId = userId.trim();
      if (targetUserId.isNotEmpty) {
        final userSpecific = await _firestore
            .collection(FirestorePaths.notifications)
            .where('recipientUserId', isEqualTo: targetUserId)
            .get();
        for (final doc in userSpecific.docs) {
          await doc.reference.set({'isRead': true}, SetOptions(merge: true));
        }
      }
    } catch (_) {
      for (var i = 0; i < _fallbackNotifications.length; i++) {
        final item = _fallbackNotifications[i];
        final isRoleWide =
            item.recipientRole == role && item.recipientUserId.isEmpty;
        final isDirect =
            userId.trim().isNotEmpty && item.recipientUserId == userId.trim();
        if (isRoleWide || isDirect) {
          _fallbackNotifications[i] = AppNotification(
            notificationId: item.notificationId,
            title: item.title,
            message: item.message,
            recipientUserId: item.recipientUserId,
            recipientRole: item.recipientRole,
            createdBy: item.createdBy,
            createdAt: item.createdAt,
            isRead: true,
          );
        }
      }
    }
  }

  Future<void> createRoleNotification({
    required String role,
    required String title,
    required String message,
    required String createdBy,
  }) async {
    final notificationId = 'n_${DateTime.now().millisecondsSinceEpoch}';
    final payload = AppNotification(
      notificationId: notificationId,
      title: title,
      message: message,
      recipientUserId: '',
      recipientRole: role,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      isRead: false,
    );
    try {
      await _firestore
          .collection(FirestorePaths.notifications)
          .doc(notificationId)
          .set(payload.toMap());
      return;
    } catch (_) {
      _fallbackNotifications.add(payload);
    }
  }

  List<AppNotification> _fallbackForRole(String role) {
    return _fallbackNotifications
        .where((item) => item.recipientRole == role)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
