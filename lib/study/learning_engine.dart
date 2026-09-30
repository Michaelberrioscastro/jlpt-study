import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../somatome/lesson_catalog.dart';

class ConceptMastery {
  final String id;
  int attempts;
  int correct;
  int streak;
  int lapses;
  double ease;
  double intervalDays;
  DateTime? lastSeen;
  DateTime? dueAt;
  int totalResponseMs;
  int responseCount;
  int lastResponseMs;
  final List<bool> recent;

  ConceptMastery({
    required this.id,
    this.attempts = 0,
    this.correct = 0,
    this.streak = 0,
    this.lapses = 0,
    this.ease = 2.5,
    this.intervalDays = 0,
    this.lastSeen,
    this.dueAt,
    this.totalResponseMs = 0,
    this.responseCount = 0,
    this.lastResponseMs = 0,
    List<bool>? recent,
  }) : recent = recent ?? <bool>[];

  double get accuracy => attempts == 0 ? 0 : correct / attempts;
  double get averageResponseMs => responseCount == 0 ? 0 : totalResponseMs / responseCount;

  double get mastery {
    if (attempts == 0) return 0;
    final accuracyScore = accuracy * 70;
    final streakScore = (streak.clamp(0, 5) / 5) * 15;
    final spacingScore = (intervalDays.clamp(0, 30) / 30) * 15;
    final samplePenalty = attempts < 3 ? 12 : 0;
    return (accuracyScore + streakScore + spacingScore - samplePenalty)
        .clamp(0, 100)
        .toDouble();
  }

  bool get isDue =>
      attempts > 0 && dueAt != null && !dueAt!.isAfter(DateTime.now());

  bool get isWeak => attempts >= 2 && mastery < 60;

  bool get isAtRisk {
    if (attempts < 3 || dueAt == null) return false;
    final hoursUntilDue = dueAt!.difference(DateTime.now()).inHours;
    final recentMiss = recent.isNotEmpty && !recent.last;
    return (hoursUntilDue <= 36 && mastery < 85) || recentMiss;
  }

  double get priority {
    var score = (100 - mastery) * .65;
    if (isDue) score += 35;
    if (isAtRisk) score += 20;
    if (recent.isNotEmpty && !recent.last) score += 25;
    if (r.lastResponseMs >= 12000) score += 8;
    return score;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'attempts': attempts,
        'correct': correct,
        'streak': streak,
        'lapses': lapses,
        'ease': ease,
        'intervalDays': intervalDays,
        'lastSeen': lastSeen?.millisecondsSinceEpoch,
        'dueAt': dueAt?.millisecondsSinceEpoch,
        'totalResponseMs': totalResponseMs,
        'responseCount': responseCount,
        'lastResponseMs': lastResponseMs,
        'recent': recent,
      };

