import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/learning_vocabulary.dart';
import 'learning_database_service.dart';

/// Local progress storage for the new LEARN module.
///
/// This database NEVER stores vocabulary content. It stores only the learner's
/// state, skill mastery, attempts, sessions and scheduling metadata.
///
/// Content lives in [LearningDatabaseService] and can therefore be updated
/// independently without deleting or resetting the learner's progress.
class LearningProgressService {
  LearningProgressService._();

  static const String _databaseName = 'jlpt_learning_progress.sqlite';
  static const int _schemaVersion = 1;

  static const List<String> _coreSkills = <String>[
    'meaning',
    'reading',
    'usage',
    'recall',
  ];

  static Database? _database;
  static Future<Database>? _databaseInitialization;

  static Future<Database> get database {
    final readyDatabase = _database;
    if (readyDatabase != null) {
      return Future.value(readyDatabase);
    }

    final initialization = _databaseInitialization;
    if (initialization != null) {
      return initialization;
    }

    final newInitialization = _openAndInitializeDatabase();
    _databaseInitialization = newInitialization;
    return newInitialization;
  }

  static Future<Database> _openAndInitializeDatabase() async {
    Database? db;

    try {
      final databasesPath = await getDatabasesPath();
      final databasePath = join(databasesPath, _databaseName);

      db = await openDatabase(
        databasePath,
        version: _schemaVersion,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await _createSchema(database);
        },
      );

      await _createSchema(db);
      await _ensureDefaultSettings(db);
      await _syncDefaultCourseItems(db);

      _database = db;
      return db;
    } catch (_) {
      if (db != null && db.isOpen) {
        await db.close();
      }
      rethrow;
    } finally {
      _databaseInitialization = null;
    }
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS learn_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS learn_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),

        new_words_per_day INTEGER NOT NULL DEFAULT 10
          CHECK (new_words_per_day BETWEEN 0 AND 50),

        max_due_reviews_per_day INTEGER NOT NULL DEFAULT 80
          CHECK (max_due_reviews_per_day BETWEEN 10 AND 500),

        batch_size INTEGER NOT NULL DEFAULT 5
          CHECK (batch_size BETWEEN 1 AND 10),

        core_before_standard_ratio REAL NOT NULL DEFAULT 0.80
          CHECK (core_before_standard_ratio BETWEEN 0.0 AND 1.0),

        introduce_standard_after_core_seen REAL NOT NULL DEFAULT 0.35
          CHECK (introduce_standard_after_core_seen BETWEEN 0.0 AND 1.0),

        show_reading_on_first_exposure INTEGER NOT NULL DEFAULT 1
          CHECK (show_reading_on_first_exposure IN (0, 1)),

        progressive_furigana INTEGER NOT NULL DEFAULT 1
          CHECK (progressive_furigana IN (0, 1)),

        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS learn_item_state (
        vocabulary_id TEXT PRIMARY KEY,

        state TEXT NOT NULL DEFAULT 'unseen'
          CHECK (state IN (
            'unseen',
            'introduced',
            'learning',
            'review',
            'mastered',
            'suspended'
          )),

        priority TEXT NOT NULL
          CHECK (priority IN ('CORE', 'STANDARD', 'EXTENDED')),

        first_seen_at TEXT,
        introduced_at TEXT,
        entered_review_at TEXT,
        mastered_at TEXT,
        last_seen_at TEXT,

        total_attempts INTEGER NOT NULL DEFAULT 0
          CHECK (total_attempts >= 0),

        total_correct INTEGER NOT NULL DEFAULT 0
          CHECK (total_correct >= 0),

        total_lapses INTEGER NOT NULL DEFAULT 0
          CHECK (total_lapses >= 0),

        consecutive_correct INTEGER NOT NULL DEFAULT 0
          CHECK (consecutive_correct >= 0),

        leech_score INTEGER NOT NULL DEFAULT 0
          CHECK (leech_score >= 0),

        next_due_at TEXT,

        mastery_score REAL NOT NULL DEFAULT 0
          CHECK (mastery_score BETWEEN 0 AND 100),

        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_learn_item_state_state_due
      ON learn_item_state(state, next_due_at)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_learn_item_state_priority_state
      ON learn_item_state(priority, state)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS learn_skill_state (
        vocabulary_id TEXT NOT NULL,

        skill TEXT NOT NULL
          CHECK (skill IN (
            'meaning',
            'reading',
            'usage',
            'recall',
            'listening'
          )),

        enabled INTEGER NOT NULL DEFAULT 1
          CHECK (enabled IN (0, 1)),

        mastery_score REAL NOT NULL DEFAULT 0
          CHECK (mastery_score BETWEEN 0 AND 100),

        attempts INTEGER NOT NULL DEFAULT 0
          CHECK (attempts >= 0),

        correct_attempts INTEGER NOT NULL DEFAULT 0
          CHECK (correct_attempts >= 0),

        consecutive_correct INTEGER NOT NULL DEFAULT 0
          CHECK (consecutive_correct >= 0),

        lapses INTEGER NOT NULL DEFAULT 0
          CHECK (lapses >= 0),

        last_result INTEGER
          CHECK (last_result IS NULL OR last_result IN (0, 1)),

        last_attempt_at TEXT,
        next_due_at TEXT,

        interval_hours REAL NOT NULL DEFAULT 0
          CHECK (interval_hours >= 0),

        ease_factor REAL NOT NULL DEFAULT 2.30
          CHECK (ease_factor BETWEEN 1.30 AND 3.00),

        PRIMARY KEY(vocabulary_id, skill),

        FOREIGN KEY(vocabulary_id)
          REFERENCES learn_item_state(vocabulary_id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_learn_skill_due
      ON learn_skill_state(enabled, next_due_at)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_learn_skill_weak
      ON learn_skill_state(enabled, mastery_score, lapses)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS learn_session (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        started_at TEXT NOT NULL,
        completed_at TEXT,

        session_type TEXT NOT NULL
          CHECK (session_type IN (
            'daily',
            'new_words',
            'review',
            'weak_words',
            'mini_quiz'
          )),

        planned_new INTEGER NOT NULL DEFAULT 0,
        introduced_count INTEGER NOT NULL DEFAULT 0,
        reviewed_count INTEGER NOT NULL DEFAULT 0,

        attempts INTEGER NOT NULL DEFAULT 0,
        correct_attempts INTEGER NOT NULL DEFAULT 0,

        meaning_attempts INTEGER NOT NULL DEFAULT 0,
        reading_attempts INTEGER NOT NULL DEFAULT 0,
        usage_attempts INTEGER NOT NULL DEFAULT 0,
        recall_attempts INTEGER NOT NULL DEFAULT 0,
        listening_attempts INTEGER NOT NULL DEFAULT 0,

        meaning_correct INTEGER NOT NULL DEFAULT 0,
        reading_correct INTEGER NOT NULL DEFAULT 0,
        usage_correct INTEGER NOT NULL DEFAULT 0,
        recall_correct INTEGER NOT NULL DEFAULT 0,
        listening_correct INTEGER NOT NULL DEFAULT 0,

        completed INTEGER NOT NULL DEFAULT 0
          CHECK (completed IN (0, 1))
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_learn_session_started
      ON learn_session(started_at DESC)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS learn_attempt_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        session_id INTEGER,
        vocabulary_id TEXT NOT NULL,

        skill TEXT NOT NULL
          CHECK (skill IN (
            'meaning',
            'reading',
            'usage',
            'recall',
            'listening'
          )),

        prompt_type TEXT NOT NULL
          CHECK (prompt_type IN (
            'meaning_mcq',
            'reading_mcq',
            'context_cloze',
            'reverse_recall',
            'listening_mcq'
          )),

        attempted_at TEXT NOT NULL,

        correct INTEGER NOT NULL
          CHECK (correct IN (0, 1)),

        response_time_ms INTEGER
          CHECK (response_time_ms IS NULL OR response_time_ms >= 0),

        response_value TEXT,
        distractors_json TEXT NOT NULL DEFAULT '[]',

        mastery_before REAL NOT NULL DEFAULT 0,
        mastery_after REAL NOT NULL DEFAULT 0,

        state_before TEXT,
        state_after TEXT,

        FOREIGN KEY(session_id)
          REFERENCES learn_session(id)
          ON DELETE SET NULL,

        FOREIGN KEY(vocabulary_id)
          REFERENCES learn_item_state(vocabulary_id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_learn_attempt_vocab_time
      ON learn_attempt_log(vocabulary_id, attempted_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_learn_attempt_skill_time
      ON learn_attempt_log(skill, attempted_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_learn_attempt_incorrect
      ON learn_attempt_log(correct, attempted_at DESC)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS learn_queue_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        session_id INTEGER NOT NULL,
        vocabulary_id TEXT NOT NULL,

        queue_reason TEXT NOT NULL
          CHECK (queue_reason IN (
            'new_core',
            'new_standard',
            'due_review',
            'weak_meaning',
            'weak_reading',
            'weak_usage',
            'weak_recall',
            'same_session_retry'
          )),

        position INTEGER NOT NULL,
        created_at TEXT NOT NULL,

        FOREIGN KEY(session_id)
          REFERENCES learn_session(id)
          ON DELETE CASCADE,

        FOREIGN KEY(vocabulary_id)
          REFERENCES learn_item_state(vocabulary_id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_learn_queue_session_position
      ON learn_queue_log(session_id, position)
    ''');

    await db.execute('''
      CREATE VIEW IF NOT EXISTS learn_progress_summary AS
      SELECT
        COUNT(*) AS total_started,
        SUM(CASE WHEN state = 'introduced' THEN 1 ELSE 0 END) AS introduced,
        SUM(CASE WHEN state = 'learning' THEN 1 ELSE 0 END) AS learning,
        SUM(CASE WHEN state = 'review' THEN 1 ELSE 0 END) AS reviewing,
        SUM(CASE WHEN state = 'mastered' THEN 1 ELSE 0 END) AS mastered,
        SUM(CASE WHEN state = 'suspended' THEN 1 ELSE 0 END) AS suspended,
        ROUND(AVG(mastery_score), 1) AS average_mastery
      FROM learn_item_state
      WHERE state <> 'unseen'
    ''');

    await db.execute('''
      CREATE VIEW IF NOT EXISTS learn_weak_items AS
      SELECT
        i.vocabulary_id,
        i.priority,
        i.state,
        i.mastery_score AS overall_mastery,
        MIN(s.mastery_score) AS weakest_skill_score,
        SUM(s.lapses) AS skill_lapses,
        i.total_lapses,
        i.leech_score
      FROM learn_item_state i
      JOIN learn_skill_state s
        ON s.vocabulary_id = i.vocabulary_id
       AND s.enabled = 1
      WHERE i.state IN ('learning', 'review', 'mastered')
      GROUP BY i.vocabulary_id
      HAVING MIN(s.mastery_score) < 60
          OR SUM(s.lapses) >= 3
      ORDER BY
        MIN(s.mastery_score) ASC,
        SUM(s.lapses) DESC,
        i.last_seen_at ASC
    ''');

    await db.insert('learn_metadata', {
      'key': 'schema_version',
      'value': _schemaVersion.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('learn_metadata', {
      'key': 'module',
      'value': 'learn_vocabulary',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await db.insert('learn_metadata', {
      'key': 'content_level',
      'value': 'N4',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> _ensureDefaultSettings(Database db) async {
    final now = DateTime.now().toIso8601String();

    await db.insert('learn_settings', {
      'id': 1,
      'new_words_per_day': 10,
      'max_due_reviews_per_day': 80,
      'batch_size': 5,
      'core_before_standard_ratio': 0.80,
      'introduce_standard_after_core_seen': 0.35,
      'show_reading_on_first_exposure': 1,
      'progressive_furigana': 1,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Ensures every current CORE/STANDARD vocabulary item has an UNSEEN row.
  ///
  /// Existing progress is never replaced. If curated content changes priority
  /// in a future release, only the cached priority is refreshed.
  static Future<void> _syncDefaultCourseItems(Database db) async {
    final vocabulary = await LearningDatabaseService.getVocabulary();
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      for (final word in vocabulary) {
        await txn.insert('learn_item_state', {
          'vocabulary_id': word.id,
          'state': 'unseen',
          'priority': word.priority,
          'mastery_score': 0.0,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        await txn.update(
          'learn_item_state',
          {'priority': word.priority, 'updated_at': now},
          where: 'vocabulary_id = ?',
          whereArgs: [word.id],
        );
      }
    });
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final db = await database;

    final rows = await db.query(
      'learn_settings',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw StateError('LEARN settings were not initialized.');
    }

    return Map<String, dynamic>.from(rows.first);
  }

  static Future<void> updateSettings({
    int? newWordsPerDay,
    int? maxDueReviewsPerDay,
    int? batchSize,
    bool? showReadingOnFirstExposure,
    bool? progressiveFurigana,
  }) async {
    final db = await database;
    final values = <String, Object?>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (newWordsPerDay != null) {
      values['new_words_per_day'] = newWordsPerDay;
    }

    if (maxDueReviewsPerDay != null) {
      values['max_due_reviews_per_day'] = maxDueReviewsPerDay;
    }

    if (batchSize != null) {
      values['batch_size'] = batchSize;
    }

    if (showReadingOnFirstExposure != null) {
      values['show_reading_on_first_exposure'] = showReadingOnFirstExposure
          ? 1
          : 0;
    }

    if (progressiveFurigana != null) {
      values['progressive_furigana'] = progressiveFurigana ? 1 : 0;
    }

    await db.update('learn_settings', values, where: 'id = ?', whereArgs: [1]);
  }

  static Future<Map<String, int>> getStateCounts() async {
    final db = await database;

    final rows = await db.rawQuery('''
      SELECT state, COUNT(*) AS count
      FROM learn_item_state
      GROUP BY state
    ''');

    final counts = <String, int>{
      'unseen': 0,
      'introduced': 0,
      'learning': 0,
      'review': 0,
      'mastered': 0,
      'suspended': 0,
    };

    for (final row in rows) {
      final state = row['state']?.toString();
      final count = (row['count'] as num?)?.toInt() ?? 0;

      if (state != null && counts.containsKey(state)) {
        counts[state] = count;
      }
    }

    return counts;
  }

  static Future<Map<String, int>> getPriorityCounts() async {
    final db = await database;

    final rows = await db.rawQuery('''
      SELECT
        priority,
        COUNT(*) AS total,
        SUM(CASE WHEN state <> 'unseen' THEN 1 ELSE 0 END) AS seen,
        SUM(CASE WHEN state = 'mastered' THEN 1 ELSE 0 END) AS mastered
      FROM learn_item_state
      GROUP BY priority
    ''');

    final result = <String, int>{};

    for (final row in rows) {
      final priority = row['priority']?.toString().toLowerCase();
      if (priority == null) continue;

      result['${priority}_total'] = (row['total'] as num?)?.toInt() ?? 0;
      result['${priority}_seen'] = (row['seen'] as num?)?.toInt() ?? 0;
      result['${priority}_mastered'] = (row['mastered'] as num?)?.toInt() ?? 0;
    }

    return result;
  }

  static Future<int> getDueReviewCount() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(DISTINCT vocabulary_id)
            FROM learn_skill_state
            WHERE enabled = 1
              AND next_due_at IS NOT NULL
              AND next_due_at <= ?
            ''',
            [now],
          ),
        ) ??
        0;
  }

  static Future<int> getWeakWordCount() async {
    final db = await database;

    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM learn_weak_items'),
        ) ??
        0;
  }

  static Future<Map<String, dynamic>?> getItemState(String vocabularyId) async {
    final db = await database;

    final rows = await db.query(
      'learn_item_state',
      where: 'vocabulary_id = ?',
      whereArgs: [vocabularyId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(rows.first);
  }

  static Future<List<Map<String, dynamic>>> getSkillStates(
    String vocabularyId,
  ) async {
    final db = await database;

    final rows = await db.query(
      'learn_skill_state',
      where: 'vocabulary_id = ?',
      whereArgs: [vocabularyId],
      orderBy: 'skill ASC',
    );

    return rows.map(Map<String, dynamic>.from).toList(growable: false);
  }

  /// Moves a word from UNSEEN to INTRODUCED and creates independent skill
  /// rows. Reopening a word never resets previous mastery or scheduling.
  static Future<void> introduceVocabulary(LearningVocabulary word) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final rows = await txn.query(
        'learn_item_state',
        where: 'vocabulary_id = ?',
        whereArgs: [word.id],
        limit: 1,
      );

      if (rows.isEmpty) {
        await txn.insert('learn_item_state', {
          'vocabulary_id': word.id,
          'state': 'introduced',
          'priority': word.priority,
          'first_seen_at': now,
          'introduced_at': now,
          'last_seen_at': now,
          'next_due_at': now,
          'mastery_score': 0.0,
          'updated_at': now,
        });
      } else {
        final currentState = rows.first['state']?.toString() ?? 'unseen';

        if (currentState == 'unseen') {
          await txn.update(
            'learn_item_state',
            {
              'state': 'introduced',
              'first_seen_at': now,
              'introduced_at': now,
              'last_seen_at': now,
              'next_due_at': now,
              'updated_at': now,
            },
            where: 'vocabulary_id = ?',
            whereArgs: [word.id],
          );
        } else {
          await txn.update(
            'learn_item_state',
            {'last_seen_at': now, 'updated_at': now},
            where: 'vocabulary_id = ?',
            whereArgs: [word.id],
          );
        }
      }

      for (final skill in _coreSkills) {
        await txn.insert('learn_skill_state', {
          'vocabulary_id': word.id,
          'skill': skill,
          'enabled': 1,
          'mastery_score': 0.0,
          'attempts': 0,
          'correct_attempts': 0,
          'consecutive_correct': 0,
          'lapses': 0,
          'next_due_at': now,
          'interval_hours': 0.0,
          'ease_factor': 2.30,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      await txn.insert('learn_skill_state', {
        'vocabulary_id': word.id,
        'skill': 'listening',
        // Audio filenames may exist in the curated source database, but
        // the actual audio assets are not bundled in LEARN yet. Keep
        // listening disabled until the media integration is implemented.
        'enabled': 0,
        'mastery_score': 0.0,
        'attempts': 0,
        'correct_attempts': 0,
        'consecutive_correct': 0,
        'lapses': 0,
        'next_due_at': null,
        'interval_hours': 0.0,
        'ease_factor': 2.30,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    });
  }

  static Future<void> markLearning(String vocabularyId) async {
    await _moveState(vocabularyId, targetState: 'learning');
  }

  static Future<void> markReview(String vocabularyId) async {
    await _moveState(
      vocabularyId,
      targetState: 'review',
      setEnteredReviewAt: true,
    );
  }

  static Future<void> markMastered(String vocabularyId) async {
    await _moveState(
      vocabularyId,
      targetState: 'mastered',
      setMasteredAt: true,
    );
  }

  static Future<void> suspend(String vocabularyId) async {
    await _moveState(vocabularyId, targetState: 'suspended');
  }

  static Future<void> _moveState(
    String vocabularyId, {
    required String targetState,
    bool setEnteredReviewAt = false,
    bool setMasteredAt = false,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final values = <String, Object?>{
      'state': targetState,
      'last_seen_at': now,
      'updated_at': now,
    };

    if (setEnteredReviewAt) {
      values['entered_review_at'] = now;
    }

    if (setMasteredAt) {
      values['mastered_at'] = now;
    }

    await db.update(
      'learn_item_state',
      values,
      where: 'vocabulary_id = ?',
      whereArgs: [vocabularyId],
    );
  }

  static Future<Map<String, dynamic>> getDashboardSnapshot() async {
    final stateCounts = await getStateCounts();
    final priorityCounts = await getPriorityCounts();
    final dueReviews = await getDueReviewCount();
    final weakWords = await getWeakWordCount();
    final settings = await getSettings();

    return {
      ...stateCounts,
      ...priorityCounts,
      'due_reviews': dueReviews,
      'weak_words': weakWords,
      'new_words_per_day':
          (settings['new_words_per_day'] as num?)?.toInt() ?? 10,
      'batch_size': (settings['batch_size'] as num?)?.toInt() ?? 5,
    };
  }

  static Future<void> close() async {
    final db = _database;

    _database = null;
    _databaseInitialization = null;

    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}
