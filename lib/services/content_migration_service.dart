import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class ContentMigrationService {
  ContentMigrationService._();

  static const _migrationKey = 'content_data_v1';
  static const _vocabularyAsset = 'assets/data/jlpt_vocab.csv';
  static const _kanjiAsset = 'assets/data/anchorI_kanji.json';

  static Future<void> migrate(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS content_sources (
        source_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        license TEXT,
        url TEXT,
        version TEXT,
        imported_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vocabulary_sources (
        source_id TEXT NOT NULL,
        external_key TEXT NOT NULL,
        vocabulary_id INTEGER NOT NULL,
        PRIMARY KEY(source_id, external_key)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS kanji_metadata (
        kanji_id INTEGER PRIMARY KEY,
        strokes INTEGER,
        radical_number INTEGER,
        frequency INTEGER,
        begins INTEGER,
        used_in INTEGER,
        component_in INTEGER,
        description TEXT,
        source_id TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vocabulary_kanji (
        vocabulary_id INTEGER NOT NULL,
        kanji_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        PRIMARY KEY(vocabulary_id, kanji_id)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_vocabulary_kanji_kanji '
      'ON vocabulary_kanji(kanji_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_vocabulary_sources_vocab '
      'ON vocabulary_sources(vocabulary_id)',
    );

    final applied = await db.query(
      'app_migrations',
      where: 'migration_key = ?',
      whereArgs: [_migrationKey],
      limit: 1,
    );
    if (applied.isNotEmpty) return;

    await _registerSource(
      db,
      sourceId: 'jlpt_vocab_user',
      name: 'JLPT vocabulary source CSV',
      license: null,
      url: null,
    );
    await _registerSource(
      db,
      sourceId: 'anchori_jlpt_kanji',
      name: 'AnchorI JLPT Kanji Dictionary',
      license: 'MIT',
      url: 'https://github.com/AnchorI/jlpt-kanji-dictionary',
    );

    await db.transaction((txn) async {
      await _importKanji(txn);
      await _importVocabulary(txn);

      await txn.insert(
        'app_migrations',
        {
          'migration_key': _migrationKey,
          'applied_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });
  }

  static Future<void> _registerSource(
    Database db, {
    required String sourceId,
    required String name,
    required String? license,
    required String? url,
  }) async {
    await db.insert(
      'content_sources',
      {
        'source_id': sourceId,
        'name': name,
        'license': license,
        'url': url,
        'version': '1',
        'imported_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> _importKanji(Database db) async {
    final text = await rootBundle.loadString(_kanjiAsset);
    final decoded = jsonDecode(text);
    if (decoded is! Map || decoded['items'] is! List) {
      throw const FormatException('anchorI_kanji.json tiene un formato inválido.');
    }

    final columns = await _tableColumns(db, 'kanji');
    if (!columns.contains('kanji')) {
      throw StateError('La tabla kanji no contiene la columna kanji.');
    }

    for (final raw in decoded['items'] as List) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final character = (item['kanji'] ?? '').toString().trim();
      final level = (item['jlpt'] ?? '').toString().trim().toUpperCase();
      if (character.isEmpty || level.isEmpty) continue;

      final existing = await db.query(
        'kanji',
        columns: ['id'],
        where: 'kanji = ?',
        whereArgs: [character],
        limit: 1,
      );

      int kanjiId;
      if (existing.isNotEmpty) {
        kanjiId = (existing.first['id'] as num).toInt();
      } else {
        final values = <String, Object?>{
          'kanji': character,
          'level': level,
          'meaning': (item['description'] ?? '').toString(),
          'reading': '',
        };
        final insertValues = {
          for (final entry in values.entries)
            if (columns.contains(entry.key)) entry.key: entry.value,
        };
        kanjiId = await db.insert(
          'kanji',
          insertValues,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        if (kanjiId == 0) {
          final retry = await db.query(
            'kanji',
            columns: ['id'],
            where: 'kanji = ?',
            whereArgs: [character],
            limit: 1,
          );
          if (retry.isEmpty) continue;
          kanjiId = (retry.first['id'] as num).toInt();
        }
      }

      await db.insert(
        'kanji_metadata',
        {
          'kanji_id': kanjiId,
          'strokes': (item['strokes'] as num?)?.toInt(),
          'radical_number': (item['radical_number'] as num?)?.toInt(),
          'frequency': (item['frequency'] as num?)?.toInt(),
          'begins': (item['begins'] as num?)?.toInt(),
          'used_in': (item['used_in'] as num?)?.toInt(),
          'component_in': (item['component_in'] as num?)?.toInt(),
          'description': item['description']?.toString(),
          'source_id': 'anchori_jlpt_kanji',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> _importVocabulary(Database db) async {
    final text = await rootBundle.loadString(_vocabularyAsset);
    final rows = _parseCsv(text);
    if (rows.isEmpty) return;

    final header = rows.first.map((value) => value.trim()).toList();
    final index = <String, int>{
      for (var i = 0; i < header.length; i++) header[i].toLowerCase(): i,
    };

    String value(List<String> row, String key) {
      final position = index[key.toLowerCase()];
      if (position == null || position >= row.length) return '';
      return row[position].trim();
    }

    final columns = await _tableColumns(db, 'vocabulary');
    if (!columns.contains('expression') ||
        !columns.contains('reading') ||
        !columns.contains('meaning') ||
        !columns.contains('level')) {
      throw StateError(
        'La tabla vocabulary no tiene el esquema mínimo esperado.',
      );
    }

    for (final row in rows.skip(1)) {
      final expression = value(row, 'Original');
      final reading = value(row, 'Furigana');
      final meaning = value(row, 'English');
      final level = value(row, 'JLPT Level').toUpperCase();
      if (expression.isEmpty || level.isEmpty) continue;

      final externalKey =
          '$expression\u0001$reading\u0001$level\u0001$meaning';

      final mapped = await db.query(
        'vocabulary_sources',
        columns: ['vocabulary_id'],
        where: 'source_id = ? AND external_key = ?',
        whereArgs: ['jlpt_vocab_user', externalKey],
        limit: 1,
      );
      if (mapped.isNotEmpty) continue;

      final existing = await db.query(
        'vocabulary',
        columns: ['id'],
        where: 'expression = ? AND reading = ? AND level = ?',
        whereArgs: [expression, reading, level],
        limit: 1,
      );

      int vocabularyId;
      if (existing.isNotEmpty) {
        vocabularyId = (existing.first['id'] as num).toInt();
      } else {
        vocabularyId = await db.insert(
          'vocabulary',
          {
            'expression': expression,
            'reading': reading,
            'meaning': meaning,
            'level': level,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        if (vocabularyId == 0) {
          final retry = await db.query(
            'vocabulary',
            columns: ['id'],
            where: 'expression = ? AND reading = ? AND level = ?',
            whereArgs: [expression, reading, level],
            limit: 1,
          );
          if (retry.isEmpty) continue;
          vocabularyId = (retry.first['id'] as num).toInt();
        }
      }

      await db.insert(
        'vocabulary_sources',
        {
          'source_id': 'jlpt_vocab_user',
          'external_key': externalKey,
          'vocabulary_id': vocabularyId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      final kanjiChars = _kanjiCharacters(expression);
      for (var position = 0; position < kanjiChars.length; position++) {
        final matches = await db.query(
          'kanji',
          columns: ['id'],
          where: 'kanji = ?',
          whereArgs: [kanjiChars[position]],
          limit: 1,
        );
        if (matches.isEmpty) continue;

        await db.insert(
          'vocabulary_kanji',
          {
            'vocabulary_id': vocabularyId,
            'kanji_id': matches.first['id'],
            'position': position,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  static Future<Set<String>> _tableColumns(
    Database db,
    String table,
  ) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.map((row) => row['name'].toString()).toSet();
  }

  static List<String> _kanjiCharacters(String value) {
    return value.runes
        .map(String.fromCharCode)
        .where((character) {
          final code = character.runes.first;
          return (code >= 0x3400 && code <= 0x4dbf) ||
              (code >= 0x4e00 && code <= 0x9fff) ||
              (code >= 0xf900 && code <= 0xfaff);
        })
        .toList();
  }

  static List<List<String>> _parseCsv(String input) {
    final result = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;

    for (var i = 0; i < input.length; i++) {
      final character = input[i];

      if (quoted) {
        if (character == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          field.write(character);
        }
        continue;
      }

      if (character == '"') {
        quoted = true;
      } else if (character == ',') {
        row.add(field.toString());
        field = StringBuffer();
      } else if (character == '\n' || character == '\r') {
        if (character == '\r' &&
            i + 1 < input.length &&
            input[i + 1] == '\n') {
          i++;
        }
        row.add(field.toString());
        field = StringBuffer();
        if (row.any((value) => value.isNotEmpty)) {
          result.add(row);
        }
        row = <String>[];
      } else {
        field.write(character);
      }
    }

    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      if (row.any((value) => value.isNotEmpty)) {
        result.add(row);
      }
    }

    return result;
  }
}
