import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/firestore_paths.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const String _teacherAccessCode = String.fromEnvironment(
    'TEACHER_ACCESS_CODE',
    defaultValue: '',
  );
  static const String _adminSetupCode = String.fromEnvironment(
    'ADMIN_SETUP_CODE',
    defaultValue: '',
  );
  static const String _seedAdminEmail = String.fromEnvironment(
    'SEED_ADMIN_EMAIL',
    defaultValue: 'admin@earthscience.app',
  );
  static const String _seedAdminPassword = String.fromEnvironment(
    'SEED_ADMIN_PASSWORD',
    defaultValue: 'Admin@12345',
  );
  static const String _seedAdminName = String.fromEnvironment(
    'SEED_ADMIN_NAME',
    defaultValue: 'Earth Science Admin',
  );

  AppUser? _localUser;

  Stream<User?> authStateChanges() {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<AppUser?> currentAppUser() async {
    final authUser = _auth.currentUser;
    if (authUser == null) {
      return _localUser;
    }

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.users)
          .doc(authUser.uid)
          .get();
      if (snapshot.exists && snapshot.data() != null) {
        final map = snapshot.data()!;
        if (_isDeletedProfile(map)) {
          await signOut();
          return null;
        }
        final user = AppUser.fromMap(map);
        await _ensureAccountCanAccessApp(user: user, userMap: map);
        _localUser = user;
        return user;
      }
    } catch (_) {
      // fallback below
    }

    return _localUser;
  }

  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required AppRole role,
    String? teacherAccessCode,
    String? adminAccessCode,
  }) async {
    _ensureAdminAccountAccess(role: role, adminAccessCode: adminAccessCode);
    final normalizedEmail = email.trim().toLowerCase();
    User? createdAuthUser;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final firebaseUser = credential.user!;
      createdAuthUser = firebaseUser;

      _TeacherInviteAccess? teacherInvite;
      if (role == AppRole.teacher) {
        try {
          teacherInvite = await _validateTeacherInviteForRole(
            role: role,
            teacherAccessCode: teacherAccessCode,
          );
        } catch (error) {
          await firebaseUser.delete();
          throw Exception(error.toString().replaceFirst('Exception: ', ''));
        }
      }

      if (role == AppRole.teacher && teacherInvite?.docId != null) {
        try {
          await _consumeTeacherInviteCode(
            inviteDocId: teacherInvite!.docId!,
            userId: firebaseUser.uid,
          );
        } catch (error) {
          await firebaseUser.delete();
          throw Exception(error.toString().replaceFirst('Exception: ', ''));
        }
      }

      final user = AppUser(
        uid: firebaseUser.uid,
        name: name,
        email: normalizedEmail,
        role: role,
        xp: 0,
        level: 1,
        streak: 0,
        createdAt: DateTime.now(),
      );

      final userMap = user.toMap();
      userMap['localPasswordHash'] = _hashPassword(password);
      userMap['isDeleted'] = false;
      if (role == AppRole.teacher && teacherInvite != null) {
        userMap['teacherInviteCode'] = teacherInvite.code;
        userMap['invitedAt'] = DateTime.now().millisecondsSinceEpoch;
        if (teacherInvite.docId != null) {
          userMap['teacherInviteCodeId'] = teacherInvite.docId;
        }
      }
      if (role == AppRole.admin) {
        userMap['adminSetupApproved'] = true;
      }

      await _writeUserProfileWithRetry(userId: user.uid, userMap: userMap);

      _localUser = user;
      return user;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'operation-not-allowed') {
        throw Exception(
          'Email/Password sign-in is disabled in Firebase. Enable it in Firebase Console -> Authentication -> Sign-in method.',
        );
      }
      if (role != AppRole.student) {
        throw Exception('Registration failed (${error.code}).');
      }
      if (createdAuthUser != null) {
        throw Exception(
          'Registration could not finish profile setup. Please try again.',
        );
      }
      final local = AppUser(
        uid: 'local_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: normalizedEmail,
        role: role,
        xp: 0,
        level: 1,
        streak: 0,
        createdAt: DateTime.now(),
      );
      _localUser = local;
      return local;
    } catch (error) {
      if (createdAuthUser != null) {
        try {
          await createdAuthUser.delete();
        } catch (_) {
          // Keep the explicit error below; user can retry registration.
        }
      }
      if (role != AppRole.student) {
        throw Exception(error.toString().replaceFirst('Exception: ', ''));
      }
      if (createdAuthUser != null) {
        throw Exception(error.toString().replaceFirst('Exception: ', ''));
      }

      final local = AppUser(
        uid: 'local_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: normalizedEmail,
        role: role,
        xp: 0,
        level: 1,
        streak: 0,
        createdAt: DateTime.now(),
      );
      _localUser = local;
      return local;
    }
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (_isSeedAdminCredential(email: normalizedEmail, password: password)) {
        if (error.code == 'operation-not-allowed') {
          throw Exception(
            'Email/Password sign-in is disabled in Firebase. Enable it in Firebase Console -> Authentication -> Sign-in method.',
          );
        }
        return _createOrLoadSeedAdminAccount();
      }

      final localFallback = await _tryLocalPasswordLogin(
        email: normalizedEmail,
        password: password,
      );
      if (localFallback != null) {
        _localUser = localFallback;
        return localFallback;
      }

      throw Exception(_friendlyEmailLoginError(error));
    }

    final snapshot = await _firestore
        .collection(FirestorePaths.users)
        .doc(credential.user!.uid)
        .get();

    if (!snapshot.exists || snapshot.data() == null) {
      if (_isSeedAdminCredential(email: normalizedEmail, password: password)) {
        return _upsertSeedAdminProfile(credential.user!);
      }
      return _recoverMissingAccountProfile(
        firebaseUser: credential.user!,
        fallbackEmail: normalizedEmail,
      );
    }

    final userMap = snapshot.data()!;
    if (_isDeletedProfile(userMap)) {
      await signOut();
      throw Exception(
        'This account has been removed by an administrator. Please contact support.',
      );
    }

    final user = AppUser.fromMap(userMap);
    await _ensureAccountCanAccessApp(user: user, userMap: userMap);
    _localUser = user;
    return user;
  }

  Future<AppUser> updateCurrentUserName(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Name is required.');
    }

    final authUser = _auth.currentUser;
    if (authUser == null) {
      throw Exception('Please login again to update profile.');
    }

    try {
      await authUser.updateDisplayName(trimmedName);
    } catch (_) {
      // Firestore write below remains source of truth for app profile.
    }

    await _firestore.collection(FirestorePaths.users).doc(authUser.uid).set({
      'name': trimmedName,
    }, SetOptions(merge: true));

    final existing = await _firestore
        .collection(FirestorePaths.users)
        .doc(authUser.uid)
        .get();
    if (existing.exists && existing.data() != null) {
      final updated = AppUser.fromMap(existing.data()!);
      _localUser = updated;
      return updated;
    }

    final fallback =
        _localUser?.copyWith(name: trimmedName) ??
        AppUser(
          uid: authUser.uid,
          name: trimmedName,
          email: authUser.email ?? '',
          role: AppRole.student,
          xp: 0,
          level: 1,
          streak: 0,
          createdAt: DateTime.now(),
        );
    _localUser = fallback;
    return fallback;
  }

  Future<AppUser> updateCurrentUserEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Enter a valid email address.');
    }

    final authUser = _auth.currentUser;
    if (authUser == null) {
      throw Exception('Please login again to update email.');
    }

    await _firestore.collection(FirestorePaths.users).doc(authUser.uid).set({
      'email': normalizedEmail,
    }, SetOptions(merge: true));

    final existing = await _firestore
        .collection(FirestorePaths.users)
        .doc(authUser.uid)
        .get();
    if (existing.exists && existing.data() != null) {
      final updated = AppUser.fromMap(existing.data()!);
      _localUser = updated;
      return updated;
    }

    final fallback =
        _localUser?.copyWith(email: normalizedEmail) ??
        AppUser(
          uid: authUser.uid,
          name: authUser.displayName ?? 'Learner',
          email: normalizedEmail,
          role: AppRole.student,
          xp: 0,
          level: 1,
          streak: 0,
          createdAt: DateTime.now(),
        );
    _localUser = fallback;
    return fallback;
  }

  Future<void> updateCurrentUserPassword(String newPassword) async {
    final trimmed = newPassword.trim();
    if (trimmed.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final authUser = _auth.currentUser;
    if (authUser == null && _localUser == null) {
      throw Exception('Please login again to change password.');
    }

    if (authUser != null) {
      try {
        await authUser.updatePassword(trimmed);
      } on FirebaseAuthException catch (error) {
        if (error.code == 'requires-recent-login') {
          throw Exception(
            'For security, please logout then login again before changing password.',
          );
        }
        throw Exception(
          'Unable to update password (${error.code}). Please try again.',
        );
      }
    }

    final targetUserId = authUser?.uid ?? _localUser!.uid;
    await _firestore.collection(FirestorePaths.users).doc(targetUserId).set({
      'localPasswordHash': _hashPassword(trimmed),
      'passwordUpdatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<bool> verifyRegisteredEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Enter a valid email address.');
    }

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.users)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetPasswordWithoutEmailVerification({
    required String email,
    required String newPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPassword = newPassword.trim();

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Enter a valid email address.');
    }
    if (trimmedPassword.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final query = await _firestore
        .collection(FirestorePaths.users)
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw Exception('Email not found.');
    }

    final userId = query.docs.first.id;
    await _firestore.collection(FirestorePaths.users).doc(userId).set({
      'localPasswordHash': _hashPassword(trimmedPassword),
      'passwordUpdatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));

    final current = _auth.currentUser;
    if (current != null && current.email?.toLowerCase() == normalizedEmail) {
      try {
        await current.updatePassword(trimmedPassword);
      } catch (_) {
        // Fallback mode remains valid via local password hash.
      }
    }
  }

  Future<_TeacherInviteAccess?> _validateTeacherInviteForRole({
    required AppRole role,
    String? teacherAccessCode,
  }) async {
    if (role != AppRole.teacher) {
      return null;
    }

    final suppliedCode = teacherAccessCode?.trim().toUpperCase() ?? '';
    if (suppliedCode.isEmpty) {
      throw Exception('Teacher invite code is required.');
    }

    Object? firestoreError;
    try {
      final directDoc = await _firestore
          .collection(FirestorePaths.teacherInviteCodes)
          .doc(suppliedCode)
          .get();

      if (directDoc.exists && directDoc.data() != null) {
        final data = directDoc.data()!;
        final isActive = data['isActive'] as bool? ?? true;
        final usedBy = (data['usedByUserId'] as String? ?? '').trim();

        if (!isActive) {
          throw Exception('This teacher invite code is inactive.');
        }
        if (usedBy.isNotEmpty) {
          throw Exception('This teacher invite code is already used.');
        }

        return _TeacherInviteAccess(code: suppliedCode, docId: directDoc.id);
      }

      // Backward compatibility for old invite docs that used random ids.
      final snapshot = await _firestore
          .collection(FirestorePaths.teacherInviteCodes)
          .where('code', isEqualTo: suppliedCode)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final fallbackDoc = snapshot.docs.first;
        final data = fallbackDoc.data();
        final isActive = data['isActive'] as bool? ?? true;
        final usedBy = (data['usedByUserId'] as String? ?? '').trim();

        if (!isActive) {
          throw Exception('This teacher invite code is inactive.');
        }
        if (usedBy.isNotEmpty) {
          throw Exception('This teacher invite code is already used.');
        }

        return _TeacherInviteAccess(code: suppliedCode, docId: fallbackDoc.id);
      }
    } catch (error) {
      final message = error.toString();
      if (message.contains('inactive') || message.contains('already used')) {
        rethrow;
      }
      firestoreError = error;
    }

    if (_teacherAccessCode.trim().toUpperCase() == suppliedCode) {
      return _TeacherInviteAccess(code: suppliedCode);
    }

    if (firestoreError != null) {
      throw Exception(
        'Unable to verify teacher invite code right now. Please try again.',
      );
    }

    throw Exception('Invalid teacher invite code.');
  }

  Future<void> _consumeTeacherInviteCode({
    required String inviteDocId,
    required String userId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final ref = _firestore
          .collection(FirestorePaths.teacherInviteCodes)
          .doc(inviteDocId);
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('Teacher invite code no longer exists.');
      }

      final data = snapshot.data()!;
      final isActive = data['isActive'] as bool? ?? true;
      final usedBy = (data['usedByUserId'] as String? ?? '').trim();

      if (!isActive || usedBy.isNotEmpty) {
        throw Exception('This teacher invite code is already used.');
      }

      transaction.update(ref, {
        'isActive': false,
        'usedByUserId': userId,
        'usedAt': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  Future<void> _ensureAccountCanAccessApp({
    required AppUser user,
    required Map<String, dynamic> userMap,
  }) async {
    if (user.role != AppRole.teacher) {
      return;
    }

    final inviteDocId = (userMap['teacherInviteCodeId'] as String? ?? '')
        .trim();
    if (inviteDocId.isNotEmpty) {
      final inviteSnapshot = await _firestore
          .collection(FirestorePaths.teacherInviteCodes)
          .doc(inviteDocId)
          .get();
      if (!inviteSnapshot.exists || inviteSnapshot.data() == null) {
        throw Exception('Teacher account is not invited. Contact admin.');
      }
      final data = inviteSnapshot.data()!;
      final usedBy = (data['usedByUserId'] as String? ?? '').trim();
      if (usedBy == user.uid) {
        return;
      }
      throw Exception('Teacher account invite validation failed.');
    }

    final legacyStaticCode = (userMap['teacherInviteCode'] as String? ?? '')
        .trim()
        .toUpperCase();
    if (_teacherAccessCode.trim().isNotEmpty &&
        legacyStaticCode == _teacherAccessCode.trim().toUpperCase()) {
      return;
    }

    final inviteLookup = await _firestore
        .collection(FirestorePaths.teacherInviteCodes)
        .where('usedByUserId', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (inviteLookup.docs.isNotEmpty) {
      final inviteDoc = inviteLookup.docs.first;
      final code = (inviteDoc.data()['code'] as String? ?? '').trim();
      await _firestore.collection(FirestorePaths.users).doc(user.uid).set({
        'teacherInviteCodeId': inviteDoc.id,
        if (code.isNotEmpty) 'teacherInviteCode': code,
      }, SetOptions(merge: true));
      return;
    }

    throw Exception('Teacher account is not invited. Contact admin.');
  }

  void _ensureAdminAccountAccess({
    required AppRole role,
    String? adminAccessCode,
  }) {
    if (role != AppRole.admin) {
      return;
    }

    if (_adminSetupCode.isEmpty) {
      throw Exception(
        'Admin account creation is disabled. Set ADMIN_SETUP_CODE first.',
      );
    }

    final suppliedCode = adminAccessCode?.trim() ?? '';
    if (suppliedCode.isEmpty) {
      throw Exception('Admin setup code is required.');
    }
    if (suppliedCode != _adminSetupCode) {
      throw Exception('Invalid admin setup code.');
    }
  }

  bool _isSeedAdminCredential({
    required String email,
    required String password,
  }) {
    return email.trim().toLowerCase() == _seedAdminEmail.toLowerCase() &&
        password == _seedAdminPassword;
  }

  Future<AppUser> _createOrLoadSeedAdminAccount() async {
    UserCredential credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: _seedAdminEmail,
        password: _seedAdminPassword,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') {
        throw Exception('Unable to create seed admin account (${error.code}).');
      }
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: _seedAdminEmail,
          password: _seedAdminPassword,
        );
      } on FirebaseAuthException {
        throw Exception(
          'Seed admin already exists with a different password. Use the updated admin password.',
        );
      }
    }

    return _upsertSeedAdminProfile(credential.user!);
  }

  Future<AppUser> _upsertSeedAdminProfile(User firebaseUser) async {
    final map = {
      'uid': firebaseUser.uid,
      'name': _seedAdminName,
      'email': _seedAdminEmail,
      'role': AppRole.admin.value,
      'xp': 0,
      'level': 1,
      'streak': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'seedAdmin': true,
      'adminSetupApproved': true,
      'isDeleted': false,
    };

    await _firestore
        .collection(FirestorePaths.users)
        .doc(firebaseUser.uid)
        .set(map, SetOptions(merge: true));

    final user = AppUser.fromMap(map);
    _localUser = user;
    return user;
  }

  String _friendlyEmailLoginError(FirebaseAuthException error) {
    if (error.code == 'operation-not-allowed') {
      return 'Email/Password sign-in is disabled in Firebase. Enable it in Firebase Console -> Authentication -> Sign-in method.';
    }
    if (error.code == 'invalid-credential' ||
        error.code == 'user-not-found' ||
        error.code == 'wrong-password') {
      return 'Invalid email or password.';
    }
    return 'Login failed (${error.code}). Please try again.';
  }

  Future<AppUser?> _tryLocalPasswordLogin({
    required String email,
    required String password,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.users)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        return null;
      }

      final map = snapshot.docs.first.data();
      if (_isDeletedProfile(map)) {
        return null;
      }
      final storedHash = (map['localPasswordHash'] as String? ?? '').trim();
      if (storedHash.isEmpty) {
        return null;
      }
      if (storedHash != _hashPassword(password)) {
        return null;
      }

      return AppUser.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  String _hashPassword(String password) {
    final normalized = password.trim();
    int hash = 5381;
    for (final codeUnit in normalized.codeUnits) {
      hash = ((hash << 5) + hash) ^ codeUnit;
    }
    return hash.abs().toRadixString(16);
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (_) {
      // Allow local-mode operation.
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // local mode
    }
    _localUser = null;
  }

  bool _isDeletedProfile(Map<String, dynamic> map) {
    return map['isDeleted'] == true;
  }

  Future<void> _writeUserProfileWithRetry({
    required String userId,
    required Map<String, dynamic> userMap,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await _firestore
            .collection(FirestorePaths.users)
            .doc(userId)
            .set(userMap);
        return;
      } catch (error) {
        lastError = error;
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 280));
        }
      }
    }

    throw Exception(
      lastError?.toString().replaceFirst('Exception: ', '') ??
          'Unable to save account profile.',
    );
  }

  Future<AppUser> _recoverMissingAccountProfile({
    required User firebaseUser,
    required String fallbackEmail,
  }) async {
    final normalizedEmail = (firebaseUser.email ?? fallbackEmail)
        .trim()
        .toLowerCase();
    final rawName = (firebaseUser.displayName ?? '').trim();
    final userMap = <String, dynamic>{
      'uid': firebaseUser.uid,
      'name': rawName.isEmpty ? 'Learner' : rawName,
      'email': normalizedEmail,
      'role': AppRole.student.value,
      'xp': 0,
      'level': 1,
      'streak': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isDeleted': false,
    };

    await _writeUserProfileWithRetry(
      userId: firebaseUser.uid,
      userMap: userMap,
    );
    final recoveredUser = AppUser.fromMap(userMap);
    _localUser = recoveredUser;
    return recoveredUser;
  }
}

class _TeacherInviteAccess {
  const _TeacherInviteAccess({required this.code, this.docId});

  final String code;
  final String? docId;
}
