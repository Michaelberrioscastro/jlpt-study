import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

class BeginnerLessonProgress {
  final String lessonId;
  final bool passed;
  final int bestScore;
  final int bestTotal;
  final int attempts;
  final DateTime? completedAt;

  const BeginnerLessonProgress({
    required this.lessonId,
    required this.passed,
    required this.bestScore,
    required this.bestTotal,
    required this.attempts,
    required this.completedAt,
  });

  double get bestPercent => bestTotal <= 0 ? 0 : bestScore / bestTotal;
}

class BeginnerProgressService {
  BeginnerProgressService._();

  static bool _ready = false;

  static Future<void> _ensureTable() async {
    if (_ready) return;

    final db = await DatabaseService.database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS beginner_lesson_progress (
        lesson_id TEXT PRIMARY KEY,
        passed INTEGER NOT NULL DEFAULT 0,
        best_score INTEGER NOT NULL DEFAULT 0,
        best_total INTEGER NOT NULL DEFAULT 0,
        attempts INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT
      )
    ''');

    _ready = true;
  }

  static Future<Map<String, BeginnerLessonProgress>> getAll() async {
    await _ensureTable();
    final db = await DatabaseService.database;

    final rows = await db.query('beginner_lesson_progress');
    final result = <String, BeginnerLessonProgress>{};

    for (final row in rows) {
      final id = (row['lesson_id'] ?? '').toString();
      if (id.isEmpty) continue;

      result[id] = BeginnerLessonProgress(
        lessonId: id,
        passed: (row['passed'] as num?)?.toInt() == 1,
        bestScore: (row['best_score'] as num?)?.toInt() ?? 0,
        bestTotal: (row['best_total'] as num?)?.toInt() ?? 0,
        attempts: (row['attempts'] as num?)?.toInt() ?? 0,
        completedAt: row['completed_at'] == null
            ? null
            : DateTime.tryParse(row['completed_at'].toString()),
      );
    }

    return result;
  }

  static Future<BeginnerLessonProgress?> getLesson(String lessonId) async {
    await _ensureTable();
    final db = await DatabaseService.database;

    final rows = await db.query(
      'beginner_lesson_progress',
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final row = rows.first;

    return BeginnerLessonProgress(
      lessonId: lessonId,
      passed: (row['passed'] as num?)?.toInt() == 1,
      bestScore: (row['best_score'] as num?)?.toInt() ?? 0,
      bestTotal: (row['best_total'] as num?)?.toInt() ?? 0,
      attempts: (row['attempts'] as num?)?.toInt() ?? 0,
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.tryParse(row['completed_at'].toString()),
    );
  }

  static Future<void> recordQuiz({
    required String lessonId,
    required int score,
    required int total,
    required bool passed,
  }) async {
    await _ensureTable();
    final db = await DatabaseService.database;

    final previous = await getLesson(lessonId);
    final previousScore = previous?.bestScore ?? 0;
    final previousTotal = previous?.bestTotal ?? 0;
    final previousRatio = previousTotal <= 0
        ? 0.0
        : previousScore / previousTotal;
    final currentRatio = total <= 0 ? 0.0 : score / total;
    final keepCurrent = currentRatio >= previousRatio;

    await db.insert('beginner_lesson_progress', {
      'lesson_id': lessonId,
      'passed': (passed || (previous?.passed ?? false)) ? 1 : 0,
      'best_score': keepCurrent ? score : previousScore,
      'best_total': keepCurrent ? total : previousTotal,
      'attempts': (previous?.attempts ?? 0) + 1,
      'completed_at': passed
          ? DateTime.now().toIso8601String()
          : previous?.completedAt?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
