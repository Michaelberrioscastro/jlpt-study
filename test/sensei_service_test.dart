import 'package:flutter_test/flutter_test.dart';
import 'package:jlpt_study/somatome/sensei_service.dart';

void main() {
  test('explains common grammar patterns', () {
    final reply = SenseiService.answer('Que significa ほど?', level: 'N4');

    expect(reply.text, contains('ほど'));
    expect(reply.text, contains('grado'));
  });

  test('finds content from the active course catalog', () {
    final reply = SenseiService.answer('antes de las 9', level: 'N4');

    expect(reply.text, contains('sesiones'));
  });

  test('keeps unknown questions conversational', () {
    final reply = SenseiService.answer('Explícame una duda muy específica', level: 'N4');

    expect(reply.text, contains('no encuentro'));
    expect(reply.suggestions, isNotEmpty);
  });

  test('uses the visible lesson context for contextual hints', () {
    final reply = SenseiService.answer(
      'Dame una pista de esto',
      level: 'N4',
      contextDescription: 'Pregunta actual: 9時までに来てください。 Foco: までに.',
    );

    expect(reply.text, contains('9時までに来てください'));
    expect(reply.text, contains('Fijate'));
  });
}
