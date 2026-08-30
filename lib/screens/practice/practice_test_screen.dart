import 'package:flutter/material.dart';

import '../../models/jlpt_practice_question.dart';
import '../../services/practice_progress_service.dart';
import '../../theme/app_colors.dart';

class PracticeTestScreen extends StatefulWidget {
  final String title;
  final List<JlptPracticeQuestion> questions;
  final bool examMode;
  final String mode;
  final String section;

  const PracticeTestScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.examMode,
    required this.mode,
    required this.section,
  });

  @override
  State<PracticeTestScreen> createState() => _PracticeTestScreenState();
}

class _PracticeTestScreenState extends State<PracticeTestScreen> {
  int _index = 0;
  int _score = 0;
  int? _selectedOption;
  bool _checked = false;

  JlptPracticeQuestion get _question => widget.questions[_index];

  String get _level {
    final match = RegExp(r'\bN[1-5]\b').firstMatch(widget.title.toUpperCase());
    return match?.group(0) ?? 'N5';
  }

  String get _sectionSymbol {
    switch (widget.section) {
      case 'grammar':
        return '文';
      case 'reading':
        return '読';
      case 'listening':
        return '聴';
      case 'vocabulary':
      default:
        return '語';
    }
  }

  void _select(int option) {
    if (_checked && !widget.examMode) return;
    setState(() => _selectedOption = option);
  }

  void _continue() {
    if (_selectedOption == null) return;

    if (!widget.examMode && !_checked) {
      setState(() {
        _checked = true;
        if (_selectedOption == _question.correctOption) {
          _score++;
        }
      });
      return;
    }

    if (widget.examMode && _selectedOption == _question.correctOption) {
      _score++;
    }

    if (_index < widget.questions.length - 1) {
      setState(() {
        _index++;
        _selectedOption = null;
        _checked = false;
      });
      return;
    }

    _showResult();
  }

  Future<void> _showResult() async {
    final total = widget.questions.length;
    final percent = total == 0 ? 0 : ((_score / total) * 100).round();

    await PracticeProgressService.saveAttempt(
      level: _level,
      section: widget.section,
      mode: widget.mode,
      questionCount: total,
      correctCount: _score,
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
                  child: Text(
                    _sectionSymbol,
                    style: const TextStyle(
                      color: AppColors.primaryStrong,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Practice complete',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$_level · ${_sectionLabel(widget.section)}',
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
                          value: '$_score / $total',
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
                  'This attempt has been saved and will update your '
                  '${_sectionLabel(widget.section)} practice score.',
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
                    label: Text(
                      'Back to ${_sectionLabel(widget.section)} Practice',
                    ),
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
    if (widget.questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(widget.title)),
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
                    Icons.quiz_outlined,
                    color: AppColors.textMuted,
                    size: 34,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No questions available.',
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

    final progress = (_index + 1) / widget.questions.length;

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
            _QuestionProgressHeader(
              level: _level,
              section: _sectionLabel(widget.section),
              symbol: _sectionSymbol,
              current: _index + 1,
              total: widget.questions.length,
              progress: progress,
              contextLabel: widget.examMode
                  ? 'Exam mode'
                  : _subtypeLabel(_question.subtype),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'もんだい ${_question.mondai}',
                      style: const TextStyle(
                        color: AppColors.primaryStrong,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _question.prompt,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(height: 1.6, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 24),
                    ..._question.options.map(_buildOption),
                    if (_checked && !widget.examMode) ...[
                      const SizedBox(height: 4),
                      _AnswerFeedbackCard(
                        correct: _selectedOption == _question.correctOption,
                        correctOption: _question.correctOption,
                        correctText: _correctOptionText(),
                      ),
                    ],
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
                  onPressed: _selectedOption == null ? null : _continue,
                  icon: Icon(
                    !widget.examMode && !_checked
                        ? Icons.check_rounded
                        : _index == widget.questions.length - 1
                        ? Icons.fact_check_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    !widget.examMode && !_checked
                        ? 'Check answer'
                        : _index == widget.questions.length - 1
                        ? 'View result'
                        : 'Next question',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(JlptPracticeOption option) {
    final selected = _selectedOption == option.id;
    final correct = option.id == _question.correctOption;

    Color background = AppColors.surface;
    Color border = AppColors.outline;
    Color numberBackground = AppColors.surfaceSoft;
    Color numberForeground = AppColors.textSecondary;

    if (!widget.examMode && _checked && correct) {
      background = AppColors.sageSoft;
      border = AppColors.success;
      numberBackground = AppColors.success;
      numberForeground = Colors.white;
    } else if (!widget.examMode && _checked && selected && !correct) {
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _select(option.id),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: border,
                width: selected || (!widget.examMode && _checked && correct)
                    ? 1.5
                    : 1,
              ),
              borderRadius: BorderRadius.circular(18),
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
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ),
                if (selected && !_checked) ...[
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

  String _correctOptionText() {
    for (final option in _question.options) {
      if (option.id == _question.correctOption) {
        return option.text;
      }
    }
    return '';
  }

  String _subtypeLabel(String subtype) {
    switch (subtype) {
      case 'kanji_reading':
        return 'Reading';
      case 'context':
        return 'Context';
      case 'paraphrase':
        return 'Meaning';
      case 'particle':
        return 'Particles';
      case 'verb_form':
        return 'Verb form';
      case 'comparison':
        return 'Comparison';
      case 'before_after':
        return 'Time expression';
      case 'giving_receiving':
        return 'Giving / receiving';
      case 'context_completion':
        return 'Grammar in context';
      case 'request_expression':
        return 'Expression';
      default:
        return widget.section == 'grammar' ? 'Grammar' : 'Vocabulary';
    }
  }

  String _sectionLabel(String section) {
    switch (section) {
      case 'grammar':
        return 'Grammar';
      case 'reading':
        return 'Reading';
      case 'listening':
        return 'Listening';
      case 'vocabulary':
      default:
        return 'Vocabulary';
    }
  }
}

class _QuestionProgressHeader extends StatelessWidget {
  final String level;
  final String section;
  final String symbol;
  final int current;
  final int total;
  final double progress;
  final String contextLabel;

  const _QuestionProgressHeader({
    required this.level,
    required this.section,
    required this.symbol,
    required this.current,
    required this.total,
    required this.progress,
    required this.contextLabel,
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
                child: Text(
                  symbol,
                  style: const TextStyle(
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
                      '$level · $section',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contextLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$current / $total',
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: .45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: accent,
            size: 21,
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
