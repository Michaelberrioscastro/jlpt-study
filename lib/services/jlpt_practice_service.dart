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

  static const String _n5VocabAsset =
      'assets/data/practice/jlpt_practice_n5_vocab_clean.json';
  static const String _n5GrammarAsset =
      'assets/data/practice/jlpt_practice_n5_grammar_clean.json';
  static const String _n5ReadingAsset =
      'assets/data/practice/jlpt_practice_n5_reading_clean.json';

  static List<JlptPracticeTest>? _cachedN5Vocabulary;
  static List<JlptPracticeTest>? _cachedN5Grammar;
  static List<JlptReadingPassage>? _cachedN5Reading;

  static Future<List<JlptPracticeTest>> loadN5Vocabulary() async {
    if (_cachedN5Vocabulary != null) {
      return _cachedN5Vocabulary!;
    }

    final raw = await rootBundle.loadString(_n5VocabAsset);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rawTests = (decoded['tests'] as List?) ?? const [];

    final tests = rawTests
        .map(
          (e) => JlptPracticeTest.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    _cachedN5Vocabulary = tests;
    return tests;
  }

  static Future<List<JlptPracticeQuestion>> getN5VocabularyQuestions() async {
    final tests = await loadN5Vocabulary();

    final unique = <String, JlptPracticeQuestion>{};

    for (final test in tests) {
      for (final question in test.questions) {
        unique[question.id] = question;
      }
    }

    return unique.values.toList();
  }

  static Future<List<JlptPracticeTest>> loadN5Grammar() async {
    if (_cachedN5Grammar != null) {
      return _cachedN5Grammar!;
    }

    final raw = await rootBundle.loadString(_n5GrammarAsset);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final rawTests = (decoded['tests'] as List?) ?? const [];

    final tests = rawTests
        .map(
          (e) => JlptPracticeTest.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    _cachedN5Grammar = tests;
    return tests;
  }

  static Future<List<JlptPracticeQuestion>> getN5GrammarQuestions() async {
    final tests = await loadN5Grammar();
    final unique = <String, JlptPracticeQuestion>{};

    for (final test in tests) {
      for (final question in test.questions) {
        unique[question.id] = question;
      }
    }

    return unique.values.toList();
  }

  static Future<List<JlptPracticeQuestion>> buildGrammarSession({
    required int count,
    bool shuffle = true,
  }) async {
    final questions = await getN5GrammarQuestions();

    if (!shuffle || count >= questions.length) {
      return List<JlptPracticeQuestion>.from(questions);
    }

    final copy = List<JlptPracticeQuestion>.from(questions);
    copy.shuffle(Random());
    return copy.take(count).toList();
  }

  static Future<List<JlptReadingPassage>> loadN5Reading() async {
    if (_cachedN5Reading != null) {
      return _cachedN5Reading!;
    }

    final raw = await rootBundle.loadString(_n5ReadingAsset);
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

    _cachedN5Reading = passages;
    return passages;
  }

  static Future<int> getN5ReadingQuestionCount() async {
    final passages = await loadN5Reading();
    return passages.fold<int>(
      0,
      (total, passage) => total + passage.questions.length,
    );
  }

  static Future<List<JlptReadingPassage>> buildReadingSession({
    required int questionCount,
    bool shufflePassages = true,
  }) async {
    final passages = List<JlptReadingPassage>.from(await loadN5Reading());

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

  static Future<List<JlptPracticeQuestion>> buildSession({
    required int count,
    bool shuffle = true,
  }) async {
    final questions = await getN5VocabularyQuestions();

    if (!shuffle || count >= questions.length) {
      return List<JlptPracticeQuestion>.from(questions);
    }

    final copy = List<JlptPracticeQuestion>.from(questions);
    copy.shuffle(Random());
    return copy.take(count).toList();
  }
}
