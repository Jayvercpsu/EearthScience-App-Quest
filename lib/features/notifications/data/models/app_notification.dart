import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  const AppNotification({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.recipientUserId,
    required this.recipientRole,
    required this.createdBy,
    required this.createdAt,
    required this.isRead,
  });

  final String notificationId;
  final String title;
  final String message;
  final String recipientUserId;
  final String recipientRole;
  final String createdBy;
  final DateTime createdAt;
  final bool isRead;

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'title': title,
      'message': message,
      'recipientUserId': recipientUserId,
      'recipientRole': recipientRole,
      'createdBy': createdBy,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      notificationId: map['notificationId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      recipientUserId: map['recipientUserId'] as String? ?? '',
      recipientRole: map['recipientRole'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      isRead: map['isRead'] as bool? ?? false,
    );
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
