import 'dart:convert';
import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../models/learning_vocabulary.dart';
import 'learning_database_service.dart';
import 'learning_progress_service.dart';

enum LearningSkill { meaning, reading, usage, recall, listening }

extension LearningSkillValue on LearningSkill {
  String get dbValue => name;
}

enum LearningPromptType {
  meaningMcq,
  readingMcq,
  contextCloze,
  reverseRecall,
  listeningMcq,
}

extension LearningPromptTypeValue on LearningPromptType {
  String get dbValue {
    switch (this) {
      case LearningPromptType.meaningMcq:
        return 'meaning_mcq';
      case LearningPromptType.readingMcq:
        return 'reading_mcq';
      case LearningPromptType.contextCloze:
        return 'context_cloze';
      case LearningPromptType.reverseRecall:
        return 'reverse_recall';
      case LearningPromptType.listeningMcq:
        return 'listening_mcq';
    }
  }
}

enum LearningQueueReason {
  newCore,
  newStandard,
  dueReview,
  weakMeaning,
  weakReading,
  weakUsage,
  weakRecall,
  sameSessionRetry,
}

extension LearningQueueReasonValue on LearningQueueReason {
  String get dbValue {
    switch (this) {
      case LearningQueueReason.newCore:
        return 'new_core';
      case LearningQueueReason.newStandard:
        return 'new_standard';
      case LearningQueueReason.dueReview:
        return 'due_review';
      case LearningQueueReason.weakMeaning:
        return 'weak_meaning';
      case LearningQueueReason.weakReading:
        return 'weak_reading';
      case LearningQueueReason.weakUsage:
        return 'weak_usage';
      case LearningQueueReason.weakRecall:
        return 'weak_recall';
      case LearningQueueReason.sameSessionRetry:
        return 'same_session_retry';
    }
  }
}

class LearningTask {
  final LearningVocabulary word;
  final LearningSkill skill;
  final LearningPromptType promptType;
  final LearningQueueReason reason;
  final bool isRetry;

  const LearningTask({
    required this.word,
    required this.skill,
    required this.promptType,
    required this.reason,
    this.isRetry = false,
  });

  LearningTask asRetry() {
    return LearningTask(
      word: word,
      skill: skill,
      promptType: promptType,
      reason: LearningQueueReason.sameSessionRetry,
      isRetry: true,
    );
  }
}

class LearningBatch {
  final List<LearningVocabulary> words;

  const LearningBatch(this.words);
}

class LearningDailyPlan {
  final int sessionId;
  final List<LearningBatch> newBatches;
  final List<LearningTask> dueReviewTasks;
  final int configuredNewWords;
  final int effectiveNewWords;
  final int totalDueWords;
  final bool newWordsReducedForBacklog;
  final int selectedCoreWords;
  final int selectedStandardWords;

  const LearningDailyPlan({
    required this.sessionId,
    required this.newBatches,
    required this.dueReviewTasks,
    required this.configuredNewWords,
    required this.effectiveNewWords,
    required this.totalDueWords,
    required this.newWordsReducedForBacklog,
    required this.selectedCoreWords,
    required this.selectedStandardWords,
  });

  List<LearningVocabulary> get newWords =>
      newBatches.expand((batch) => batch.words).toList(growable: false);
}

/// Pedagogical decision engine for LEARN vocabulary.
///
/// It decides what should be learned or reviewed and updates skill-specific
/// mastery. Visible quiz wording and distractors will be built separately.
class LearningEngineService {
  LearningEngineService._();

  static const double _firstCorrectGain = 28.0;
  static const double _secondCorrectGain = 18.0;
  static const double _laterCorrectGain = 12.0;
  static const double _earlyErrorPenalty = 8.0;
  static const double _normalErrorPenalty = 15.0;

  static const double _minimumEase = 1.30;
  static const double _maximumEase = 3.00;
  static const double _firstCorrectIntervalHours = 8.0;
  static const double _secondCorrectIntervalHours = 24.0;
  static const double _retryIntervalHours = 10.0 / 60.0;

  static const double _masteredMinimumScore = 85.0;
  static const int _masteredMinimumCorrectPerSkill = 4;
  static const double _masteredMinimumIntervalHours = 21.0 * 24.0;

