import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../study/book_catalog.dart';
import '../study/study_catalog.dart';

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

class ProgressService extends ChangeNotifier {
  ProgressService._();
  static final instance = ProgressService._();

  SharedPreferences? _prefs;
  final Set<String> _completed = {};
  final Map<String, Map<String, dynamic>> _mistakes = {};
  int _total = 0, _correct = 0, _wrong = 0, _corrected = 0, _xp = 0, _streak = 1;
  bool _loaded = false;
  String _level = 'N4';
  String _bookId = BookCatalog.somatomeN4.id;

  String get studyLevel => _level;
  String get bookId => _bookId;
  StudyBook get book => BookCatalog.forId(_bookId);

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
    if (selected.level != _level) return;
    if (value == _bookId && _loaded) return;

    // Persist the requested book before reloading. load() restores the selected
    // book from SharedPreferences, so saving first prevents it from snapping
    // back to the previously selected N4 book.
    final p = _prefs ??= await SharedPreferences.getInstance();
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
