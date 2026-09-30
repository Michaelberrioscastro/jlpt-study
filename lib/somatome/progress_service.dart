import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../study/book_catalog.dart';
import '../study/study_catalog.dart';
import '../study/learning_engine.dart';

class StudyStats {
  final int totalAnswers, correct, wrong, corrected, xp, streak, openMistakes, level;
  const StudyStats({
    this.totalAnswers = 0,
    this.correct = 0,
    this.wrong = 0,
    this.corrected = 0,
    this.xp = 0,
    this.streak = 1,
    this.openMistakes = 0,
    this.level = 1,
  });
  double get accuracy => totalAnswers == 0 ? 0 : correct / totalAnswers * 100;
}

class LevelProgressSnapshot {
  final StudyBook book;
  final int completed;
  final int total;
  final int xp;
  final int answers;
  final int correct;

  const LevelProgressSnapshot({
    required this.book,
    required this.completed,
    required this.total,
    required this.xp,
    required this.answers,
    required this.correct,
  });

  double get progress => total == 0 ? 0 : completed / total;
  double get accuracy => answers == 0 ? 0 : correct / answers * 100;
}

class ProgressService extends ChangeNotifier {
  ProgressService._();
  static final instance = ProgressService._();

  SharedPreferences? _prefs;
  final LearningEngine _learning = LearningEngine();
  final Set<String> _completed = {};
  final Map<String, Map<String, dynamic>> _mistakes = {};
  int _total = 0, _correct = 0, _wrong = 0, _corrected = 0, _xp = 0, _streak = 1;
  bool _loaded = false;
  String _level = 'N4';
  String _bookId = BookCatalog.somatomeN4.id;

  String get studyLevel => _level;
  String get bookId => _bookId;
  StudyBook get book => BookCatalog.forId(_bookId);

  StudyBook selectedBookForLevel(String level) {
    final saved = _prefs?.getString('selected_book_' + level);
    if (saved != null) {
      final candidate = BookCatalog.forId(saved);
      if (candidate.level == level) return candidate;
    }
    return BookCatalog.defaultForLevel(level);
  }

  LevelProgressSnapshot progressForBook(StudyBook book) {
    final p = _prefs;
    final prefix = book.level + '_' + book.id;
    final legacySomatome = book.id == BookCatalog.somatomeN4.id;
    final legacyN3 = book.id == BookCatalog.shinKanzenN3Grammar.id;

    final completed = (p?.getStringList('completed_sessions_' + prefix) ??
            (legacySomatome
                ? p?.getStringList('completed_sessions')
                : legacyN3
                    ? p?.getStringList('completed_sessions_N3')
                    : null) ??
            const <String>[])
        .length;
    final answers = p?.getInt('total_answers_' + prefix) ??
        (legacySomatome
            ? p?.getInt('total_answers')
            : legacyN3
                ? p?.getInt('total_answers_N3')
                : null) ??
        0;
    final correct = p?.getInt('correct_' + prefix) ??
        (legacySomatome
            ? p?.getInt('correct')
            : legacyN3
                ? p?.getInt('correct_N3')
                : null) ??
        0;
    final xp = p?.getInt('xp_' + prefix) ??
        (legacySomatome
            ? p?.getInt('xp')
            : legacyN3
                ? p?.getInt('xp_N3')
                : null) ??
        0;

    final total = book.id == BookCatalog.somatomeN4.id
        ? 42
        : book.id == BookCatalog.shinKanzenN4Reading.id
            ? 21
            : 50;

    return LevelProgressSnapshot(
      book: book,
      completed: completed,
      total: total,
      xp: xp,
      answers: answers,
      correct: correct
    );
  }

  String _storagePrefix() => _level + '_' + _bookId;

