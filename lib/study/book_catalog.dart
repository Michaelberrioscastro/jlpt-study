class StudyBook {
  final String id;
  final String level;
  final String title;
  final String shortTitle;
  final String subtitle;
  final String description;

  const StudyBook({
    required this.id,
    required this.level,
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.description,
  });
}

abstract final class BookCatalog {
  static const somatomeN4 = StudyBook(
    id: 'somatome_n4',
    level: 'N4',
    title: '日本語総まとめ N4',
    shortTitle: '総まとめ N4',
    subtitle: 'Gramática · Reading · Listening',
    description: 'Curso N4 organizado en seis semanas.',
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

  static const books = <StudyBook>[
    somatomeN4,
    shinKanzenN4Reading,
    shinKanzenN3Grammar,
  ];

  static List<StudyBook> forLevel(String level) =>
      books.where((book) => book.level == level).toList(growable: false);

  static StudyBook forId(String id) => books.firstWhere((book) => book.id == id);

  static StudyBook defaultForLevel(String level) =>
      level == 'N3' ? shinKanzenN3Grammar : somatomeN4;
}
