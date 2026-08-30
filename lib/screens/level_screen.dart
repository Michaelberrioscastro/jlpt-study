import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/study_item.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import 'practice/practice_level_screen.dart';
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
    HapticFeedback.mediumImpact();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyScreen(level: widget.level, studyType: studyType),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  Future<void> _openPractice() async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PracticeLevelScreen(level: widget.level),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  Future<void> _openStudyCatalog({
    required String type,
    required String title,
    required String symbol,
  }) async {
    HapticFeedback.selectionClick();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: _StudyCatalogSheet(
            level: widget.level,
            type: type,
            title: title,
            symbol: symbol,
          ),
        );
      },
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
        return 'Vocabulary';
      case 'kanji':
        return 'Kanji';
      case 'grammar':
        return 'Grammar';
      default:
        return 'Mixed';
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
      appBar: AppBar(title: Text('${widget.level} Tracker')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            if (loading)
              const _LevelScreenSkeleton()
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

              const SizedBox(height: 24),

              _TrackerStatusCard(
                learned: learned,
                learning: learning,
                due: due,
                notLearned: newItems,
              ),

              const SizedBox(height: 28),

              Text(
                'Track by area',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Open a category to browse its items and mark what you already know.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),

              _ProgressTile(
                title: 'Vocabulary',
                symbol: '語',
                progress: _progressFor('vocab'),
                stats: byType?['vocab'],
                onTap: () => _openStudyCatalog(
                  type: 'vocab',
                  title: 'Vocabulary',
                  symbol: '語',
                ),
              ),
              const SizedBox(height: 10),
              _ProgressTile(
                title: 'Kanji',
                symbol: '字',
                progress: _progressFor('kanji'),
                stats: byType?['kanji'],
                onTap: () => _openStudyCatalog(
                  type: 'kanji',
                  title: 'Kanji',
                  symbol: '字',
                ),
              ),
              const SizedBox(height: 10),
              _ProgressTile(
                title: 'Grammar',
                symbol: '文',
                progress: _progressFor('grammar'),
                stats: byType?['grammar'],
                onTap: () => _openStudyCatalog(
                  type: 'grammar',
                  title: 'Grammar',
                  symbol: '文',
                ),
              ),

              const SizedBox(height: 30),

              Text(
                'Review your knowledge',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose what to include in this SRS review session.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),

              _StudyTypeSelector(
                selected: studyType,
                onSelected: (value) {
                  setState(() => studyType = value);
                },
              ),

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: total == 0 ? null : _startStudy,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text('Start $_studyLabel review'),
                ),
              ),

              const SizedBox(height: 16),

              _SessionInfo(
                learned: learned,
                learning: learning,
                due: due,
                newItems: newItems,
              ),

              const SizedBox(height: 30),

              Text(
                'Practice your knowledge',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Test your ${widget.level} knowledge with JLPT-style Vocabulary, Grammar, and Reading questions.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),

              _PracticeKnowledgeCard(level: widget.level, onTap: _openPractice),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrackerStatusCard extends StatelessWidget {
  final int learned;
  final int learning;
  final int due;
  final int notLearned;

  const _TrackerStatusCard({
    required this.learned,
    required this.learning,
    required this.due,
    required this.notLearned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Knowledge status',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'A quick snapshot of how your ${learned + learning + notLearned} tracked items are classified.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TrackerStatusMetric(
                  label: 'Learned',
                  value: learned,
                  icon: Icons.check_circle_rounded,
                  accent: AppColors.sage,
                  background: AppColors.sageSoft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrackerStatusMetric(
                  label: 'Learning',
                  value: learning,
                  icon: Icons.autorenew_rounded,
                  accent: AppColors.primary,
                  background: AppColors.primarySoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TrackerStatusMetric(
                  label: 'Due',
                  value: due,
                  icon: Icons.schedule_rounded,
                  accent: AppColors.gold,
                  background: AppColors.goldSoft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrackerStatusMetric(
                  label: 'Not learned',
                  value: notLearned,
                  icon: Icons.radio_button_unchecked_rounded,
                  accent: AppColors.textSecondary,
                  background: AppColors.surfaceSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackerStatusMetric extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color accent;
  final Color background;

  const _TrackerStatusMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                      '$level knowledge tracker',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$due reviews ready',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Text(
                    '${(value * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: AppColors.primaryStrong,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 560),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 10,
                color: AppColors.primaryStrong,
                backgroundColor: AppColors.surface.withValues(alpha: .72),
                borderRadius: BorderRadius.circular(99),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '$learned of $total marked learned',
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
      ('mix', 'Mixed', Icons.auto_awesome_rounded),
      ('vocab', 'Vocabulary', Icons.menu_book_outlined),
      ('kanji', 'Kanji', Icons.translate_rounded),
      ('grammar', 'Grammar', Icons.edit_note_outlined),
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

class _TypeButton extends StatefulWidget {
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
  State<_TypeButton> createState() => _TypeButtonState();
}

class _TypeButtonState extends State<_TypeButton> {
  bool _pressed = false;

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.982 : 1,
      duration: const Duration(milliseconds: 105),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: _handleTap,
          onHighlightChanged: (value) {
            if (_pressed == value) return;
            setState(() => _pressed = value);
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 185),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.primaryStrong
                  : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.selected
                    ? AppColors.primaryStrong
                    : AppColors.outline,
              ),
              boxShadow: widget.selected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryStrong.withValues(alpha: .12),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Icon(
                    widget.icon,
                    key: ValueKey('${widget.value}-${widget.selected}'),
                    size: 19,
                    color: widget.selected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.selected
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
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

class _ProgressTile extends StatefulWidget {
  final String title;
  final String symbol;
  final double progress;
  final Map<String, int>? stats;
  final VoidCallback? onTap;

  const _ProgressTile({
    required this.title,
    required this.symbol,
    required this.progress,
    required this.stats,
    this.onTap,
  });

  @override
  State<_ProgressTile> createState() => _ProgressTileState();
}

class _ProgressTileState extends State<_ProgressTile> {
  bool _pressed = false;

  void _handleTap() {
    if (widget.onTap == null) return;
    HapticFeedback.selectionClick();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final learned = widget.stats?['learned'] ?? 0;
    final total = widget.stats?['total'] ?? 0;
    final learning = widget.stats?['learning'] ?? 0;

    return AnimatedScale(
      scale: _pressed ? 0.988 : 1,
      duration: const Duration(milliseconds: 105),
      curve: Curves.easeOutCubic,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: widget.onTap == null ? null : _handleTap,
          onHighlightChanged: widget.onTap == null
              ? null
              : (value) {
                  if (_pressed == value) return;
                  setState(() => _pressed = value);
                },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outline),
              boxShadow: _pressed
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: .025),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    widget.symbol,
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
                              widget.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: widget.progress),
                            duration: const Duration(milliseconds: 430),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return Text(
                                '${(value * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: AppColors.primaryStrong,
                                  fontWeight: FontWeight.w900,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: widget.progress),
                        duration: const Duration(milliseconds: 480),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 7,
                            color: AppColors.primaryStrong,
                            backgroundColor: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(99),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$learned / $total learned · $learning in SRS',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSlide(
                  offset: _pressed ? const Offset(.08, 0) : Offset.zero,
                  duration: const Duration(milliseconds: 105),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryStrong,
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

class _PracticeKnowledgeCard extends StatefulWidget {
  final String level;
  final VoidCallback onTap;

  const _PracticeKnowledgeCard({required this.level, required this.onTap});

  @override
  State<_PracticeKnowledgeCard> createState() => _PracticeKnowledgeCardState();
}

class _PracticeKnowledgeCardState extends State<_PracticeKnowledgeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? .988 : 1,
      duration: const Duration(milliseconds: 105),
      curve: Curves.easeOutCubic,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) {
            if (_pressed == value) return;
            setState(() => _pressed = value);
          },
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.outline),
              boxShadow: _pressed
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: .025),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.sageSoft,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    color: AppColors.sage,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.level} JLPT Practice',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vocabulary · Grammar · Reading',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Open practice for ${widget.level}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.sage,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSlide(
                  offset: _pressed ? const Offset(.08, 0) : Offset.zero,
                  duration: const Duration(milliseconds: 105),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.sage,
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

class _StudyCatalogSheet extends StatefulWidget {
  final String level;
  final String type;
  final String title;
  final String symbol;

  const _StudyCatalogSheet({
    required this.level,
    required this.type,
    required this.title,
    required this.symbol,
  });

  @override
  State<_StudyCatalogSheet> createState() => _StudyCatalogSheetState();
}

class _StudyCatalogSheetState extends State<_StudyCatalogSheet> {
  final TextEditingController _searchController = TextEditingController();

  List<StudyItem> _items = const [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';
  final Set<int> _savingIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final items = await DatabaseService.getStudyCatalogItems(
        level: widget.level,
        type: widget.type,
      );

      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggleLearned(StudyItem item) async {
    if (_savingIds.contains(item.id)) return;

    HapticFeedback.selectionClick();
    setState(() => _savingIds.add(item.id));

    try {
      await DatabaseService.setLearned(item, learned: !item.learned);
      await _loadItems(showLoading: false);
      HapticFeedback.lightImpact();
    } catch (e) {
      HapticFeedback.mediumImpact();
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Couldn\'t update: $e')));
    } finally {
      if (mounted) {
        setState(() => _savingIds.remove(item.id));
      }
    }
  }

  List<StudyItem> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();

    return _items.where((item) {
      if (_filter == 'learned' && !item.learned) return false;
      if (_filter == 'pending' && item.learned) return false;

      if (query.isEmpty) return true;

      return item.front.toLowerCase().contains(query) ||
          item.reading.toLowerCase().contains(query) ||
          item.meaning.toLowerCase().contains(query);
    }).toList();
  }

  int get _learnedCount => _items.where((item) => item.learned).length;

  String get _searchHint {
    switch (widget.type) {
      case 'vocab':
        return 'Search word, reading, or meaning';
      case 'kanji':
        return 'Search kanji, reading, or meaning';
      case 'grammar':
        return 'Search pattern or meaning';
      default:
        return 'Search';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;
    final pendingCount = _items.length - _learnedCount;

    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        widget.symbol,
                        style: const TextStyle(
                          color: AppColors.primaryStrong,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.title} · ${widget.level}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_learnedCount} of ${_items.length} marked learned',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: _searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: AppColors.surfaceSoft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  children: [
                    ChoiceChip(
                      label: Text('All (${_items.length})'),
                      selected: _filter == 'all',
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = 'all');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Not learned ($pendingCount)'),
                      selected: _filter == 'pending',
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = 'pending');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Learned ($_learnedCount)'),
                      selected: _filter == 'learned',
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = 'learned');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 17,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Mark items as Learned when you already know them. '
                        'Learned items stay out of SRS, while review history is preserved.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildBody(filteredItems)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<StudyItem> filteredItems) {
    if (_loading) {
      return const _CatalogListSkeleton();
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 30,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _loadItems, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'There is no ${widget.title.toLowerCase()} content '
          'for ${widget.level}.',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (filteredItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No items match your search or filter.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: filteredItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _CatalogItemCard(
          item: item,
          type: widget.type,
          saving: _savingIds.contains(item.id),
          onToggle: () => _toggleLearned(item),
        );
      },
    );
  }
}

