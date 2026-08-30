import 'dart:math' as math;

import '../models/learning_vocabulary.dart';
import 'learning_database_service.dart';
import 'learning_engine_service.dart';

enum LearningQuestionMode { multipleChoice, selfRecall }

enum LearningQuestionStyle {
  meaningChoice,
  readingChoice,
  contextMeaning,
  selfRecall,
}

/// UI-ready question data for one [LearningTask].
///
/// The question layer is intentionally separate from the scheduling engine:
/// - LearningEngineService decides WHAT skill should be practised.
/// - LearningQuestionService decides HOW to ask it clearly.
/// - The UI only renders this object and sends the result back to the engine.
class LearningQuestion {
  final LearningTask task;
  final LearningQuestionMode mode;
  final LearningQuestionStyle style;

  /// Main content shown before the learner answers.
  ///
  /// Examples:
  /// - Japanese expression for meaning/reading recognition.
  /// - English meaning for reverse recall.
  final String prompt;

  /// Optional Japanese example used for context questions.
  final String? contextJapanese;

  /// Optional reading for the context sentence. The UI should normally hide
  /// this until feedback unless accessibility/help is explicitly requested.
  final String? contextReading;

  /// Translation of the example. Keep hidden until feedback so it does not
  /// reveal the answer during context retrieval.
  final String? contextEnglish;

  /// Multiple-choice options. Empty for self-recall questions.
  final List<String> options;

  /// Exact visible answer used for feedback.
  final String answer;

  /// Other answers that should be treated as valid when free-text input is
  /// added later. For reading questions this includes curated alternative
  /// readings where available.
  final List<String> acceptedAnswers;

  /// Reading revealed with the answer when useful.
  final String? answerReading;

  /// Curated grammatical label from the source database.
  final String? partOfSpeech;

  /// Additional meanings are feedback-only, never used to make the prompt
  /// unnecessarily dense.
  final List<String> additionalMeanings;

  const LearningQuestion({
    required this.task,
    required this.mode,
    required this.style,
    required this.prompt,
    required this.contextJapanese,
    required this.contextReading,
    required this.contextEnglish,
    required this.options,
    required this.answer,
    required this.acceptedAnswers,
    required this.answerReading,
    required this.partOfSpeech,
    required this.additionalMeanings,
  });

  bool get isMultipleChoice => mode == LearningQuestionMode.multipleChoice;

  bool get isSelfRecall => mode == LearningQuestionMode.selfRecall;

  int? get correctOptionIndex {
    if (!isMultipleChoice) {
      return null;
    }

    final index = options.indexOf(answer);
    return index < 0 ? null : index;
  }
}

/// Builds pedagogically safer questions from the curated N4 dataset.
///
/// Design rules:
/// 1. Meaning distractors prefer the same broad part of speech.
/// 2. Reading distractors prefer similar-length real N4 readings and then
///    carefully generated near-misses if necessary.
/// 3. Usage questions use the complete curated example and ask for meaning in
///    context instead of generating an unsafe automatic cloze. A random noun
///    or verb can easily produce multiple grammatically-valid cloze answers.
/// 4. Recall remains active recall: no multiple-choice options are shown.
///
/// This service NEVER invents example sentences or vocabulary definitions.
class LearningQuestionService {
  LearningQuestionService._();

  static final math.Random _random = math.Random();

  static List<LearningVocabulary>? _cachedCourse;

  static Future<LearningQuestion> buildQuestion(LearningTask task) async {
    final course = await _course();

    switch (task.skill) {
      case LearningSkill.meaning:
        return _buildMeaningQuestion(task, course);

      case LearningSkill.reading:
        return _buildReadingQuestion(task, course);

      case LearningSkill.usage:
        return _buildContextQuestion(task, course);

      case LearningSkill.recall:
        return _buildRecallQuestion(task);

      case LearningSkill.listening:
        throw StateError('Listening questions are not enabled in LEARN yet.');
    }
  }

