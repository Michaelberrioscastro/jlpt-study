import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/beginner_course.dart';
import '../../services/beginner_progress_service.dart';
import '../../theme/app_colors.dart';

class BeginnerQuizScreen extends StatefulWidget {
  final BeginnerCourse course;
  final BeginnerLesson lesson;

  const BeginnerQuizScreen({
    super.key,
    required this.course,
    required this.lesson,
  });

  @override
  State<BeginnerQuizScreen> createState() => _BeginnerQuizScreenState();
}

class _BeginnerQuizScreenState extends State<BeginnerQuizScreen> {
  late final List<_QuizQuestion> _questions;

  int _index = 0;
  int _score = 0;
  String? _selected;
  bool _checked = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _questions = _QuizBuilder.build(
      course: widget.course,
      lesson: widget.lesson,
    );
  }

  _QuizQuestion get _question => _questions[_index];
  int get _requiredScore => (_questions.length * .8).ceil();

  void _select(String option) {
    if (_checked) return;
    setState(() => _selected = option);
  }

  void _check() {
    if (_selected == null || _checked) return;

    setState(() {
      _checked = true;
      if (_selected == _question.answer) _score++;
    });
  }

  Future<void> _next() async {
    if (!_checked) {
      _check();
      return;
    }

    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _checked = false;
      });
      return;
    }

    await _finish();
  }

  Future<void> _finish() async {
    if (_saving) return;

    setState(() => _saving = true);

    final passed = _score >= _requiredScore;

    await BeginnerProgressService.recordQuiz(
      lessonId: widget.lesson.id,
      score: _score,
      total: _questions.length,
      passed: passed,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  passed ? '🌸' : '📚',
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  passed ? '¡Lección superada!' : 'Repasemos una vez más',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '$_score / ${_questions.length} correctas · '
                  '${((_score / _questions.length) * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  passed
                      ? 'Has desbloqueado la siguiente lección.'
                      : 'Necesitas al menos $_requiredScore de '
                            '${_questions.length} respuestas correctas para avanzar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      if (passed) {
                        Navigator.pop(context, true);
                      } else {
                        setState(() {
                          _index = 0;
                          _score = 0;
                          _selected = null;
                          _checked = false;
                        });
                      }
                    },
                    child: Text(passed ? 'Continuar' : 'Intentar de nuevo'),
                  ),
                ),
                if (!passed) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.pop(context, false);
                    },
                    child: const Text('Volver a repasar la lección'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(
          child: Text('Esta lección todavía no tiene preguntas disponibles.'),
        ),
      );
    }

    final progress = (_index + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(title: Text('Quiz · ${widget.lesson.title}')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
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
                        '${_index + 1}/${_questions.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        'Aprobación: 80%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMPRUEBA LO APRENDIDO',
                      style: TextStyle(
                        color: AppColors.primaryStrong,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _question.question,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (_question.prompt.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Center(
                        child: Text(
                          _question.prompt,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ..._question.options.map(_option),
                    if (_checked) ...[
                      const SizedBox(height: 8),
                      Text(
                        _selected == _question.answer
                            ? '¡Correcto!'
                            : 'Respuesta correcta: ${_question.answer}',
                        style: TextStyle(
                          color: _selected == _question.answer
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving || _selected == null ? null : _next,
                  child: Text(
                    !_checked
                        ? 'Comprobar'
                        : _index == _questions.length - 1
                        ? 'Ver resultado'
                        : 'Siguiente',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(String option) {
    final selected = _selected == option;
    final correct = option == _question.answer;

    Color background = AppColors.surface;
    Color border = AppColors.outline;

    if (_checked && correct) {
      background = AppColors.sageSoft;
      border = AppColors.success;
    } else if (_checked && selected && !correct) {
      background = const Color(0xFFFFE8E9);
      border = AppColors.error;
    } else if (selected) {
      background = AppColors.primarySoft;
      border = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: _checked ? null : () => _select(option),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              option,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizQuestion {
  final String question;
  final String prompt;
  final List<String> options;
  final String answer;

  const _QuizQuestion({
    required this.question,
    required this.prompt,
    required this.options,
    required this.answer,
  });
}

class _QuizBuilder {
  static List<_QuizQuestion> build({
    required BeginnerCourse course,
    required BeginnerLesson lesson,
  }) {
    final allExamples = <Map<String, dynamic>>[];

    for (final unit in course.units) {
      for (final l in unit.lessons) {
        for (final step in l.steps) {
          if (step.type == 'example') {
            allExamples.add(step.data);
          }
        }
      }
    }

    final lessonExamples = lesson.steps
        .where((step) => step.type == 'example')
        .map((step) => step.data)
        .toList();

    final result = <_QuizQuestion>[];
    final seed = lesson.id.codeUnits.fold<int>(0, (a, b) => a + b);
    final random = Random(seed);

    List<String> distractors(String field, String answer, {int count = 3}) {
      final pool =
          allExamples
              .map((e) => (e[field] ?? '').toString().trim())
              .where((e) => e.isNotEmpty && e != answer)
              .toSet()
              .toList()
            ..shuffle(random);

      return pool.take(count).toList();
    }

    void addQuestion({
      required String question,
      String prompt = '',
      required String answer,
      required List<String> wrong,
    }) {
      if (answer.trim().isEmpty) return;

      final options = <String>{answer, ...wrong}.toList();
      if (options.length < 2) return;

      options.shuffle(random);

      result.add(
        _QuizQuestion(
          question: question,
          prompt: prompt,
          options: options,
          answer: answer,
        ),
      );
    }

    for (final ex in lessonExamples) {
      final jp = (ex['japanese'] ?? '').toString().trim();
      final romaji = (ex['romaji'] ?? '').toString().trim();
      final meaning = (ex['meaning'] ?? '').toString().trim();

      if (jp.isNotEmpty && meaning.isNotEmpty) {
        addQuestion(
          question: '¿Qué significa?',
          prompt: jp,
          answer: meaning,
          wrong: distractors('meaning', meaning),
        );

        addQuestion(
          question: '¿Cuál expresión japonesa corresponde a "$meaning"?',
          answer: jp,
          wrong: distractors('japanese', jp),
        );
      }

      if (jp.isNotEmpty && romaji.isNotEmpty) {
        addQuestion(
          question: '¿Cómo se lee?',
          prompt: jp,
          answer: romaji,
          wrong: distractors('romaji', romaji),
        );

        addQuestion(
          question: '¿Cuál corresponde a "$romaji"?',
          answer: jp,
          wrong: distractors('japanese', jp),
        );
      }
    }

    for (final step in lesson.steps) {
      if (step.type == 'multiple_choice') {
        final options = ((step.data['options'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList();

        addQuestion(
          question: (step.data['question'] ?? '').toString(),
          answer: (step.data['answer'] ?? '').toString(),
          wrong: options
              .where((e) => e != (step.data['answer'] ?? '').toString())
              .toList(),
        );
      }

      if (step.type == 'kana_choice') {
        final options = ((step.data['options'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList();

        addQuestion(
          question: '¿Cómo se lee?',
          prompt: (step.data['prompt'] ?? '').toString(),
          answer: (step.data['answer'] ?? '').toString(),
          wrong: options
              .where((e) => e != (step.data['answer'] ?? '').toString())
              .toList(),
        );
      }
    }

    final unique = <String, _QuizQuestion>{};

    for (final q in result) {
      final key = '${q.question}|${q.prompt}|${q.answer}';
      unique.putIfAbsent(key, () => q);
    }

    final questions = unique.values.toList();

    if (questions.length > 5) {
      questions.shuffle(random);
      return questions.take(5).toList();
    }

    return questions;
  }
}