class _CatalogItemCard extends StatelessWidget {
  final StudyItem item;
  final String type;
  final bool saving;
  final VoidCallback onToggle;

  const _CatalogItemCard({
    required this.item,
    required this.type,
    required this.saving,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final showReading = item.reading.trim().isNotEmpty;
    final titleSize = type == 'kanji' ? 27.0 : 16.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(15, 13, 10, 13),
      decoration: BoxDecoration(
        color: item.learned
            ? AppColors.sageSoft.withValues(alpha: .62)
            : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.learned
              ? AppColors.sage.withValues(alpha: .34)
              : AppColors.outline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.front,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (showReading) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.reading,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (item.meaning.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.meaning,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 190),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      child: _SmallStatusChip(
                        key: ValueKey('learned-${item.id}-${item.learned}'),
                        label: item.learned ? 'Learned' : 'Not learned',
                        icon: item.learned
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        active: item.learned,
                      ),
                    ),
                    _SmallStatusChip(
                      label: _srsLabel(item.state),
                      icon: Icons.autorenew_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            height: 42,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              child: saving
                  ? const _CompactSavingIndicator(key: ValueKey('saving'))
                  : IconButton(
                      key: ValueKey('toggle-${item.id}-${item.learned}'),
                      onPressed: onToggle,
                      tooltip: item.learned
                          ? 'Mark as not learned'
                          : 'Mark as learned',
                      icon: Icon(
                        item.learned
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: item.learned
                            ? AppColors.sage
                            : AppColors.textMuted,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String _srsLabel(String state) {
    switch (state) {
      case 'learning':
        return 'SRS · Learning';
      case 'review':
        return 'SRS · Review';
      case 'mature':
        return 'SRS · Mature';
      default:
        return 'SRS · New';
    }
  }
}

class _CompactSavingIndicator extends StatefulWidget {
  const _CompactSavingIndicator({super.key});

  @override
  State<_CompactSavingIndicator> createState() =>
      _CompactSavingIndicatorState();
}

class _CompactSavingIndicatorState extends State<_CompactSavingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: const Icon(
        Icons.sync_rounded,
        color: AppColors.primaryStrong,
        size: 22,
      ),
    );
  }
}

class _SmallStatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;

  const _SmallStatusChip({
    super.key,
    required this.label,
    required this.icon,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.sageSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: active
              ? AppColors.sage.withValues(alpha: .32)
              : AppColors.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: active ? AppColors.sage : AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: active ? AppColors.sage : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelScreenSkeleton extends StatelessWidget {
  const _LevelScreenSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBlock(width: double.infinity, height: 154, radius: 28),
        SizedBox(height: 26),
        _SkeletonBlock(width: 210, height: 23, radius: 9),
        SizedBox(height: 9),
        _SkeletonBlock(width: 250, height: 12, radius: 7),
        SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _SkeletonBlock(
                width: double.infinity,
                height: 50,
                radius: 18,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _SkeletonBlock(
                width: double.infinity,
                height: 50,
                radius: 18,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SkeletonBlock(
                width: double.infinity,
                height: 50,
                radius: 18,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _SkeletonBlock(
                width: double.infinity,
                height: 50,
                radius: 18,
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        _SkeletonBlock(width: double.infinity, height: 54, radius: 18),
        SizedBox(height: 30),
        _SkeletonBlock(width: 170, height: 18, radius: 8),
        SizedBox(height: 12),
        _SkeletonBlock(width: double.infinity, height: 84, radius: 20),
        SizedBox(height: 10),
        _SkeletonBlock(width: double.infinity, height: 84, radius: 20),
      ],
    );
  }
}

class _CatalogListSkeleton extends StatelessWidget {
  const _CatalogListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        return const _CatalogRowSkeleton();
      },
    );
  }
}

class _CatalogRowSkeleton extends StatelessWidget {
  const _CatalogRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SkeletonBlock(width: 120, height: 15, radius: 8),
                SizedBox(height: 8),
                _SkeletonBlock(width: 190, height: 11, radius: 7),
                SizedBox(height: 11),
                _SkeletonBlock(width: 92, height: 22, radius: 99),
              ],
            ),
          ),
          SizedBox(width: 12),
          _SkeletonBlock(width: 34, height: 34, radius: 17),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBlock({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  State<_SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<_SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat(reverse: true);

    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final color = Color.lerp(
          AppColors.surfaceMuted,
          AppColors.surfaceSoft,
          _pulse.value,
        );

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
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
              'Review sessions prioritize due items, then reinforce items already in SRS. '
              'Up to 8 not-yet-tracked items may be introduced when needed.',
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
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