  static Future<LearningDailyPlan> startDailySession() async {
    final progressDb = await LearningProgressService.database;
    final settings = await LearningProgressService.getSettings();

    final configuredNewWords =
        (settings['new_words_per_day'] as num?)?.toInt() ?? 10;
    final maxDueReviews =
        (settings['max_due_reviews_per_day'] as num?)?.toInt() ?? 80;
    final batchSize = (settings['batch_size'] as num?)?.toInt() ?? 5;

    final totalDueWords = await LearningProgressService.getDueReviewCount();

    final effectiveNewWords = _adaptNewWordCount(
      configuredNewWords: configuredNewWords,
      dueWords: totalDueWords,
      maxDueReviews: maxDueReviews,
      batchSize: batchSize,
    );

    final newWords = await _selectNewWords(
      limit: effectiveNewWords,
      settings: settings,
    );

    final dueTasks = await _selectDueReviewTasks(limit: maxDueReviews);

    final now = DateTime.now().toIso8601String();

    final sessionId = await progressDb.insert('learn_session', {
      'started_at': now,
      'session_type': 'daily',
      'planned_new': newWords.length,
    });

    await _writeDailyQueueLog(
      sessionId: sessionId,
      dueTasks: dueTasks,
      newWords: newWords,
      createdAt: now,
    );

    final batches = <LearningBatch>[];

    for (var index = 0; index < newWords.length; index += batchSize) {
      final end = math.min(index + batchSize, newWords.length).toInt();
      batches.add(
        LearningBatch(
          List<LearningVocabulary>.unmodifiable(newWords.sublist(index, end)),
        ),
      );
    }

    final selectedCoreWords = newWords.where((word) => word.isCore).length;
    final selectedStandardWords = newWords
        .where((word) => word.isStandard)
        .length;

    return LearningDailyPlan(
      sessionId: sessionId,
      newBatches: List<LearningBatch>.unmodifiable(batches),
      dueReviewTasks: List<LearningTask>.unmodifiable(dueTasks),
      configuredNewWords: configuredNewWords,
      effectiveNewWords: newWords.length,
      totalDueWords: totalDueWords,
      newWordsReducedForBacklog: newWords.length < configuredNewWords,
      selectedCoreWords: selectedCoreWords,
      selectedStandardWords: selectedStandardWords,
    );
  }

  static Future<void> introduceWord({
    required int sessionId,
    required LearningVocabulary word,
  }) async {
    final before = await LearningProgressService.getItemState(word.id);
    final wasUnseen = before == null || before['state']?.toString() == 'unseen';

    await LearningProgressService.introduceVocabulary(word);

    final progressDb = await LearningProgressService.database;

    await progressDb.transaction((txn) async {
      if (!_containsKanji(word.expression)) {
        await txn.update(
          'learn_skill_state',
          {'enabled': 0, 'next_due_at': null},
          where: 'vocabulary_id = ? AND skill = ?',
          whereArgs: [word.id, LearningSkill.reading.dbValue],
        );
      }

      if (!word.hasExample) {
        await txn.update(
          'learn_skill_state',
          {'enabled': 0, 'next_due_at': null},
          where: 'vocabulary_id = ? AND skill = ?',
          whereArgs: [word.id, LearningSkill.usage.dbValue],
        );
      }

      await txn.update(
        'learn_skill_state',
        {'enabled': 0, 'next_due_at': null},
        where: 'vocabulary_id = ? AND skill = ?',
        whereArgs: [word.id, LearningSkill.listening.dbValue],
      );

      if (wasUnseen) {
        await txn.rawUpdate(
          '''
          UPDATE learn_session
          SET introduced_count = introduced_count + 1
          WHERE id = ?
          ''',
          [sessionId],
        );
      }
    });
  }

  static List<LearningTask> buildBatchCheckTasks(
    Iterable<LearningVocabulary> words,
  ) {
    final tasks = <LearningTask>[];

    for (final word in words) {
      tasks.add(
        LearningTask(
          word: word,
          skill: LearningSkill.meaning,
          promptType: LearningPromptType.meaningMcq,
          reason: _newReason(word),
        ),
      );

      if (_containsKanji(word.expression)) {
        tasks.add(
          LearningTask(
            word: word,
            skill: LearningSkill.reading,
            promptType: LearningPromptType.readingMcq,
            reason: _newReason(word),
          ),
        );
      }
    }

    return List<LearningTask>.unmodifiable(tasks);
  }

