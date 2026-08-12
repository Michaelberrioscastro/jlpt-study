import 'package:sqflite/sqflite.dart';

import '../models/study_item.dart';
import 'database_service.dart';

enum ReviewRating { again, hard, good, easy }

class SrsService {
  SrsService._();

  static Future<void> review(StudyItem item, ReviewRating rating) async {
    final db = await DatabaseService.database;
    final now = DateTime.now();

    final rows = await db.query(
      'review_state',
      where: 'item_type = ? AND item_id = ?',
      whereArgs: [item.type, item.id],
      limit: 1,
    );

    final previous = rows.isEmpty ? null : rows.first;

    final oldState = (previous?['state'] ?? 'new').toString();

    final oldInterval = (previous?['interval_days'] as num?)?.toDouble() ?? 0.0;

    final oldLearned = (previous?['learned'] as num?)?.toInt() ?? 0;

    var ease = (previous?['ease_factor'] as num?)?.toDouble() ?? 2.5;

    var repetitions = (previous?['repetitions'] as num?)?.toInt() ?? 0;

    var lapses = (previous?['lapses'] as num?)?.toInt() ?? 0;

    late String newState;
    late double interval;
    late DateTime nextReview;

    var learned = oldLearned;

    switch (rating) {
      case ReviewRating.again:
        lapses += 1;
        repetitions = 0;

        ease = (ease - 0.20).clamp(1.3, 3.0).toDouble();

        newState = 'learning';
        interval = 0.0;

        nextReview = now.add(const Duration(minutes: 10));

        // Si fallaste una tarjeta que habías marcado
        // como aprendida, deja de contar como aprendida.
        learned = 0;

        break;

      case ReviewRating.hard:
        repetitions += 1;

        ease = (ease - 0.15).clamp(1.3, 3.0).toDouble();

        if (oldState == 'new' || oldState == 'learning') {
          newState = 'learning';
          interval = 0.0;

          nextReview = now.add(const Duration(hours: 8));
        } else {
          newState = 'review';

          interval = oldInterval <= 0 ? 1.0 : oldInterval * 1.2;

          nextReview = now.add(Duration(minutes: (interval * 1440).round()));
        }

        break;

      case ReviewRating.good:
        repetitions += 1;

        if (oldState == 'new' || oldState == 'learning') {
          interval = 1.0;
        } else {
          interval = (oldInterval * ease).clamp(1.0, 3650.0).toDouble();
        }

        newState = interval >= 21 ? 'mature' : 'review';

        nextReview = now.add(Duration(minutes: (interval * 1440).round()));

        break;

      case ReviewRating.easy:
        repetitions += 1;

        ease = (ease + 0.15).clamp(1.3, 3.0).toDouble();

        if (oldState == 'new' || oldState == 'learning') {
          interval = 4.0;
        } else {
          interval = (oldInterval * ease * 1.3).clamp(4.0, 3650.0).toDouble();
        }

        newState = interval >= 21 ? 'mature' : 'review';

        nextReview = now.add(Duration(minutes: (interval * 1440).round()));

        break;
    }

    await db.transaction((txn) async {
      await txn.insert('review_state', {
        'item_type': item.type,
        'item_id': item.id,
        'state': newState,
        'last_review': now.toIso8601String(),
        'next_review': nextReview.toIso8601String(),
        'interval_days': interval,
        'ease_factor': ease,
        'repetitions': repetitions,
        'lapses': lapses,
        'steps_remaining': newState == 'learning' ? 1 : 0,

        // Nuevo campo
        'learned': learned,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.insert('review_log', {
        'item_type': item.type,
        'item_id': item.id,
        'reviewed_at': now.toIso8601String(),
        'rating': rating.index + 1,
        'previous_state': oldState,
        'new_state': newState,
        'previous_interval': oldInterval,
        'new_interval': interval,
      });
    });
  }
}
