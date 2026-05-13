import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/models/app_user.dart';
import '../data/models/teacher_invite_code.dart';
import '../data/repositories/admin_repository.dart';

const _unset = Object();
const _defaultPageSize = 40;

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final adminStatsProvider = FutureProvider<AdminStatsSnapshot>((ref) {
  return ref.read(adminRepositoryProvider).fetchStats();
});

final adminUsersProvider =
    StateNotifierProvider<AdminUsersController, AdminUsersState>(
      (ref) => AdminUsersController(ref.read(adminRepositoryProvider)),
    );

final adminInviteCodesProvider =
    StateNotifierProvider<AdminInviteCodesController, AdminInviteCodesState>(
      (ref) => AdminInviteCodesController(ref.read(adminRepositoryProvider)),
    );

final adminActionProvider =
    StateNotifierProvider<AdminActionController, AsyncValue<void>>(
      (ref) => AdminActionController(ref.read(adminRepositoryProvider)),
    );

class AdminUsersController extends StateNotifier<AdminUsersState> {
  AdminUsersController(this._repository) : super(const AdminUsersState());

  final AdminRepository _repository;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;

  Future<void> loadInitial({AppRole? roleFilter}) async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      error: null,
      roleFilter: roleFilter,
      users: const [],
    );
    _cursor = null;

    try {
      final page = await _repository.fetchUsersPage(
        startAfter: null,
        limit: _defaultPageSize,
        roleFilter: roleFilter,
      );
      _cursor = page.lastDoc;
      state = state.copyWith(
        users: page.users,
        isLoading: false,
        hasMore: page.hasMore,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final page = await _repository.fetchUsersPage(
        startAfter: _cursor,
        limit: _defaultPageSize,
        roleFilter: state.roleFilter,
      );
      _cursor = page.lastDoc;
      state = state.copyWith(
        users: [...state.users, ...page.users],
        isLoadingMore: false,
        hasMore: page.hasMore,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMore: false, error: error);
    }
  }

  Future<void> refresh() async {
    await loadInitial(roleFilter: state.roleFilter);
  }
}

class AdminInviteCodesController extends StateNotifier<AdminInviteCodesState> {
  AdminInviteCodesController(this._repository)
    : super(const AdminInviteCodesState());

  final AdminRepository _repository;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;

  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      error: null,
      invites: const [],
    );
    _cursor = null;

    try {
      final page = await _repository.fetchInviteCodesPage(
        startAfter: null,
        limit: _defaultPageSize,
      );
      _cursor = page.lastDoc;
      state = state.copyWith(
        invites: page.invites,
        isLoading: false,
        hasMore: page.hasMore,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final page = await _repository.fetchInviteCodesPage(
        startAfter: _cursor,
        limit: _defaultPageSize,
      );
      _cursor = page.lastDoc;
      state = state.copyWith(
        invites: [...state.invites, ...page.invites],
        isLoadingMore: false,
        hasMore: page.hasMore,
        error: null,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMore: false, error: error);
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

class AdminActionController extends StateNotifier<AsyncValue<void>> {
  AdminActionController(this._repository) : super(const AsyncValue.data(null));

  final AdminRepository _repository;

  Future<String> createInviteCode({
    required String adminUserId,
    String? adminName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final code = await _repository.createTeacherInviteCode(
        adminUserId: adminUserId,
        adminName: adminName,
      );
      state = const AsyncValue.data(null);
      return code;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> deactivateInviteCode(String inviteDocId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.deactivateInviteCode(inviteDocId),
    );
  }

  Future<void> deleteUser({
    required String targetUserId,
    required String adminUserId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.softDeleteUser(
        targetUserId: targetUserId,
        adminUserId: adminUserId,
      ),
    );
  }
}

class AdminUsersState {
  const AdminUsersState({
    this.users = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.roleFilter,
    this.error,
  });

  final List<AppUser> users;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final AppRole? roleFilter;
  final Object? error;

  AdminUsersState copyWith({
    List<AppUser>? users,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? roleFilter = _unset,
    Object? error = _unset,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      roleFilter: roleFilter == _unset
          ? this.roleFilter
          : roleFilter as AppRole?,
      error: error == _unset ? this.error : error,
    );
  }
}

class AdminInviteCodesState {
  const AdminInviteCodesState({
    this.invites = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<TeacherInviteCode> invites;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  AdminInviteCodesState copyWith({
    List<TeacherInviteCode>? invites,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error = _unset,
  }) {
    return AdminInviteCodesState(
      invites: invites ?? this.invites,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error == _unset ? this.error : error,
    );
  }
}
