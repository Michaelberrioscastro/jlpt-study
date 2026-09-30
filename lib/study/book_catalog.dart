class StudyBook {
  final String id;
  final String level;
  final String title;
  final String shortTitle;
  final String subtitle;
  final String description;
  final String category;
  final String? parentBookId;
  final int sessionCount;

  const StudyBook({
    required this.id,
    required this.level,
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.description,
    this.category = 'course',
    this.parentBookId,
    this.sessionCount = 42,
  });
}

abstract final class BookCatalog {
  static const somatomeN4 = StudyBook(
    id: 'somatome_n4',
    level: 'N4',
    title: '日本語総まとめ N4',
    shortTitle: '総まとめ N4',
    subtitle: 'Gramática · Reading',
    description: 'Curso N4 organizado en cinco semanas.',
  );

  static const shinKanzenN4Reading = StudyBook(
    id: 'shinkanzen_n4_dokkai',
    level: 'N4',
    title: '新完全マスター 読解 N4',
    shortTitle: '新完全マスター N4',
    subtitle: 'Comprensión lectora',
    description: 'Entrenamiento de lectura, preguntas y simulacro N4.',
  );

  static const shinKanzenN3Grammar = StudyBook(
    id: 'shinkanzen_n3_grammar',
    level: 'N3',
    title: '新完全マスター 文法 N3',
    shortTitle: '新完全マスター N3',
    subtitle: 'Gramática',
    description: 'Curso de gramática N3 organizado por bloques.',
  );

  static const somatomeN4Kanji = StudyBook(
    id: 'somatome_n4_kanji',
    level: 'N4',
    title: '日本語総まとめ N4 · 漢字',
    shortTitle: 'Kanji N4',
    subtitle: 'Kanji esencial',
    description: 'Curso complementario de kanji para 日本語総まとめ N4.',
    category: 'kanji',
    parentBookId: 'somatome_n4',
    sessionCount: 12,
  );

  static const somatomeN4Vocabulary = StudyBook(
    id: 'somatome_n4_vocabulary',
    level: 'N4',
    title: '日本語総まとめ N4 · 語彙',
    shortTitle: 'Vocabulario N4',
    subtitle: 'Vocabulario esencial',
    description: 'Curso complementario de vocabulario para 日本語総まとめ N4.',
    category: 'vocabulary',
    parentBookId: 'somatome_n4',
    sessionCount: 12,
  );

  static const shinKanzenN4Kanji = StudyBook(
    id: 'shinkanzen_n4_kanji',
    level: 'N4',
    title: '新完全マスター N4 · 漢字',
    shortTitle: 'Kanji N4',
    subtitle: 'Kanji para lectura',
    description: 'Curso complementario de kanji para 新完全マスター 読解 N4.',
    category: 'kanji',
    parentBookId: 'shinkanzen_n4_dokkai',
    sessionCount: 12,
  );

  static const shinKanzenN4Vocabulary = StudyBook(
    id: 'shinkanzen_n4_vocabulary',
    level: 'N4',
    title: '新完全マスター N4 · 語彙',
    shortTitle: 'Vocabulario N4',
    subtitle: 'Vocabulario para lectura',
    description: 'Curso complementario de vocabulario para 新完全マスター 読解 N4.',
    category: 'vocabulary',
    parentBookId: 'shinkanzen_n4_dokkai',
    sessionCount: 12,
  );

  static const shinKanzenN3Kanji = StudyBook(
    id: 'shinkanzen_n3_kanji',
    level: 'N3',
    title: '新完全マスター N3 · 漢字',
    shortTitle: 'Kanji N3',
    subtitle: 'Kanji de consolidación',
    description: 'Curso complementario de kanji para 新完全マスター 文法 N3.',
    category: 'kanji',
    parentBookId: 'shinkanzen_n3_grammar',
    sessionCount: 12,
  );

  static const shinKanzenN3Vocabulary = StudyBook(
    id: 'shinkanzen_n3_vocabulary',
    level: 'N3',
    title: '新完全マスター N3 · 語彙',
    shortTitle: 'Vocabulario N3',
    subtitle: 'Vocabulario de consolidación',
    description: 'Curso complementario de vocabulario para 新完全マスター 文法 N3.',
    category: 'vocabulary',
    parentBookId: 'shinkanzen_n3_grammar',
    sessionCount: 12,
  );

  static const books = <StudyBook>[
    somatomeN4,
    shinKanzenN4Reading,
    shinKanzenN3Grammar,
    somatomeN4Kanji,
    somatomeN4Vocabulary,
    shinKanzenN4Kanji,
    shinKanzenN4Vocabulary,
    shinKanzenN3Kanji,
    shinKanzenN3Vocabulary,
  ];

  static List<StudyBook> forLevel(String level) =>
      books.where((book) => book.level == level).toList(growable: false);

  static StudyBook forId(String id) => books.firstWhere((book) => book.id == id);

  static StudyBook defaultForLevel(String level) =>
      level == 'N3' ? shinKanzenN3Grammar : somatomeN4;
}