  Future<void> load() async {
    if (_loaded) return;

    _prefs = await SharedPreferences.getInstance();

    final selectedBook =
        _prefs!.getString('selected_book_' + _level) ??
        BookCatalog.defaultForLevel(_level).id;

    if (BookCatalog.forId(selectedBook).level == _level) {
      _bookId = selectedBook;
    } else {
      _bookId = BookCatalog.defaultForLevel(_level).id;
    }

    StudyCatalog.activeLevel = _level;
    StudyCatalog.activeBookId = _bookId;

    await _learning.load(_prefs!, _level);

    final prefix = _storagePrefix();
    final completedKey = 'completed_sessions_' + prefix;
    final mistakesKey = 'mistakes_' + prefix;
    final totalKey = 'total_answers_' + prefix;
    final correctKey = 'correct_' + prefix;
    final wrongKey = 'wrong_' + prefix;
    final correctedKey = 'corrected_' + prefix;
    final xpKey = 'xp_' + prefix;
    final streakKey = 'streak_' + prefix;

    final legacySomatome = _level == 'N4' && _bookId == BookCatalog.somatomeN4.id;
    final legacyN3 = _level == 'N3' && _bookId == BookCatalog.shinKanzenN3Grammar.id;

    _completed.addAll(
      _prefs!.getStringList(completedKey) ??
          (legacySomatome
              ? (_prefs!.getStringList('completed_sessions') ?? const [])
              : legacyN3
                  ? (_prefs!.getStringList('completed_sessions_N3') ?? const [])
                  : const []),
    );

    final raw = _prefs!.getString(mistakesKey) ??
        (legacySomatome
            ? _prefs!.getString('mistakes')
            : legacyN3
                ? _prefs!.getString('mistakes_N3')
                : null);

    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in decoded.entries) {
        _mistakes[e.key] = Map<String, dynamic>.from(e.value as Map);
      }
    }

    _total = _prefs!.getInt(totalKey) ??
        (legacySomatome
            ? (_prefs!.getInt('total_answers') ?? 0)
            : legacyN3
                ? (_prefs!.getInt('total_answers_N3') ?? 0)
                : 0);
    _correct = _prefs!.getInt(correctKey) ??
        (legacySomatome
            ? (_prefs!.getInt('correct') ?? 0)
            : legacyN3
                ? (_prefs!.getInt('correct_N3') ?? 0)
                : 0);
    _wrong = _prefs!.getInt(wrongKey) ??
        (legacySomatome
            ? (_prefs!.getInt('wrong') ?? 0)
            : legacyN3
                ? (_prefs!.getInt('wrong_N3') ?? 0)
                : 0);
    _corrected = _prefs!.getInt(correctedKey) ??
        (legacySomatome
            ? (_prefs!.getInt('corrected') ?? 0)
            : legacyN3
                ? (_prefs!.getInt('corrected_N3') ?? 0)
                : 0);
    _xp = _prefs!.getInt(xpKey) ??
        (legacySomatome
            ? (_prefs!.getInt('xp') ?? 0)
            : legacyN3
                ? (_prefs!.getInt('xp_N3') ?? 0)
                : 0);
    _streak = _prefs!.getInt(streakKey) ??
        (legacySomatome
            ? (_prefs!.getInt('streak') ?? 1)
            : legacyN3
                ? (_prefs!.getInt('streak_N3') ?? 1)
                : 1);

    _loaded = true;
    notifyListeners();
  }

  Future<void> setLevel(String value) async {
    if (value == _level && _loaded) return;

    _level = value;
    _bookId = BookCatalog.defaultForLevel(value).id;
    _resetMemory();
    await load();
  }

  Future<void> setBook(String value) async {
    final selected = BookCatalog.forId(value);
    final p = _prefs ??= await SharedPreferences.getInstance();

    if (selected.level != _level) {
      _level = selected.level;
    }

    await p.setString('selected_book_' + _level, value);

    _bookId = value;
    _resetMemory();
    await load();
  }

  void _resetMemory() {
    StudyCatalog.activeLevel = _level;
    StudyCatalog.activeBookId = _bookId;
    _completed.clear();
    _mistakes.clear();
    _total = 0;
    _correct = 0;
    _wrong = 0;
    _corrected = 0;
    _xp = 0;
    _streak = 1;
    _loaded = false;
  }

  LearningSnapshot get learningSnapshot => _learning.snapshot();

  SmartSessionPlan get smartPlan => _learning.recommend(
        sessions: StudyCatalog.sessions,
        completedIds: _completed,
      );

  ConceptMastery? conceptMastery(String id) => _learning.concept(id);

  StudyStats get stats => StudyStats(
        totalAnswers: _total,
        correct: _correct,
        wrong: _wrong,
        corrected: _corrected,
        xp: _xp,
        streak: _streak,
        openMistakes: _mistakes.values.where((m) => m['open'] == true).length,
        level: (_xp ~/ 300) + 1,
      );

  int get completedCount => _completed.length;

  double get sessionProgress => StudyCatalog.totalSessions == 0
      ? 0
      : completedCount / StudyCatalog.totalSessions;

  List<String> get mistakePrompts => _mistakes.values
      .where((m) => m['open'] == true)
      .map((m) => m['prompt'] as String)
      .toList();

  bool isCompleted(String id) => _completed.contains(id);

  bool isUnlocked(String id) {
    final i = StudyCatalog.sessions.indexWhere((s) => s.id == id);
    if (i < 0) return false;
    return i == 0 || isCompleted(StudyCatalog.sessions[i - 1].id);
  }

  SessionInfo nextUnlockedSession() => StudyCatalog.sessions.firstWhere(
        (s) => !isCompleted(s.id),
        orElse: () => StudyCatalog.sessions.last,
      );

  bool weekUnlocked(int week) => StudyCatalog.sessions
      .where((s) => s.week == week)
      .any((s) => isUnlocked(s.id));

  bool weekCompleted(int week) {
    final items = StudyCatalog.sessions.where((s) => s.week == week).toList();
    return items.isNotEmpty && items.every((s) => isCompleted(s.id));
  }

  Future<void> recordAnswer({
    required String sessionId,
    required String questionId,
    required String prompt,
    required bool correct,
    List<String> conceptIds = const <String>[],
    int responseMs = 0,
  }) async {
    _total++;
    final existing = _mistakes[questionId];

    if (correct) {
      _correct++;
      if (existing != null && existing['open'] == true) {
        existing['open'] = false;
        _corrected++;
      }
    } else {
      _wrong++;
      _mistakes[questionId] = {
        'sessionId': sessionId,
        'prompt': prompt,
        'open': true,
      };
    }

    final p = _prefs ??= await SharedPreferences.getInstance();
    await _learning.record(
      prefs: p,
      level: _level,
      conceptIds: conceptIds,
      sessionId: sessionId,
      questionId: questionId,
      correct: correct,
      responseMs: responseMs,
    );

    await _save();
    notifyListeners();
  }

  Future<void> completeSession(String id, int correct, int wrong) async {
    if (_completed.add(id)) {
      _xp += 50 + correct * 10;
      await _save();
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final p = _prefs ??= await SharedPreferences.getInstance();
    final prefix = _storagePrefix();

    await p.setString('selected_book_' + _level, _bookId);
    await p.setStringList('completed_sessions_' + prefix, _completed.toList());
    await p.setString('mistakes_' + prefix, jsonEncode(_mistakes));
    await p.setInt('total_answers_' + prefix, _total);
    await p.setInt('correct_' + prefix, _correct);
    await p.setInt('wrong_' + prefix, _wrong);
    await p.setInt('corrected_' + prefix, _corrected);
    await p.setInt('xp_' + prefix, _xp);
    await p.setInt('streak_' + prefix, _streak);
  }
}
