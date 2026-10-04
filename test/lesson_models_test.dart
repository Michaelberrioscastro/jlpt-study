import 'package:flutter_test/flutter_test.dart';

import '../lib/models/knowledge_state.dart';
import '../lib/models/lesson_models.dart';

void main() {
  test('lesson exercise preserves adaptive dimension and answer metadata', () {
    const exercise = LessonExercise(
      id: 'vocab:1:meaningChoice',
      itemType: 'vocab',
      itemId: 1,
      type: ExerciseType.meaningChoice,
      dimension: KnowledgeDimension.meaning,
      prompt: 'Elige la palabra japonesa para: comer',
      answer: '食べる',
      options: ['食べる', '飲む', '見る', '行く'],
      difficulty: 2,
    );

    expect(exercise.dimension, KnowledgeDimension.meaning);
    expect(exercise.options, contains(exercise.answer));
    expect(exercise.toMap()['type'], 'meaningChoice');
  });

  test('lesson session reports exercise count', () {
    const session = LessonSession(
      id: 'lesson-test',
      level: 'N5',
      phase: LessonPhase.newContent,
      exercises: [],
      createdAt: DateTime.utc(2026, 1, 1),
    );

    expect(session.total, 0);
  });
}
