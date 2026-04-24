enum AppRole { student, teacher, admin }

extension AppRoleX on AppRole {
  String get value {
    switch (this) {
      case AppRole.student:
        return 'student';
      case AppRole.teacher:
        return 'teacher';
      case AppRole.admin:
        return 'admin';
    }
  }

  String get homeRoute {
    switch (this) {
      case AppRole.student:
        return '/student';
      case AppRole.teacher:
        return '/teacher';
      case AppRole.admin:
        return '/admin';
    }
  }

  static AppRole fromValue(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'teacher') {
      return AppRole.teacher;
    }
    if (normalized == 'admin') {
      return AppRole.admin;
    }

    return AppRole.student;
  }
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.xp,
    required this.level,
    required this.streak,
    required this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final AppRole role;
  final int xp;
  final int level;
  final int streak;
  final DateTime createdAt;

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    AppRole? role,
    int? xp,
    int? level,
    int? streak,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.value,
      'xp': xp,
      'level': level,
      'streak': streak,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? 'Learner',
      email: map['email'] as String? ?? '',
      role: AppRoleX.fromValue(map['role'] as String? ?? 'student'),
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
