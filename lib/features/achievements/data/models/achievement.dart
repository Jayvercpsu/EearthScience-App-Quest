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
    final fallbackIcon = Icons.emoji_events;
    final codePoint =
        (map['badgeIconCode'] as num?)?.toInt() ?? fallbackIcon.codePoint;
    return Achievement(
      achievementId: map['achievementId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      badgeIcon: _iconFromCodePoint(codePoint),
      rewardXp: (map['rewardXp'] as num?)?.toInt() ?? 0,
      unlocked: map['unlocked'] as bool? ?? false,
    );
  }
}

IconData _iconFromCodePoint(int codePoint) {
  switch (codePoint) {
    case 0xe7f8: // emoji_events
      return Icons.emoji_events;
    case 0xe86c: // star
      return Icons.star;
    case 0xe1a1: // school
      return Icons.school;
    case 0xe55f: // public
      return Icons.public;
    case 0xe838: // favorite
      return Icons.favorite;
    case 0xe0be: // science
      return Icons.science;
    case 0xe3af: // bolt
      return Icons.bolt;
    default:
      return Icons.emoji_events;
  }
}