  static Future<List<LearningQuestion>> buildQuestions(
    Iterable<LearningTask> tasks,
  ) async {
    final course = await _course();
    final questions = <LearningQuestion>[];

    for (final task in tasks) {
      switch (task.skill) {
        case LearningSkill.meaning:
          questions.add(_buildMeaningQuestion(task, course));

        case LearningSkill.reading:
          questions.add(_buildReadingQuestion(task, course));

        case LearningSkill.usage:
          questions.add(_buildContextQuestion(task, course));

        case LearningSkill.recall:
          questions.add(_buildRecallQuestion(task));

        case LearningSkill.listening:
          throw StateError('Listening questions are not enabled in LEARN yet.');
      }
    }

    return List<LearningQuestion>.unmodifiable(questions);
  }

  static LearningQuestion _buildMeaningQuestion(
    LearningTask task,
    List<LearningVocabulary> course,
  ) {
    final word = task.word;

    final distractors = _meaningDistractors(
      target: word,
      course: course,
      count: 3,
    );

    final options = _shuffledUnique(<String>[
      word.displayMeaning,
      ...distractors,
    ]);

    return LearningQuestion(
      task: task,
      mode: LearningQuestionMode.multipleChoice,
      style: LearningQuestionStyle.meaningChoice,
      prompt: word.expression,
      contextJapanese: null,
      contextReading: null,
      contextEnglish: null,
      options: options,
      answer: word.displayMeaning,
      acceptedAnswers: <String>[
        word.displayMeaning,
        ...word.additionalMeanings,
      ],
      answerReading: word.displayReading,
      partOfSpeech: word.partOfSpeech,
      additionalMeanings: word.additionalMeanings,
    );
  }

  static LearningQuestion _buildReadingQuestion(
    LearningTask task,
    List<LearningVocabulary> course,
  ) {
    final word = task.word;

    if (!_containsKanji(word.expression)) {
      throw StateError(
        'Reading recognition should not be generated for kana-only word '
        '${word.id}: ${word.expression}',
      );
    }

    final distractors = _readingDistractors(
      target: word,
      course: course,
      count: 3,
    );

    final options = _shuffledUnique(<String>[
      word.displayReading,
      ...distractors,
    ]);

    if (options.length < 4) {
      throw StateError(
        'Could not build enough distinct reading options for '
        '${word.id}: ${word.expression}',
      );
    }

    return LearningQuestion(
      task: task,
      mode: LearningQuestionMode.multipleChoice,
      style: LearningQuestionStyle.readingChoice,
      prompt: word.expression,
      contextJapanese: null,
      contextReading: null,
      contextEnglish: null,
      options: options,
      answer: word.displayReading,
      acceptedAnswers: <String>[
        word.displayReading,
        ...word.additionalReadings,
      ],
      answerReading: word.displayReading,
      partOfSpeech: word.partOfSpeech,
      additionalMeanings: word.additionalMeanings,
    );
  }

  static LearningQuestion _buildContextQuestion(
    LearningTask task,
    List<LearningVocabulary> course,
  ) {
    final word = task.word;

    if (!word.hasExample || word.exampleJapanese == null) {
      throw StateError(
        'Context question requested without a curated example for '
        '${word.id}: ${word.expression}',
      );
    }

    final distractors = _meaningDistractors(
      target: word,
      course: course,
      count: 3,
    );

    final options = _shuffledUnique(<String>[
      word.displayMeaning,
      ...distractors,
    ]);

    return LearningQuestion(
      task: task,
      mode: LearningQuestionMode.multipleChoice,
      style: LearningQuestionStyle.contextMeaning,
      prompt: word.expression,
      contextJapanese: word.exampleJapanese,
      contextReading: word.exampleReading,
      contextEnglish: word.exampleEnglish,
      options: options,
      answer: word.displayMeaning,
      acceptedAnswers: <String>[
        word.displayMeaning,
        ...word.additionalMeanings,
      ],
      answerReading: word.displayReading,
      partOfSpeech: word.partOfSpeech,
      additionalMeanings: word.additionalMeanings,
    );
  }

