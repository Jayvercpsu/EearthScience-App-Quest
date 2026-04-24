import 'package:flutter/material.dart';

class Achievement {
  const Achievement({
    required this.achievementId,
    required this.title,
    required this.description,
    required this.badgeIcon,
    required this.rewardXp,
    required this.unlocked,
  });

  final String achievementId;
  final String title;
  final String description;
  final IconData badgeIcon;
  final int rewardXp;
  final bool unlocked;

  Achievement copyWith({bool? unlocked}) {
    return Achievement(
      achievementId: achievementId,
      title: title,
      description: description,
      badgeIcon: badgeIcon,
      rewardXp: rewardXp,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'title': title,
      'description': description,
      'badgeIconCode': badgeIcon.codePoint,
      'badgeIconFont': badgeIcon.fontFamily,
      'rewardXp': rewardXp,
      'unlocked': unlocked,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      achievementId: map['achievementId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      badgeIcon: IconData(
        (map['badgeIconCode'] as num?)?.toInt() ?? Icons.emoji_events.codePoint,
        fontFamily: map['badgeIconFont'] as String? ?? 'MaterialIcons',
      ),
      rewardXp: (map['rewardXp'] as num?)?.toInt() ?? 0,
      unlocked: map['unlocked'] as bool? ?? false,
    );
  }
}
