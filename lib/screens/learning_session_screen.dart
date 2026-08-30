import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/learning_vocabulary.dart';
import '../services/learning_engine_service.dart';
import '../services/learning_question_service.dart';
import '../theme/app_colors.dart';

enum _SessionStage {
  introduction,
  batchCheck,
  cumulativeCheck,
  dueReview,
  summary,
}

class LearningSessionScreen extends StatefulWidget {
  const LearningSessionScreen({super.key});

  @override
  State<LearningSessionScreen> createState() => _LearningSessionScreenState();
}

class _LearningSessionScreenState extends State<LearningSessionScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;

  LearningDailyPlan? _plan;
  _SessionStage _stage = _SessionStage.introduction;

  int _batchIndex = 0;
  int _introIndex = 0;

  List<LearningTask> _tasks = <LearningTask>[];
  int _taskIndex = 0;
  LearningQuestion? _question;

  String? _selectedOption;
  bool _showFeedback = false;
  bool _recallRevealed = false;
  bool? _lastCorrect;

  final Map<String, int> _retryCounts = <String, int>{};

  int _attempts = 0;
  int _correct = 0;

  final Map<LearningSkill, int> _skillAttempts = <LearningSkill, int>{
    LearningSkill.meaning: 0,
    LearningSkill.reading: 0,
    LearningSkill.usage: 0,
    LearningSkill.recall: 0,
  };

  final Map<LearningSkill, int> _skillCorrect = <LearningSkill, int>{
    LearningSkill.meaning: 0,
    LearningSkill.reading: 0,
    LearningSkill.usage: 0,
    LearningSkill.recall: 0,
  };

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final plan = await LearningEngineService.startDailySession();

      if (!mounted) return;
      _plan = plan;

      if (plan.newBatches.isNotEmpty) {
        await _startIntroductionBatch(0);
        return;
      }

      if (plan.dueReviewTasks.isNotEmpty) {
        await _startTaskPhase(_SessionStage.dueReview, plan.dueReviewTasks);
        return;
      }

      await LearningEngineService.completeSession(plan.sessionId);

      if (!mounted) return;
      setState(() {
        _stage = _SessionStage.summary;
        _loading = false;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _startIntroductionBatch(int index) async {
    final plan = _plan;
    if (plan == null || index >= plan.newBatches.length) return;

    setState(() {
      _batchIndex = index;
      _introIndex = 0;
      _stage = _SessionStage.introduction;
      _loading = true;
      _busy = false;
      _error = null;
      _tasks = <LearningTask>[];
      _taskIndex = 0;
      _question = null;
      _resetAnswer();
    });

    await _introduceCurrentWord();
  }

  Future<void> _introduceCurrentWord() async {
    final plan = _plan;
    final word = _currentIntroWord;
    if (plan == null || word == null) return;

    try {
      await LearningEngineService.introduceWord(
        sessionId: plan.sessionId,
        word: word,
      );

      if (!mounted) return;
      setState(() {
        _loading = false;
        _busy = false;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _continueIntroduction() async {
    if (_busy) return;

    final plan = _plan;
    if (plan == null) return;

    final batch = plan.newBatches[_batchIndex];

    if (_introIndex + 1 < batch.words.length) {
      setState(() {
        _busy = true;
        _introIndex += 1;
      });
      await _introduceCurrentWord();
      return;
    }

    await _startTaskPhase(
      _SessionStage.batchCheck,
      LearningEngineService.buildBatchCheckTasks(batch.words),
    );
  }

  Future<void> _startTaskPhase(
    _SessionStage stage,
    Iterable<LearningTask> tasks,
  ) async {
    setState(() {
      _stage = stage;
      _tasks = List<LearningTask>.from(tasks);
      _taskIndex = 0;
      _question = null;
      _loading = true;
      _busy = false;
      _error = null;
      _resetAnswer();
    });

    if (_tasks.isEmpty) {
      await _finishTaskPhase();
      return;
    }

    await _loadCurrentQuestion();
  }

  Future<void> _loadCurrentQuestion() async {
    if (_taskIndex >= _tasks.length) {
      await _finishTaskPhase();
      return;
    }

    try {
      final question = await LearningQuestionService.buildQuestion(
        _tasks[_taskIndex],
      );

      if (!mounted) return;
      setState(() {
        _question = question;
        _loading = false;
        _busy = false;
        _resetAnswer();
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _finishTaskPhase() async {
    final plan = _plan;
    if (plan == null) return;

    if (_stage == _SessionStage.batchCheck) {
      if (_batchIndex + 1 < plan.newBatches.length) {
        await _startIntroductionBatch(_batchIndex + 1);
        return;
      }

      final cumulative = LearningEngineService.buildCumulativeTasks(
        plan.newWords,
      );

      if (cumulative.isNotEmpty) {
        await _startTaskPhase(_SessionStage.cumulativeCheck, cumulative);
        return;
      }
    }

    if ((_stage == _SessionStage.batchCheck ||
            _stage == _SessionStage.cumulativeCheck) &&
        plan.dueReviewTasks.isNotEmpty) {
      await _startTaskPhase(_SessionStage.dueReview, plan.dueReviewTasks);
      return;
    }

    await _completeSession();
  }

  Future<void> _completeSession() async {
    final plan = _plan;
    if (plan == null) return;

    setState(() {
      _loading = true;
      _busy = true;
    });

    try {
      await LearningEngineService.completeSession(plan.sessionId);

      if (!mounted) return;
      setState(() {
        _stage = _SessionStage.summary;
        _loading = false;
        _busy = false;
        _question = null;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _choose(String option) async {
    final question = _question;
    final plan = _plan;

    if (question == null ||
        plan == null ||
        !question.isMultipleChoice ||
        _showFeedback ||
        _busy) {
      return;
    }

    final correct = question.acceptedAnswers.contains(option);

    setState(() {
      _selectedOption = option;
      _busy = true;
    });

    try {
      await LearningEngineService.recordAttempt(
        sessionId: plan.sessionId,
        task: question.task,
        correct: correct,
        responseValue: option,
        distractors: question.options
            .where((value) => !question.acceptedAnswers.contains(value))
            .toList(growable: false),
      );

      _register(question.task.skill, correct);
      if (!correct) _insertRetry(question.task);

      if (!mounted) return;
      setState(() {
        _busy = false;
        _showFeedback = true;
        _lastCorrect = correct;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _rateRecall(bool remembered) async {
    final question = _question;
    final plan = _plan;

    if (question == null ||
        plan == null ||
        !question.isSelfRecall ||
        !_recallRevealed ||
        _showFeedback ||
        _busy) {
      return;
    }

    setState(() => _busy = true);

    try {
      await LearningEngineService.recordAttempt(
        sessionId: plan.sessionId,
        task: question.task,
        correct: remembered,
        responseValue: remembered ? 'remembered' : 'not_remembered',
      );

      _register(question.task.skill, remembered);
      if (!remembered) _insertRetry(question.task);

      if (!mounted) return;
      setState(() {
        _busy = false;
        _showFeedback = true;
        _lastCorrect = remembered;
      });
    } catch (error) {
      _showError(error);
    }
  }

  void _register(LearningSkill skill, bool correct) {
    _attempts += 1;
    if (correct) _correct += 1;

    if (_skillAttempts.containsKey(skill)) {
      _skillAttempts[skill] = (_skillAttempts[skill] ?? 0) + 1;
      if (correct) {
        _skillCorrect[skill] = (_skillCorrect[skill] ?? 0) + 1;
      }
    }
  }

  void _insertRetry(LearningTask failedTask) {
    final key = '${failedTask.word.id}:${failedTask.skill.dbValue}';
    final count = _retryCounts[key] ?? 0;
    if (count >= 2) return;

    _retryCounts[key] = count + 1;

    final desired =
        _taskIndex + LearningEngineService.recommendedRetryGapCards + 1;
    final index = math.min(desired, _tasks.length).toInt();

    _tasks.insert(index, LearningEngineService.buildRetryTask(failedTask));
  }

  Future<void> _continueQuestion() async {
    if (!_showFeedback || _busy) return;

    setState(() {
      _taskIndex += 1;
      _question = null;
      _loading = true;
      _resetAnswer();
    });

    await _loadCurrentQuestion();
  }

  void _resetAnswer() {
    _selectedOption = null;
    _showFeedback = false;
    _recallRevealed = false;
    _lastCorrect = null;
  }

  void _showError(Object error) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _busy = false;
      _error = error.toString();
    });
  }

  LearningVocabulary? get _currentIntroWord {
    final plan = _plan;
    if (plan == null ||
        plan.newBatches.isEmpty ||
        _batchIndex >= plan.newBatches.length) {
      return null;
    }

    final batch = plan.newBatches[_batchIndex];
    if (_introIndex >= batch.words.length) return null;

    return batch.words[_introIndex];
  }

  int get _currentBatchSize {
    final plan = _plan;
    if (plan == null ||
        plan.newBatches.isEmpty ||
        _batchIndex >= plan.newBatches.length) {
      return 0;
    }
    return plan.newBatches[_batchIndex].words.length;
  }

  String get _stageTitle => switch (_stage) {
    _SessionStage.introduction => 'Learn',
    _SessionStage.batchCheck => 'Quick check',
    _SessionStage.cumulativeCheck => 'Use & recall',
    _SessionStage.dueReview => 'Review',
    _SessionStage.summary => 'Complete',
  };

  String get _stageSubtitle => switch (_stage) {
    _SessionStage.introduction =>
      'Understand the word before testing yourself.',
    _SessionStage.batchCheck =>
      'Check meaning and reading while the words are fresh.',
    _SessionStage.cumulativeCheck =>
      'Retrieve the words through context and active recall.',
    _SessionStage.dueReview => 'Protect what you learned on previous days.',
    _SessionStage.summary => 'Your study session is complete.',
  };

  double get _progress {
    if (_stage == _SessionStage.summary) return 1.0;

    if (_stage == _SessionStage.introduction) {
      final size = _currentBatchSize;
      if (size == 0) return 0.0;
      return ((_introIndex + 1) / size).clamp(0.0, 1.0);
    }

    if (_tasks.isEmpty) return 0.0;
    return ((_taskIndex + 1) / _tasks.length).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('N4 Vocabulary')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _SessionHeader(
              title: _stageTitle,
              subtitle: _stageSubtitle,
              progress: _progress,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _ErrorView(
        key: const ValueKey<String>('error'),
        message: _error!,
        onClose: () => Navigator.of(context).pop(),
      );
    }

    if (_loading) {
      return const Center(
        key: ValueKey<String>('loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (_stage == _SessionStage.summary) {
      return _SummaryView(
        key: const ValueKey<String>('summary'),
        plan: _plan,
        attempts: _attempts,
        correct: _correct,
        skillAttempts: _skillAttempts,
        skillCorrect: _skillCorrect,
        onDone: () => Navigator.of(context).pop(true),
      );
    }

    if (_stage == _SessionStage.introduction) {
      final word = _currentIntroWord;
      if (word == null) return const SizedBox.shrink();

      return _IntroductionView(
        key: ValueKey<String>('intro:${word.id}:$_introIndex'),
        word: word,
        batchNumber: _batchIndex + 1,
        totalBatches: _plan?.newBatches.length ?? 1,
        position: _introIndex + 1,
        batchSize: _currentBatchSize,
        busy: _busy,
        onContinue: _continueIntroduction,
      );
    }

    final question = _question;
    if (question == null) return const SizedBox.shrink();

    return _QuestionView(
      key: ValueKey<String>(
        'q:${question.task.word.id}:${question.task.skill.dbValue}:$_taskIndex',
      ),
      question: question,
      selectedOption: _selectedOption,
      showFeedback: _showFeedback,
      recallRevealed: _recallRevealed,
      lastCorrect: _lastCorrect,
      busy: _busy,
      onOptionSelected: _choose,
      onRevealRecall: () {
        setState(() => _recallRevealed = true);
      },
      onRateRecall: _rateRecall,
      onContinue: _continueQuestion,
    );
  }
}

class _SessionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;

  const _SessionHeader({
    required this.title,
    required this.subtitle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryStrong,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: progress, minHeight: 7),
          ),
        ],
      ),
    );
  }
}

class _IntroductionView extends StatelessWidget {
  final LearningVocabulary word;
  final int batchNumber;
  final int totalBatches;
  final int position;
  final int batchSize;
  final bool busy;
  final Future<void> Function() onContinue;

  const _IntroductionView({
    super.key,
    required this.word,
    required this.batchNumber,
    required this.totalBatches,
    required this.position,
    required this.batchSize,
    required this.busy,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final showReading = word.reading.trim() != word.expression.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
      children: [
        Row(
          children: [
            _Pill(text: 'BLOCK $batchNumber / $totalBatches'),
            const Spacer(),
            Text(
              '$position of $batchSize',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 27, 22, 24),
            child: Column(
              children: [
                _PriorityBadge(priority: word.priority),
                const SizedBox(height: 21),
                Text(
                  word.expression,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 43,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                if (showReading) ...[
                  const SizedBox(height: 8),
                  Text(
                    word.reading,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  word.meaning,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (word.partOfSpeech != null) ...[
                  const SizedBox(height: 9),
                  _Pill(text: word.partOfSpeech!),
                ],
                if (word.additionalMeanings.isNotEmpty) ...[
                  const SizedBox(height: 13),
                  Text(
                    'Also: ${word.additionalMeanings.join(' · ')}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (word.hasExample) ...[
          const SizedBox(height: 14),
          _ExampleCard(
            japanese: word.exampleJapanese!,
            reading: word.exampleReading,
            english: word.exampleEnglish,
          ),
        ],
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.sageSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.sage,
                size: 21,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Say the reading quietly, connect it with the meaning, '
                  'and notice how it appears in the example. You will have '
                  'to retrieve it without this support in a moment.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: busy ? null : () => onContinue(),
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(position < batchSize ? 'Next word' : 'Check this block'),
        ),
      ],
    );
  }
}

class _QuestionView extends StatelessWidget {
  final LearningQuestion question;
  final String? selectedOption;
  final bool showFeedback;
  final bool recallRevealed;
  final bool? lastCorrect;
  final bool busy;
  final Future<void> Function(String) onOptionSelected;
  final VoidCallback onRevealRecall;
  final Future<void> Function(bool) onRateRecall;
  final Future<void> Function() onContinue;

  const _QuestionView({
    super.key,
    required this.question,
    required this.selectedOption,
    required this.showFeedback,
    required this.recallRevealed,
    required this.lastCorrect,
    required this.busy,
    required this.onOptionSelected,
    required this.onRevealRecall,
    required this.onRateRecall,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
      children: [
        Row(
          children: [
            _SkillBadge(skill: question.task.skill),
            if (question.task.isRetry) ...[
              const SizedBox(width: 8),
              const _Pill(text: 'RETRY'),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 23, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _instruction(question.style),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 19),
                Text(
                  question.prompt,
                  textAlign: TextAlign.center,
                  style: question.isSelfRecall
                      ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        )
                      : const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 39,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                ),
                if (question.contextJapanese != null) ...[
                  const SizedBox(height: 18),
                  _ExampleCard(
                    japanese: question.contextJapanese!,
                    reading: showFeedback ? question.contextReading : null,
                    english: showFeedback ? question.contextEnglish : null,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 13),
        if (question.isMultipleChoice)
          ...question.options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _AnswerOption(
                text: option,
                selected: selectedOption == option,
                correct:
                    showFeedback && question.acceptedAnswers.contains(option),
                incorrect:
                    showFeedback &&
                    selectedOption == option &&
                    !question.acceptedAnswers.contains(option),
                disabled: busy || showFeedback,
                onTap: () => onOptionSelected(option),
              ),
            ),
          )
        else
          _RecallArea(
            question: question,
            revealed: recallRevealed,
            showFeedback: showFeedback,
            remembered: lastCorrect,
            busy: busy,
            onReveal: onRevealRecall,
            onRate: onRateRecall,
          ),
        if (showFeedback) ...[
          const SizedBox(height: 8),
          _FeedbackCard(question: question, correct: lastCorrect ?? false),
          const SizedBox(height: 13),
          FilledButton(
            onPressed: busy ? null : () => onContinue(),
            child: const Text('Continue'),
          ),
        ],
      ],
    );
  }

  static String _instruction(LearningQuestionStyle style) {
    return switch (style) {
      LearningQuestionStyle.meaningChoice => 'What does this word mean?',
      LearningQuestionStyle.readingChoice => 'How is this word read?',
      LearningQuestionStyle.contextMeaning =>
        'What does this word mean in the sentence?',
      LearningQuestionStyle.selfRecall =>
        'Retrieve the Japanese word before revealing the answer.',
    };
  }
}

class _RecallArea extends StatelessWidget {
  final LearningQuestion question;
  final bool revealed;
  final bool showFeedback;
  final bool? remembered;
  final bool busy;
  final VoidCallback onReveal;
  final Future<void> Function(bool) onRate;

  const _RecallArea({
    required this.question,
    required this.revealed,
    required this.showFeedback,
    required this.remembered,
    required this.busy,
    required this.onReveal,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    if (!revealed) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Say the Japanese word aloud or in your head before '
              'revealing it.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 13),
          OutlinedButton.icon(
            onPressed: busy ? null : onReveal,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Show answer'),
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: [
              Text(
                question.answer,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (question.answerReading != null &&
                  question.answerReading != question.answer) ...[
                const SizedBox(height: 5),
                Text(
                  question.answerReading!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryStrong,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!showFeedback) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : () => onRate(false),
                  child: const Text("Didn't remember"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : () => onRate(true),
                  child: const Text('Remembered'),
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            remembered == true
                ? 'Marked as remembered.'
                : 'Marked for extra practice.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: remembered == true ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final String text;
  final bool selected;
  final bool correct;
  final bool incorrect;
  final bool disabled;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.text,
    required this.selected,
    required this.correct,
    required this.incorrect,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = correct
        ? AppColors.sageSoft
        : incorrect
        ? AppColors.vermilionSoft
        : selected
        ? AppColors.primaryContainer
        : AppColors.surface;

    final border = correct
        ? AppColors.sage
        : incorrect
        ? AppColors.vermilion
        : selected
        ? AppColors.primaryStrong
        : AppColors.outline;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: border,
              width: selected || correct || incorrect ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                correct
                    ? Icons.check_circle_rounded
                    : incorrect
                    ? Icons.cancel_rounded
                    : Icons.circle_outlined,
                color: correct
                    ? AppColors.success
                    : incorrect
                    ? AppColors.error
                    : AppColors.textMuted,
                size: 21,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final LearningQuestion question;
  final bool correct;

  const _FeedbackCard({required this.question, required this.correct});

  @override
  Widget build(BuildContext context) {
    final word = question.task.word;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: correct ? AppColors.sageSoft : AppColors.vermilionSoft,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.refresh_rounded,
                color: correct ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 9),
              Text(
                correct ? 'Correct' : 'Study it once more',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            word.expression,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (word.reading != word.expression) ...[
            const SizedBox(height: 3),
            Text(
              word.reading,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primaryStrong,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 5),
          Text(
            word.meaning,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (word.hasExample &&
              question.style != LearningQuestionStyle.contextMeaning) ...[
            const SizedBox(height: 11),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              word.exampleJapanese!,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (word.exampleReading != null) ...[
              const SizedBox(height: 3),
              Text(
                word.exampleReading!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.primaryStrong),
              ),
            ],
            if (word.exampleEnglish != null) ...[
              const SizedBox(height: 4),
              Text(
                word.exampleEnglish!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
          if (!correct) ...[
            const SizedBox(height: 10),
            Text(
              'This skill will return after a short gap instead of '
              'immediately.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final String japanese;
  final String? reading;
  final String? english;

  const _ExampleCard({
    required this.japanese,
    required this.reading,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            japanese,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (reading != null && reading!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              reading!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.primaryStrong),
            ),
          ],
          if (english != null && english!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(english!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final isCore = priority == 'CORE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: isCore ? AppColors.goldSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        priority,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isCore ? AppColors.gold : AppColors.primaryStrong,
          fontWeight: FontWeight.w900,
          letterSpacing: .7,
        ),
      ),
    );
  }
}

class _SkillBadge extends StatelessWidget {
  final LearningSkill skill;

  const _SkillBadge({required this.skill});

  @override
  Widget build(BuildContext context) {
    final label = switch (skill) {
      LearningSkill.meaning => 'MEANING',
      LearningSkill.reading => 'READING',
      LearningSkill.usage => 'CONTEXT',
      LearningSkill.recall => 'RECALL',
      LearningSkill.listening => 'LISTENING',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primaryStrong,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  final LearningDailyPlan? plan;
  final int attempts;
  final int correct;
  final Map<LearningSkill, int> skillAttempts;
  final Map<LearningSkill, int> skillCorrect;
  final VoidCallback onDone;

  const _SummaryView({
    super.key,
    required this.plan,
    required this.attempts,
    required this.correct,
    required this.skillAttempts,
    required this.skillCorrect,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = attempts == 0 ? 0 : ((correct / attempts) * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryStrong,
                size: 54,
              ),
              const SizedBox(height: 12),
              Text(
                'Session complete',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                attempts == 0
                    ? 'Nothing was due today.'
                    : '$correct of $attempts answers correct · $accuracy%',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SummaryMetric(
                value: '${plan?.effectiveNewWords ?? 0}',
                label: 'New words',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryMetric(
                value: '${plan?.dueReviewTasks.length ?? 0}',
                label: 'Review words',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryMetric(value: '$accuracy%', label: 'Accuracy'),
            ),
          ],
        ),
        if (attempts > 0) ...[
          const SizedBox(height: 20),
          Text(
            'Skill breakdown',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _SkillResult(
            label: 'Meaning',
            correct: skillCorrect[LearningSkill.meaning] ?? 0,
            attempts: skillAttempts[LearningSkill.meaning] ?? 0,
          ),
          const SizedBox(height: 8),
          _SkillResult(
            label: 'Reading',
            correct: skillCorrect[LearningSkill.reading] ?? 0,
            attempts: skillAttempts[LearningSkill.reading] ?? 0,
          ),
          const SizedBox(height: 8),
          _SkillResult(
            label: 'Context',
            correct: skillCorrect[LearningSkill.usage] ?? 0,
            attempts: skillAttempts[LearningSkill.usage] ?? 0,
          ),
          const SizedBox(height: 8),
          _SkillResult(
            label: 'Recall',
            correct: skillCorrect[LearningSkill.recall] ?? 0,
            attempts: skillAttempts[LearningSkill.recall] ?? 0,
          ),
        ],
        const SizedBox(height: 22),
        FilledButton(onPressed: onDone, child: const Text('Done')),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SkillResult extends StatelessWidget {
  final String label;
  final int correct;
  final int attempts;

  const _SkillResult({
    required this.label,
    required this.correct,
    required this.attempts,
  });

  @override
  Widget build(BuildContext context) {
    final value = attempts == 0 ? 0.0 : (correct / attempts).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(value: value, minHeight: 7),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            attempts == 0 ? '—' : '$correct/$attempts',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ErrorView({super.key, required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 38,
                ),
                const SizedBox(height: 12),
                Text(
                  'The lesson could not continue',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
                FilledButton(onPressed: onClose, child: const Text('Close')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
