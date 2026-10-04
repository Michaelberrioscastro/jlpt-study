import 'dart:math';

import '../models/knowledge_state.dart';
import '../models/lesson_models.dart';
import '../models/study_item.dart';
import 'adaptive_engine.dart';
import 'database_service.dart';
import 'knowledge_service.dart';

class LessonEngine {
  LessonEngine._();

  static final Random _random = Random();

  static Future<LessonSession> createSession({
    required String level,
    String? itemType,
    int length = 10,
  }) async {
    final recommendations = await AdaptiveEngine.recommend(
      level: level,
      itemType: itemType,
      limit: max(length * 2, 20),
    );

    final exercises = <LessonExercise>[];
    final used = <String>{};

    for (final row in recommendations) {
      if (exercises.length >= length) break;

      final key = '${row['item_type']}:${row['item_id']}';
      if (!used.add(key)) continue;

      final exercise = await _buildExercise(row);
      if (exercise != null) exercises.add(exercise);
    }

    return LessonSession(
      id: 'lesson_${DateTime.now().microsecondsSinceEpoch}',
      level: level,
      phase: _phaseFor(exercises),
      exercises: exercises,
      createdAt: DateTime.now(),
    );
  }

  static LessonPhase _phaseFor(List<LessonExercise> exercises) {
    if (exercises.isEmpty) return LessonPhase.complete;
    if (exercises.every((e) => e.isReview)) return LessonPhase.review;
    if (exercises.length <= 2) return LessonPhase.reinforcement;
    return LessonPhase.newContent;
  }

  static Future<LessonExercise?> _buildExercise(
    Map<String, dynamic> row,
  ) async {
    final itemType = row['item_type'].toString();
    final itemId = (row['item_id'] as num).toInt();
    final front = (row['front'] ?? '').toString();
    final reading = (row['reading'] ?? '').toString();
    final meaning = (row['meaning'] ?? '').toString();
    final isReview = row['srs_state'] != 'new';

    final state = await KnowledgeService.getState(
      itemType: itemType,
      itemId: itemId,
    );

    final dimension = _weakestDimension(state, itemType);
    final item = StudyItem(
      id: itemId,
      type: itemType,
      level: row['level'].toString(),
      front: front,
      reading: reading,
      meaning: meaning,
      state: row['srs_state']?.toString() ?? 'new',
    );
    final details = await DatabaseService.getItemDetails(item);

    switch (dimension) {
      case KnowledgeDimension.recognition:
        return _choice(
          row: row,
          type: ExerciseType.recognitionChoice,
          dimension: dimension,
          prompt: '¿Qué significa $front?',
          answer: meaning,
          distractors: _distractors(row, 'meaning'),
          isReview: isReview,
        );
      case KnowledgeDimension.meaning:
        return _choice(
          row: row,
          type: ExerciseType.meaningChoice,
          dimension: dimension,
          prompt: 'Elige la palabra japonesa para: $meaning',
          answer: front,
          distractors: _distractors(row, 'front'),
          isReview: isReview,
        );
      case KnowledgeDimension.reading:
        return _choice(
          row: row,
          type: ExerciseType.readingChoice,
          dimension: dimension,
          prompt: '¿Cuál es la lectura de $front?',
          answer: reading,
          distractors: _distractors(row, 'reading'),
          isReview: isReview,
        );
      case KnowledgeDimension.context:
        final examples = details?['examples'];
        if (examples is List && examples.isNotEmpty) {
          final example = Map<String, dynamic>.from(examples.first);
          final sentence = (example['japanese'] ??
                  example['sentence'] ??
                  example['example'] ??
                  front)
              .toString();
          return LessonExercise(
            id: _id(itemType, itemId, ExerciseType.contextChoice),
            itemType: itemType,
            itemId: itemId,
            type: ExerciseType.contextChoice,
            dimension: dimension,
            prompt: '¿Qué opción encaja mejor en este contexto?\n$sentence',
            answer: front,
            options: [front],
            difficulty: 3,
            isReview: isReview,
          );
        }
        return _choice(
          row: row,
          type: ExerciseType.meaningChoice,
          dimension: dimension,
          prompt: 'Relaciona $front con su significado.',
          answer: meaning,
          distractors: _distractors(row, 'meaning'),
          isReview: isReview,
        );
      case KnowledgeDimension.listening:
      case KnowledgeDimension.production:
        return _choice(
          row: row,
          type: ExerciseType.meaningChoice,
          dimension: dimension,
          prompt: 'Refuerzo: identifica $front.',
          answer: meaning,
          distractors: _distractors(row, 'meaning'),
          isReview: isReview,
        );
    }
  }

  static KnowledgeDimension _weakestDimension(
    KnowledgeState? state,
    String itemType,
  ) {
    if (state == null) {
      return itemType == 'kanji'
          ? KnowledgeDimension.meaning
          : KnowledgeDimension.recognition;
    }

    final measured = KnowledgeDimension.values
        .where((d) => (state.exposure[d] ?? 0) > 0)
        .toList();

    if (measured.isEmpty) {
      return itemType == 'kanji'
          ? KnowledgeDimension.meaning
          : KnowledgeDimension.recognition;
    }

    return measured.reduce(
      (a, b) => state.dimension(a) <= state.dimension(b) ? a : b,
    );
  }

  static Future<LessonExercise> _choice({
    required Map<String, dynamic> row,
    required ExerciseType type,
    required KnowledgeDimension dimension,
    required String prompt,
    required String answer,
    required Future<List<String>> distractors,
    required bool isReview,
  }) async {
    final values = <String>{answer};
    values.addAll(await distractors);
    final options = values.where((value) => value.isNotEmpty).take(4).toList();
    options.shuffle(_random);

    return LessonExercise(
      id: _id(
        row['item_type'].toString(),
        (row['item_id'] as num).toInt(),
        type,
      ),
      itemType: row['item_type'].toString(),
      itemId: (row['item_id'] as num).toInt(),
      type: type,
      dimension: dimension,
      prompt: prompt,
      answer: answer,
      options: options,
      difficulty: isReview ? 2 : 1,
      isReview: isReview,
    );
  }

  static Future<List<String>> _distractors(
    Map<String, dynamic> row,
    String field,
  ) async {
    final db = await DatabaseService.database;
    final type = row['item_type'].toString();
    final level = row['level'].toString();

    if (!{'front', 'reading', 'meaning'}.contains(field)) return [];

    final result = await db.rawQuery(
      '''
      SELECT $field AS value
      FROM learning_items
      WHERE item_type = ?
        AND level = ?
        AND item_id != ?
        AND $field IS NOT NULL
        AND TRIM($field) != ''
      ORDER BY RANDOM()
      LIMIT 8
      ''',
      [type, level, row['item_id']],
    );

    return result
        .map((r) => r['value'].toString())
        .where((v) => v.isNotEmpty)
        .toList();
  }

  static Future<KnowledgeState> submitAnswer({
    required LessonExercise exercise,
    required bool correct,
    int responseMs = 0,
  }) {
    return KnowledgeService.recordPerformance(
      itemType: exercise.itemType,
      itemId: exercise.itemId,
      correct: correct,
      dimensions: [exercise.dimension],
      difficulty: exercise.difficulty / 4.0,
      responseMs: responseMs,
    );
  }

  static String _id(String type, int id, ExerciseType exerciseType) =>
      '$type:$id:${exerciseType.name}';
}
