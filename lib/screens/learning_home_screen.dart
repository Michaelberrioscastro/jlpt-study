import 'package:flutter/material.dart';

import '../services/learning_database_service.dart';
import '../services/learning_progress_service.dart';
import '../theme/app_colors.dart';
import 'learning_session_screen.dart';

class LearningHomeScreen extends StatefulWidget {
  const LearningHomeScreen({super.key});

  @override
  State<LearningHomeScreen> createState() => _LearningHomeScreenState();
}

class _LearningHomeScreenState extends State<LearningHomeScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _dashboard = const <String, dynamic>{};
  Map<String, int> _courseCounts = const <String, int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final dashboard = await LearningProgressService.getDashboardSnapshot();
      final courseCounts = await LearningDatabaseService.getCourseCounts();

      if (!mounted) return;

      setState(() {
        _dashboard = dashboard;
        _courseCounts = courseCounts;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _openTodayLesson() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const LearningSessionScreen()),
    );

    if (!mounted) return;
    await _load();
  }

  int _dashboardInt(String key) {
    return (_dashboard[key] as num?)?.toInt() ?? 0;
  }

  int _courseInt(String key) {
    return _courseCounts[key] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn N4 Vocabulary')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          children: [
            const _LearningHero(),
            const SizedBox(height: 22),
            if (_loading)
              const _LoadingCard()
            else if (_error != null)
              _ErrorCard(message: _error!, onRetry: _load)
            else ...[
              _TodayCard(
                dueReviews: _dashboardInt('due_reviews'),
                newWords: _dashboardInt('new_words_per_day'),
                weakWords: _dashboardInt('weak_words'),
                batchSize: _dashboardInt('batch_size'),
                onStart: _openTodayLesson,
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                eyebrow: 'REAL PROGRESS',
                title: 'What you actually retain',
                description:
                    'Seeing a word is not the same as mastering it. '
                    'LEARN tracks exposure and retention separately.',
              ),
              const SizedBox(height: 12),
              _OverallProgressCard(
                total: _courseInt('default'),
                unseen: _dashboardInt('unseen'),
                introduced: _dashboardInt('introduced'),
                learning: _dashboardInt('learning'),
                reviewing: _dashboardInt('review'),
                mastered: _dashboardInt('mastered'),
              ),
              const SizedBox(height: 14),
              _PriorityProgressCard(
                title: 'CORE vocabulary',
                subtitle: 'High-priority N4 vocabulary introduced first.',
                total: _dashboardInt('core_total'),
                seen: _dashboardInt('core_seen'),
                mastered: _dashboardInt('core_mastered'),
                icon: Icons.auto_awesome_rounded,
              ),
              const SizedBox(height: 11),
              _PriorityProgressCard(
                title: 'STANDARD vocabulary',
                subtitle: 'Introduced gradually after the CORE foundation.',
                total: _dashboardInt('standard_total'),
                seen: _dashboardInt('standard_seen'),
                mastered: _dashboardInt('standard_mastered'),
                icon: Icons.menu_book_rounded,
              ),
              const SizedBox(height: 24),
              const _SectionHeader(
                eyebrow: 'HOW LEARN WORKS',
                title: 'More than flashcards',
                description:
                    'Each word is trained through separate retrieval skills '
                    'instead of a single Good/Again score.',
              ),
              const SizedBox(height: 12),
              const _SkillGrid(),
              const SizedBox(height: 14),
              _CourseScopeCard(
                core: _courseInt('core'),
                standard: _courseInt('standard'),
                extended: _courseInt('extended'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LearningHero extends StatelessWidget {
  const _LearningHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .76),
              borderRadius: BorderRadius.circular(21),
            ),
            child: const Text(
              '語',
              style: TextStyle(
                color: AppColors.primaryStrong,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build your N4 vocabulary',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Learn meaning, reading, context and active recall '
                  'before long-term review.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 260,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              'LEARN could not be loaded',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final int dueReviews;
  final int newWords;
  final int weakWords;
  final int batchSize;
  final Future<void> Function() onStart;

  const _TodayCard({
    required this.dueReviews,
    required this.newWords,
    required this.weakWords,
    required this.batchSize,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.goldSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.today_rounded, color: AppColors.gold),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's study",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Small batches, retrieval first.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _TodayMetric(
                    value: '$dueReviews',
                    label: 'Reviews',
                    icon: Icons.schedule_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TodayMetric(
                    value: '$newWords',
                    label: 'New max',
                    icon: Icons.add_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TodayMetric(
                    value: '$weakWords',
                    label: 'Weak',
                    icon: Icons.fitness_center_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                batchSize <= 1
                    ? 'New vocabulary is introduced one word at a time.'
                    : 'New vocabulary is introduced in blocks of '
                          '$batchSize words before a short check.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await onStart();
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text("Start today's lesson"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayMetric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _TodayMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryStrong, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.primaryStrong,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  final int total;
  final int unseen;
  final int introduced;
  final int learning;
  final int reviewing;
  final int mastered;

  const _OverallProgressCard({
    required this.total,
    required this.unseen,
    required this.introduced,
    required this.learning,
    required this.reviewing,
    required this.mastered,
  });

  @override
  Widget build(BuildContext context) {
    final seen = (total - unseen).clamp(0, total);
    final masteryProgress = total <= 0
        ? 0.0
        : (mastered / total).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    'N4 vocabulary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '$mastered / $total mastered',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryStrong,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: masteryProgress,
                minHeight: 9,
              ),
            ),
            const SizedBox(height: 17),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatePill(label: 'Seen', value: seen),
                _StatePill(label: 'Introduced', value: introduced),
                _StatePill(label: 'Learning', value: learning),
                _StatePill(label: 'Reviewing', value: reviewing),
                _StatePill(label: 'Mastered', value: mastered),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  final String label;
  final int value;

  const _StatePill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$label · $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PriorityProgressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int total;
  final int seen;
  final int mastered;
  final IconData icon;

  const _PriorityProgressCard({
    required this.title,
    required this.subtitle,
    required this.total,
    required this.seen,
    required this.mastered,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final seenProgress = total <= 0 ? 0.0 : (seen / total).clamp(0.0, 1.0);
    final masteryProgress = total <= 0
        ? 0.0
        : (mastered / total).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.sageSoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: AppColors.sage),
            ),
            const SizedBox(width: 14),
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
                        '$mastered / $total',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryStrong,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 11),
                  _DoubleProgressBar(
                    seenProgress: seenProgress,
                    masteryProgress: masteryProgress,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Seen $seen / $total',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        'Mastered $mastered',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoubleProgressBar extends StatelessWidget {
  final double seenProgress;
  final double masteryProgress;

  const _DoubleProgressBar({
    required this.seenProgress,
    required this.masteryProgress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 9,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(color: AppColors.surfaceMuted),
            ),
          ),
          FractionallySizedBox(
            widthFactor: seenProgress,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(color: AppColors.primarySoft),
            ),
          ),
          FractionallySizedBox(
            widthFactor: masteryProgress,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(color: AppColors.primaryStrong),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillGrid extends StatelessWidget {
  const _SkillGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _SkillCard(
          icon: Icons.translate_rounded,
          title: 'Meaning',
          subtitle: 'Recognize what it means',
        ),
        _SkillCard(
          icon: Icons.record_voice_over_rounded,
          title: 'Reading',
          subtitle: 'Retrieve the kana reading',
        ),
        _SkillCard(
          icon: Icons.format_quote_rounded,
          title: 'Context',
          subtitle: 'Understand it in a sentence',
        ),
        _SkillCard(
          icon: Icons.psychology_alt_rounded,
          title: 'Recall',
          subtitle: 'Retrieve the Japanese word',
        ),
      ],
    );
  }
}

class _SkillCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SkillCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: AppColors.primaryStrong),
          const Spacer(),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CourseScopeCard extends StatelessWidget {
  final int core;
  final int standard;
  final int extended;

  const _CourseScopeCard({
    required this.core,
    required this.standard,
    required this.extended,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.goldSoft.withValues(alpha: .62),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandGold.withValues(alpha: .34)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.layers_rounded, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: '${core + standard} words in the main N4 course',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(text: ' · $core CORE · $standard STANDARD'),
                  if (extended > 0)
                    TextSpan(
                      text:
                          '\n$extended EXTENDED words stay outside the default '
                          'course for optional study later.',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
