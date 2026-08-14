import 'package:flutter/material.dart';

import '../../models/beginner_course.dart';
import '../../services/database_service.dart';
import '../../theme/app_colors.dart';
import '../kana_screen.dart';
import '../level_screen.dart';
import 'beginner_quiz_screen.dart';

class BeginnerLessonScreen extends StatefulWidget {
  final BeginnerCourse course;
  final String unitTitle;
  final BeginnerLesson lesson;

  const BeginnerLessonScreen({
    super.key,
    required this.course,
    required this.unitTitle,
    required this.lesson,
  });

  @override
  State<BeginnerLessonScreen> createState() => _BeginnerLessonScreenState();
}

class _BeginnerLessonScreenState extends State<BeginnerLessonScreen> {
  int _index = 0;
  int _phraseMatchIndex = 0;
  String? _selected;
  bool _checked = false;

  LessonStep get _step => widget.lesson.steps[_index];

  void _next() {
    if (_index >= widget.lesson.steps.length - 1) {
      _finish();
      return;
    }

    setState(() {
      _index++;
      _phraseMatchIndex = 0;
      _selected = null;
      _checked = false;
    });
  }

  Future<void> _finish() async {
    final passed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            BeginnerQuizScreen(course: widget.course, lesson: widget.lesson),
      ),
    );

    if (!mounted) return;

    if (passed == true) {
      await DatabaseService.activateBeginnerItems(
        lessonId: widget.lesson.id,
        unitId: widget.unitTitle,
        items: _collectSrsItems(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  List<Map<String, String>> _collectSrsItems() {
    final result = <Map<String, String>>[];
    final seen = <String>{};

    void addItem(dynamic raw) {
      if (raw is! Map) return;
      final data = Map<String, dynamic>.from(raw);

      final japanese = (data['japanese'] ?? '').toString().trim();
      final meaning = (data['meaning'] ?? '').toString().trim();
      final romaji = (data['romaji'] ?? data['reading'] ?? '')
          .toString()
          .trim();

      if (japanese.isEmpty || meaning.isEmpty) return;

      final key = '$japanese|$meaning';
      if (!seen.add(key)) return;

      result.add({'japanese': japanese, 'romaji': romaji, 'meaning': meaning});
    }

    for (final step in widget.lesson.steps) {
      if (step.type == 'srs_add') {
        final items = step.data['items'];
        if (items is List) {
          for (final item in items) {
            addItem(item);
          }
        } else {
          addItem(step.data);
        }
      }

      if (step.type == 'example') {
        addItem(step.data);
      }

      if (step.type == 'phrase_match') {
        final pairs = step.data['pairs'];
        if (pairs is List) {
          for (final pair in pairs) {
            addItem(pair);
          }
        }
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_index + 1) / widget.lesson.steps.length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(value: progress, minHeight: 8),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: SingleChildScrollView(
                  key: ValueKey(_index),
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: _buildStep(_step),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canContinue ? _handleContinue : null,
                  child: Text(_buttonLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isQuestion =>
      _step.type == 'multiple_choice' ||
      _step.type == 'kana_choice' ||
      _step.type == 'phrase_match';

  bool get _canContinue {
    if (_step.type == 'route_link') return true;
    if (!_isQuestion) return true;
    return _selected != null;
  }

  String get _buttonLabel {
    if (_step.type == 'route_link') {
      return (_step.data['label'] ?? 'Abrir').toString();
    }

    if (_isQuestion && !_checked) return 'Comprobar';

    if (_step.type == 'phrase_match' && _checked) {
      final pairs = (_step.data['pairs'] as List?) ?? const [];
      if (_phraseMatchIndex < pairs.length - 1) return 'Siguiente';
    }

    if (_index == widget.lesson.steps.length - 1) return 'Terminar';
    return 'Continuar';
  }

  Future<void> _handleContinue() async {
    if (_step.type == 'route_link') {
      await _openRoute(_step.data);
      return;
    }

    if (_isQuestion && !_checked) {
      setState(() => _checked = true);
      return;
    }

    if (_step.type == 'phrase_match') {
      final pairs = (_step.data['pairs'] as List?) ?? const [];
      if (_phraseMatchIndex < pairs.length - 1) {
        setState(() {
          _phraseMatchIndex++;
          _selected = null;
          _checked = false;
        });
        return;
      }
    }

    _next();
  }

  Future<void> _openRoute(Map<String, dynamic> data) async {
    final target = (data['target'] ?? '').toString();

    if (target == 'kana' || target.startsWith('kana:')) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => KanaScreen()));

      if (!mounted) return;
      _next();
      return;
    }

    if (target.startsWith('level:')) {
      final level = target.split(':').last.trim();

      if (level.isNotEmpty) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => LevelScreen(level: level)));
      }

      if (!mounted) return;
      _next();
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          target.isEmpty
              ? 'Este enlace todavía no tiene un destino configurado.'
              : 'Destino no reconocido: $target',
        ),
      ),
    );
  }

  Widget _buildStep(LessonStep step) {
    switch (step.type) {
      case 'explanation':
        return _ExplanationStep(data: step.data);
      case 'example':
        return _ExampleStep(data: step.data);
      case 'multiple_choice':
        return _ChoiceStep(
          data: step.data,
          selected: _selected,
          checked: _checked,
          onSelected: (value) => setState(() => _selected = value),
        );
      case 'kana_choice':
        return _ChoiceStep(
          data: {
            'question': '¿Cómo se lee?',
            'prompt': step.data['prompt'],
            'options': step.data['options'],
            'answer': step.data['answer'],
          },
          selected: _selected,
          checked: _checked,
          onSelected: (value) => setState(() => _selected = value),
        );
      case 'srs_add':
        return const _SimpleStep(
          icon: Icons.repeat_rounded,
          title: 'Listo para repasar',
          body:
              'Cuando apruebes el quiz, este contenido se añadirá automáticamente a tus repasos.',
        );
      case 'route_link':
        return _RouteStep(data: step.data);
      case 'phrase_match':
        return _PhraseMatchStep(
          data: step.data,
          pairIndex: _phraseMatchIndex,
          selected: _selected,
          checked: _checked,
          onSelected: (value) => setState(() => _selected = value),
        );
      case 'reflection':
        return _SimpleStep(
          icon: Icons.auto_awesome_rounded,
          title: 'Muy bien',
          body: (step.data['text'] ?? '').toString(),
        );
      default:
        return _SimpleStep(
          icon: Icons.info_outline_rounded,
          title: 'Paso de lección',
          body: 'Tipo: ${step.type}',
        );
    }
  }
}

