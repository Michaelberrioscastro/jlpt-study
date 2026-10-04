import 'package:sqflite/sqflite.dart';

class KnowledgeMigrationService {
  KnowledgeMigrationService._();

  static const migrationKey = 'adaptive_learning_core_v2';

  static Future<void> migrate(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_state (
        item_type TEXT NOT NULL,
        item_id INTEGER NOT NULL,
        recognition REAL NOT NULL DEFAULT 0,
        meaning REAL NOT NULL DEFAULT 0,
        reading REAL NOT NULL DEFAULT 0,
        listening REAL NOT NULL DEFAULT 0,
        production REAL NOT NULL DEFAULT 0,
        context REAL NOT NULL DEFAULT 0,
        recognition_attempts INTEGER NOT NULL DEFAULT 0,
        meaning_attempts INTEGER NOT NULL DEFAULT 0,
        reading_attempts INTEGER NOT NULL DEFAULT 0,
        listening_attempts INTEGER NOT NULL DEFAULT 0,
        production_attempts INTEGER NOT NULL DEFAULT 0,
        context_attempts INTEGER NOT NULL DEFAULT 0,
        attempts INTEGER NOT NULL DEFAULT 0,
        correct INTEGER NOT NULL DEFAULT 0,
        lapses INTEGER NOT NULL DEFAULT 0,
        confidence REAL NOT NULL DEFAULT 0,
        last_seen TEXT,
        last_correct TEXT,
        PRIMARY KEY(item_type, item_id)
      )
    ''');

    for (final column in const [
      'recognition_attempts',
      'meaning_attempts',
      'reading_attempts',
      'listening_attempts',
      'production_attempts',
      'context_attempts',
    ]) {
      try {
        await db.execute(
          'ALTER TABLE knowledge_state ADD COLUMN $column INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {
        // Column already exists.
      }
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS knowledge_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_type TEXT NOT NULL,
        item_id INTEGER NOT NULL,
        occurred_at TEXT NOT NULL,
        event_type TEXT NOT NULL,
        dimensions_json TEXT NOT NULL DEFAULT '',
        difficulty REAL NOT NULL DEFAULT 0.5,
        response_ms INTEGER NOT NULL DEFAULT 0,
        mastery_before REAL NOT NULL DEFAULT 0,
        mastery_after REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_knowledge_events_item '
      'ON knowledge_events(item_type, item_id, occurred_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_knowledge_state_mastery '
      'ON knowledge_state(meaning, reading, recognition)',
    );

    // Existing SRS history gives us evidence for recognition/meaning/reading.
    // Do not invent evidence for listening, production or context.
    await db.execute('''
      INSERT OR IGNORE INTO knowledge_state (
        item_type, item_id,
        recognition, meaning, reading,
        recognition_attempts, meaning_attempts, reading_attempts,
        listening, production, context,
        attempts, correct, lapses, confidence,
        last_seen, last_correct
      )
      SELECT
        item_type,
        item_id,
        CASE
          WHEN repetitions >= 8 THEN 0.90
          WHEN repetitions >= 5 THEN 0.75
          WHEN repetitions >= 3 THEN 0.55
          WHEN repetitions >= 1 THEN 0.35
          ELSE 0.0
        END,
        CASE
          WHEN repetitions >= 8 THEN 0.90
          WHEN repetitions >= 5 THEN 0.75
          WHEN repetitions >= 3 THEN 0.55
          WHEN repetitions >= 1 THEN 0.35
          ELSE 0.0
        END,
        CASE
          WHEN repetitions >= 8 THEN 0.85
          WHEN repetitions >= 5 THEN 0.65
          WHEN repetitions >= 3 THEN 0.45
          WHEN repetitions >= 1 THEN 0.25
          ELSE 0.0
        END,
        CASE WHEN repetitions + lapses > 0 THEN repetitions + lapses ELSE 0 END,
        CASE WHEN repetitions + lapses > 0 THEN repetitions + lapses ELSE 0 END,
        CASE WHEN repetitions + lapses > 0 THEN repetitions + lapses ELSE 0 END,
        0.0, 0.0, 0.0,
        repetitions + lapses,
        repetitions,
        lapses,
        CASE
          WHEN repetitions + lapses = 0 THEN 0.0
          ELSE CAST(repetitions AS REAL) / (repetitions + lapses)
        END,
        last_review,
        CASE WHEN repetitions > 0 THEN last_review ELSE NULL END
      FROM review_state
    ''');

    await db.insert(
      'app_migrations',
      {
        'migration_key': migrationKey,
        'applied_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
