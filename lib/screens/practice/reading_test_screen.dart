import 'package:flutter/material.dart';

import '../../services/jlpt_practice_service.dart';
import '../../services/practice_progress_service.dart';
import '../../theme/app_colors.dart';

class ReadingTestScreen extends StatefulWidget {
  final String title;
  final List<JlptReadingPassage> passages;
  final String mode;
  final bool examMode;
  final int maxQuestions;

  const ReadingTestScreen({
    super.key,
    required this.title,
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
      level: 'N5',
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
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 46,
                  color: AppColors.primaryStrong,
                ),
                const SizedBox(height: 14),
                Text(
                  'Resultado Reading',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '$score / $total · $percent%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Este intento ya quedó guardado y actualizará tu preparación de Reading.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.pop(context, true);
                    },
                    child: const Text('Volver a Reading'),
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
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('No hay lecturas disponibles.')),
      );
    }

    final progress = _answeredCount / _items.length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Text(
                        '$_answeredCount/${_items.length} respondidas',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        widget.examMode ? 'Modo examen' : 'Práctica',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: SelectableText(
                        _passage.passage,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    ..._visibleQuestions.map(_buildQuestion),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _passageComplete ? _continue : null,
                  child: Text(
                    !widget.examMode && !_checking
                        ? 'Comprobar'
                        : (_passageIndex == widget.passages.length - 1 ||
                              _answeredCount >= _items.length)
                        ? 'Ver resultado'
                        : 'Siguiente lectura',
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${question.number}. ${question.prompt}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              height: 1.6,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...question.options.map(
            (option) => _buildOption(question, option, selected),
          ),
          if (_checking && !widget.examMode) ...[
            const SizedBox(height: 4),
            Text(
              selected == question.correctOption
                  ? '✓ Correcto'
                  : 'Respuesta correcta: ${question.correctOption}',
              style: TextStyle(
                color: selected == question.correctOption
                    ? AppColors.success
                    : AppColors.error,
                fontWeight: FontWeight.w900,
              ),
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

    if (!widget.examMode && _checking && correct) {
      background = AppColors.sageSoft;
      border = AppColors.success;
    } else if (!widget.examMode && _checking && selected && !correct) {
      background = const Color(0xFFFFE8E9);
      border = AppColors.error;
    } else if (selected) {
      background = AppColors.primarySoft;
      border = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: () => _select(question, option.id),
          borderRadius: BorderRadius.circular(17),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryStrong
                        : AppColors.surfaceSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${option.id}',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.text,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingItem {
  final JlptReadingPassage passage;
  final JlptReadingQuestion question;

  const _ReadingItem({required this.passage, required this.question});
}
