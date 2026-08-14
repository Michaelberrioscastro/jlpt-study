import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../theme/app_colors.dart';
import 'kana_screen.dart';
import 'level_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  String _selectedLevel = 'N5';
  Map<String, int>? _counts;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await DatabaseService.getStudyCounts(_selectedLevel);
      if (!mounted) return;

      setState(() {
        _counts = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectLevel(String level) async {
    if (_selectedLevel == level) return;

    setState(() => _selectedLevel = level);
    await _loadCounts();
  }

  Future<void> _openKana() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KanaScreen()),
    );

    if (!mounted) return;
    await _loadCounts();
  }

  Future<void> _openLevel() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LevelScreen(level: _selectedLevel)),
    );

    if (!mounted) return;
    await _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final total = _counts?['total'] ?? 0;
    final learned = _counts?['learned'] ?? 0;
    final learning = _counts?['learning'] ?? 0;
    final due = _counts?['due'] ?? 0;
    final newItems = _counts?['new'] ?? 0;
    final progress = total == 0 ? 0.0 : learned / total;

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      drawer: _StudyDrawer(
        selectedLevel: _selectedLevel,
        onKanaTap: _openKana,
      ),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _HeroHeader(
              selectedLevel: _selectedLevel,
              overallDue: due,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    eyebrow: 'RUTA JLPT',
                    title: 'Tu nivel',
                    trailing: _MiniBadge(
                      icon: Icons.auto_graph_rounded,
                      label: _selectedLevel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LevelRail(
                    levels: _levels,
                    selectedLevel: _selectedLevel,
                    onSelected: _selectLevel,
                  ),
                  const SizedBox(height: 16),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0.03, 0),
                        end: Offset.zero,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: _buildLevelArea(
                      key: ValueKey(
                        '$_selectedLevel-$_loading-${_error != null}-$learned-$learning-$due-$newItems',
                      ),
                      progress: progress,
                      total: total,
                      learned: learned,
                      learning: learning,
                      due: due,
                      newItems: newItems,
                    ),
                  ),

                  const SizedBox(height: 28),
                  _FooterTip(
                    text:
                        'Tu porcentaje solo sube cuando marcas un elemento como Aprendida.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelArea({
    required Key key,
    required double progress,
    required int total,
    required int learned,
    required int learning,
    required int due,
    required int newItems,
  }) {
    if (_loading) {
      return SizedBox(
        key: key,
        height: 265,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _ErrorPanel(key: key, error: _error!, onRetry: _loadCounts);
    }

    return _PrimaryStudyCard(
      key: key,
      symbol: _selectedLevel,
      title: 'Perfil $_selectedLevel',
      subtitle: 'Vocabulario · Kanji · Gramática · Mix',
      progress: progress,
      learned: learned,
      total: total,
      learning: learning,
      due: due,
      newItems: newItems,
      accent: AppColors.sage,
      accentSoft: AppColors.sageSoft,
      buttonLabel: 'Entrar a $_selectedLevel',
      onTap: total == 0 ? null : _openLevel,
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String selectedLevel;
  final int overallDue;

  const _HeroHeader({required this.selectedLevel, required this.overallDue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEEF3), Color(0xFFFFF8FA)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Builder(
                  builder: (context) {
                    return Material(
                      color: AppColors.primaryStrong,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => Scaffold.of(context).openDrawer(),
                        borderRadius: BorderRadius.circular(16),
                        child: const SizedBox(
                          width: 46,
                          height: 46,
                          child: Icon(
                            Icons.menu_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JLPT Study',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Japonés, un poco mejor cada día.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _HeaderPill(
                  icon: overallDue > 0
                      ? Icons.notifications_active_outlined
                      : Icons.check_circle_outline_rounded,
                  label: overallDue > 0 ? '$overallDue' : '✓',
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              '今日は何を勉強する？',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Continúa tu ruta $selectedLevel o cambia de nivel cuando quieras.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyDrawer extends StatelessWidget {
  final String selectedLevel;
  final Future<void> Function() onKanaTap;

  const _StudyDrawer({
    required this.selectedLevel,
    required this.onKanaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'あ',
                      style: TextStyle(
                        color: AppColors.primaryStrong,
                        fontSize: 25,
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
                          'JLPT Study',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Elige tu ruta de estudio',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 9),
              child: Text(
                'ESTUDIAR',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _DrawerDestination(
              icon: Icons.school_rounded,
              title: 'Niveles JLPT',
              subtitle: 'N5 · N4 · N3 · N2 · N1',
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            _DrawerDestination(
              icon: Icons.translate_rounded,
              title: 'Kana',
              subtitle: 'Hiragana · Katakana',
              onTap: () async {
                Navigator.pop(context);
                await Future<void>.delayed(
                  const Duration(milliseconds: 180),
                );
                await onKanaTap();
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_graph_rounded,
                      size: 18,
                      color: AppColors.primaryStrong,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Nivel activo: $selectedLevel',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerDestination extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerDestination({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: selected ? AppColors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 21,
                    color: selected
                        ? AppColors.primaryStrong
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: selected
                              ? AppColors.primaryStrong
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected
                      ? AppColors.primaryStrong
                      : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.primaryStrong),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryStrong,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget? trailing;

  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelRail extends StatelessWidget {
  final List<String> levels;
  final String selectedLevel;
  final ValueChanged<String> onSelected;

  const _LevelRail({
    required this.levels,
    required this.selectedLevel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: levels.map((level) {
          final selected = selectedLevel == level;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: level == levels.last ? 0 : 5),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelected(level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryStrong
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x208F405A),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PrimaryStudyCard extends StatefulWidget {
  final String symbol;
  final String title;
  final String subtitle;
  final double progress;
  final int learned;
  final int total;
  final int learning;
  final int due;
  final int newItems;
  final Color accent;
  final Color accentSoft;
  final String buttonLabel;
  final VoidCallback? onTap;

  const _PrimaryStudyCard({
    super.key,
    required this.symbol,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.learned,
    required this.total,
    required this.learning,
    required this.due,
    required this.newItems,
    required this.accent,
    required this.accentSoft,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  State<_PrimaryStudyCard> createState() => _PrimaryStudyCardState();
}

class _PrimaryStudyCardState extends State<_PrimaryStudyCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.986 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _pressed ? 0.025 : 0.045),
              blurRadius: _pressed ? 8 : 22,
              offset: Offset(0, _pressed ? 3 : 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: _setPressed,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: widget.accentSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.symbol,
                          style: TextStyle(
                            color: widget.accent,
                            fontSize: widget.symbol.length <= 2 ? 27 : 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.subtitle,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  _AnimatedProgress(
                    progress: widget.progress,
                    accent: widget.accent,
                    learned: widget.learned,
                    total: widget.total,
                  ),

                  const SizedBox(height: 20),
                  _StatStrip(
                    learned: widget.learned,
                    learning: widget.learning,
                    due: widget.due,
                    newItems: widget.newItems,
                    accent: widget.accent,
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.accent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: Text(widget.buttonLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedProgress extends StatelessWidget {
  final double progress;
  final Color accent;
  final int learned;
  final int total;

  const _AnimatedProgress({
    required this.progress,
    required this.accent,
    required this.learned,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '$learned / $total aprendidos',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 9,
                color: accent,
                backgroundColor: AppColors.surfaceMuted,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatStrip extends StatelessWidget {
  final int learned;
  final int learning;
  final int due;
  final int newItems;
  final Color accent;

  const _StatStrip({
    required this.learned,
    required this.learning,
    required this.due,
    required this.newItems,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TinyStat(
              icon: Icons.check_rounded,
              label: 'Aprendidas',
              value: learned,
              accent: accent,
            ),
          ),
          Expanded(
            child: _TinyStat(
              icon: Icons.school_outlined,
              label: 'Estudiando',
              value: learning,
              accent: accent,
            ),
          ),
          Expanded(
            child: _TinyStat(
              icon: Icons.schedule_rounded,
              label: 'Repasos',
              value: due,
              accent: accent,
            ),
          ),
          Expanded(
            child: _TinyStat(
              icon: Icons.auto_awesome_outlined,
              label: 'Nuevas',
              value: newItems,
              accent: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color accent;

  const _TinyStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9.5),
        ),
      ],
    );
  }
}

class _FooterTip extends StatelessWidget {
  final String text;

  const _FooterTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.blue,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorPanel({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            'No pude cargar el progreso.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
