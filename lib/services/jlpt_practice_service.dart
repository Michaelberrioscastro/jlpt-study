import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/jlpt_practice_question.dart';

class JlptReadingOption {
  final int id;
  final String text;

  const JlptReadingOption({required this.id, required this.text});

  factory JlptReadingOption.fromJson(Map<String, dynamic> json) {
    return JlptReadingOption(
      id: (json['id'] as num).toInt(),
      text: (json['text'] ?? '').toString(),
    );
  }
}

class JlptReadingQuestion {
  final String id;
  final int number;
  final String prompt;
  final List<JlptReadingOption> options;
  final int correctOption;

  const JlptReadingQuestion({
    required this.id,
    required this.number,
    required this.prompt,
    required this.options,
    required this.correctOption,
  });

  factory JlptReadingQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List?) ?? const [];

    return JlptReadingQuestion(
      id: (json['id'] ?? '').toString(),
      number: (json['number'] as num?)?.toInt() ?? 0,
      prompt: (json['prompt'] ?? '').toString(),
      options: rawOptions
          .map(
            (e) =>
                JlptReadingOption.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      correctOption: (json['correct_option'] as num).toInt(),
    );
  }
}

class JlptReadingPassage {
  final String id;
  final int mondai;
  final String subtype;
  final String passage;
  final List<JlptReadingQuestion> questions;

  const JlptReadingPassage({
    required this.id,
    required this.mondai,
    required this.subtype,
    required this.passage,
    required this.questions,
  });

