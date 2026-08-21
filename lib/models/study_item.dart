class StudyItem {
  final String type;
  final int id;
  final String level;
  final String front;
  final String reading;
  final String meaning;

  // Estado de repetición espaciada
  final String state;
  final DateTime? nextReview;
  final double intervalDays;
  final double easeFactor;
  final int repetitions;
  final int lapses;

  // Estado manual para saber si el usuario considera este contenido aprendido.
  final bool learned;

  const StudyItem({
    required this.type,
    required this.id,
    required this.level,
    required this.front,
    required this.reading,
    required this.meaning,
    this.state = 'new',
    this.nextReview,
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    this.lapses = 0,
    this.learned = false,
  });

  bool get isNew => state == 'new';

  bool get isLearning => state == 'learning';

  bool get isReview => state == 'review';

  bool get isMature => state == 'mature';

  bool get isLearned => learned;

  factory StudyItem.fromMap(Map<String, dynamic> map) {
    return StudyItem(
      type: (map['item_type'] ?? '').toString(),
      id: (map['item_id'] as num).toInt(),
      level: (map['level'] ?? '').toString(),
      front: (map['front'] ?? '').toString(),
      reading: (map['reading'] ?? '').toString(),
      meaning: (map['meaning'] ?? '').toString(),

      state: (map['state'] ?? 'new').toString(),

      nextReview: map['next_review'] == null
          ? null
          : DateTime.tryParse(map['next_review'].toString()),

      intervalDays: (map['interval_days'] as num?)?.toDouble() ?? 0,

      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,

      repetitions: (map['repetitions'] as num?)?.toInt() ?? 0,

      lapses: (map['lapses'] as num?)?.toInt() ?? 0,

      learned: (map['learned'] as num?)?.toInt() == 1,
    );
  }
}
