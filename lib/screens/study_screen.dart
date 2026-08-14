import 'package:flutter/material.dart';

import '../models/study_item.dart';
import '../services/database_service.dart';
import '../services/srs_service.dart';

class StudyScreen extends StatefulWidget {
  final String level;
  final String studyType;

  const StudyScreen({super.key, required this.level, this.studyType = 'mix'});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  List<StudyItem> _items = [];
  Map<String, dynamic>? _details;

  bool _loading = true;
  bool _revealed = false;
  bool _saving = false;
  String? _error;

  int _index = 0;
  int _againCount = 0;
  int _hardCount = 0;
  int _goodCount = 0;
  int _easyCount = 0;
  int _learnedCount = 0;
  int _retryCount = 0;

  // Items rated "Otra vez" remain unresolved until they later receive
  // Difícil/Bien/Fácil or are marked Aprendida.
  final Set<String> _pendingAgain = <String>{};

  StudyItem? get _current {
    if (_index < 0 || _index >= _items.length) {
      return null;
    }

    return _items[_index];
  }

  String _itemKey(StudyItem item) => '${item.type}:${item.id}';

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final List<StudyItem> loaded;
      if (widget.level == 'BEGINNER') {
        loaded = await DatabaseService.getTodayBeginnerItems(limit: 20);
      } else if (widget.level == 'KANA') {
        loaded = await DatabaseService.getTodayKanaItems(
          script: widget.studyType,
          dueReviewLimit: 20,
          learningLimit: 2,
          newLimit: 8,
        );
      } else {
        loaded = await DatabaseService.getTodayStudyItems(
          level: widget.level,
          studyType: widget.studyType,
          dueReviewLimit: 20,
          learningLimit: 2,
          newLimit: 8,
        );
      }

      if (!mounted) return;

      setState(() {
        _items = loaded;
        _loading = false;
        _error = null;
      });

