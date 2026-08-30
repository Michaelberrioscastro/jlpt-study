import 'package:flutter/material.dart';

import '../../services/jlpt_practice_service.dart';
import '../../services/practice_progress_service.dart';
import '../../theme/app_colors.dart';

class ReadingTestScreen extends StatefulWidget {
  final String title;
  final String level;
  final List<JlptReadingPassage> passages;
  final String mode;
  final bool examMode;
  final int maxQuestions;

  const ReadingTestScreen({
    super.key,
    required this.title,
    required this.level,
    required this.passages,
    required this.mode,
    required this.examMode,
    required this.maxQuestions,
  });

  @override
  State<ReadingTestScreen> createState() => _ReadingTestScreenState();
}

class _ReadingTestScreenState extends State<ReadingTestScreen> {
  int _passageIndex = 0;
  final Map<String, int> _answers = {};
  bool _checking = false;

  JlptReadingPassage get _passage => widget.passages[_passageIndex];

  List<_ReadingItem> get _items {
    final items = <_ReadingItem>[];
    var remaining = widget.maxQuestions;

    for (final passage in widget.passages) {
      if (remaining <= 0) break;
      final questions = passage.questions.take(remaining).toList();
      for (final question in questions) {
        items.add(_ReadingItem(passage: passage, question: question));
      }
      remaining -= questions.length;
    }

    return items;
  }

  List<JlptReadingQuestion> get _visibleQuestions {
    final ids = _items
        .where((item) => item.passage.id == _passage.id)
        .map((item) => item.question.id)
        .toSet();

    return _passage.questions.where((q) => ids.contains(q.id)).toList();
  }

  bool get _passageComplete =>
      _visibleQuestions.every((q) => _answers.containsKey(q.id));

  int get _answeredCount =>
      _items.where((item) => _answers.containsKey(item.question.id)).length;

  void _select(JlptReadingQuestion question, int option) {
    if (_checking && !widget.examMode) return;
    setState(() => _answers[question.id] = option);
  }

  void _continue() {
    if (!_passageComplete) return;

    if (!widget.examMode && !_checking) {
      setState(() => _checking = true);
      return;
    }

    if (_passageIndex < widget.passages.length - 1 &&
        _answeredCount < _items.length) {
      setState(() {
        _passageIndex++;
        _checking = false;
      });
      return;
    }

    _finish();
  }

