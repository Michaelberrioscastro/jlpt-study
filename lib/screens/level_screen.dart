import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../theme/app_colors.dart';
import 'study_screen.dart';

class LevelScreen extends StatefulWidget {
  final String level;

  const LevelScreen({super.key, required this.level});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  Map<String, int>? overall;
  Map<String, Map<String, int>>? byType;

  bool loading = true;
  String? error;

  String studyType = 'mix';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await DatabaseService.getStudyCounts(widget.level);
      final perType = await DatabaseService.getStudyCountsByType(widget.level);

      if (!mounted) return;

      setState(() {
        overall = result;
        byType = perType;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _startStudy() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyScreen(level: widget.level, studyType: studyType),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  double _progressFor(String type) {
    final stats = byType?[type];
    final total = stats?['total'] ?? 0;
    final learned = stats?['learned'] ?? 0;

    return total == 0 ? 0 : learned / total;
  }

  String get _studyLabel {
    switch (studyType) {
      case 'vocab':
        return 'Vocabulario';
      case 'kanji':
        return 'Kanji';
      case 'grammar':
        return 'Gramática';
      default:
        return 'Mix';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = overall ?? const <String, int>{};

    final total = stats['total'] ?? 0;
    final learned = stats['learned'] ?? 0;
    final learning = stats['learning'] ?? 0;
    final due = stats['due'] ?? 0;
    final newItems = stats['new'] ?? 0;
    final progress = total == 0 ? 0.0 : learned / total;

    return Scaffold(
      appBar: AppBar(title: Text(widget.level)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            if (loading)
              const SizedBox(
                height: 420,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              _ErrorCard(message: error!, onRetry: _load)
            else ...[
              _LevelHero(
                level: widget.level,
                progress: progress,
                learned: learned,
                total: total,
                due: due,
              ),

              const SizedBox(height: 26),

              Text(
                '¿Qué quieres estudiar?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Elige una modalidad para esta sesión.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),

              _StudyTypeSelector(
                selected: studyType,
                onSelected: (value) {
                  setState(() => studyType = value);
                },
              ),

              // The CTA now sits immediately under the selector.
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: total == 0 ? null : _startStudy,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Estudiar $_studyLabel'),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  Text(
                    'Progreso por área',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$learning estudiando',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _ProgressTile(
                title: 'Vocabulario',
                symbol: '語',
                progress: _progressFor('vocab'),
                stats: byType?['vocab'],
              ),
              const SizedBox(height: 10),
              _ProgressTile(
                title: 'Kanji',
                symbol: '字',
                progress: _progressFor('kanji'),
                stats: byType?['kanji'],
              ),
              const SizedBox(height: 10),
              _ProgressTile(
                title: 'Gramática',
                symbol: '文',
                progress: _progressFor('grammar'),
                stats: byType?['grammar'],
              ),

              const SizedBox(height: 18),

              _SessionInfo(
                learned: learned,
                learning: learning,
                due: due,
                newItems: newItems,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelHero extends StatelessWidget {
  final String level;
  final double progress;
  final int learned;
  final int total;
  final int due;

  const _LevelHero({
    required this.level,
    required this.progress,
    required this.learned,
    required this.total,
    required this.due,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .75),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  level,
                  style: const TextStyle(
                    color: AppColors.primaryStrong,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perfil $level',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$due repasos pendientes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.primaryStrong,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            color: AppColors.primaryStrong,
            backgroundColor: Colors.white.withValues(alpha: .7),
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 8),
          Text(
            '$learned de $total aprendidos',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StudyTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _StudyTypeSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('mix', 'Mix', Icons.auto_awesome_rounded),
      ('vocab', 'Vocab', Icons.menu_book_outlined),
      ('kanji', 'Kanji', Icons.translate_rounded),
      ('grammar', 'Gramática', Icons.edit_note_outlined),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TypeButton(
                value: items[0].$1,
                label: items[0].$2,
                icon: items[0].$3,
                selected: selected == items[0].$1,
                onTap: () => onSelected(items[0].$1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeButton(
                value: items[1].$1,
                label: items[1].$2,
                icon: items[1].$3,
                selected: selected == items[1].$1,
                onTap: () => onSelected(items[1].$1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TypeButton(
                value: items[2].$1,
                label: items[2].$2,
                icon: items[2].$3,
                selected: selected == items[2].$1,
                onTap: () => onSelected(items[2].$1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeButton(
                value: items[3].$1,
                label: items[3].$2,
                icon: items[3].$3,
                selected: selected == items[3].$1,
                onTap: () => onSelected(items[3].$1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryStrong : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  final String title;
  final String symbol;
  final double progress;
  final Map<String, int>? stats;

  const _ProgressTile({
    required this.title,
    required this.symbol,
    required this.progress,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final learned = stats?['learned'] ?? 0;
    final total = stats?['total'] ?? 0;
    final learning = stats?['learning'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              symbol,
              style: const TextStyle(
                color: AppColors.primaryStrong,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: AppColors.primaryStrong,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(99),
                ),
                const SizedBox(height: 6),
                Text(
                  '$learned / $total aprendidos · $learning estudiando',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionInfo extends StatelessWidget {
  final int learned;
  final int learning;
  final int due;
  final int newItems;

  const _SessionInfo({
    required this.learned,
    required this.learning,
    required this.due,
    required this.newItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.blue,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'La sesión prioriza repasos, mezcla contenido en aprendizaje y añade hasta 8 elementos nuevos.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