  static List<LearningTask> buildCumulativeTasks(
    Iterable<LearningVocabulary> words,
  ) {
    final tasks = <LearningTask>[];

    for (final word in words) {
      if (word.hasExample) {
        tasks.add(
          LearningTask(
            word: word,
            skill: LearningSkill.usage,
            promptType: LearningPromptType.contextCloze,
            reason: _newReason(word),
          ),
        );
      }

      tasks.add(
        LearningTask(
          word: word,
          skill: LearningSkill.recall,
          promptType: LearningPromptType.reverseRecall,
          reason: _newReason(word),
        ),
      );
    }

    return List<LearningTask>.unmodifiable(tasks);
  }

  static LearningTask buildRetryTask(LearningTask failedTask) {
    return failedTask.asRetry();
  }

  static int get recommendedRetryGapCards => 2;

  static Future<void> recordAttempt({
    required int sessionId,
    required LearningTask task,
    required bool correct,
    int? responseTimeMs,
    String? responseValue,
    List<String> distractors = const <String>[],
  }) async {
    if (responseTimeMs != null && responseTimeMs < 0) {
      throw ArgumentError.value(
        responseTimeMs,
        'responseTimeMs',
        'Response time cannot be negative.',
      );
    }

    final progressDb = await LearningProgressService.database;

    final itemBefore = await LearningProgressService.getItemState(task.word.id);
    if (itemBefore == null) {
      await introduceWord(sessionId: sessionId, word: task.word);
    }

    await progressDb.transaction((txn) async {
      final itemRows = await txn.query(
        'learn_item_state',
        where: 'vocabulary_id = ?',
        whereArgs: [task.word.id],
        limit: 1,
      );

      if (itemRows.isEmpty) {
        throw StateError(
          'LEARN item state could not be initialized for ${task.word.id}.',
        );
      }

      final skillRows = await txn.query(
        'learn_skill_state',
        where: 'vocabulary_id = ? AND skill = ?',
        whereArgs: [task.word.id, task.skill.dbValue],
        limit: 1,
      );

      if (skillRows.isEmpty) {
        throw StateError(
          'LEARN skill state is missing for '
          '${task.word.id}/${task.skill.dbValue}.',
        );
      }

      final item = itemRows.first;
      final skill = skillRows.first;

      final enabled = (skill['enabled'] as num?)?.toInt() ?? 0;
      if (enabled != 1) {
        throw StateError(
          'Cannot record a disabled LEARN skill: '
          '${task.word.id}/${task.skill.dbValue}.',
        );
      }

      final now = DateTime.now();
      final nowText = now.toIso8601String();
      final stateBefore = item['state']?.toString() ?? 'introduced';

      final oldMastery = (skill['mastery_score'] as num?)?.toDouble() ?? 0.0;
      final oldAttempts = (skill['attempts'] as num?)?.toInt() ?? 0;
      final oldCorrectAttempts =
          (skill['correct_attempts'] as num?)?.toInt() ?? 0;
      final oldConsecutive =
          (skill['consecutive_correct'] as num?)?.toInt() ?? 0;
      final oldLapses = (skill['lapses'] as num?)?.toInt() ?? 0;
      final oldInterval = (skill['interval_hours'] as num?)?.toDouble() ?? 0.0;
      final oldEase = (skill['ease_factor'] as num?)?.toDouble() ?? 2.30;

      final newMastery = _nextMastery(
        current: oldMastery,
        correct: correct,
        previousConsecutiveCorrect: oldConsecutive,
      );

      final newConsecutive = correct ? oldConsecutive + 1 : 0;
      final newLapses = correct ? oldLapses : oldLapses + 1;

      final newEase = correct
          ? (oldEase + 0.05).clamp(_minimumEase, _maximumEase).toDouble()
          : (oldEase - 0.15).clamp(_minimumEase, _maximumEase).toDouble();

      final newInterval = _nextIntervalHours(
        currentIntervalHours: oldInterval,
        easeFactor: newEase,
        correct: correct,
      );

      final nextDue = now.add(
        Duration(seconds: math.max(1, (newInterval * 3600).round()).toInt()),
      );

      await txn.update(
        'learn_skill_state',
        {
          'mastery_score': newMastery,
          'attempts': oldAttempts + 1,
          'correct_attempts': oldCorrectAttempts + (correct ? 1 : 0),
          'consecutive_correct': newConsecutive,
          'lapses': newLapses,
          'last_result': correct ? 1 : 0,
          'last_attempt_at': nowText,
          'next_due_at': nextDue.toIso8601String(),
          'interval_hours': newInterval,
          'ease_factor': newEase,
        },
        where: 'vocabulary_id = ? AND skill = ?',
        whereArgs: [task.word.id, task.skill.dbValue],
      );

      final refreshedSkills = await txn.query(
        'learn_skill_state',
        where: 'vocabulary_id = ? AND enabled = 1',
        whereArgs: [task.word.id],
      );

      final overallMastery = _averageEnabledMastery(refreshedSkills);
      final nextItemDue = _earliestDue(refreshedSkills);

      final oldTotalAttempts = (item['total_attempts'] as num?)?.toInt() ?? 0;
      final oldTotalCorrect = (item['total_correct'] as num?)?.toInt() ?? 0;
      final oldTotalLapses = (item['total_lapses'] as num?)?.toInt() ?? 0;
      final oldItemConsecutive =
          (item['consecutive_correct'] as num?)?.toInt() ?? 0;

      final newTotalLapses = oldTotalLapses + (correct ? 0 : 1);

      final stateAfter = _nextItemState(
        currentState: stateBefore,
        skills: refreshedSkills,
        latestCorrect: correct,
      );

      final itemValues = <String, Object?>{
        'state': stateAfter,
        'last_seen_at': nowText,
        'total_attempts': oldTotalAttempts + 1,
        'total_correct': oldTotalCorrect + (correct ? 1 : 0),
        'total_lapses': newTotalLapses,
        'consecutive_correct': correct ? oldItemConsecutive + 1 : 0,
        'leech_score': newTotalLapses ~/ 3,
        'next_due_at': nextItemDue,
        'mastery_score': overallMastery,
        'updated_at': nowText,
      };

      if (stateAfter == 'review' &&
          stateBefore != 'review' &&
          item['entered_review_at'] == null) {
        itemValues['entered_review_at'] = nowText;
      }

      if (stateAfter == 'mastered' && stateBefore != 'mastered') {
        itemValues['mastered_at'] = nowText;
      }

      if (stateAfter != 'mastered' && stateBefore == 'mastered') {
        itemValues['mastered_at'] = null;
      }

      await txn.update(
        'learn_item_state',
        itemValues,
        where: 'vocabulary_id = ?',
        whereArgs: [task.word.id],
      );

      await txn.insert('learn_attempt_log', {
        'session_id': sessionId,
        'vocabulary_id': task.word.id,
        'skill': task.skill.dbValue,
        'prompt_type': task.promptType.dbValue,
        'attempted_at': nowText,
        'correct': correct ? 1 : 0,
        'response_time_ms': responseTimeMs,
        'response_value': responseValue,
        'distractors_json': jsonEncode(distractors),
        'mastery_before': oldMastery,
        'mastery_after': newMastery,
        'state_before': stateBefore,
        'state_after': stateAfter,
      });

      final attemptColumn = '${task.skill.dbValue}_attempts';
      final correctColumn = '${task.skill.dbValue}_correct';

      await txn.rawUpdate(
        '''
        UPDATE learn_session
        SET
          attempts = attempts + 1,
          correct_attempts = correct_attempts + ?,
          $attemptColumn = $attemptColumn + 1,
          $correctColumn = $correctColumn + ?
        WHERE id = ?
        ''',
        [correct ? 1 : 0, correct ? 1 : 0, sessionId],
      );
    });
  }

