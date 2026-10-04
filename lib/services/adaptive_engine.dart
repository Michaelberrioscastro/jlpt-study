import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

class AdaptiveEngine {
  AdaptiveEngine._();

  static Future<List<Map<String, dynamic>>> recommend({
    required String level,
    String? itemType,
    int limit = 12,
  }) async {
    final db = await DatabaseService.database;
    final now = DateTime.now();
    final args = <Object?>[level];
    final typeClause = itemType == null ? '' : 'AND li.item_type = ?';

    if (itemType != null) args.add(itemType);

    final rows = await db.rawQuery(
      '''
      SELECT
        li.item_type,
        li.item_id,
        li.level,
        li.front,
        li.reading,
        li.meaning,
        COALESCE(ks.recognition, 0) AS recognition,
        COALESCE(ks.meaning, 0) AS meaning,
        COALESCE(ks.reading, 0) AS reading,
        COALESCE(ks.listening, 0) AS listening,
        COALESCE(ks.production, 0) AS production,
        COALESCE(ks.context, 0) AS context,
        COALESCE(ks.recognition_attempts, 0) AS recognition_attempts,
        COALESCE(ks.meaning_attempts, 0) AS meaning_attempts,
        COALESCE(ks.reading_attempts, 0) AS reading_attempts,
        COALESCE(ks.listening_attempts, 0) AS listening_attempts,
        COALESCE(ks.production_attempts, 0) AS production_attempts,
        COALESCE(ks.context_attempts, 0) AS context_attempts,
        COALESCE(rs.state, 'new') AS srs_state,
        rs.next_review
      FROM learning_items li
      LEFT JOIN knowledge_state ks
        ON ks.item_type = li.item_type
       AND ks.item_id = li.item_id
      LEFT JOIN review_state rs
        ON rs.item_type = li.item_type
       AND rs.item_id = li.item_id
      WHERE li.level = ?
        $typeClause
      ''',
      args,
    );

    double score(Map<String, dynamic> row) {
      final dimensions = [
        ('recognition', 'recognition_attempts'),
        ('meaning', 'meaning_attempts'),
        ('reading', 'reading_attempts'),
        ('listening', 'listening_attempts'),
        ('production', 'production_attempts'),
        ('context', 'context_attempts'),
      ];
      var masteryTotal = 0.0;
      var measuredDimensions = 0;

      for (final dimension in dimensions) {
        final attempts = (row[dimension.$2] as num?)?.toInt() ?? 0;
        if (attempts <= 0) continue;
        masteryTotal += (row[dimension.$1] as num?)?.toDouble() ?? 0.0;
        measuredDimensions++;
      }

      final mastery =
          measuredDimensions == 0 ? 0.0 : masteryTotal / measuredDimensions;

      final nextReview = row['next_review'] == null
          ? null
          : DateTime.tryParse(row['next_review'].toString());

      double urgency;
      if (nextReview == null) {
        urgency = 0.25;
      } else {
        final overdueHours = now.difference(nextReview).inMinutes / 60.0;
        urgency = overdueHours <= 0
            ? 0.15
            : (0.35 + overdueHours / 72.0).clamp(0.35, 1.0);
      }

      final weakness = 1 - mastery;
      final isNew = row['srs_state'] == 'new';
      final newBonus = isNew ? 0.12 : 0.0;

      return weakness * 0.55 + urgency * 0.33 + newBonus;
    }

    rows.sort((a, b) => score(b).compareTo(score(a)));
    return rows.take(limit).map(Map<String, dynamic>.from).toList();
  }
}