      if (_items.isNotEmpty) {
        await _loadDetails();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadDetails() async {
    final item = _current;

    if (item == null) {
      return;
    }

    try {
      final result = await DatabaseService.getItemDetails(item);

      if (!mounted) return;

      setState(() {
        _details = result;
        _revealed = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _rate(ReviewRating rating) async {
    final item = _current;

    if (item == null || _saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await SrsService.review(item, rating);

      final itemKey = _itemKey(item);

      switch (rating) {
        case ReviewRating.again:
          _againCount += 1;
          _retryCount += 1;
          _pendingAgain.add(itemKey);

          // "Otra vez" nunca resuelve la tarjeta. Reaparece tras hasta
          // dos tarjetas distintas. Si vuelve a recibir "Otra vez", se
          // programa de nuevo y la sesión no puede terminar con ella pendiente.
          final retryIndex = (_index + 3).clamp(0, _items.length);
          _items.insert(retryIndex, item);
          break;
        case ReviewRating.hard:
          _hardCount += 1;
          _pendingAgain.remove(itemKey);
          break;
        case ReviewRating.good:
          _goodCount += 1;
          _pendingAgain.remove(itemKey);
          break;
        case ReviewRating.easy:
          _easyCount += 1;
          _pendingAgain.remove(itemKey);
          break;
      }

      _index += 1;

      if (!mounted) return;

      if (_current == null) {
        setState(() {
          _saving = false;
          _details = null;
        });
        return;
      }

      setState(() {
        _saving = false;
        _details = null;
        _revealed = false;
      });

      await _loadDetails();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _markLearned() async {
    final item = _current;
    if (item == null || _saving) return;

    setState(() => _saving = true);

    try {
      await DatabaseService.setLearned(item, learned: true);
      _pendingAgain.remove(_itemKey(item));
      _learnedCount += 1;
      _index += 1;

      if (!mounted) return;

      if (_current == null) {
        setState(() {
          _saving = false;
          _details = null;
        });
        return;
      }

      setState(() {
        _saving = false;
        _details = null;
        _revealed = false;
      });
      await _loadDetails();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  String get _studyTypeLabel {
    switch (widget.studyType) {
      case 'vocab':
        return 'Vocabulario';
      case 'kanji':
        return 'Kanji';
      case 'grammar':
        return 'Gramática';
      case 'hiragana':
        return 'Hiragana';
      case 'katakana':
        return 'Katakana';
      case 'beginner':
        return 'Repaso';
      case 'mix':
      default:
        return 'Mix';
    }
  }

  String _questionFor(String type) {
    switch (type) {
      case 'kanji':
        return '¿Recuerdas su significado y lectura?';
      case 'grammar':
        return '¿Qué expresa esta estructura?';
      case 'kana':
        return '¿Recuerdas cómo se lee este kana?';
      case 'beginner':
        return '¿Recuerdas qué significa esta expresión?';
      case 'vocab':
      default:
        return '¿Conoces esta palabra?';
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'kanji':
        return 'KANJI';
      case 'grammar':
        return 'GRAMÁTICA';
      case 'vocab':
        return 'VOCABULARIO';
      case 'kana':
        return 'KANA';
      case 'beginner':
        return 'BEGINNER';
      default:
        return type.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.level)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Ocurrió un problema durante la sesión.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });

                  _loadSession();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.level)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No hay contenido pendiente para esta sesión. 🌸',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );
    }

    if (_current == null) {
      return _buildSummary();
    }

    final item = _current!;
    final progress = (_index + 1) / _items.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9FA),
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${widget.level} · $_studyTypeLabel · ${_index + 1}/${_items.length}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: progress, minHeight: 7),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBE8EE),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            _typeLabel(item.type),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          item.front,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize:
                                (item.type == 'kanji' || item.type == 'kana')
                                ? 72
                                : 42,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (!_revealed) ...[
                          const SizedBox(height: 24),
                          Text(
                            _questionFor(item.type),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 30),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              setState(() {
                                _revealed = true;
                              });
                            },
                            icon: const Icon(Icons.visibility_rounded),
                            label: const Text('Mostrar respuesta'),
                          ),
                        ] else ...[
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 20),
                          if (item.reading.isNotEmpty) ...[
                            Text(
                              item.reading,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            item.meaning,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _Details(item: item, details: _details),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_revealed)
              _RatingBar(
                disabled: _saving,
                onRating: _rate,
                onLearned: _markLearned,
                showLearned: widget.level != 'BEGINNER',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final total = _items.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFFF9FA),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Sesión completada',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌸', style: TextStyle(fontSize: 62)),
              const SizedBox(height: 16),
              Text(
                '${widget.level} · $_studyTypeLabel completado',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$total tarjetas completadas en la sesión',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  Chip(label: Text('Otra vez $_againCount')),
                  Chip(label: Text('Difícil $_hardCount')),
                  Chip(label: Text('Bien $_goodCount')),
                  Chip(label: Text('Fácil $_easyCount')),
                  Chip(
                    avatar: const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text('Aprendidas $_learnedCount'),
                  ),
                  if (_retryCount > 0)
                    Chip(
                      avatar: const Icon(Icons.replay_rounded, size: 18),
                      label: Text('Repetidas $_retryCount'),
                    ),
                ],
              ),
              const SizedBox(height: 30),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  child: Text('Volver al inicio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  final StudyItem item;
  final Map<String, dynamic>? details;

  const _Details({required this.item, required this.details});

  @override
  Widget build(BuildContext context) {
    if (details == null) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];

    void addInfo(String label, dynamic value) {
      final text = value?.toString().trim() ?? '';

      if (text.isEmpty) {
        return;
      }

      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 84,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (item.type == 'vocab') {
      addInfo('Tipo', details!['grammar_type']);
      addInfo('También', details!['additional_definitions']);
    } else if (item.type == 'kanji') {
      addInfo('On', details!['onyomi']);
      addInfo('Kun', details!['kunyomi']);
      addInfo('Radical', details!['radical']);
      addInfo('Trazos', details!['strokes']);
    } else if (item.type == 'grammar') {
      addInfo('Estructura', details!['structure']);
    } else if (item.type == 'kana') {
      final script = details!['script']?.toString();
      addInfo(
        'Silabario',
        script == 'hiragana'
            ? 'Hiragana'
            : script == 'katakana'
            ? 'Katakana'
            : script,
      );
      addInfo('Grupo', details!['category']);
    }

    final examples = details!['examples'] as List? ?? const [];

    if (examples.isNotEmpty) {
      final first = Map<String, dynamic>.from(examples.first as Map);

      final japanese = (first['japanese'] ?? first['word'] ?? '')
          .toString()
          .trim();

      final english = (first['english'] ?? first['meaning'] ?? '')
          .toString()
          .trim();

      if (japanese.isNotEmpty || english.isNotEmpty) {
        children.add(const SizedBox(height: 18));
        children.add(
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ejemplo',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        );

        if (japanese.isNotEmpty) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  japanese,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }

        if (english.isNotEmpty) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  english,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ),
          );
        }
      }
    }

    return Column(children: children);
  }
}

class _RatingBar extends StatelessWidget {
  final bool disabled;
  final ValueChanged<ReviewRating> onRating;
  final VoidCallback onLearned;
  final bool showLearned;

  const _RatingBar({
    required this.disabled,
    required this.onRating,
    required this.onLearned,
    this.showLearned = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _button('Otra vez', ReviewRating.again),
                  _button('Difícil', ReviewRating.hard),
                  _button('Bien', ReviewRating.good),
                  _button('Fácil', ReviewRating.easy),
                ],
              ),
              if (showLearned) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: disabled ? null : onLearned,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Aprendida',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(String label, ReviewRating rating) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: OutlinedButton(
          onPressed: disabled ? null : () => onRating(rating),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }
}
