import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/database_service.dart';
import '../theme/app_colors.dart';
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
    HapticFeedback.mediumImpact();

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
        return 'Mixed';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Kana Tracker',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            if (_loading)
              const _KanaScreenSkeleton()
            else if (_error != null)
              _ErrorCard(error: _error!, onRetry: _load)
            else ...[
              _KanaHero(
                progress: progress,
                total: total,
                learned: learned,
                due: due,
              ),
              const SizedBox(height: 24),
              _KanaStatusCard(
                learned: learned,
                learning: learning,
                due: due,
                notLearned: newItems,
              ),
              const SizedBox(height: 28),
              Text(
                'Track your knowledge',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'See how much Hiragana and Katakana you have already marked learned.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              _ProgressCard(
                symbol: 'あ',
                title: 'Hiragana',
                progress: _progressFor('hiragana'),
                stats: _byScript?['hiragana'],
              ),
              const SizedBox(height: 10),
              _ProgressCard(
                symbol: 'ア',
                title: 'Katakana',
                progress: _progressFor('katakana'),
                stats: _byScript?['katakana'],
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
                'Choose which kana to include in this SRS review session.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              _ReviewTypeSelector(
                selected: _studyType,
                onSelected: (value) => setState(() => _studyType = value),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: total == 0 ? null : _startStudy,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Start ${_labelFor(_studyType)} review',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _ReviewInfoCard(),
            ],
          ],
        ),
      ),
    );
  }
}

class _KanaHero extends StatelessWidget {
  final double progress;
  final int total;
  final int learned;
  final int due;

  const _KanaHero({
    required this.progress,
    required this.total,
    required this.learned,
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
                  color: AppColors.surface.withValues(alpha: .78),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'あ',
                  style: TextStyle(
                    color: AppColors.primaryStrong,
                    fontSize: 27,
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
                      'Kana knowledge tracker',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      due > 0
                          ? '$due reviews ready'
                          : 'Your review queue is clear',
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
            '$learned of $total kana marked learned',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _KanaStatusCard extends StatelessWidget {
  final int learned;
  final int learning;
  final int due;
  final int notLearned;

  const _KanaStatusCard({
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
            'Your current Kana tracker and SRS status.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatusMetric(
                  label: 'Learned',
                  value: learned,
                  icon: Icons.check_circle_rounded,
                  accent: AppColors.sage,
                  background: AppColors.sageSoft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusMetric(
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
                child: _StatusMetric(
                  label: 'Due',
                  value: due,
                  icon: Icons.schedule_rounded,
                  accent: AppColors.blue,
                  background: AppColors.blueSoft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatusMetric(
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

class _StatusMetric extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color accent;
  final Color background;

  const _StatusMetric({
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

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
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
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              symbol,
              style: const TextStyle(
                color: AppColors.primaryStrong,
                fontSize: 24,
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
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
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
                  tween: Tween(begin: 0, end: progress),
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
        ],
      ),
    );
  }
}

class _ReviewTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _ReviewTypeSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const options = [
      ('mix', 'Mixed', Icons.auto_awesome_rounded),
      ('hiragana', 'Hiragana', Icons.text_fields_rounded),
      ('katakana', 'Katakana', Icons.translate_rounded),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ReviewTypeButton(
                value: options[0].$1,
                label: options[0].$2,
                icon: options[0].$3,
                selected: selected == options[0].$1,
                onTap: () => onSelected(options[0].$1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ReviewTypeButton(
                value: options[1].$1,
                label: options[1].$2,
                icon: options[1].$3,
                selected: selected == options[1].$1,
                onTap: () => onSelected(options[1].$1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ReviewTypeButton(
                value: options[2].$1,
                label: options[2].$2,
                icon: options[2].$3,
                selected: selected == options[2].$1,
                onTap: () => onSelected(options[2].$1),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

class _ReviewTypeButton extends StatefulWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ReviewTypeButton({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ReviewTypeButton> createState() => _ReviewTypeButtonState();
}

class _ReviewTypeButtonState extends State<_ReviewTypeButton> {
  bool _pressed = false;

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? .982 : 1,
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
                Icon(
                  widget.icon,
                  size: 19,
                  color: widget.selected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _ReviewInfoCard extends StatelessWidget {
  const _ReviewInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.blue,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Review sessions prioritize due kana, then reinforce items already in SRS. '
              'Up to 8 new kana may be introduced when needed.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _KanaScreenSkeleton extends StatelessWidget {
  const _KanaScreenSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBlock(width: double.infinity, height: 154, radius: 28),
        SizedBox(height: 24),
        _SkeletonBlock(width: double.infinity, height: 154, radius: 22),
        SizedBox(height: 28),
        _SkeletonBlock(width: 190, height: 22, radius: 8),
        SizedBox(height: 9),
        _SkeletonBlock(width: 270, height: 12, radius: 7),
        SizedBox(height: 14),
        _SkeletonBlock(width: double.infinity, height: 92, radius: 20),
        SizedBox(height: 10),
        _SkeletonBlock(width: double.infinity, height: 92, radius: 20),
        SizedBox(height: 30),
        _SkeletonBlock(width: 190, height: 22, radius: 8),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SkeletonBlock(
                width: double.infinity,
                height: 52,
                radius: 18,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _SkeletonBlock(
                width: double.infinity,
                height: 52,
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
                height: 52,
                radius: 18,
              ),
            ),
            SizedBox(width: 10),
            Expanded(child: SizedBox()),
          ],
        ),
      ],
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

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorCard({required this.error, required this.onRetry});

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
            'Couldn\'t load Kana.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
