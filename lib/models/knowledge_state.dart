enum KnowledgeDimension {
  recognition,
  meaning,
  reading,
  listening,
  production,
  context,
}

class KnowledgeState {
  final String itemType;
  final int itemId;
  final Map<KnowledgeDimension, double> mastery;
  final int attempts;
  final int correct;
  final int lapses;
  final double confidence;
  final DateTime? lastSeen;
  final DateTime? lastCorrect;

  const KnowledgeState({
    required this.itemType,
    required this.itemId,
    required this.mastery,
    required this.attempts,
    required this.correct,
    required this.lapses,
    required this.confidence,
    this.lastSeen,
    this.lastCorrect,
  });

  double get overallMastery {
    if (mastery.isEmpty) return 0;
    return mastery.values.reduce((a, b) => a + b) / mastery.length;
  }

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  double dimension(KnowledgeDimension value) => mastery[value] ?? 0;

  Map<String, dynamic> toMap() => {
        'item_type': itemType,
        'item_id': itemId,
        'recognition': dimension(KnowledgeDimension.recognition),
        'meaning': dimension(KnowledgeDimension.meaning),
        'reading': dimension(KnowledgeDimension.reading),
        'listening': dimension(KnowledgeDimension.listening),
        'production': dimension(KnowledgeDimension.production),
        'context': dimension(KnowledgeDimension.context),
        'attempts': attempts,
        'correct': correct,
        'lapses': lapses,
        'confidence': confidence,
        'last_seen': lastSeen?.toIso8601String(),
        'last_correct': lastCorrect?.toIso8601String(),
      };

  factory KnowledgeState.fromMap(Map<String, dynamic> map) {
    double n(String key) => (map[key] as num?)?.toDouble() ?? 0;
    DateTime? date(String key) {
      final value = map[key]?.toString();
      return value == null || value.isEmpty ? null : DateTime.tryParse(value);
    }

    return KnowledgeState(
      itemType: map['item_type'].toString(),
      itemId: (map['item_id'] as num).toInt(),
      mastery: {
        KnowledgeDimension.recognition: n('recognition'),
        KnowledgeDimension.meaning: n('meaning'),
        KnowledgeDimension.reading: n('reading'),
        KnowledgeDimension.listening: n('listening'),
        KnowledgeDimension.production: n('production'),
        KnowledgeDimension.context: n('context'),
      },
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      correct: (map['correct'] as num?)?.toInt() ?? 0,
      lapses: (map['lapses'] as num?)?.toInt() ?? 0,
      confidence: n('confidence'),
      lastSeen: date('last_seen'),
      lastCorrect: date('last_correct'),
    );
  }
}
