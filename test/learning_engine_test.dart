import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jlpt_study/study/learning_engine.dart';
import 'package:jlpt_study/somatome/lesson_catalog.dart';

void main() {
  group('LearningEngine', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('normalizes equivalent grammar concepts', () {
      expect(
        LearningEngine.normalizeConcept('うちに'),
        LearningEngine.normalizeConcept('～うちに'),
      );
      expect(
        LearningEngine.normalizeConcept('ておく'),
        LearningEngine.normalizeConcept('～ておく'),
      );
    });

    test('splits multi-concept focus into reusable tags', () {
      final concepts = LearningEngine.conceptsForFocus(
        'ておく / てしまう / ている',
      );

      expect(concepts, contains('～ておく'));
      expect(concepts, contains('～てしまう'));
      expect(concepts, contains('ている'));
    });

    test('creates due review state after an error', () async {
      final prefs = await SharedPreferences.getInstance();
      final engine = LearningEngine();

      await engine.load(prefs, 'N4');
      await engine.record(
        prefs: prefs,
        level: 'N4',
        conceptIds: const <String>['～うちに'],
        sessionId: 'W01D01',
        questionId: 'q1',
        correct: false,
        responseMs: 15000,
      );

      final record = engine.concept('～うちに');
      expect(record, isNotNull);
      expect(record!.attempts, 1);
      expect(record.correct, 0);
      expect(record.dueAt, isNotNull);
      expect(record.lastResponseMs, 15000);
    });

    test('builds a personalized plan after learning data exists', () async {
      final prefs = await SharedPreferences.getInstance();
      final engine = LearningEngine();

      await engine.load(prefs, 'N4');
      await engine.record(
        prefs: prefs,
        level: 'N4',
        conceptIds: const <String>['～うちに'],
        sessionId: 'W01D01',
        questionId: 'q1',
        correct: false,
      );

      final plan = engine.recommend(
        sessions: const <SessionInfo>[
          SessionInfo(
            id: 'W01D01',
            week: 1,
            day: 1,
            type: 'grammar',
            titleJa: 'テスト',
            titleEs: 'Prueba',
            focus: '～うちに',
            pages: <int>[1],
            review: false,
          ),
          SessionInfo(
            id: 'W01D02',
            week: 1,
            day: 2,
            type: 'grammar',
            titleJa: 'テスト2',
            titleEs: 'Prueba 2',
            focus: '～間に',
            pages: <int>[2],
            review: false,
          ),
        ],
        completedIds: const <String>{'W01D01'},
      );

      expect(plan.hasPlan, isTrue);
      expect(plan.conceptIds, contains('～うちに'));
      expect(plan.sessions, isNotEmpty);
    });
  });
}
