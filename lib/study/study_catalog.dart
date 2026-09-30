export '../somatome/lesson_catalog.dart';

import '../somatome/lesson_catalog.dart';
import '../n3/n3_catalog.dart';
import '../shinkanzen_n4/shinkanzen_n4_catalog.dart';
import 'book_catalog.dart';
import 'supplement_catalog.dart';

abstract final class StudyCatalog {
  static String activeLevel = 'N4';
  static String activeBookId = BookCatalog.somatomeN4.id;

  static StudyBook get activeBook => BookCatalog.forId(activeBookId);

  static List<SessionInfo> get sessions {
    switch (activeBookId) {
      case 'shinkanzen_n4_dokkai':
        return ShinKanzenN4ReadingCatalog.sessions;
      case 'shinkanzen_n3_grammar':
        return N3Catalog.sessions;
      case 'somatome_n4_kanji':
      case 'somatome_n4_vocabulary':
      case 'shinkanzen_n4_kanji':
      case 'shinkanzen_n4_vocabulary':
      case 'shinkanzen_n3_kanji':
      case 'shinkanzen_n3_vocabulary':
        return SupplementCatalog.sessionsFor(activeBookId);
      case 'somatome_n4':
      default:
        return LessonCatalog.sessions;
    }
  }

  static int get totalSessions => sessions.length;

  static int get totalBlocks {
    if (BookCatalog.forId(activeBookId).category != 'course') return 4;
    switch (activeBookId) {
      case 'shinkanzen_n4_dokkai':
        return 4;
      case 'shinkanzen_n3_grammar':
        return 8;
      case 'somatome_n4':
      default:
        return 5;
    }
  }

  static String get blockLabel =>
      BookCatalog.forId(activeBookId).category != 'course'
          ? 'Semana'
          : activeBookId == 'shinkanzen_n4_dokkai'
              ? 'Parte'
              : activeBookId == 'shinkanzen_n3_grammar'
                  ? 'Bloque'
                  : 'Semana';

  static LessonPacket buildPacket(SessionInfo session) {
    if (BookCatalog.forId(activeBookId).category != 'course') {
      return SupplementCatalog.buildPacket(session, activeBookId);
    }
    switch (activeBookId) {
      case 'shinkanzen_n4_dokkai':
        return ShinKanzenN4ReadingCatalog.buildPacket(session);
      case 'shinkanzen_n3_grammar':
        return N3Catalog.buildPacket(session);
      case 'somatome_n4':
      default:
        return LessonCatalog.buildPacket(session);
    }
  }
}