class _ExplanationStep extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ExplanationStep({required this.data});

  @override
  Widget build(BuildContext context) {
    return _LessonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('APRENDE'),
          const SizedBox(height: 12),
          Text(
            (data['title'] ?? '').toString(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          Text(
            (data['body'] ?? '').toString(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _ExampleStep extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ExampleStep({required this.data});

  @override
  Widget build(BuildContext context) {
    return _LessonCard(
      child: Column(
        children: [
          const _Eyebrow('EJEMPLO'),
          const SizedBox(height: 24),
          Text(
            (data['japanese'] ?? '').toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          if ((data['reading'] ?? '').toString().isNotEmpty &&
              (data['reading'] ?? '').toString() !=
                  (data['japanese'] ?? '').toString()) ...[
            const SizedBox(height: 10),
            Text(
              (data['reading'] ?? '').toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primaryStrong,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if ((data['romaji'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              (data['romaji'] ?? '').toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              (data['meaning'] ?? '').toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? selected;
  final bool checked;
  final ValueChanged<String> onSelected;

  const _ChoiceStep({
    required this.data,
    required this.selected,
    required this.checked,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = ((data['options'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final answer = (data['answer'] ?? '').toString();
    final prompt = (data['prompt'] ?? '').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('PRACTICA'),
        const SizedBox(height: 12),
        Text(
          (data['question'] ?? '').toString(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (prompt.isNotEmpty) ...[
          const SizedBox(height: 24),
          Center(
            child: Text(
              prompt,
              style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900),
            ),
          ),
        ],
        const SizedBox(height: 22),
        ...options.map((option) {
          final isSelected = selected == option;
          final isCorrect = option == answer;

          Color background = AppColors.surface;
          Color border = AppColors.outline;

          if (checked && isCorrect) {
            background = AppColors.sageSoft;
            border = AppColors.success;
          } else if (checked && isSelected && !isCorrect) {
            background = const Color(0xFFFFE8E9);
            border = AppColors.error;
          } else if (isSelected) {
            background = AppColors.primarySoft;
            border = AppColors.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: background,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: checked ? null : () => onSelected(option),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        if (checked) ...[
          const SizedBox(height: 8),
          Text(
            selected == answer
                ? '¡Correcto!'
                : 'La respuesta correcta es $answer.',
            style: TextStyle(
              color: selected == answer ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

class _PhraseMatchStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final int pairIndex;
  final String? selected;
  final bool checked;
  final ValueChanged<String> onSelected;

  const _PhraseMatchStep({
    required this.data,
    required this.pairIndex,
    required this.selected,
    required this.checked,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final rawPairs = (data['pairs'] as List?) ?? const [];
    final pairs = rawPairs
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (pairs.isEmpty) {
      return const _SimpleStep(
        icon: Icons.extension_off_rounded,
        title: 'Sin contenido',
        body: 'Este ejercicio no contiene pares configurados.',
      );
    }

    final safeIndex = pairIndex.clamp(0, pairs.length - 1);
    final current = pairs[safeIndex];
    final japanese = (current['japanese'] ?? '').toString();
    final romaji = (current['romaji'] ?? '').toString();
    final answer = (current['meaning'] ?? '').toString();

    final options = pairs
        .map((pair) => (pair['meaning'] ?? '').toString())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    if (options.length > 1) {
      final shift = safeIndex % options.length;
      final rotated = [...options.skip(shift), ...options.take(shift)];
      options
        ..clear()
        ..addAll(rotated);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('RELACIONA'),
        const SizedBox(height: 8),
        Text(
          '${safeIndex + 1} de ${pairs.length}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        _LessonCard(
          child: Column(
            children: [
              Text(
                japanese,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (romaji.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(
                  romaji,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '¿Con qué significado se relaciona?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...options.map((option) {
          final isSelected = selected == option;
          final isCorrect = option == answer;

          Color background = AppColors.surface;
          Color border = AppColors.outline;

          if (checked && isCorrect) {
            background = AppColors.sageSoft;
            border = AppColors.success;
          } else if (checked && isSelected && !isCorrect) {
            background = const Color(0xFFFFE8E9);
            border = AppColors.error;
          } else if (isSelected) {
            background = AppColors.primarySoft;
            border = AppColors.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: background,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: checked ? null : () => onSelected(option),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        if (checked) ...[
          const SizedBox(height: 6),
          Text(
            selected == answer
                ? '¡Correcto!'
                : 'La respuesta correcta es $answer.',
            style: TextStyle(
              color: selected == answer ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

class _RouteStep extends StatelessWidget {
  final Map<String, dynamic> data;

  const _RouteStep({required this.data});

  @override
  Widget build(BuildContext context) {
    final target = (data['target'] ?? '').toString();
    final label = (data['label'] ?? 'Continuar').toString();

    final isKana = target == 'kana' || target.startsWith('kana:');
    final isLevel = target.startsWith('level:');

    return _LessonCard(
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isKana
                  ? Icons.translate_rounded
                  : isLevel
                  ? Icons.school_rounded
                  : Icons.route_rounded,
              color: AppColors.primaryStrong,
              size: 29,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Práctica guiada',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            isKana
                ? 'Abre el módulo Kana para reforzar lo que acabas de aprender. Al volver, continuarás esta lección.'
                : isLevel
                ? 'Ya puedes visitar $label. Al volver, podrás terminar esta ruta.'
                : label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (target == 'kana:hiragana') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'En Kana, selecciona Hiragana para esta práctica.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Widget child;

  const _LessonCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.outline),
      ),
      child: child,
    );
  }
}

class _SimpleStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _SimpleStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return _LessonCard(
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryStrong, size: 28),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;

  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.primaryStrong,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.3,
      ),
    );
  }
}
