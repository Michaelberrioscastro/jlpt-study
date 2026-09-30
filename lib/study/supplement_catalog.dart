import 'book_catalog.dart';
import '../somatome/lesson_catalog.dart';

abstract final class SupplementCatalog {
  static List<SessionInfo> sessionsFor(String bookId) {
    final kanji = bookId.endsWith('_kanji');
    final level = bookId.contains('_n3_') ? 'N3' : 'N4';
    final prefix = kanji ? 'KANJI' : 'VOCAB';
    final focus = kanji ? 'Kanji $level' : 'Vocabulario $level';
    final entries = kanji
        ? <String>['日・月・火', '水・木・金', '土・山・川', '人・入・出', '上・下・中', '大・小・多', '先・生・学', '校・時・間', '今・週・年']
        : <String>['Rutinas diarias', 'Personas y relaciones', 'Lugares y transporte', 'Tiempo y frecuencia', 'Comida y compras', 'Casa y objetos', 'Trabajo y estudio', 'Naturaleza y clima', 'Repaso acumulativo'];

    return List<SessionInfo>.generate(12, (index) {
      final week = index ~/ 3 + 1;
      final day = index % 3 + 1;
      final review = day == 3;
      final topic = entries[index % entries.length];
      return SessionInfo(
        id: '${bookId}_W${week.toString().padLeft(2, '0')}D$day',
        week: week,
        day: day,
        type: kanji ? 'kanji' : 'vocabulary',
        titleJa: review ? 'まとめ復習' : topic,
        titleEs: review
            ? 'Repaso de la semana $week.'
            : kanji
                ? 'Reconoce y escribe los kanji de $topic.'
                : 'Descubre vocabulario sobre $topic.',
        focus: review ? 'Repaso' : focus,
        pages: const <int>[],
        review: review,
        durationMinutes: review ? 15 : 10,
        xpReward: review ? 90 : 60,
      );
    });
  }

  static LessonPacket buildPacket(SessionInfo session, String bookId) {
    final kanji = bookId.endsWith('_kanji');
    final subject = kanji ? 'kanji' : 'vocabulario';
    final prompt = session.review
        ? 'Repaso de la semana ${session.week}'
        : session.titleEs;

    return LessonPacket(session, [
      TeachStep(
        label: session.review ? 'REPASO' : 'DESCUBRE',
        title: session.review ? 'Consolida lo aprendido' : 'Una pieza mas de tu japones',
        body: '$prompt\n\nEsta sesion complementa tu libro principal con $subject practico.',
        pattern: session.focus,
        exampleJa: session.titleJa,
        exampleEs: session.titleEs,
        tip: 'Vuelve a reconocerlo en contexto antes de pasar al siguiente nodo.',
      ),
      QuestionStep(
        id: '${session.id}-q1',
        title: 'Reconocimiento rapido',
        question: 'Que debes trabajar en esta sesion?\n\n${session.titleJa}',
        options: [session.focus, 'Una estructura aleatoria', 'Solo pronunciacion'],
        answer: 0,
        explanation: 'Esta sesion trabaja ${session.focus}.',
      ),
      QuestionStep(
        id: '${session.id}-q2',
        title: 'Fijalo en memoria',
        question: 'Cual es el objetivo de hoy?',
        options: [session.titleEs, 'Terminar cuanto antes', 'Memorizar sin contexto'],
        answer: 0,
        explanation: 'La meta es reconocer y recuperar el contenido en contexto.',
      ),
    ]);
  }

  static StudyBook bookFor(String bookId) => BookCatalog.forId(bookId);
}