  Future<void> _finish() async {
    final items = _items;
    final score = items
        .where(
          (item) => _answers[item.question.id] == item.question.correctOption,
        )
        .length;

    final total = items.length;
    final percent = total == 0 ? 0 : ((score / total) * 100).round();

    await PracticeProgressService.saveAttempt(
      level: widget.level.toUpperCase(),
      section: 'reading',
      mode: widget.mode,
      questionCount: total,
      correctCount: score,
    );

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.outline),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: .08),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '読',
                    style: TextStyle(
                      color: AppColors.primaryStrong,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Reading practice complete',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.level.toUpperCase()} · Reading',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ResultMetric(
                          label: 'Correct',
                          value: '$score / $total',
                        ),
                      ),
                      Container(width: 1, height: 40, color: AppColors.outline),
                      Expanded(
                        child: _ResultMetric(
                          label: 'Practice score',
                          value: '$percent%',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'This attempt has been saved and will update your Reading practice score.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to Reading Practice'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.passages.isEmpty || _items.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          title: Text(widget.title),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.outline),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    color: AppColors.textMuted,
                    size: 34,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No reading passages available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final progress = _answeredCount / _items.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ReadingProgressHeader(
              level: widget.level.toUpperCase(),
              currentPassage: _passageIndex + 1,
              totalPassages: widget.passages.length,
              answered: _answeredCount,
              totalQuestions: _items.length,
              progress: progress,
              examMode: widget.examMode,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'もんだい ${_passage.mondai}',
                      style: const TextStyle(
                        color: AppColors.primaryStrong,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PassageCard(text: _passage.passage),
                    const SizedBox(height: 24),
                    Text(
                      _visibleQuestions.length == 1
                          ? 'Question'
                          : '${_visibleQuestions.length} questions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._visibleQuestions.map(_buildQuestion),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(
                    color: AppColors.outline.withValues(alpha: .7),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _passageComplete ? _continue : null,
                  icon: Icon(
                    !widget.examMode && !_checking
                        ? Icons.check_rounded
                        : (_passageIndex == widget.passages.length - 1 ||
                              _answeredCount >= _items.length)
                        ? Icons.fact_check_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    !widget.examMode && !_checking
                        ? 'Check answers'
                        : (_passageIndex == widget.passages.length - 1 ||
                              _answeredCount >= _items.length)
                        ? 'View result'
                        : 'Next passage',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(JlptReadingQuestion question) {
    final selected = _answers[question.id];
    final correct = selected == question.correctOption;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${question.number}. ${question.prompt}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              height: 1.55,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ...question.options.map(
            (option) => _buildOption(question, option, selected),
          ),
          if (_checking && !widget.examMode) ...[
            const SizedBox(height: 4),
            _AnswerFeedbackCard(
              correct: correct,
              correctOption: question.correctOption,
              correctText: _correctOptionText(question),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOption(
    JlptReadingQuestion question,
    JlptReadingOption option,
    int? selectedId,
  ) {
    final selected = selectedId == option.id;
    final correct = option.id == question.correctOption;

    Color background = AppColors.surface;
    Color border = AppColors.outline;
    Color numberBackground = AppColors.surfaceSoft;
    Color numberForeground = AppColors.textSecondary;

    if (!widget.examMode && _checking && correct) {
      background = AppColors.sageSoft;
      border = AppColors.success;
      numberBackground = AppColors.success;
      numberForeground = Colors.white;
    } else if (!widget.examMode && _checking && selected && !correct) {
      background = const Color(0xFFFFE8E9);
      border = AppColors.error;
      numberBackground = AppColors.error;
      numberForeground = Colors.white;
    } else if (selected) {
      background = AppColors.primarySoft;
      border = AppColors.primary;
      numberBackground = AppColors.primaryStrong;
      numberForeground = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: () => _select(question, option.id),
          borderRadius: BorderRadius.circular(17),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: border,
                width: selected || (!widget.examMode && _checking && correct)
                    ? 1.5
                    : 1,
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: numberBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${option.id}',
                    style: TextStyle(
                      color: numberForeground,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.text,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (selected && !_checking) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.primaryStrong,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _correctOptionText(JlptReadingQuestion question) {
    for (final option in question.options) {
      if (option.id == question.correctOption) {
        return option.text;
      }
    }
    return '';
  }
}

class _ReadingProgressHeader extends StatelessWidget {
  final String level;
  final int currentPassage;
  final int totalPassages;
  final int answered;
  final int totalQuestions;
  final double progress;
  final bool examMode;

  const _ReadingProgressHeader({
    required this.level,
    required this.currentPassage,
    required this.totalPassages,
    required this.answered,
    required this.totalQuestions,
    required this.progress,
    required this.examMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '読',
                  style: TextStyle(
                    color: AppColors.primaryStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$level · Reading',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      examMode
                          ? 'Exam mode · Passage $currentPassage of $totalPassages'
                          : 'Practice · Passage $currentPassage of $totalPassages',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$answered / $totalQuestions',
                style: const TextStyle(
                  color: AppColors.primaryStrong,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            color: AppColors.primaryStrong,
            backgroundColor: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(99),
          ),
        ],
      ),
    );
  }
}

class _PassageCard extends StatelessWidget {
  final String text;

  const _PassageCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          height: 1.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AnswerFeedbackCard extends StatelessWidget {
  final bool correct;
  final int correctOption;
  final String correctText;

  const _AnswerFeedbackCard({
    required this.correct,
    required this.correctOption,
    required this.correctText,
  });

  @override
  Widget build(BuildContext context) {
    final accent = correct ? AppColors.success : AppColors.error;
    final background = correct ? AppColors.sageSoft : const Color(0xFFFFE8E9);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: .45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct ? 'Correct' : 'Not quite',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                ),
                if (!correct) ...[
                  const SizedBox(height: 4),
                  Text(
                    correctText.isEmpty
                        ? 'Correct answer: $correctOption'
                        : 'Correct answer: $correctOption · $correctText',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ResultMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primaryStrong,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReadingItem {
  final JlptReadingPassage passage;
  final JlptReadingQuestion question;

  const _ReadingItem({required this.passage, required this.question});
}