  static LearningQuestion _buildRecallQuestion(LearningTask task) {
    final word = task.word;

    return LearningQuestion(
      task: task,
      mode: LearningQuestionMode.selfRecall,
      style: LearningQuestionStyle.selfRecall,
      prompt: word.displayMeaning,
      contextJapanese: null,
      contextReading: null,
      contextEnglish: null,
      options: const <String>[],
      answer: word.expression,
      acceptedAnswers: <String>[word.expression],
      answerReading: word.displayReading,
      partOfSpeech: word.partOfSpeech,
      additionalMeanings: word.additionalMeanings,
    );
  }

  static List<String> _meaningDistractors({
    required LearningVocabulary target,
    required List<LearningVocabulary> course,
    required int count,
  }) {
    final targetMeaning = _normalize(target.displayMeaning);
    final targetPos = _broadPartOfSpeech(target.partOfSpeech);
    final targetLength = target.displayMeaning.length;

    final candidates = <_ScoredOption>[];

    for (final candidate in course) {
      if (candidate.id == target.id) {
        continue;
      }

      final meaning = candidate.displayMeaning.trim();

      if (meaning.isEmpty ||
          _normalize(meaning) == targetMeaning ||
          target.additionalMeanings.any(
            (value) => _normalize(value) == _normalize(meaning),
          )) {
        continue;
      }

      var score = 0.0;

      final candidatePos = _broadPartOfSpeech(candidate.partOfSpeech);

      if (targetPos != null && candidatePos == targetPos) {
        score += 12.0;
      }

      if (candidate.priority == target.priority) {
        score += 3.0;
      }

      final lengthDifference = (meaning.length - targetLength).abs();
      score += math.max(0.0, 5.0 - (lengthDifference / 12.0));

      // Prefer distractors that are not near-synonyms of the correct answer.
      // Shared large tokens can make a question accidentally ambiguous.
      final overlap = _meaningTokenOverlap(target.displayMeaning, meaning);
      score -= overlap * 10.0;

      candidates.add(
        _ScoredOption(value: meaning, score: score + _random.nextDouble()),
      );
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));

    final result = <String>[];
    final normalizedSeen = <String>{targetMeaning};

    for (final candidate in candidates) {
      final normalized = _normalize(candidate.value);

      if (normalizedSeen.add(normalized)) {
        result.add(candidate.value);
      }

      if (result.length >= count) {
        break;
      }
    }

    if (result.length < count) {
      throw StateError(
        'Could not build enough meaning distractors for '
        '${target.id}: ${target.expression}',
      );
    }

