import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_paths.dart';
import '../../../auth/data/models/app_user.dart';
import '../models/teacher_invite_code.dart';

class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Random _random = Random();
  bool _roleCreatedAtIndexMissing = false;

  Future<AdminUsersPage> fetchUsersPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 40,
    AppRole? roleFilter,
  }) async {
    if (roleFilter != null && _roleCreatedAtIndexMissing) {
      return _fetchUsersPageWithoutRoleIndex(
        startAfter: startAfter,
        limit: limit,
        roleFilter: roleFilter,
      );
    }

    Query<Map<String, dynamic>> query = _firestore.collection(
      FirestorePaths.users,
    );
    if (roleFilter != null) {
      query = query.where('role', isEqualTo: roleFilter.value);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    try {
      final snapshot = await query.get();
      final users = snapshot.docs
          .map(_mapActiveUserFromDoc)
          .whereType<AppUser>()
          .toList();
      final hasMore = snapshot.docs.length == limit;

      return AdminUsersPage(
        users: users,
        lastDoc: snapshot.docs.isEmpty ? startAfter : snapshot.docs.last,
        hasMore: hasMore,
      );
    } on FirebaseException catch (error) {
      if (!_isMissingCompositeIndex(error) || roleFilter == null) {
        rethrow;
      }
      _roleCreatedAtIndexMissing = true;
      return _fetchUsersPageWithoutRoleIndex(
        startAfter: startAfter,
        limit: limit,
        roleFilter: roleFilter,
      );
    }
  }

  Future<AdminInviteCodesPage> fetchInviteCodesPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 40,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestorePaths.teacherInviteCodes)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final invites = snapshot.docs.map(TeacherInviteCode.fromDoc).toList();
    final hasMore = snapshot.docs.length == limit;

    return AdminInviteCodesPage(
      invites: invites,
      lastDoc: snapshot.docs.isEmpty ? startAfter : snapshot.docs.last,
      hasMore: hasMore,
    );
  }

  Future<AdminStatsSnapshot> fetchStats() async {
    try {
      final usersSnapshot = await _firestore
          .collection(FirestorePaths.users)
          .get();
      var totalUsers = 0;
      var teacherUsers = 0;
      for (final userDoc in usersSnapshot.docs) {
        final data = userDoc.data();
        if (data['isDeleted'] == true) {
          continue;
        }
        totalUsers++;
        final role = AppRoleX.fromValue(data['role'] as String? ?? 'student');
        if (role == AppRole.teacher) {
          teacherUsers++;
        }
      }

      final totalInvites = await _firestore
          .collection(FirestorePaths.teacherInviteCodes)
          .count()
          .get();
      final activeInvites = await _firestore
          .collection(FirestorePaths.teacherInviteCodes)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      return AdminStatsSnapshot(
        totalUsers: totalUsers,
        teacherUsers: teacherUsers,
        totalInvites: totalInvites.count ?? 0,
        activeInvites: activeInvites.count ?? 0,
      );
    } catch (_) {
      return const AdminStatsSnapshot(
        totalUsers: 0,
        teacherUsers: 0,
        totalInvites: 0,
        activeInvites: 0,
      );
    }
  }

  Future<String> createTeacherInviteCode({
    required String adminUserId,
    String? adminName,
  }) async {
    for (var i = 0; i < 10; i++) {
      final code = _generateInviteCode();
      final docRef = _firestore
          .collection(FirestorePaths.teacherInviteCodes)
          .doc(code);
      final existing = await docRef.get();
      if (existing.exists) {
        continue;
      }

      await docRef.set({
        'code': code,
        'isActive': true,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'createdBy': adminUserId,
        'createdByName': adminName ?? '',
        'usedByUserId': '',
        'usedAt': null,
      });

      return code;
    }

    throw Exception('Unable to generate a unique invite code. Try again.');
  }

  Future<void> deactivateInviteCode(String inviteDocId) async {
    await _firestore
        .collection(FirestorePaths.teacherInviteCodes)
        .doc(inviteDocId)
        .set({
          'isActive': false,
          'deactivatedAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final first = List.generate(
      4,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
    final second = List.generate(
      4,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
    return 'TEACH-$first-$second';
  }

  bool _isMissingCompositeIndex(FirebaseException error) {
    return error.code.toLowerCase() == 'failed-precondition' &&
        (error.message ?? '').toLowerCase().contains('requires an index');
  }

  Future<AdminUsersPage> _fetchUsersPageWithoutRoleIndex({
    required DocumentSnapshot<Map<String, dynamic>>? startAfter,
    required int limit,
    required AppRole roleFilter,
  }) async {
    const int batchSize = 80;
    const int maxBatches = 12;
    final users = <AppUser>[];
    var cursor = startAfter;
    var hasMore = false;

    for (var i = 0; i < maxBatches; i++) {
      Query<Map<String, dynamic>> query = _firestore
          .collection(FirestorePaths.users)
          .orderBy('createdAt', descending: true)
          .limit(batchSize);

      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      var reachedLimit = false;
      for (final doc in snapshot.docs) {
        cursor = doc;
        final data = doc.data();
        if (data['isDeleted'] == true) {
          continue;
        }
        final normalized = Map<String, dynamic>.from(data);
        final docUid = (normalized['uid'] as String? ?? '').trim();
        if (docUid.isEmpty) {
          normalized['uid'] = doc.id;
        }
        final role = AppRoleX.fromValue(
          normalized['role'] as String? ?? 'student',
        );
        if (role == roleFilter) {
          users.add(AppUser.fromMap(normalized));
        }
        if (users.length >= limit) {
          reachedLimit = true;
          break;
        }
      }

      if (reachedLimit) {
        hasMore = true;
        break;
      }

      if (snapshot.docs.length < batchSize) {
        hasMore = false;
        break;
      }

      hasMore = true;
    }

    return AdminUsersPage(users: users, lastDoc: cursor, hasMore: hasMore);
  }

  AppUser? _mapActiveUserFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final rawMap = doc.data();
    if (rawMap == null || rawMap['isDeleted'] == true) {
      return null;
    }

    final map = Map<String, dynamic>.from(rawMap);
    final uid = (map['uid'] as String? ?? '').trim();
    if (uid.isEmpty) {
      map['uid'] = doc.id;
    }
    return AppUser.fromMap(map);
  }
}

class AdminUsersPage {
  const AdminUsersPage({
    required this.users,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<AppUser> users;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

class AdminInviteCodesPage {
  const AdminInviteCodesPage({
    required this.invites,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<TeacherInviteCode> invites;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

class AdminStatsSnapshot {
  const AdminStatsSnapshot({
    required this.totalUsers,
    required this.teacherUsers,
    required this.totalInvites,
    required this.activeInvites,
  });

  final int totalUsers;
  final int teacherUsers;
  final int totalInvites;
  final int activeInvites;
}