  factory ConceptMastery.fromJson(Map<String, dynamic> map) {
    return ConceptMastery(
      id: map['id']?.toString() ?? '',
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      correct: (map['correct'] as num?)?.toInt() ?? 0,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      lapses: (map['lapses'] as num?)?.toInt() ?? 0,
      ease: (map['ease'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (map['intervalDays'] as num?)?.toDouble() ?? 0,
      lastSeen: _date(map['lastSeen']),
      dueAt: _date(map['dueAt']),
      totalResponseMs: (map['totalResponseMs'] as num?)?.toInt() ?? 0,
      responseCount: (map['responseCount'] as num?)?.toInt() ?? 0,
      lastResponseMs: (map['lastResponseMs'] as num?)?.toInt() ?? 0,
      recent: (map['recent'] as List<dynamic>?)
              ?.map((x) => x == true)
              .toList() ??
          <bool>[],
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
}

class LearningSnapshot {
  final int trackedConcepts;
  final int dueConcepts;
  final int weakConcepts;
  final int atRiskConcepts;
  final double mastery;
  final List<ConceptMastery> weakest;
  final List<ConceptMastery> due;

  const LearningSnapshot({
    required this.trackedConcepts,
    required this.dueConcepts,
    required this.weakConcepts,
    required this.atRiskConcepts,
    required this.mastery,
    required this.weakest,
    required this.due,
  });

  bool get hasIntelligenceData => trackedConcepts > 0;
}

class SmartSessionPlan {
  final String title;
  final String reason;
  final String actionLabel;
  final int estimatedMinutes;
  final List<String> conceptIds;
  final List<SessionInfo> sessions;

  const SmartSessionPlan({
    required this.title,
    required this.reason,
    required this.actionLabel,
    required this.estimatedMinutes,
    required this.conceptIds,
    required this.sessions,
  });

  bool get hasPlan => conceptIds.isNotEmpty || sessions.isNotEmpty;
}

/// Local, deterministic recommendation engine.
/// State is stored by level, not book, so multiple books can share mastery.
class LearningEngine {
  final Map<String, ConceptMastery> _concepts = {};

  String _storageKey(String level) => 'learning_state_v1_' + level;

  Future<void> load(SharedPreferences prefs, String level) async {
    _concepts.clear();
    final raw = prefs.getString(_storageKey(level));
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final items = decoded['concepts'] as Map<String, dynamic>? ?? {};
      for (final entry in items.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          final record = ConceptMastery.fromJson(value);
          if (record.id.isNotEmpty) _concepts[record.id] = record;
        }
      }
    } catch (_) {
      // Intelligence state is optional; never block the study experience.
    }
  }

  Future<void> record({
    required SharedPreferences prefs,
    required String level,
    required List<String> conceptIds,
    required String sessionId,
    required String questionId,
    required bool correct,
    int responseMs = 0,
  }) async {
    final ids = conceptIds.isEmpty
        ? <String>[normalizeConcept(sessionId)]
        : conceptIds
            .map(normalizeConcept)
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

    for (final id in ids) {
      final record = _concepts.putIfAbsent(id, () => ConceptMastery(id: id));
      _update(record, correct, responseMs);
    }

    await _save(prefs, level);
  }

  LearningSnapshot snapshot() {
    final all = _concepts.values.toList();
    final due = all.where((x) => x.isDue).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    final weak = all.where((x) => x.isWeak).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final weakest = all.where((x) => x.attempts > 0).toList()
      ..sort((a, b) => a.mastery.compareTo(b.mastery));

    final mastery = all.isEmpty
        ? 0.0
        : all.map((x) => x.mastery).reduce((a, b) => a + b) / all.length;

    return LearningSnapshot(
      trackedConcepts: all.length,
      dueConcepts: due.length,
      weakConcepts: weak.length,
      atRiskConcepts: all.where((x) => x.isAtRisk).length,
      mastery: mastery,
      weakest: weakest.take(5).toList(),
      due: due.take(8).toList(),
    );
  }

  SmartSessionPlan recommend({
    required List<SessionInfo> sessions,
    required Set<String> completedIds,
  }) {
    final snap = snapshot();

    if (snap.due.isNotEmpty) {
      final ids = snap.due.take(5).map((x) => x.id).toList();
      return SmartSessionPlan(
        title: 'Repaso inteligente',
        reason: 'Tienes \${snap.due.length} concepto(s) cuyo repaso ya toca. '
            'La app priorizará recuperación y contenido relacionado.',
        actionLabel: 'REPASAR AHORA',
        estimatedMinutes: 10,
        conceptIds: ids,
        sessions: _relatedSessions(sessions, ids, completedIds),
      );
    }

    if (snap.weakest.isNotEmpty) {
      final ids = snap.weakest.take(4).map((x) => x.id).toList();
      return SmartSessionPlan(
        title: 'Refuerzo personalizado',
        reason: 'He detectado áreas con rendimiento bajo. '
            'Vamos a reforzarlas antes de avanzar demasiado.',
        actionLabel: 'REFORZAR',
        estimatedMinutes: 12,
        conceptIds: ids,
        sessions: _relatedSessions(sessions, ids, completedIds),
      );
    }

    final next = sessions.firstWhere(
      (s) => !completedIds.contains(s.id),
      orElse: () => sessions.isEmpty ? _emptySession() : sessions.last,
    );

    return SmartSessionPlan(
      title: 'Siguiente paso',
      reason: 'Todavía no hay suficiente historial para personalizar el plan. '
          'Cada respuesta hará que las recomendaciones sean más precisas.',
      actionLabel: 'EMPEZAR',
      estimatedMinutes: 12,
      conceptIds: sessions.isEmpty
          ? const <String>[]
          : <String>[normalizeConcept(next.focus)],
      sessions: sessions.isEmpty ? const [] : <SessionInfo>[next],
    );
  }

  ConceptMastery? concept(String id) => _concepts[normalizeConcept(id)];

  static List<String> conceptsForFocus(String focus) {
    final parts = focus
        .split(RegExp(r'\s*[·/／,、]+\s*'))
        .map(normalizeConcept)
        .where((x) => x.isNotEmpty && x != 'Review')
        .toSet()
        .toList();
    return parts.isEmpty ? <String>[normalizeConcept(focus)] : parts;
  }

  static String normalizeConcept(String value) {
    var text = value
        .replaceAll('〜', '～')
        .replaceAll('・', ' ')
        .replaceAll('/', ' ')
        .replaceAll('／', ' ')
        .trim();

    const aliases = <String, String>{
      'うちに': '～うちに',
      '～うちに': '～うちに',
      '間に': '～間に',
      '～間に': '～間に',
      'までに': '～までに',
      '～までに': '～までに',
      'しか～ない': 'しか～ない',
      'たことがある': '～たことがある',
      'ことにする': '～ことにする',
      'ことになる': '～ことになる',
      'なければならない': '～なければならない',
      'なくてもいい': '～なくてもいい',
      'ておく': '～ておく',
      'てしまう': '～てしまう',
      'てくれる': '～てくれる',
      'てもらう': '～てもらう',
      'てあげる': '～てあげる',
      'ようにする': '～ようにする',
      'ようになる': '～ようになる',
      'たら': '～たら',
      'ば': '～ば',
      'なら': '～なら',
      'ようだ': '～ようだ',
      'みたいだ': '～みたいだ',
      'そうだ': '～そうだ',
      'でしょう': '～でしょう',
      'すぎる': '～すぎる',
      'やすい': '～やすい',
      'にくい': '～にくい',
      'ために': '～ために',
      'たびに': '～たびに',
      'わけ': '～わけ',
      'ばかり': '～ばかり',
      'べき': '～べき',
      'ようとする': '～ようとする',
      'とは限らない': '～とは限らない',
      'わけではない': '～わけではない',
      'ないことはない': '～ないことはない',
      'ないわけにはいかない': '～ないわけにはいかない',
    };

    if (aliases.containsKey(text)) return aliases[text]!;
    final compact = text.replaceAll(' ', '');
    if (aliases.containsKey(compact)) return aliases[compact]!;
    return text.length > 70 ? text.substring(0, 70) : text;
  }

  void _update(ConceptMastery r, bool correct, int responseMs) {
    final now = DateTime.now();
    if (responseMs > 0) {
      r.totalResponseMs += responseMs;
      r.responseCount++;
      r.lastResponseMs = responseMs;
    }
    r.attempts++;

    if (correct) {
      r.correct++;
      r.streak++;
      r.ease = (r.ease + .08).clamp(1.3, 2.8).toDouble();
      if (r.streak == 1) {
        r.intervalDays = 1;
      } else if (r.intervalDays <= 0) {
        r.intervalDays = 2;
      } else {
        r.intervalDays = (r.intervalDays * r.ease).clamp(1, 60).toDouble();
      }
      r.dueAt = now.add(Duration(hours: (r.intervalDays * 24).round()));
    } else {
      r.lapses++;
      r.streak = 0;
      r.ease = (r.ease - .2).clamp(1.3, 2.8).toDouble();
      r.intervalDays = r.attempts <= 1 ? 0 : .25;
      r.dueAt = now;
    }

    r.lastSeen = now;
    r.recent.add(correct);
    if (r.recent.length > 8) r.recent.removeAt(0);
  }

  List<SessionInfo> _relatedSessions(
    List<SessionInfo> sessions,
    List<String> conceptIds,
    Set<String> completedIds,
  ) {
    final scored = <MapEntry<SessionInfo, double>>[];

    for (final session in sessions) {
      final focus = normalizeConcept(session.focus);
      var score = 0.0;

      for (final id in conceptIds) {
        if (focus == id || focus.contains(id) || id.contains(focus)) {
          score += 5;
        }
      }

      if (score > 0) scored.add(MapEntry(session, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    if (scored.isNotEmpty) {
      return scored.take(2).map((x) => x.key).toList();
    }

    final next = sessions.firstWhere(
      (s) => !completedIds.contains(s.id),
      orElse: () => sessions.isEmpty ? _emptySession() : sessions.last,
    );
    return sessions.isEmpty ? const [] : <SessionInfo>[next];
  }

  Future<void> _save(SharedPreferences prefs, String level) async {
    final data = <String, dynamic>{
      'version': 1,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'concepts': _concepts.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
    await prefs.setString(_storageKey(level), jsonEncode(data));
  }

  static SessionInfo _emptySession() => const SessionInfo(
        id: '__empty__',
        week: 0,
        day: 0,
        type: 'empty',
        titleJa: '',
        titleEs: '',
        focus: '',
        pages: <int>[],
        review: false,
      );
}