    return result;
  }

  static List<String> _readingDistractors({
    required LearningVocabulary target,
    required List<LearningVocabulary> course,
    required int count,
  }) {
    final correct = target.displayReading.trim();
    final accepted = <String>{
      correct,
      ...target.additionalReadings.map((value) => value.trim()),
    };

    final candidates = <_ScoredOption>[];

    for (final candidate in course) {
      if (candidate.id == target.id) {
        continue;
      }

      final reading = candidate.displayReading.trim();

      if (reading.isEmpty ||
          accepted.contains(reading) ||
          !_isKanaReading(reading)) {
        continue;
      }

      final lengthDifference =
          (_kanaUnits(reading).length - _kanaUnits(correct).length).abs();

      if (lengthDifference > 2) {
        continue;
      }

      final distance = _editDistance(_kanaUnits(correct), _kanaUnits(reading));

      // Similar readings make stronger recognition distractors. Exact matches
      // are already excluded above.
      var score = 20.0 - (distance * 4.0) - (lengthDifference * 2.0);

      if (_firstKana(reading) == _firstKana(correct)) {
        score += 4.0;
      }

      if (candidate.priority == target.priority) {
        score += 1.0;
      }

      candidates.add(
        _ScoredOption(value: reading, score: score + _random.nextDouble()),
      );
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));

    final result = <String>[];
    final seen = <String>{...accepted};

    // First prefer real N4 readings from the curated course.
    for (final candidate in candidates) {
      if (seen.add(candidate.value)) {
        result.add(candidate.value);
      }

      if (result.length >= count) {
        return result;
      }
    }

    // If real near-neighbours are insufficient, use controlled phonological
    // near-misses. These are distractors only; they are never stored as
    // vocabulary content.
    for (final synthetic in _syntheticReadingVariants(correct)) {
      if (seen.add(synthetic)) {
        result.add(synthetic);
      }

      if (result.length >= count) {
        return result;
      }
    }

    return result;
  }

  static Iterable<String> _syntheticReadingVariants(String reading) sync* {
    final units = _kanaUnits(reading);

    const replacements = <String, List<String>>{
      'か': ['が'],
      'が': ['か'],
      'き': ['ぎ'],
      'ぎ': ['き'],
      'く': ['ぐ'],
      'ぐ': ['く'],
      'け': ['げ'],
      'げ': ['け'],
      'こ': ['ご'],
      'ご': ['こ'],
      'さ': ['ざ'],
      'ざ': ['さ'],
      'し': ['じ'],
      'じ': ['し'],
      'す': ['ず'],
      'ず': ['す'],
      'せ': ['ぜ'],
      'ぜ': ['せ'],
      'そ': ['ぞ'],
      'ぞ': ['そ'],
      'た': ['だ'],
      'だ': ['た'],
      'ち': ['ぢ'],
      'ぢ': ['ち'],
      'つ': ['づ'],
      'づ': ['つ'],
      'て': ['で'],
      'で': ['て'],
      'と': ['ど'],
      'ど': ['と'],
      'は': ['ば', 'ぱ'],
      'ば': ['は', 'ぱ'],
      'ぱ': ['は', 'ば'],
      'ひ': ['び', 'ぴ'],
      'び': ['ひ', 'ぴ'],
      'ぴ': ['ひ', 'び'],
      'ふ': ['ぶ', 'ぷ'],
      'ぶ': ['ふ', 'ぷ'],
      'ぷ': ['ふ', 'ぶ'],
      'へ': ['べ', 'ぺ'],
      'べ': ['へ', 'ぺ'],
      'ぺ': ['へ', 'べ'],
      'ほ': ['ぼ', 'ぽ'],
      'ぼ': ['ほ', 'ぽ'],
      'ぽ': ['ほ', 'ぼ'],
    };

    for (var index = 0; index < units.length; index++) {
      final alternatives = replacements[units[index]];

      if (alternatives == null) {
        continue;
      }

      for (final replacement in alternatives) {
        final changed = List<String>.from(units);
        changed[index] = replacement;
        yield changed.join();
      }
    }

    if (units.length >= 3) {
      for (var index = 1; index < units.length - 1; index++) {
        if (_isSmallKana(units[index]) || _isSmallKana(units[index + 1])) {
          continue;
        }

        final swapped = List<String>.from(units);
        final temp = swapped[index];
        swapped[index] = swapped[index + 1];
        swapped[index + 1] = temp;

        final value = swapped.join();
        if (value != reading) {
          yield value;
        }
      }
    }

    // Controlled long-vowel confusion for katakana loanword readings.
    if (reading.contains('ー')) {
      final shortened = reading.replaceFirst('ー', '');
      if (shortened.isNotEmpty && shortened != reading) {
        yield shortened;
      }
    }
  }

  static List<String> _shuffledUnique(Iterable<String> values) {
    final result = <String>[];
    final seen = <String>{};

    for (final raw in values) {
      final value = raw.trim();

      if (value.isEmpty) {
        continue;
      }

      if (seen.add(_normalize(value))) {
        result.add(value);
      }
    }

    result.shuffle(_random);
    return List<String>.unmodifiable(result);
  }

  static Future<List<LearningVocabulary>> _course() async {
    final cached = _cachedCourse;
    if (cached != null) {
      return cached;
    }

    final loaded = await LearningDatabaseService.getVocabulary();
    final frozen = List<LearningVocabulary>.unmodifiable(loaded);

    _cachedCourse = frozen;
    return frozen;
  }

  static void clearCache() {
    _cachedCourse = null;
  }

  static String? _broadPartOfSpeech(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final value = raw.toLowerCase();

    if (value.contains('verb')) {
      return 'verb';
    }

    if (value.contains('i-adjective')) {
      return 'i-adjective';
    }

    if (value.contains('na-adjective')) {
      return 'na-adjective';
    }

    if (value.contains('adverb')) {
      return 'adverb';
    }

    if (value.contains('pronoun')) {
      return 'pronoun';
    }

    if (value.contains('counter')) {
      return 'counter';
    }

    if (value.contains('particle')) {
      return 'particle';
    }

    if (value.contains('conjunction')) {
      return 'conjunction';
    }

    if (value.contains('expression')) {
      return 'expression';
    }

    if (value.contains('noun')) {
      return 'noun';
    }

    return value.split(';').first.trim();
  }

  static double _meaningTokenOverlap(String first, String second) {
    final firstTokens = _meaningTokens(first);
    final secondTokens = _meaningTokens(second);

    if (firstTokens.isEmpty || secondTokens.isEmpty) {
      return 0.0;
    }

    final intersection = firstTokens.intersection(secondTokens).length;
    final smaller = math.min(firstTokens.length, secondTokens.length);

    if (smaller == 0) {
      return 0.0;
    }

    return intersection / smaller;
  }

  static Set<String> _meaningTokens(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .split(' ')
        .map((token) => token.trim())
        .where((token) => token.length >= 3)
        .where(
          (token) => !const <String>{
            'the',
            'and',
            'for',
            'with',
            'from',
            'into',
            'that',
            'this',
            'one',
          }.contains(token),
        )
        .toSet();
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool _containsKanji(String value) {
    return RegExp(r'[一-龯々]').hasMatch(value);
  }

  static bool _isKanaReading(String value) {
    return RegExp(r'^[ぁ-ゖァ-ヺー・]+$').hasMatch(value);
  }

  static String _firstKana(String value) {
    final units = _kanaUnits(value);
    return units.isEmpty ? '' : units.first;
  }

  static List<String> _kanaUnits(String value) {
    final units = <String>[];

    for (var index = 0; index < value.length; index++) {
      final current = value[index];

      if (_isSmallKana(current) && units.isNotEmpty) {
        units[units.length - 1] = '${units.last}$current';
      } else {
        units.add(current);
      }
    }

    return units;
  }

  static bool _isSmallKana(String value) {
    return const <String>{
      'ゃ',
      'ゅ',
      'ょ',
      'ぁ',
      'ぃ',
      'ぅ',
      'ぇ',
      'ぉ',
      'ゎ',
      'ャ',
      'ュ',
      'ョ',
      'ァ',
      'ィ',
      'ゥ',
      'ェ',
      'ォ',
      'ヮ',
    }.contains(value);
  }

  static int _editDistance(List<String> first, List<String> second) {
    if (first.isEmpty) {
      return second.length;
    }

    if (second.isEmpty) {
      return first.length;
    }

    final previous = List<int>.generate(second.length + 1, (index) => index);

    for (var firstIndex = 1; firstIndex <= first.length; firstIndex++) {
      final current = List<int>.filled(second.length + 1, 0);
      current[0] = firstIndex;

      for (var secondIndex = 1; secondIndex <= second.length; secondIndex++) {
        final substitutionCost =
            first[firstIndex - 1] == second[secondIndex - 1] ? 0 : 1;

        current[secondIndex] = math.min(
          math.min(current[secondIndex - 1] + 1, previous[secondIndex] + 1),
          previous[secondIndex - 1] + substitutionCost,
        );
      }

      for (var index = 0; index < previous.length; index++) {
        previous[index] = current[index];
      }
    }

    return previous.last;
  }
}

class _ScoredOption {
  final String value;
  final double score;

  const _ScoredOption({required this.value, required this.score});
}
