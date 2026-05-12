import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherInviteCode {
  const TeacherInviteCode({
    required this.id,
    required this.code,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
    this.usedByUserId,
    this.usedAt,
  });

  final String id;
  final String code;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;
  final String? usedByUserId;
  final DateTime? usedAt;

  bool get isUsed => (usedByUserId ?? '').trim().isNotEmpty;

  factory TeacherInviteCode.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data();
    return TeacherInviteCode(
      id: doc.id,
      code: (map['code'] as String? ?? '').trim(),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _parseDateTime(map['createdAt']),
      createdBy: map['createdBy'] as String? ?? '',
      usedByUserId: map['usedByUserId'] as String?,
      usedAt: _parseDateTimeOrNull(map['usedAt']),
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

DateTime? _parseDateTimeOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  return _parseDateTime(value);
}
