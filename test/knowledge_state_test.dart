import 'package:flutter_test/flutter_test.dart';

import 'package:jlpt_study/models/knowledge_state.dart';

void main() {
  test('overall mastery ignores dimensions that have not been measured', () {
    final state = KnowledgeState(
      itemType: 'vocab',
      itemId: 1,
      mastery: {
        KnowledgeDimension.recognition: 0.8,
        KnowledgeDimension.meaning: 0.6,
        KnowledgeDimension.reading: 0.4,
        KnowledgeDimension.listening: 0.0,
        KnowledgeDimension.production: 0.0,
        KnowledgeDimension.context: 0.0,
      },
      exposure: {
        KnowledgeDimension.recognition: 3,
        KnowledgeDimension.meaning: 2,
        KnowledgeDimension.reading: 1,
        KnowledgeDimension.listening: 0,
        KnowledgeDimension.production: 0,
        KnowledgeDimension.context: 0,
      },
      attempts: 3,
      correct: 3,
      lapses: 0,
      confidence: 0.9,
    );

    expect(state.overallMastery, closeTo(0.6, 0.0001));
  });

  test('dimension without exposure remains available but unmeasured', () {
    final state = KnowledgeState(
      itemType: 'kana',
      itemId: 1,
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

    expect(state.overallMastery, 0);
    expect(state.exposure[KnowledgeDimension.listening], 0);
  });
}
