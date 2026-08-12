import 'package:flutter/material.dart';

import '../services/database_service.dart';
import 'study_screen.dart';

class KanaScreen extends StatefulWidget {
  const KanaScreen({super.key});

  @override
  State<KanaScreen> createState() => _KanaScreenState();
}

class _KanaScreenState extends State<KanaScreen> {
  Map<String, int>? _overall;
  Map<String, Map<String, int>>? _byScript;

  bool _loading = true;
  String? _error;

  String _studyType = 'mix';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final overall = await DatabaseService.getKanaOverallCounts();
      final byScript = await DatabaseService.getKanaStudyCounts();

      if (!mounted) return;

      setState(() {
        _overall = overall;
        _byScript = byScript;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _startStudy() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyScreen(level: 'KANA', studyType: _studyType),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  double _progressFor(String script) {
    final stats = _byScript?[script];

    if (stats == null) return 0;

    final total = stats['total'] ?? 0;
    final learned = stats['learned'] ?? 0;

    if (total <= 0) return 0;

    return learned / total;
  }

  String _labelFor(String type) {
    switch (type) {
      case 'hiragana':
        return 'Hiragana';
      case 'katakana':
        return 'Katakana';
      case 'mix':
      default:
        return 'Mix';
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'hiragana':
        return Icons.text_fields_rounded;
      case 'katakana':
        return Icons.translate_rounded;
      case 'mix':
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overall = _overall ?? const <String, int>{};

    final total = overall['total'] ?? 0;
    final learned = overall['learned'] ?? 0;
    final learning = overall['learning'] ?? 0;
    final due = overall['due'] ?? 0;
    final newItems = overall['new'] ?? 0;

    final progress = total <= 0 ? 0.0 : learned / total;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9FA),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Kana · Perfil de estudio',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 70),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorCard(error: _error!, onRetry: _load)
            else ...[
              _OverallCard(
                progress: progress,
                total: total,
                learned: learned,
                learning: learning,
                due: due,
                newItems: newItems,
              ),
              const SizedBox(height: 22),
              const Text(
                '¿Qué quieres estudiar?',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _StudyTypeCard(
                    label: 'Mix',
                    subtitle: '4 hiragana · 4 katakana',
                    icon: Icons.auto_awesome_rounded,
                    selected: _studyType == 'mix',
                    onTap: () {
                      setState(() {
                        _studyType = 'mix';
                      });
                    },
                  ),
                  _StudyTypeCard(
                    label: 'Hiragana',
                    subtitle: 'Solo hiragana',
                    icon: Icons.text_fields_rounded,
                    selected: _studyType == 'hiragana',
                    onTap: () {
                      setState(() {
                        _studyType = 'hiragana';
                      });
                    },
                  ),
                  _StudyTypeCard(
                    label: 'Katakana',
                    subtitle: 'Solo katakana',
                    icon: Icons.translate_rounded,
                    selected: _studyType == 'katakana',
                    onTap: () {
                      setState(() {
                        _studyType = 'katakana';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'Progreso por silabario',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _ProgressCard(
                symbol: 'あ',
                title: 'Hiragana',
                progress: _progressFor('hiragana'),
                stats: _byScript?['hiragana'],
              ),
              const SizedBox(height: 12),
              _ProgressCard(
                symbol: 'ア',
                title: 'Katakana',
                progress: _progressFor('katakana'),
                stats: _byScript?['katakana'],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: total == 0 ? null : _startStudy,
                icon: Icon(_iconFor(_studyType)),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Estudiar ${_labelFor(_studyType)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Las sesiones incluyen repasos vencidos, hasta 2 kana en aprendizaje y hasta 8 nuevos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  final double progress;
  final int total;
  final int learned;
  final int learning;
  final int due;
  final int newItems;

  const _OverallCard({
    required this.progress,
    required this.total,
    required this.learned,
    required this.learning,
    required this.due,
    required this.newItems,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFBE8EE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'かな・カナ',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text('Kana', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: progress,
              minHeight: 11,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(label: 'Aprendidas', value: learned),
                ),
                Expanded(
                  child: _MiniStat(label: 'Estudiando', value: learning),
                ),
                Expanded(
                  child: _MiniStat(label: 'Repasos', value: due),
                ),
                Expanded(
                  child: _MiniStat(label: 'Nuevas', value: newItems),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$learned de $total kana marcados como aprendidos',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String symbol;
  final String title;
  final double progress;
  final Map<String, int>? stats;

  const _ProgressCard({
    required this.symbol,
    required this.title,
    required this.progress,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final total = stats?['total'] ?? 0;
    final learned = stats?['learned'] ?? 0;
    final learning = stats?['learning'] ?? 0;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE8EE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    symbol,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '$learned / $total aprendidos',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '$learning estudiando',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyTypeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _StudyTypeCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: selected ? const Color(0xFFFBE8EE) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 44),
            const SizedBox(height: 14),
            const Text(
              'No pude cargar Kana.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
