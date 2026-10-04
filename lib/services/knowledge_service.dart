import 'package:sqflite/sqflite.dart';

import '../models/knowledge_state.dart';
import 'database_service.dart';

class KnowledgeService {
  KnowledgeService._();

  static Future<KnowledgeState?> getState({
    required String itemType,
    required int itemId,
  }) async {
    final db = await DatabaseService.database;
    final rows = await db.query(
      'knowledge_state',
      where: 'item_type = ? AND item_id = ?',
      whereArgs: [itemType, itemId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return KnowledgeState.fromMap(Map<String, dynamic>.from(rows.first));
  }

  static Future<KnowledgeState> getOrCreate({
    required String itemType,
    required int itemId,
  }) async {
    final existing = await getState(itemType: itemType, itemId: itemId);
    if (existing != null) return existing;

    final state = KnowledgeState(
      itemType: itemType,
      itemId: itemId,
      mastery: {
        for (final dimension in KnowledgeDimension.values) dimension: 0.0,
      },
      exposure: {
        for (final dimension in KnowledgeDimension.values) dimension: 0,
      },
      attempts: 0,
      correct: 0,
      lapses: 0,
      confidence: 0,
    );

    final db = await DatabaseService.database;
    await db.insert(
      'knowledge_state',
      state.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return state;
  }

  static Future<KnowledgeState> recordPerformance({
    required String itemType,
    required int itemId,
    required bool correct,
    Iterable<KnowledgeDimension> dimensions = const [
      KnowledgeDimension.recognition,
      KnowledgeDimension.meaning,
      KnowledgeDimension.reading,
    ],
    double difficulty = 0.5,
    int responseMs = 0,
  }) async {
    final db = await DatabaseService.database;
    final current = await getOrCreate(itemType: itemType, itemId: itemId);
    final now = DateTime.now();

    final measured = dimensions.toSet();
    final normalizedDifficulty = difficulty.clamp(0.0, 1.0).toDouble();
    final step = correct
        ? 0.08 + normalizedDifficulty * 0.07
        : 0.14 + normalizedDifficulty * 0.08;

    final mastery = <KnowledgeDimension, double>{...current.mastery};
    final exposure = <KnowledgeDimension, int>{...current.exposure};

    for (final dimension in measured) {
      final old = mastery[dimension] ?? 0;
      exposure[dimension] = (exposure[dimension] ?? 0) + 1;
      mastery[dimension] = correct
          ? (old + step * (1 - old)).clamp(0.0, 1.0).toDouble()
          : (old - step * (0.35 + old * 0.65)).clamp(0.0, 1.0).toDouble();
    }

    final attempts = current.attempts + 1;
    final correctCount = current.correct + (correct ? 1 : 0);
    final lapses = current.lapses + (correct ? 0 : 1);
    final observedAccuracy = correctCount / attempts;
    final confidence = ((current.confidence * 0.8) +
            (observedAccuracy * 0.2) +
            (responseMs > 0 && responseMs < 2500 ? 0.03 : 0.0))
        .clamp(0.0, 1.0)
        .toDouble();

    final observedDimensions =
        measured.where((d) => (exposure[d] ?? 0) > 0).toList();
    final masteryAfter = observedDimensions.isEmpty
        ? current.overallMastery
        : observedDimensions
                .map((d) => mastery[d] ?? 0)
                .reduce((a, b) => a + b) /
            observedDimensions.length;

    await db.update(
      'knowledge_state',
      {
        'recognition': mastery[KnowledgeDimension.recognition],
        'meaning': mastery[KnowledgeDimension.meaning],
        'reading': mastery[KnowledgeDimension.reading],
        'listening': mastery[KnowledgeDimension.listening],
        'production': mastery[KnowledgeDimension.production],
        'context': mastery[KnowledgeDimension.context],
        'recognition_attempts': exposure[KnowledgeDimension.recognition] ?? 0,
        'meaning_attempts': exposure[KnowledgeDimension.meaning] ?? 0,
        'reading_attempts': exposure[KnowledgeDimension.reading] ?? 0,
        'listening_attempts': exposure[KnowledgeDimension.listening] ?? 0,
        'production_attempts': exposure[KnowledgeDimension.production] ?? 0,
        'context_attempts': exposure[KnowledgeDimension.context] ?? 0,
        'attempts': attempts,
        'correct': correctCount,
        'lapses': lapses,
        'confidence': confidence,
        'last_seen': now.toIso8601String(),
        'last_correct':
            correct ? now.toIso8601String() : current.lastCorrect?.toIso8601String(),
      },
      where: 'item_type = ? AND item_id = ?',
      whereArgs: [itemType, itemId],
    );

    await db.insert('knowledge_events', {
      'item_type': itemType,
      'item_id': itemId,
      'occurred_at': now.toIso8601String(),
      'event_type': correct ? 'correct' : 'incorrect',
      'dimensions_json': measured.map((e) => e.name).join(','),
      'difficulty': normalizedDifficulty,
      'response_ms': responseMs,
      'mastery_before': current.overallMastery,
      'mastery_after': masteryAfter,
    });

    return KnowledgeState(
      itemType: itemType,
      itemId: itemId,
      mastery: mastery,
      exposure: exposure,
      attempts: attempts,
      correct: correctCount,
      lapses: lapses,
      confidence: confidence,
      lastSeen: now,
      lastCorrect: correct ? now : current.lastCorrect,
    );
  }

  static Future<List<Map<String, dynamic>>> weakestItems({
    String? itemType,
    String? level,
    int limit = 20,
  }) async {
    final db = await DatabaseService.database;
    final args = <Object?>[];
    final conditions = <String>[];

    if (itemType != null) {
      conditions.add('ks.item_type = ?');
      args.add(itemType);
    }
    if (level != null) {
      conditions.add('li.level = ?');
      args.add(level);
    }

    final where = conditions.isEmpty ? '' : 'WHERE ' + conditions.join(' AND ');

    return db.rawQuery(
      '''
      SELECT
        ks.*,
        li.level,
        li.front,
        li.reading,
        li.meaning,
        (
          (CASE WHEN ks.recognition_attempts > 0 THEN ks.recognition ELSE 0 END) +
          (CASE WHEN ks.meaning_attempts > 0 THEN ks.meaning ELSE 0 END) +
          (CASE WHEN ks.reading_attempts > 0 THEN ks.reading ELSE 0 END) +
          (CASE WHEN ks.listening_attempts > 0 THEN ks.listening ELSE 0 END) +
          (CASE WHEN ks.production_attempts > 0 THEN ks.production ELSE 0 END) +
          (CASE WHEN ks.context_attempts > 0 THEN ks.context ELSE 0 END)
        ) /
        NULLIF(
          (CASE WHEN ks.recognition_attempts > 0 THEN 1 ELSE 0 END) +
          (CASE WHEN ks.meaning_attempts > 0 THEN 1 ELSE 0 END) +
          (CASE WHEN ks.reading_attempts > 0 THEN 1 ELSE 0 END) +
          (CASE WHEN ks.listening_attempts > 0 THEN 1 ELSE 0 END) +
          (CASE WHEN ks.production_attempts > 0 THEN 1 ELSE 0 END) +
          (CASE WHEN ks.context_attempts > 0 THEN 1 ELSE 0 END),
          0
        ) AS mastery
      FROM knowledge_state ks
      LEFT JOIN learning_items li
        ON li.item_type = ks.item_type
       AND li.item_id = ks.item_id
      $where
      ORDER BY mastery ASC, ks.last_seen ASC
      LIMIT ?
      ''',
      [...args, limit],
    );
  }
}
