/// Immutable vocabulary item used by the new LEARN module.
///
/// This model represents learning CONTENT only. User progress, mastery,
/// attempts and scheduling intentionally live in the separate LEARN progress
/// database.
class LearningVocabulary {
  final String id;
  final String level;
  final String expression;
  final String reading;
  final String meaning;

  final String? partOfSpeech;
  final List<String> additionalMeanings;
  final List<String> additionalReadings;

  final String? exampleJapanese;
  final String? exampleReading;
  final String? exampleEnglish;
  final String exampleSource;

  final List<String> audioFiles;

  final int sourceCount;
  final List<String> sourceDecks;
  final List<String> sourceNoteIds;

  final List<String> originalExpressions;
  final List<String> originalMeanings;
  final List<String> tags;

  final String classification;
  final String priority;
  final String confidence;

  final bool needsReview;
  final String? reviewNote;
  final bool active;

  final int learningOrder;

  final String? morphologyType;
  final String? attachmentPosition;

  const LearningVocabulary({
    required this.id,
    required this.level,
    required this.expression,
    required this.reading,
    required this.meaning,
    required this.partOfSpeech,
    required this.additionalMeanings,
    required this.additionalReadings,
    required this.exampleJapanese,
    required this.exampleReading,
    required this.exampleEnglish,
    required this.exampleSource,
    required this.audioFiles,
    required this.sourceCount,
    required this.sourceDecks,
    required this.sourceNoteIds,
    required this.originalExpressions,
    required this.originalMeanings,
    required this.tags,
    required this.classification,
    required this.priority,
    required this.confidence,
    required this.needsReview,
    required this.reviewNote,
    required this.active,
    required this.learningOrder,
    required this.morphologyType,
    required this.attachmentPosition,
  });

  factory LearningVocabulary.fromMap(Map<String, dynamic> map) {
    return LearningVocabulary(
      id: _requiredString(map['id'], 'id'),
      level: _requiredString(map['level'], 'level'),
      expression: _requiredString(map['expression'], 'expression'),
      reading: _requiredString(map['reading'], 'reading'),
      meaning: _requiredString(map['meaning'], 'meaning'),
      partOfSpeech: _nullableString(map['part_of_speech']),
      additionalMeanings: _splitPipeList(map['additional_meanings']),
      additionalReadings: _splitPipeList(map['additional_readings']),
      exampleJapanese: _nullableString(map['example_japanese']),
      exampleReading: _nullableString(map['example_reading']),
      exampleEnglish: _nullableString(map['example_english']),
      exampleSource: _nullableString(map['example_source']) ?? 'none',
      audioFiles: _splitPipeList(map['audio_files']),
      sourceCount: _intValue(map['source_count']),
      sourceDecks: _splitPipeList(map['source_decks']),
      sourceNoteIds: _splitPipeList(map['source_note_ids']),
      originalExpressions: _splitPipeList(map['original_expressions']),
      originalMeanings: _splitPipeList(map['original_meanings']),
      tags: _splitPipeList(map['tags']),
      classification: _nullableString(map['classification']) ?? 'KEEP_N4',
      priority: _nullableString(map['priority']) ?? 'STANDARD',
      confidence: _nullableString(map['confidence']) ?? 'REVIEW',
      needsReview: _boolValue(map['needs_review']),
      reviewNote: _nullableString(map['review_note']),
      active: _boolValue(map['active'], defaultValue: true),
      learningOrder: _intValue(map['learning_order']),
      morphologyType: _nullableString(map['morphology_type']),
      attachmentPosition: _nullableString(map['attachment_position']),
    );
  }

  bool get isCore => priority == 'CORE';

  bool get isStandard => priority == 'STANDARD';

  bool get isExtended => priority == 'EXTENDED';

  bool get hasExample =>
      exampleJapanese != null &&
      exampleJapanese!.isNotEmpty &&
      exampleEnglish != null &&
      exampleEnglish!.isNotEmpty;

  bool get hasExampleReading =>
      exampleReading != null && exampleReading!.isNotEmpty;

  bool get hasAudio => audioFiles.isNotEmpty;

  bool get hasAdditionalMeanings => additionalMeanings.isNotEmpty;

  bool get hasAdditionalReadings => additionalReadings.isNotEmpty;

  /// Primary display meaning for the first exposure screen.
  ///
  /// The curated database already stores the preferred teaching sense in
  /// [meaning], so LEARN should display this before optional additional senses.
  String get displayMeaning => meaning;

  /// Reading shown during the introduction stage.
  String get displayReading => reading;

  /// Whether this row belongs to the default LEARN course.
  bool get isDefaultCourseItem =>
      active && !needsReview && (isCore || isStandard);

  @override
  String toString() {
    return 'LearningVocabulary('
        'id: $id, '
        'expression: $expression, '
        'reading: $reading, '
        'priority: $priority, '
        'learningOrder: $learningOrder'
        ')';
  }

  static String _requiredString(Object? value, String fieldName) {
    final result = value?.toString().trim() ?? '';

    if (result.isEmpty) {
      throw FormatException(
        'Learning vocabulary row is missing required field: $fieldName',
      );
    }

    return result;
  }

  static String? _nullableString(Object? value) {
    final result = value?.toString().trim();

    if (result == null || result.isEmpty) {
      return null;
    }

    return result;
  }

  static int _intValue(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _boolValue(Object? value, {bool defaultValue = false}) {
    if (value == null) {
      return defaultValue;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value.toString().trim().toLowerCase();

    if (normalized == 'true' || normalized == '1') {
      return true;
    }

    if (normalized == 'false' || normalized == '0') {
      return false;
    }

    return defaultValue;
  }

  static List<String> _splitPipeList(Object? value) {
    final raw = _nullableString(value);

    if (raw == null) {
      return const [];
    }

    return raw
        .split('|')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }
}
