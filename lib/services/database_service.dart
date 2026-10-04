import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/study_item.dart';
import 'content_migration_service.dart';
import 'knowledge_migration_service.dart';

class DatabaseService {
  DatabaseService._();

  static const _assetPath = 'assets/database/jlpt_study_master.sqlite';
  static const _kanaSeedPath = 'assets/data/kana_seed.json';
  static const _databaseName = 'jlpt_study.sqlite';

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

      if (!await databaseExists(databasePath)) {
        final data = await rootBundle.load(_assetPath);

        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        await Directory(dirname(databasePath)).create(recursive: true);

        await File(databasePath).writeAsBytes(bytes, flush: true);
      }

      db = await openDatabase(databasePath, readOnly: false);

      // Do not expose the database until every migration has completed.
      // Several tabs can request the database during the first app launch.
      await _ensureLearnedColumn(db);
      await _migrateKana(db);
      await KnowledgeMigrationService.migrate(db);
      await ContentMigrationService.migrate(db);

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

  static Future<void> _ensureLearnedColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(review_state)');
    final hasLearned = columns.any(
      (column) => column['name']?.toString() == 'learned',
    );

    if (!hasLearned) {
      await db.execute(
        'ALTER TABLE review_state ADD COLUMN learned INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  static Future<void> _migrateKana(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_migrations (
        migration_key TEXT PRIMARY KEY,
        applied_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS kana (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_note_id INTEGER NOT NULL UNIQUE,
        script TEXT NOT NULL,
        kana TEXT NOT NULL,
        romaji TEXT NOT NULL,
        category TEXT NOT NULL,
        audio_file TEXT NOT NULL DEFAULT '',
        tags_json TEXT NOT NULL DEFAULT '[]',
        source TEXT NOT NULL DEFAULT 'Complete Japanese Kana practice deck',
        UNIQUE(script, kana)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_kana_script ON kana(script)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_kana_category ON kana(category)',
    );

    // Existing installations may have a CHECK constraint that only accepts
    // vocab/kanji/grammar. Rebuild review_state once so Kana can use the
    // same SRS without deleting existing progress.
    final schemaRows = await db.rawQuery(
      "SELECT sql FROM sqlite_master "
      "WHERE type = 'table' AND name = 'review_state'",
    );

    if (schemaRows.isNotEmpty) {
      final schema = (schemaRows.first['sql'] ?? '').toString().toLowerCase();
      final hasRestrictedTypeCheck =
          schema.contains('check') &&
          schema.contains('item_type') &&
          !schema.contains("'kana'");

      if (hasRestrictedTypeCheck) {
        await db.transaction((txn) async {
          await txn.execute('DROP TABLE IF EXISTS review_state_kana_tmp');

          await txn.execute('''
            CREATE TABLE review_state_kana_tmp (
              item_type TEXT NOT NULL
                CHECK(item_type IN ('vocab','kanji','grammar','kana','custom')),
              item_id INTEGER NOT NULL,
              state TEXT NOT NULL DEFAULT 'new'
                CHECK(state IN ('new','learning','review','mature')),
              last_review TEXT,
              next_review TEXT,
              interval_days REAL NOT NULL DEFAULT 0,
              ease_factor REAL NOT NULL DEFAULT 2.5,
              repetitions INTEGER NOT NULL DEFAULT 0,
              lapses INTEGER NOT NULL DEFAULT 0,
              steps_remaining INTEGER NOT NULL DEFAULT 0,
              learned INTEGER NOT NULL DEFAULT 0,
              PRIMARY KEY(item_type, item_id)
            )
          ''');

          await txn.execute('''
            INSERT INTO review_state_kana_tmp (
              item_type,
              item_id,
              state,
              last_review,
              next_review,
              interval_days,
              ease_factor,
              repetitions,
              lapses,
              steps_remaining,
              learned
            )
            SELECT
              item_type,
              item_id,
              state,
              last_review,
              next_review,
              interval_days,
              ease_factor,
              repetitions,
              lapses,
              steps_remaining,
              COALESCE(learned, 0)
            FROM review_state
          ''');

          await txn.execute('DROP TABLE review_state');
          await txn.execute(
            'ALTER TABLE review_state_kana_tmp RENAME TO review_state',
          );
          await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_review_next '
            'ON review_state(state, next_review)',
          );
        });
      }
    }

    // Recreate the unified learning view so Kana behaves like any StudyItem.
    final viewRows = await db.rawQuery(
      "SELECT sql FROM sqlite_master "
      "WHERE type = 'view' AND name = 'learning_items'",
    );

    final currentView = viewRows.isEmpty
        ? ''
        : (viewRows.first['sql'] ?? '').toString();

    if (!currentView.toLowerCase().contains("select 'kana'")) {
      await db.transaction((txn) async {
        await txn.execute('DROP VIEW IF EXISTS learning_items');

        await txn.execute('''
          CREATE VIEW learning_items AS
          SELECT
            'vocab' AS item_type,
            id AS item_id,
            level,
            expression AS front,
            reading,
            meaning
          FROM vocabulary

          UNION ALL

          SELECT
            'kanji',
            id,
            level,
            kanji,
            reading,
            meaning
          FROM kanji

          UNION ALL

          SELECT
            'grammar',
            id,
            level,
            pattern,
            '',
            meaning
          FROM grammar

          UNION ALL

          SELECT
            'kana',
            id,
            'KANA',
            kana,
            romaji,
            CASE script
              WHEN 'hiragana' THEN 'Hiragana'
              ELSE 'Katakana'
            END
          FROM kana
        ''');
      });
    }

    final migration = await db.query(
      'app_migrations',
      where: 'migration_key = ?',
      whereArgs: ['kana_seed_v1'],
      limit: 1,
    );

    if (migration.isNotEmpty) return;

    final seedText = await rootBundle.loadString(_kanaSeedPath);
    final decoded = jsonDecode(seedText);

    if (decoded is! Map<String, dynamic> || decoded['items'] is! List) {
      throw const FormatException(
        'kana_seed.json no tiene el formato esperado.',
      );
    }

    final items = decoded['items'] as List;

    await db.transaction((txn) async {
      for (final raw in items) {
        if (raw is! Map) continue;

        final item = Map<String, dynamic>.from(raw);

        await txn.insert('kana', {
          'source_note_id': item['source_note_id'],
          'script': item['script'],
          'kana': item['kana'],
          'romaji': item['romaji'],
          'category': item['category'] ?? 'Other',
          'audio_file': item['audio_file'] ?? '',
          'tags_json': jsonEncode(item['tags'] ?? const []),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      await txn.insert('app_migrations', {
        'migration_key': 'kana_seed_v1',
        'applied_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    });
  }

  static Future<Map<String, Map<String, int>>> getKanaStudyCounts() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final result = <String, Map<String, int>>{};

    for (final script in ['hiragana', 'katakana']) {
      Future<int> count(String sql, List<Object?> args) async =>
          Sqflite.firstIntValue(await db.rawQuery(sql, args)) ?? 0;

      final total = await count('SELECT COUNT(*) FROM kana WHERE script = ?', [
        script,
      ]);

      final studied = await count(
        '''
        SELECT COUNT(*)
        FROM review_state rs
        JOIN kana k
          ON rs.item_type = 'kana' AND rs.item_id = k.id
        WHERE k.script = ?
        ''',
        [script],
      );

      final learned = await count(
        '''
        SELECT COUNT(*)
        FROM review_state rs
        JOIN kana k
          ON rs.item_type = 'kana' AND rs.item_id = k.id
        WHERE k.script = ? AND COALESCE(rs.learned, 0) = 1
        ''',
        [script],
      );

      final due = await count(
        '''
        SELECT COUNT(*)
        FROM review_state rs
        JOIN kana k
          ON rs.item_type = 'kana' AND rs.item_id = k.id
        WHERE k.script = ?
          AND rs.next_review IS NOT NULL
          AND rs.next_review <= ?
        ''',
        [script, now],
      );

      result[script] = {
        'total': total,
        'studied': studied,
        'learned': learned,
        'learning': studied - learned,
        'new': total - studied,
        'due': due,
      };
    }

    return result;
  }

  static Future<Map<String, int>> getKanaOverallCounts() async {
    final byScript = await getKanaStudyCounts();

    int sum(String key) =>
        byScript.values.fold(0, (total, row) => total + (row[key] ?? 0));

    return {
      'total': sum('total'),
      'studied': sum('studied'),
      'learned': sum('learned'),
      'learning': sum('learning'),
      'new': sum('new'),
      'due': sum('due'),
    };
  }

  static Future<List<StudyItem>> getTodayKanaItems({
    String script = 'mix',
    int dueReviewLimit = 20,
    int learningLimit = 2,
    int newLimit = 8,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final isMix = script == 'mix';
    final scriptClause = isMix ? '' : 'AND k.script = ?';

    List<Object?> withScript(List<Object?> tail) =>
        isMix ? tail : [script, ...tail];

    final dueRows = await db.rawQuery('''
      SELECT
        'kana' AS item_type,
        k.id AS item_id,
        'KANA' AS level,
        k.kana AS front,
        k.romaji AS reading,
        CASE k.script
          WHEN 'hiragana' THEN 'Hiragana'
          ELSE 'Katakana'
        END AS meaning,
        rs.state,
        rs.next_review,
        rs.interval_days,
        rs.ease_factor,
        rs.repetitions,
        rs.lapses,
        COALESCE(rs.learned, 0) AS learned
      FROM review_state rs
      JOIN kana k
        ON rs.item_type = 'kana' AND rs.item_id = k.id
      WHERE 1 = 1
        $scriptClause
        AND rs.state IN ('review', 'mature')
        AND rs.next_review IS NOT NULL
        AND rs.next_review <= ?
      ORDER BY rs.next_review ASC
      LIMIT ?
      ''', withScript([now, dueReviewLimit]));

    final learningRows = await db.rawQuery('''
      SELECT
        'kana' AS item_type,
        k.id AS item_id,
        'KANA' AS level,
        k.kana AS front,
        k.romaji AS reading,
        CASE k.script
          WHEN 'hiragana' THEN 'Hiragana'
          ELSE 'Katakana'
        END AS meaning,
        rs.state,
        rs.next_review,
        rs.interval_days,
        rs.ease_factor,
        rs.repetitions,
        rs.lapses,
        COALESCE(rs.learned, 0) AS learned
      FROM review_state rs
      JOIN kana k
        ON rs.item_type = 'kana' AND rs.item_id = k.id
      WHERE 1 = 1
        $scriptClause
        AND rs.state = 'learning'
        AND COALESCE(rs.learned, 0) = 0
      ORDER BY
        CASE WHEN rs.next_review IS NULL THEN 1 ELSE 0 END,
        rs.next_review ASC,
        rs.last_review ASC
      LIMIT ?
      ''', withScript([learningLimit]));

    Future<List<Map<String, Object?>>> loadNew(String targetScript, int limit) {
      return db.rawQuery(
        '''
        SELECT
          'kana' AS item_type,
          k.id AS item_id,
          'KANA' AS level,
          k.kana AS front,
          k.romaji AS reading,
          CASE k.script
            WHEN 'hiragana' THEN 'Hiragana'
            ELSE 'Katakana'
          END AS meaning,
          'new' AS state,
          NULL AS next_review,
          0.0 AS interval_days,
          2.5 AS ease_factor,
          0 AS repetitions,
          0 AS lapses,
          0 AS learned
        FROM kana k
        LEFT JOIN review_state rs
          ON rs.item_type = 'kana' AND rs.item_id = k.id
        WHERE k.script = ? AND rs.item_id IS NULL
        ORDER BY
          CASE k.category
            WHEN 'Gojūon' THEN 1
            WHEN 'Dakuon' THEN 2
            WHEN 'Handakuon' THEN 3
            WHEN 'Yōon' THEN 4
            WHEN 'Additional' THEN 5
            ELSE 6
          END,
          k.id ASC
        LIMIT ?
        ''',
        [targetScript, limit],
      );
    }

    final newRows = <Map<String, Object?>>[];

    if (isMix) {
      newRows.addAll(await loadNew('hiragana', 4));
      newRows.addAll(await loadNew('katakana', 4));

      if (newRows.length < newLimit) {
        final used = newRows.map((row) => row['item_id']).toSet();

        final fallback = await db.rawQuery(
          '''
          SELECT
            'kana' AS item_type,
            k.id AS item_id,
            'KANA' AS level,
            k.kana AS front,
            k.romaji AS reading,
            CASE k.script
              WHEN 'hiragana' THEN 'Hiragana'
              ELSE 'Katakana'
            END AS meaning,
            'new' AS state,
            NULL AS next_review,
            0.0 AS interval_days,
            2.5 AS ease_factor,
            0 AS repetitions,
            0 AS lapses,
            0 AS learned
          FROM kana k
          LEFT JOIN review_state rs
            ON rs.item_type = 'kana' AND rs.item_id = k.id
          WHERE rs.item_id IS NULL
          ORDER BY
            CASE k.category
              WHEN 'Gojūon' THEN 1
              WHEN 'Dakuon' THEN 2
              WHEN 'Handakuon' THEN 3
              WHEN 'Yōon' THEN 4
              WHEN 'Additional' THEN 5
              ELSE 6
            END,
            k.id ASC
          LIMIT ?
          ''',
          [newLimit * 3],
        );

        for (final row in fallback) {
          if (used.add(row['item_id'])) {
            newRows.add(row);
          }
          if (newRows.length >= newLimit) break;
        }
      }
    } else {
      newRows.addAll(await loadNew(script, newLimit));
    }

    final seen = <String>{};
    final result = <StudyItem>[];

    void addRows(List<Map<String, Object?>> rows) {
      for (final row in rows) {
        final item = StudyItem.fromMap(Map<String, dynamic>.from(row));
        final key = '${item.type}:${item.id}';

        if (seen.add(key)) {
          result.add(item);
        }
      }
    }

    addRows(dueRows);
    addRows(learningRows);
    addRows(newRows.take(newLimit).toList());

    return result;
  }

  static Future<List<StudyItem>> getItemsByLevel(String level) async {
    final db = await database;

    final rows = await db.query(
      'learning_items',
      where: 'level = ?',
      whereArgs: [level],
      orderBy: '''
        CASE item_type
          WHEN 'vocab' THEN 1
          WHEN 'kanji' THEN 2
          WHEN 'grammar' THEN 3
          ELSE 4
        END,
        item_id ASC
      ''',
    );

    return rows
        .map((row) => StudyItem.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<List<StudyItem>> getStudyCatalogItems({
    required String level,
    required String type,
  }) async {
    final normalizedLevel = level.toUpperCase();
    final normalizedType = type.toLowerCase();

    if (!const {'vocab', 'kanji', 'grammar'}.contains(normalizedType)) {
      throw ArgumentError.value(
        type,
        'type',
        'Debe ser vocab, kanji o grammar.',
      );
    }

    final db = await database;

    final rows = await db.rawQuery(
      '''
      SELECT
        li.item_type,
        li.item_id,
        li.level,
        li.front,
        li.reading,
        li.meaning,
        COALESCE(rs.state, 'new') AS state,
        rs.next_review,
        COALESCE(rs.interval_days, 0.0) AS interval_days,
        COALESCE(rs.ease_factor, 2.5) AS ease_factor,
        COALESCE(rs.repetitions, 0) AS repetitions,
        COALESCE(rs.lapses, 0) AS lapses,
        COALESCE(rs.learned, 0) AS learned
      FROM learning_items li
      LEFT JOIN review_state rs
        ON rs.item_type = li.item_type
       AND rs.item_id = li.item_id
      WHERE li.level = ?
        AND li.item_type = ?
      ORDER BY li.item_id ASC
      ''',
      [normalizedLevel, normalizedType],
    );

    return rows
        .map((row) => StudyItem.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<List<StudyItem>> getGrammarItems(String level) {
    return getStudyCatalogItems(level: level, type: 'grammar');
  }

  static Future<Map<String, int>> getN5Counts() async {
    final db = await database;

    final rows = await db.rawQuery('''
      SELECT
        item_type,
        COUNT(*) AS total
      FROM learning_items
      WHERE level = 'N5'
      GROUP BY item_type
      ''');

    final result = <String, int>{};

    for (final row in rows) {
      result[row['item_type'].toString()] = (row['total'] as num).toInt();
    }

    return result;
  }

  static Future<Map<String, int>> getStudyCounts(String level) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    Future<int> count(String sql, List<Object?> args) async =>
        Sqflite.firstIntValue(await db.rawQuery(sql, args)) ?? 0;

    final total = await count(
      'SELECT COUNT(*) FROM learning_items WHERE level = ?',
      [level],
    );
    final studied = await count(
      '''
      SELECT COUNT(*) FROM review_state rs
      JOIN learning_items li
        ON li.item_type = rs.item_type AND li.item_id = rs.item_id
      WHERE li.level = ?
      ''',
      [level],
    );
    final learned = await count(
      '''
      SELECT COUNT(*) FROM review_state rs
      JOIN learning_items li
        ON li.item_type = rs.item_type AND li.item_id = rs.item_id
      WHERE li.level = ? AND COALESCE(rs.learned, 0) = 1
      ''',
      [level],
    );
    final due = await count(
      '''
      SELECT COUNT(*) FROM review_state rs
      JOIN learning_items li
        ON li.item_type = rs.item_type AND li.item_id = rs.item_id
      WHERE li.level = ?
        AND rs.next_review IS NOT NULL
        AND rs.next_review <= ?
      ''',
      [level, now],
    );

    return {
      'total': total,
      'studied': studied,
      'learned': learned,
      'due': due,
      'new': total - studied,
      'learning': studied - learned,
    };
  }

  static Future<Map<String, Map<String, int>>> getStudyCountsByType(
    String level,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final result = <String, Map<String, int>>{};

    for (final type in ['vocab', 'kanji', 'grammar']) {
      Future<int> count(String sql, List<Object?> args) async =>
          Sqflite.firstIntValue(await db.rawQuery(sql, args)) ?? 0;

      final total = await count(
        '''
        SELECT COUNT(*)
        FROM learning_items
        WHERE level = ? AND item_type = ?
        ''',
        [level, type],
      );

      final studied = await count(
        '''
        SELECT COUNT(*)
        FROM review_state rs
        JOIN learning_items li
          ON li.item_type = rs.item_type
         AND li.item_id = rs.item_id
        WHERE li.level = ?
          AND li.item_type = ?
        ''',
        [level, type],
      );

      final learned = await count(
        '''
        SELECT COUNT(*)
        FROM review_state rs
        JOIN learning_items li
          ON li.item_type = rs.item_type
         AND li.item_id = rs.item_id
        WHERE li.level = ?
          AND li.item_type = ?
          AND COALESCE(rs.learned, 0) = 1
        ''',
        [level, type],
      );

      final due = await count(
        '''
        SELECT COUNT(*)
        FROM review_state rs
        JOIN learning_items li
          ON li.item_type = rs.item_type
         AND li.item_id = rs.item_id
        WHERE li.level = ?
          AND li.item_type = ?
          AND rs.next_review IS NOT NULL
          AND rs.next_review <= ?
        ''',
        [level, type, now],
      );

      result[type] = {
        'total': total,
        'studied': studied,
        'learned': learned,
        'learning': studied - learned,
        'new': total - studied,
        'due': due,
      };
    }

    return result;
  }

  static Future<List<StudyItem>> getTodayStudyItems({
    required String level,
    String studyType = 'mix',
    int dueReviewLimit = 20,
    int learningLimit = 2,
    int newLimit = 8,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final isMix = studyType == 'mix';
    final typeClause = isMix ? '' : 'AND li.item_type = ?';

    List<Object?> argsWithType(List<Object?> tail) {
      // `li.level = ?` is always present. Mix only removes item_type.
      if (isMix) return [level, ...tail];
      return [level, studyType, ...tail];
    }

    final dueRows = await db.rawQuery('''
      SELECT
        li.item_type,
        li.item_id,
        li.level,
        li.front,
        li.reading,
        li.meaning,
        rs.state,
        rs.next_review,
        rs.interval_days,
        rs.ease_factor,
        rs.repetitions,
        rs.lapses,
        COALESCE(rs.learned, 0) AS learned
      FROM review_state rs
      JOIN learning_items li
        ON li.item_type = rs.item_type
       AND li.item_id = rs.item_id
      WHERE li.level = ?
        $typeClause
        AND rs.state IN ('review', 'mature')
        AND COALESCE(rs.learned, 0) = 0
        AND rs.next_review IS NOT NULL
        AND rs.next_review <= ?
      ORDER BY rs.next_review ASC
      LIMIT ?
      ''', argsWithType([now, dueReviewLimit]));

    final learningRows = await db.rawQuery('''
      SELECT
        li.item_type,
        li.item_id,
        li.level,
        li.front,
        li.reading,
        li.meaning,
        rs.state,
        rs.next_review,
        rs.interval_days,
        rs.ease_factor,
        rs.repetitions,
        rs.lapses,
        COALESCE(rs.learned, 0) AS learned
      FROM review_state rs
      JOIN learning_items li
        ON li.item_type = rs.item_type
       AND li.item_id = rs.item_id
      WHERE li.level = ?
        $typeClause
        AND rs.state = 'learning'
        AND COALESCE(rs.learned, 0) = 0
      ORDER BY
        CASE WHEN rs.next_review IS NULL THEN 1 ELSE 0 END,
        rs.next_review ASC,
        rs.last_review ASC
      LIMIT ?
      ''', argsWithType([learningLimit]));

    final newRows = <Map<String, Object?>>[];

    if (isMix) {
      // Mix equilibrado: intenta 4 vocabulario + 2 kanji + 2 gramática.
      final quotas = <String, int>{'vocab': 4, 'kanji': 2, 'grammar': 2};

      for (final entry in quotas.entries) {
        final rows = await db.rawQuery(
          '''
          SELECT
            li.item_type,
            li.item_id,
            li.level,
            li.front,
            li.reading,
            li.meaning,
            'new' AS state,
            NULL AS next_review,
            0.0 AS interval_days,
            2.5 AS ease_factor,
            0 AS repetitions,
            0 AS lapses,
            0 AS learned
          FROM learning_items li
          LEFT JOIN review_state rs
            ON li.item_type = rs.item_type
           AND li.item_id = rs.item_id
          WHERE li.level = ?
            AND li.item_type = ?
            AND rs.item_id IS NULL
          ORDER BY li.item_id ASC
          LIMIT ?
          ''',
          [level, entry.key, entry.value],
        );
        newRows.addAll(rows);
      }

      // Si alguna categoría ya no tiene suficientes nuevas,
      // completa la sesión con cualquier contenido nuevo disponible.
      if (newRows.length < newLimit) {
        final excluded = newRows
            .map((row) => '${row['item_type']}:${row['item_id']}')
            .toSet();

        final fallback = await db.rawQuery(
          '''
          SELECT
            li.item_type,
            li.item_id,
            li.level,
            li.front,
            li.reading,
            li.meaning,
            'new' AS state,
            NULL AS next_review,
            0.0 AS interval_days,
            2.5 AS ease_factor,
            0 AS repetitions,
            0 AS lapses,
            0 AS learned
          FROM learning_items li
          LEFT JOIN review_state rs
            ON li.item_type = rs.item_type
           AND li.item_id = rs.item_id
          WHERE li.level = ?
            AND rs.item_id IS NULL
          ORDER BY
            CASE li.item_type
              WHEN 'vocab' THEN 1
              WHEN 'kanji' THEN 2
              WHEN 'grammar' THEN 3
              ELSE 4
            END,
            li.item_id ASC
          LIMIT ?
          ''',
          [level, newLimit * 3],
        );

        for (final row in fallback) {
          final key = '${row['item_type']}:${row['item_id']}';
          if (!excluded.contains(key)) {
            newRows.add(row);
            excluded.add(key);
          }
          if (newRows.length >= newLimit) break;
        }
      }
    } else {
      final rows = await db.rawQuery(
        '''
        SELECT
          li.item_type,
          li.item_id,
          li.level,
          li.front,
          li.reading,
          li.meaning,
          'new' AS state,
          NULL AS next_review,
          0.0 AS interval_days,
          2.5 AS ease_factor,
          0 AS repetitions,
          0 AS lapses,
          0 AS learned
        FROM learning_items li
        LEFT JOIN review_state rs
          ON li.item_type = rs.item_type
         AND li.item_id = rs.item_id
        WHERE li.level = ?
          AND li.item_type = ?
          AND rs.item_id IS NULL
        ORDER BY li.item_id ASC
        LIMIT ?
        ''',
        [level, studyType, newLimit],
      );
      newRows.addAll(rows);
    }

    final seen = <String>{};
    final seenVocabularyFronts = <String>{};
    final result = <StudyItem>[];

    void addRows(List<Map<String, Object?>> rows) {
      for (final row in rows) {
        final item = StudyItem.fromMap(Map<String, dynamic>.from(row));
        final key = '${item.type}:${item.id}';

        if (!seen.add(key)) continue;

        // Keep distinct database entries, but avoid showing the same written
        // vocabulary expression twice inside one generated session.
        if (item.type == 'vocab') {
          final frontKey = item.front.trim();
          if (!seenVocabularyFronts.add(frontKey)) continue;
        }

        result.add(item);
      }
    }

    addRows(dueRows);
    addRows(learningRows);
    addRows(newRows.take(newLimit).toList());

    return result;
  }

  static Future<void> setLearned(
    StudyItem item, {
    required bool learned,
  }) async {
    final db = await database;

    final existing = await db.query(
      'review_state',
      where: 'item_type = ? AND item_id = ?',
      whereArgs: [item.type, item.id],
      limit: 1,
    );

    if (existing.isEmpty) {
      if (!learned) return;

      // Manual "learned" is intentionally independent from SRS progress.
      // A brand-new item gets a neutral review_state row only so the learned
      // flag can be persisted without pretending that a review happened.
      await db.insert('review_state', {
        'item_type': item.type,
        'item_id': item.id,
        'state': 'new',
        'last_review': null,
        'next_review': null,
        'interval_days': 0.0,
        'ease_factor': 2.5,
        'repetitions': 0,
        'lapses': 0,
        'steps_remaining': 0,
        'learned': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return;
    }

    final row = existing.first;
    final state = (row['state'] ?? 'new').toString();
    final repetitions = (row['repetitions'] as num?)?.toInt() ?? 0;
    final lastReview = row['last_review'];
    final nextReview = row['next_review'];

    final isManualOnlyState =
        state == 'new' &&
        repetitions == 0 &&
        lastReview == null &&
        nextReview == null;

    if (!learned && isManualOnlyState) {
      // If this row only existed because the user manually marked a brand-new
      // item as learned, remove it when unmarking so it becomes truly "new"
      // again and can enter the SRS normally later.
      await db.delete(
        'review_state',
        where: 'item_type = ? AND item_id = ?',
        whereArgs: [item.type, item.id],
      );
      return;
    }

    // Existing SRS history is preserved. Only the independent learned flag
    // changes, so unmarking lets the item resume from its previous SRS state.
    await db.update(
      'review_state',
      {'learned': learned ? 1 : 0},
      where: 'item_type = ? AND item_id = ?',
      whereArgs: [item.type, item.id],
    );
  }

  static Future<bool> isLearned(StudyItem item) async {
    final db = await database;
    final rows = await db.query(
      'review_state',
      columns: ['learned'],
      where: 'item_type = ? AND item_id = ?',
      whereArgs: [item.type, item.id],
      limit: 1,
    );

    if (rows.isEmpty) return false;
    return (rows.first['learned'] as num?)?.toInt() == 1;
  }

  static Future<Map<String, dynamic>?> getItemDetails(StudyItem item) async {
    final db = await database;

    if (item.type == 'vocab') {
      final rows = await db.query(
        'vocabulary',
        where: 'id = ?',
        whereArgs: [item.id],
        limit: 1,
      );

      if (rows.isEmpty) {
        return null;
      }

      final examples = await db.query(
        'vocabulary_examples',
        where: 'vocabulary_id = ?',
        whereArgs: [item.id],
        limit: 3,
      );

      final linkedKanji = await db.rawQuery(
        '''
        SELECT
          k.id,
          k.kanji,
          k.level,
          k.reading,
          k.meaning,
          vk.position
        FROM vocabulary_kanji vk
        JOIN kanji k ON k.id = vk.kanji_id
        WHERE vk.vocabulary_id = ?
        ORDER BY vk.position ASC
        ''',
        [item.id],
      );

      return {
        ...Map<String, dynamic>.from(rows.first),
        'examples': examples
            .map((row) => Map<String, dynamic>.from(row))
            .toList(),
        'kanji': linkedKanji
            .map((row) => Map<String, dynamic>.from(row))
            .toList(),
      };
    }

    if (item.type == 'kanji') {
      final rows = await db.query(
        'kanji',
        where: 'id = ?',
        whereArgs: [item.id],
        limit: 1,
      );

      if (rows.isEmpty) {
        return null;
      }

      final examples = await db.query(
        'kanji_examples',
        where: 'kanji_id = ?',
        whereArgs: [item.id],
        limit: 6,
      );

      final metadataRows = await db.query(
        'kanji_metadata',
        where: 'kanji_id = ?',
        whereArgs: [item.id],
        limit: 1,
      );

      final linkedVocabulary = await db.rawQuery(
        '''
        SELECT
          v.id,
          v.expression,
          v.reading,
          v.meaning,
          v.level,
          vk.position
        FROM vocabulary_kanji vk
        JOIN vocabulary v ON v.id = vk.vocabulary_id
        WHERE vk.kanji_id = ?
        ORDER BY vk.position ASC, v.id ASC
        LIMIT 20
        ''',
        [item.id],
      );

      return {
        ...Map<String, dynamic>.from(rows.first),
        'metadata': metadataRows.isEmpty
            ? null
            : Map<String, dynamic>.from(metadataRows.first),
        'examples': examples
            .map((row) => Map<String, dynamic>.from(row))
            .toList(),
        'vocabulary': linkedVocabulary
            .map((row) => Map<String, dynamic>.from(row))
            .toList(),
      };
    }

    if (item.type == 'grammar') {
      final rows = await db.query(
        'grammar',
        where: 'id = ?',
        whereArgs: [item.id],
        limit: 1,
      );

      if (rows.isEmpty) {
        return null;
      }

      final examples = await db.query(
        'grammar_examples',
        where: 'grammar_id = ?',
        whereArgs: [item.id],
        limit: 4,
      );

      return {
        ...Map<String, dynamic>.from(rows.first),
        'examples': examples
            .map((row) => Map<String, dynamic>.from(row))
            .toList(),
      };
    }

    if (item.type == 'kana') {
      final rows = await db.query(
        'kana',
        where: 'id = ?',
        whereArgs: [item.id],
        limit: 1,
      );

      if (rows.isEmpty) {
        return null;
      }

      return {
        ...Map<String, dynamic>.from(rows.first),
        'examples': const <Map<String, dynamic>>[],
      };
    }

    return null;
  }
}