  static Future<void> completeSession(int sessionId) async {
    final progressDb = await LearningProgressService.database;

    await progressDb.update(
      'learn_session',
      {'completed': 1, 'completed_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  static Future<List<LearningTask>> buildWeakWordTasks({int limit = 20}) async {
    final progressDb = await LearningProgressService.database;

    final rows = await progressDb.rawQuery('''
      SELECT
        s.vocabulary_id,
        s.skill,
        s.mastery_score,
        s.attempts,
        s.lapses
      FROM learn_skill_state s
      JOIN learn_item_state i
        ON i.vocabulary_id = s.vocabulary_id
      WHERE s.enabled = 1
        AND i.state IN ('learning', 'review', 'mastered')
        AND s.skill <> 'listening'
        AND (
          (s.attempts >= 2 AND s.mastery_score < 60)
          OR s.lapses >= 2
        )
      ORDER BY
        CASE WHEN s.lapses >= 2 THEN 0 ELSE 1 END,
        s.mastery_score ASC,
        s.lapses DESC,
        s.last_attempt_at ASC
      ''');

    final selectedRows = <Map<String, Object?>>[];
    final seenVocabulary = <String>{};

    for (final row in rows) {
      final vocabularyId = row['vocabulary_id']?.toString();
      if (vocabularyId == null || seenVocabulary.contains(vocabularyId)) {
        continue;
      }

      selectedRows.add(row);
      seenVocabulary.add(vocabularyId);

      if (selectedRows.length >= limit) {
        break;
      }
    }

    final words = await LearningDatabaseService.getVocabularyByIds(
      selectedRows.map((row) => row['vocabulary_id']!.toString()),
    );
    final wordsById = <String, LearningVocabulary>{
      for (final word in words) word.id: word,
    };

    final tasks = <LearningTask>[];

    for (final row in selectedRows) {
      final vocabularyId = row['vocabulary_id']!.toString();
      final word = wordsById[vocabularyId];
      if (word == null) continue;

      final skill = _skillFromDb(row['skill']!.toString());

      tasks.add(
        LearningTask(
          word: word,
          skill: skill,
          promptType: _promptForSkill(skill),
          reason: _weakReason(skill),
        ),
      );
    }

    return List<LearningTask>.unmodifiable(tasks);
  }

  static Future<List<LearningVocabulary>> _selectNewWords({
    required int limit,
    required Map<String, dynamic> settings,
  }) async {
    if (limit <= 0) {
      return const <LearningVocabulary>[];
    }

    final progressDb = await LearningProgressService.database;
    final allVocabulary = await LearningDatabaseService.getVocabulary();

    final unseenRows = await progressDb.query(
      'learn_item_state',
      columns: ['vocabulary_id', 'priority'],
      where: 'state = ?',
      whereArgs: ['unseen'],
    );

    final unseenIds = unseenRows
        .map((row) => row['vocabulary_id']?.toString())
        .whereType<String>()
        .toSet();

    final coreUnseen = allVocabulary
        .where((word) => word.isCore && unseenIds.contains(word.id))
        .toList(growable: false);

    final standardUnseen = allVocabulary
        .where((word) => word.isStandard && unseenIds.contains(word.id))
        .toList(growable: false);

    final coreTotal = allVocabulary.where((word) => word.isCore).length;
    final coreSeen = coreTotal - coreUnseen.length;

    final unlockAt =
        (settings['introduce_standard_after_core_seen'] as num?)?.toDouble() ??
        0.35;

    final standardUnlocked =
        coreTotal == 0 || (coreSeen / coreTotal) >= unlockAt;

    if (!standardUnlocked || standardUnseen.isEmpty) {
      return List<LearningVocabulary>.unmodifiable(coreUnseen.take(limit));
    }

    if (coreUnseen.isEmpty) {
      return List<LearningVocabulary>.unmodifiable(standardUnseen.take(limit));
    }

    final coreRatio =
        (settings['core_before_standard_ratio'] as num?)?.toDouble() ?? 0.80;

    var coreTarget = (limit * coreRatio).round().clamp(0, limit).toInt();
    var standardTarget = limit - coreTarget;

    if (limit >= 5 && standardTarget == 0 && standardUnseen.isNotEmpty) {
      standardTarget = 1;
      coreTarget = limit - 1;
    }

    final selected = <LearningVocabulary>[
      ...coreUnseen.take(coreTarget),
      ...standardUnseen.take(standardTarget),
    ];

    if (selected.length < limit) {
      final selectedIds = selected.map((word) => word.id).toSet();

      final remainder = <LearningVocabulary>[
        ...coreUnseen,
        ...standardUnseen,
      ].where((word) => !selectedIds.contains(word.id));

      selected.addAll(remainder.take(limit - selected.length));
    }

    selected.sort((a, b) => a.learningOrder.compareTo(b.learningOrder));

    return List<LearningVocabulary>.unmodifiable(selected);
  }

  static Future<List<LearningTask>> _selectDueReviewTasks({
    required int limit,
  }) async {
    if (limit <= 0) {
      return const <LearningTask>[];
    }

    final progressDb = await LearningProgressService.database;
    final now = DateTime.now().toIso8601String();

    final rows = await progressDb.rawQuery(
      '''
      SELECT
        s.vocabulary_id,
        s.skill,
        s.mastery_score,
        s.next_due_at,
        s.lapses
      FROM learn_skill_state s
      JOIN learn_item_state i
        ON i.vocabulary_id = s.vocabulary_id
      WHERE s.enabled = 1
        AND s.next_due_at IS NOT NULL
        AND s.next_due_at <= ?
        AND i.state IN ('introduced', 'learning', 'review', 'mastered')
        AND i.state <> 'suspended'
      ORDER BY
        s.next_due_at ASC,
        s.mastery_score ASC,
        s.lapses DESC
      ''',
      [now],
    );

    final selectedRows = <Map<String, Object?>>[];
    final seenVocabulary = <String>{};

    for (final row in rows) {
      final vocabularyId = row['vocabulary_id']?.toString();
      if (vocabularyId == null || seenVocabulary.contains(vocabularyId)) {
        continue;
      }

      selectedRows.add(row);
      seenVocabulary.add(vocabularyId);

      if (selectedRows.length >= limit) {
        break;
      }
    }

    final words = await LearningDatabaseService.getVocabularyByIds(
      selectedRows.map((row) => row['vocabulary_id']!.toString()),
    );
    final wordsById = <String, LearningVocabulary>{
      for (final word in words) word.id: word,
    };

    final tasks = <LearningTask>[];

    for (final row in selectedRows) {
      final vocabularyId = row['vocabulary_id']!.toString();
      final word = wordsById[vocabularyId];
      if (word == null) continue;

      final skill = _skillFromDb(row['skill']!.toString());

      tasks.add(
        LearningTask(
          word: word,
          skill: skill,
          promptType: _promptForSkill(skill),
          reason: LearningQueueReason.dueReview,
        ),
      );
    }

    return List<LearningTask>.unmodifiable(tasks);
  }

  static Future<void> _writeDailyQueueLog({
    required int sessionId,
    required List<LearningTask> dueTasks,
    required List<LearningVocabulary> newWords,
    required String createdAt,
  }) async {
    final progressDb = await LearningProgressService.database;

    await progressDb.transaction((txn) async {
      var position = 0;

      for (final task in dueTasks) {
        await txn.insert('learn_queue_log', {
          'session_id': sessionId,
          'vocabulary_id': task.word.id,
          'queue_reason': task.reason.dbValue,
          'position': position,
          'created_at': createdAt,
        });
        position += 1;
      }

      for (final word in newWords) {
        await txn.insert('learn_queue_log', {
          'session_id': sessionId,
          'vocabulary_id': word.id,
          'queue_reason': _newReason(word).dbValue,
          'position': position,
          'created_at': createdAt,
        });
        position += 1;
      }
    });
  }

  static int _adaptNewWordCount({
    required int configuredNewWords,
    required int dueWords,
    required int maxDueReviews,
    required int batchSize,
  }) {
    if (configuredNewWords <= 0) {
      return 0;
    }

    if (dueWords >= maxDueReviews) {
      return 0;
    }

    final backlogRatio = maxDueReviews <= 0 ? 1.0 : dueWords / maxDueReviews;

    if (backlogRatio >= 0.75) {
      return math.min(configuredNewWords, batchSize).toInt();
    }

    if (backlogRatio >= 0.50) {
      final reduced = (configuredNewWords * 0.75).round();
      return math.max(math.min(batchSize, configuredNewWords), reduced).toInt();
    }

    return configuredNewWords;
  }

  static double _nextMastery({
    required double current,
    required bool correct,
    required int previousConsecutiveCorrect,
  }) {
    if (!correct) {
      final penalty = current < 30 ? _earlyErrorPenalty : _normalErrorPenalty;
      return (current - penalty).clamp(0.0, 100.0).toDouble();
    }

    final gain = previousConsecutiveCorrect == 0
        ? _firstCorrectGain
        : previousConsecutiveCorrect == 1
        ? _secondCorrectGain
        : _laterCorrectGain;

    return (current + gain).clamp(0.0, 100.0).toDouble();
  }

  static double _nextIntervalHours({
    required double currentIntervalHours,
    required double easeFactor,
    required bool correct,
  }) {
    if (!correct) {
      return _retryIntervalHours;
    }

    if (currentIntervalHours <= 0) {
      return _firstCorrectIntervalHours;
    }

    if (currentIntervalHours < _secondCorrectIntervalHours) {
      return _secondCorrectIntervalHours;
    }

    return (currentIntervalHours * easeFactor)
        .clamp(_secondCorrectIntervalHours, 10.0 * 365.0 * 24.0)
        .toDouble();
  }

  static double _averageEnabledMastery(List<Map<String, Object?>> skills) {
    if (skills.isEmpty) {
      return 0.0;
    }

    final total = skills.fold<double>(
      0.0,
      (sum, row) => sum + ((row['mastery_score'] as num?)?.toDouble() ?? 0.0),
    );

    return (total / skills.length).clamp(0.0, 100.0).toDouble();
  }

  static String? _earliestDue(List<Map<String, Object?>> skills) {
    final dueValues = skills
        .map((row) => row['next_due_at']?.toString())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (dueValues.isEmpty) {
      return null;
    }

    dueValues.sort();
    return dueValues.first;
  }

  static String _nextItemState({
    required String currentState,
    required List<Map<String, Object?>> skills,
    required bool latestCorrect,
  }) {
    if (currentState == 'suspended') {
      return 'suspended';
    }

    if (!latestCorrect && currentState == 'mastered') {
      return 'review';
    }

    if (_qualifiesForMastered(skills)) {
      return 'mastered';
    }

    if (_qualifiesForReview(skills)) {
      return 'review';
    }

    return 'learning';
  }

  static bool _qualifiesForReview(List<Map<String, Object?>> skills) {
    final coreSkills = skills.where(
      (row) => row['skill']?.toString() != 'listening',
    );

    if (coreSkills.isEmpty) {
      return false;
    }

    return coreSkills.every((row) {
      final correctAttempts = (row['correct_attempts'] as num?)?.toInt() ?? 0;
      final lastResult = (row['last_result'] as num?)?.toInt();

      return correctAttempts >= 1 && lastResult == 1;
    });
  }

  static bool _qualifiesForMastered(List<Map<String, Object?>> skills) {
    final coreSkills = skills.where(
      (row) => row['skill']?.toString() != 'listening',
    );

    if (coreSkills.isEmpty) {
      return false;
    }

    return coreSkills.every((row) {
      final mastery = (row['mastery_score'] as num?)?.toDouble() ?? 0.0;
      final correctAttempts = (row['correct_attempts'] as num?)?.toInt() ?? 0;
      final interval = (row['interval_hours'] as num?)?.toDouble() ?? 0.0;

      return mastery >= _masteredMinimumScore &&
          correctAttempts >= _masteredMinimumCorrectPerSkill &&
          interval >= _masteredMinimumIntervalHours;
    });
  }

  static bool _containsKanji(String value) {
    return RegExp(r'[一-龯々]').hasMatch(value);
  }

  static LearningQueueReason _newReason(LearningVocabulary word) {
    return word.isCore
        ? LearningQueueReason.newCore
        : LearningQueueReason.newStandard;
  }

  static LearningSkill _skillFromDb(String value) {
    switch (value) {
      case 'meaning':
        return LearningSkill.meaning;
      case 'reading':
        return LearningSkill.reading;
      case 'usage':
        return LearningSkill.usage;
      case 'recall':
        return LearningSkill.recall;
      case 'listening':
        return LearningSkill.listening;
      default:
        throw FormatException('Unknown LEARN skill: $value');
    }
  }

  static LearningPromptType _promptForSkill(LearningSkill skill) {
    switch (skill) {
      case LearningSkill.meaning:
        return LearningPromptType.meaningMcq;
      case LearningSkill.reading:
        return LearningPromptType.readingMcq;
      case LearningSkill.usage:
        return LearningPromptType.contextCloze;
      case LearningSkill.recall:
        return LearningPromptType.reverseRecall;
      case LearningSkill.listening:
        return LearningPromptType.listeningMcq;
    }
  }

  static LearningQueueReason _weakReason(LearningSkill skill) {
    switch (skill) {
      case LearningSkill.meaning:
        return LearningQueueReason.weakMeaning;
      case LearningSkill.reading:
        return LearningQueueReason.weakReading;
      case LearningSkill.usage:
        return LearningQueueReason.weakUsage;
      case LearningSkill.recall:
        return LearningQueueReason.weakRecall;
      case LearningSkill.listening:
        return LearningQueueReason.weakRecall;
    }
  }
}
