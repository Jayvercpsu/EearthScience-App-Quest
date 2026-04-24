class Challenge {
  const Challenge({
    required this.challengeId,
    required this.title,
    required this.description,
    required this.rewardXp,
    required this.type,
    required this.progressTarget,
    required this.currentProgress,
  });

  final String challengeId;
  final String title;
  final String description;
  final int rewardXp;
  final String type;
  final int progressTarget;
  final int currentProgress;

  double get progress =>
      progressTarget == 0 ? 0 : (currentProgress / progressTarget).clamp(0, 1);

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'title': title,
      'description': description,
      'rewardXp': rewardXp,
      'type': type,
      'progressTarget': progressTarget,
      'currentProgress': currentProgress,
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      challengeId: map['challengeId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      rewardXp: (map['rewardXp'] as num?)?.toInt() ?? 0,
      type: map['type'] as String? ?? 'daily',
      progressTarget: (map['progressTarget'] as num?)?.toInt() ?? 1,
      currentProgress: (map['currentProgress'] as num?)?.toInt() ?? 0,
    );
  }
}
