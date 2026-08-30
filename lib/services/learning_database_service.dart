import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/learning_vocabulary.dart';

/// Read-only access to the curated N4 vocabulary content used by LEARN.
///
/// This database is intentionally separate from the app's historical
/// Study/Review database. It contains learning CONTENT only; user progress
/// lives in a different local database.
class LearningDatabaseService {
  LearningDatabaseService._();

  static const String _assetPath = 'assets/database/jlpt_n4_learning.sqlite';
  static const String _databaseName = 'jlpt_n4_learning.sqlite';

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

    final newInitialization = _openDatabase();
    _databaseInitialization = newInitialization;
    return newInitialization;
  }

  /// The bundled content database contains no user progress, so it is safe
  /// to refresh the local copy from the asset whenever this service is
  /// initialized in a new app process.
  static Future<Database> _openDatabase() async {
    Database? db;

    try {
      final databasesPath = await getDatabasesPath();
      final databasePath = join(databasesPath, _databaseName);

      final data = await rootBundle.load(_assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      await Directory(dirname(databasePath)).create(recursive: true);

      if (await databaseExists(databasePath)) {
        await deleteDatabase(databasePath);
      }

      await File(databasePath).writeAsBytes(bytes, flush: true);

      db = await openDatabase(databasePath, readOnly: true);

      await _validateDatabase(db);

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

  static Future<void> _validateDatabase(Database db) async {
    final viewRows = await db.rawQuery("""
      SELECT name
      FROM sqlite_master
      WHERE type = 'view'
        AND name IN ('learn_vocabulary', 'extended_vocabulary')
      """);

    final availableViews = viewRows
        .map((row) => row['name']?.toString())
        .whereType<String>()
        .toSet();

    if (!availableViews.contains('learn_vocabulary')) {
      throw const FormatException(
        'The N4 LEARN database does not contain learn_vocabulary.',
      );
    }

    final defaultCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM learn_vocabulary'),
        ) ??
        0;

    if (defaultCount <= 0) {
      throw const FormatException(
        'The N4 LEARN database contains no active course vocabulary.',
      );
    }
  }

  /// Default LEARN course: active CORE + STANDARD vocabulary.
  static Future<List<LearningVocabulary>> getVocabulary({
    int? limit,
    int offset = 0,
  }) async {
    final db = await database;

    final rows = await db.query(
      'learn_vocabulary',
      orderBy: 'learning_order ASC',
      limit: limit,
      offset: limit == null ? null : offset,
    );

    return _mapVocabularyRows(rows);
  }

  static Future<List<LearningVocabulary>> getCoreVocabulary({
    int? limit,
    int offset = 0,
  }) async {
    return _getVocabularyByPriority(
      priority: 'CORE',
      limit: limit,
      offset: offset,
    );
  }

  static Future<List<LearningVocabulary>> getStandardVocabulary({
    int? limit,
    int offset = 0,
  }) async {
    return _getVocabularyByPriority(
      priority: 'STANDARD',
      limit: limit,
      offset: offset,
    );
  }

  static Future<List<LearningVocabulary>> getExtendedVocabulary({
    int? limit,
    int offset = 0,
  }) async {
    final db = await database;

    final rows = await db.query(
      'extended_vocabulary',
      orderBy: 'learning_order ASC',
      limit: limit,
      offset: limit == null ? null : offset,
    );

    return _mapVocabularyRows(rows);
  }

  static Future<List<LearningVocabulary>> _getVocabularyByPriority({
    required String priority,
    int? limit,
    int offset = 0,
  }) async {
    final db = await database;

    final rows = await db.query(
      'learn_vocabulary',
      where: 'priority = ?',
      whereArgs: [priority],
      orderBy: 'learning_order ASC',
      limit: limit,
      offset: limit == null ? null : offset,
    );

    return _mapVocabularyRows(rows);
  }

  static Future<LearningVocabulary?> getVocabularyById(
    String vocabularyId,
  ) async {
    final db = await database;

    final rows = await db.query(
      'vocabulary',
      where: 'id = ?',
      whereArgs: [vocabularyId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return LearningVocabulary.fromMap(Map<String, dynamic>.from(rows.first));
  }

  static Future<List<LearningVocabulary>> getVocabularyByIds(
    Iterable<String> vocabularyIds,
  ) async {
    final ids = vocabularyIds.toList(growable: false);

    if (ids.isEmpty) {
      return const <LearningVocabulary>[];
    }

    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');

    final rows = await db.rawQuery("""
      SELECT *
      FROM vocabulary
      WHERE id IN ($placeholders)
      ORDER BY learning_order ASC
      """, ids);

    return _mapVocabularyRows(rows);
  }

  static Future<Map<String, int>> getCourseCounts() async {
    final db = await database;

    final core =
        Sqflite.firstIntValue(
          await db.rawQuery("""
            SELECT COUNT(*)
            FROM learn_vocabulary
            WHERE priority = 'CORE'
            """),
        ) ??
        0;

    final standard =
        Sqflite.firstIntValue(
          await db.rawQuery("""
            SELECT COUNT(*)
            FROM learn_vocabulary
            WHERE priority = 'STANDARD'
            """),
        ) ??
        0;

    final extended =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM extended_vocabulary'),
        ) ??
        0;

    return {
      'core': core,
      'standard': standard,
      'default': core + standard,
      'extended': extended,
    };
  }

  static Future<Map<String, String>> getMetadata() async {
    final db = await database;

    final rows = await db.query('metadata');
    final result = <String, String>{};

    for (final row in rows) {
      final key = row['key']?.toString();
      final value = row['value']?.toString();

      if (key != null && value != null) {
        result[key] = value;
      }
    }

    return result;
  }

  static Future<List<LearningVocabulary>> searchVocabulary(
    String query, {
    int limit = 30,
  }) async {
    final normalized = query.trim();

    if (normalized.isEmpty) {
      return const <LearningVocabulary>[];
    }

    final db = await database;
    final pattern = '%$normalized%';

    final rows = await db.rawQuery(
      """
      SELECT *
      FROM learn_vocabulary
      WHERE expression LIKE ?
         OR reading LIKE ?
         OR meaning LIKE ?
      ORDER BY
        CASE
          WHEN expression = ? THEN 0
          WHEN reading = ? THEN 1
          ELSE 2
        END,
        learning_order ASC
      LIMIT ?
      """,
      [pattern, pattern, pattern, normalized, normalized, limit],
    );

    return _mapVocabularyRows(rows);
  }

  static List<LearningVocabulary> _mapVocabularyRows(
    List<Map<String, Object?>> rows,
  ) {
    return rows
        .map(
          (row) => LearningVocabulary.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
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
