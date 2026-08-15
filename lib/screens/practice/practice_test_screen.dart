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
      level: 'N5',
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
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fact_check_rounded,
                  size: 46,
                  color: AppColors.primaryStrong,
                ),
                const SizedBox(height: 14),
                Text(
                  'Resultado',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '$_score / $total · $percent%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Este intento ya quedó guardado y actualizará tu preparación de ${_sectionLabel(widget.section)}.',
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
                    child: const Text('Volver a Práctica JLPT'),
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
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('No hay preguntas disponibles.')),
      );
    }

    final progress = (_index + 1) / widget.questions.length;

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
                        '${_index + 1}/${widget.questions.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        widget.examMode
                            ? 'Modo examen'
                            : _subtypeLabel(_question.subtype),
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
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
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
                    const SizedBox(height: 12),
                    Text(
                      _question.prompt,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(height: 1.65, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 24),
                    ..._question.options.map(_buildOption),
                    if (_checked && !widget.examMode) ...[
                      const SizedBox(height: 8),
                      Text(
                        _selectedOption == _question.correctOption
                            ? '✓ Correcto'
                            : 'Respuesta correcta: ${_question.correctOption}',
                        style: TextStyle(
                          color: _selectedOption == _question.correctOption
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
                  onPressed: _selectedOption == null ? null : _continue,
                  child: Text(
                    !widget.examMode && !_checked
                        ? 'Comprobar'
                        : _index == widget.questions.length - 1
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

  Widget _buildOption(JlptPracticeOption option) {
    final selected = _selectedOption == option.id;
    final correct = option.id == _question.correctOption;

    Color background = AppColors.surface;
    Color border = AppColors.outline;

    if (!widget.examMode && _checked && correct) {
      background = AppColors.sageSoft;
      border = AppColors.success;
    } else if (!widget.examMode && _checked && selected && !correct) {
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
          onTap: () => _select(option.id),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(18),
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
                      fontWeight: FontWeight.w700,
                      height: 1.5,
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

  String _subtypeLabel(String subtype) {
    switch (subtype) {
      case 'kanji_reading':
        return 'Lectura';
      case 'context':
        return 'Contexto';
      case 'paraphrase':
        return 'Significado';
      case 'particle':
        return 'Partículas';
      case 'verb_form':
        return 'Forma verbal';
      case 'comparison':
        return 'Comparación';
      case 'before_after':
        return 'Expresión temporal';
      case 'giving_receiving':
        return 'Dar / recibir';
      case 'context_completion':
        return 'Gramática en contexto';
      case 'request_expression':
        return 'Expresión';
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
