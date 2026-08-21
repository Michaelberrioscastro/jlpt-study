import 'database_service.dart';

class PracticeAttempt {
  final int id;
  final String level;
  final String section;
  final String mode;
  final int questionCount;
  final int correctCount;
  final double percentage;
  final DateTime completedAt;

  const PracticeAttempt({
    required this.id,
    required this.level,
    required this.section,
    required this.mode,
    required this.questionCount,
    required this.correctCount,
    required this.percentage,
    required this.completedAt,
  });

  factory PracticeAttempt.fromMap(Map<String, dynamic> map) {
    return PracticeAttempt(
      id: (map['id'] as num).toInt(),
      level: (map['level'] ?? '').toString(),
      section: (map['section'] ?? '').toString(),
      mode: (map['mode'] ?? '').toString(),
      questionCount: (map['question_count'] as num?)?.toInt() ?? 0,
      correctCount: (map['correct_count'] as num?)?.toInt() ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0,
      completedAt:
          DateTime.tryParse((map['completed_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class PracticeProgressSummary {
  final double preparationPercent;
  final List<PracticeAttempt> recentAttempts;

  const PracticeProgressSummary({
    required this.preparationPercent,
    required this.recentAttempts,
  });
}

class PracticeProgressService {
  PracticeProgressService._();

  static bool _ready = false;

  static Future<void> _ensureTable() async {
    if (_ready) return;

    final db = await DatabaseService.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS jlpt_practice_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        level TEXT NOT NULL,
        section TEXT NOT NULL,
        mode TEXT NOT NULL,
        question_count INTEGER NOT NULL,
        correct_count INTEGER NOT NULL,
        percentage REAL NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_jlpt_practice_attempts_lookup '
      'ON jlpt_practice_attempts(level, section, completed_at)',
    );

    _ready = true;
  }

  static Future<PracticeAttempt> saveAttempt({
    required String level,
    required String section,
    required String mode,
    required int questionCount,
    required int correctCount,
  }) async {
    await _ensureTable();

    final db = await DatabaseService.database;
    final percentage = questionCount <= 0
        ? 0.0
        : (correctCount / questionCount) * 100;
    final completedAt = DateTime.now();

    final id = await db.insert('jlpt_practice_attempts', {
      'level': level,
      'section': section,
      'mode': mode,
      'question_count': questionCount,
      'correct_count': correctCount,
      'percentage': percentage,
      'completed_at': completedAt.toIso8601String(),
    });

    return PracticeAttempt(
      id: id,
      level: level,
      section: section,
      mode: mode,
      questionCount: questionCount,
      correctCount: correctCount,
      percentage: percentage,
      completedAt: completedAt,
    );
  }

  static Future<List<PracticeAttempt>> getRecentAttempts({
    required String level,
    required String section,
    int limit = 5,
  }) async {
    await _ensureTable();

    final db = await DatabaseService.database;
    final rows = await db.query(
      'jlpt_practice_attempts',
      where: 'level = ? AND section = ?',
      whereArgs: [level, section],
      orderBy: 'completed_at DESC, id DESC',
      limit: limit,
    );

    return rows
        .map((row) => PracticeAttempt.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<PracticeProgressSummary> getSummary({
    required String level,
    required String section,
  }) async {
    final recent = await getRecentAttempts(
      level: level,
      section: section,
      limit: 5,
    );

    final weightedSource = recent.take(3).toList();

    if (weightedSource.isEmpty) {
      return PracticeProgressSummary(
        preparationPercent: 0,
        recentAttempts: recent,
      );
    }

    const weights = <double>[0.5, 0.3, 0.2];
    var weightedTotal = 0.0;
    var usedWeights = 0.0;

    for (var i = 0; i < weightedSource.length; i++) {
      weightedTotal += weightedSource[i].percentage * weights[i];
      usedWeights += weights[i];
    }

    final preparation = usedWeights == 0 ? 0.0 : weightedTotal / usedWeights;

    return PracticeProgressSummary(
      preparationPercent: preparation.clamp(0, 100),
      recentAttempts: recent,
    );
  }
}
