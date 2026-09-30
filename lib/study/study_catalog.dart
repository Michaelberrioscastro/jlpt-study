import '../somatome/lesson_catalog.dart';
import '../n3/n3_catalog.dart';

abstract final class StudyCatalog {
  static String activeLevel = 'N4';

  static List<SessionInfo> get sessions =>
      activeLevel == 'N3' ? N3Catalog.sessions : LessonCatalog.sessions;

  static int get totalSessions => sessions.length;

  static LessonPacket buildPacket(SessionInfo session) =>
      activeLevel == 'N3'
          ? N3Catalog.buildPacket(session)
          : LessonCatalog.buildPacket(session);
}