  factory JlptReadingPassage.fromJson(Map<String, dynamic> json) {
    final rawQuestions = (json['questions'] as List?) ?? const [];

    return JlptReadingPassage(
      id: (json['id'] ?? '').toString(),
      mondai: (json['mondai'] as num?)?.toInt() ?? 0,
      subtype: (json['subtype'] ?? '').toString(),
      passage: (json['passage'] ?? '').toString(),
      questions: rawQuestions
          .map(
            (e) => JlptReadingQuestion.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class JlptPracticeService {
  JlptPracticeService._();

  static const Set<String> supportedLevels = {'N5', 'N4', 'N3', 'N2', 'N1'};

  static final Map<String, List<JlptPracticeTest>> _practiceCache = {};
  static final Map<String, List<JlptReadingPassage>> _readingCache = {};

  static String _normalizeLevel(String level) {
    final normalized = level.trim().toUpperCase();
    if (!supportedLevels.contains(normalized)) {
      throw ArgumentError.value(level, 'level', 'Nivel JLPT no válido');
    }
    return normalized;
  }

  static String _practiceAsset(String level, String section) {
    final normalized = _normalizeLevel(level).toLowerCase();
    return 'assets/data/practice/jlpt_practice_${normalized}_${section}_clean.json';
  }

  static Future<List<JlptPracticeTest>> _loadPracticeTests({
    required String level,
    required String section,
  }) async {
    final normalized = _normalizeLevel(level);
    final key = '$normalized:$section';

    final cached = _practiceCache[key];
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(
      _practiceAsset(normalized, section),
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rawTests = (decoded['tests'] as List?) ?? const [];

    final tests = rawTests
        .map(
          (e) => JlptPracticeTest.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    _practiceCache[key] = tests;
    return tests;
  }

  static Future<List<JlptPracticeQuestion>> _getQuestions({
    required String level,
    required String section,
  }) async {
    final tests = await _loadPracticeTests(level: level, section: section);
    final unique = <String, JlptPracticeQuestion>{};

    for (final test in tests) {
      for (final question in test.questions) {
        unique[question.id] = question;
      }
    }

    return unique.values.toList();
  }

  static Future<List<JlptPracticeQuestion>> getVocabularyQuestions({
    required String level,
  }) {
    return _getQuestions(level: level, section: 'vocab');
  }

  static Future<List<JlptPracticeQuestion>> getGrammarQuestions({
    required String level,
  }) {
    return _getQuestions(level: level, section: 'grammar');
  }

  static Future<List<JlptPracticeQuestion>> buildVocabularySession({
    required String level,
    required int count,
    bool shuffle = true,
  }) async {
    final questions = await getVocabularyQuestions(level: level);
    return _buildQuestionSession(
      questions: questions,
      count: count,
      shuffle: shuffle,
    );
  }

  static Future<List<JlptPracticeQuestion>> buildGrammarSession({
    String level = 'N5',
    required int count,
    bool shuffle = true,
  }) async {
    final questions = await getGrammarQuestions(level: level);
    return _buildQuestionSession(
      questions: questions,
      count: count,
      shuffle: shuffle,
    );
  }

  static List<JlptPracticeQuestion> _buildQuestionSession({
    required List<JlptPracticeQuestion> questions,
    required int count,
    required bool shuffle,
  }) {
    if (!shuffle || count >= questions.length) {
      return List<JlptPracticeQuestion>.from(questions);
    }

    final copy = List<JlptPracticeQuestion>.from(questions);
    copy.shuffle(Random());
    return copy.take(count).toList();
  }

  static Future<List<JlptReadingPassage>> loadReading({
    required String level,
  }) async {
    final normalized = _normalizeLevel(level);
    final cached = _readingCache[normalized];
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(
      _practiceAsset(normalized, 'reading'),
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rawTests = (decoded['tests'] as List?) ?? const [];

    final passages = <JlptReadingPassage>[];

    for (final rawTest in rawTests) {
      final test = Map<String, dynamic>.from(rawTest as Map);
      final rawPassages = (test['passages'] as List?) ?? const [];

      for (final rawPassage in rawPassages) {
        passages.add(
          JlptReadingPassage.fromJson(
            Map<String, dynamic>.from(rawPassage as Map),
          ),
        );
      }
    }

    _readingCache[normalized] = passages;
    return passages;
  }

  static Future<int> getReadingQuestionCount({required String level}) async {
    final passages = await loadReading(level: level);
    return passages.fold<int>(
      0,
      (total, passage) => total + passage.questions.length,
    );
  }

  static Future<List<JlptReadingPassage>> buildReadingSession({
    String level = 'N5',
    required int questionCount,
    bool shufflePassages = true,
  }) async {
    final passages = List<JlptReadingPassage>.from(
      await loadReading(level: level),
    );

    if (shufflePassages) {
      passages.shuffle(Random());
    }

    if (questionCount <= 0) {
      return const [];
    }

    final selected = <JlptReadingPassage>[];
    var totalQuestions = 0;

    for (final passage in passages) {
      selected.add(passage);
      totalQuestions += passage.questions.length;

      if (totalQuestions >= questionCount) {
        break;
      }
    }

    return selected;
  }

  // Compatibilidad temporal con las pantallas N5 actuales.
  static Future<List<JlptPracticeTest>> loadN5Vocabulary() {
    return _loadPracticeTests(level: 'N5', section: 'vocab');
  }

  static Future<List<JlptPracticeQuestion>> getN5VocabularyQuestions() {
    return getVocabularyQuestions(level: 'N5');
  }

  static Future<List<JlptPracticeTest>> loadN5Grammar() {
    return _loadPracticeTests(level: 'N5', section: 'grammar');
  }

  static Future<List<JlptPracticeQuestion>> getN5GrammarQuestions() {
    return getGrammarQuestions(level: 'N5');
  }

  static Future<List<JlptReadingPassage>> loadN5Reading() {
    return loadReading(level: 'N5');
  }

  static Future<int> getN5ReadingQuestionCount() {
    return getReadingQuestionCount(level: 'N5');
  }

  static Future<List<JlptPracticeQuestion>> buildSession({
    required int count,
    bool shuffle = true,
  }) {
    return buildVocabularySession(level: 'N5', count: count, shuffle: shuffle);
  }
}
