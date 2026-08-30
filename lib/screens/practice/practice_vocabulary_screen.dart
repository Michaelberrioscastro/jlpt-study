import 'package:flutter/material.dart';

import '../../services/jlpt_practice_service.dart';
import '../../services/practice_progress_service.dart';
import '../../theme/app_colors.dart';
import 'practice_test_screen.dart';

class PracticeVocabularyScreen extends StatefulWidget {
  final String level;

  const PracticeVocabularyScreen({super.key, this.level = 'N5'});

  @override
  State<PracticeVocabularyScreen> createState() =>
      _PracticeVocabularyScreenState();
}

class _PracticeVocabularyScreenState extends State<PracticeVocabularyScreen> {
  String get _level => widget.level.toUpperCase();

  int? _questionCount;
  bool _loading = true;
  int _availableQuestions = 0;
  double _preparationPercent = 0;
  List<PracticeAttempt> _recentAttempts = const [];
  String? _error;

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
      final questions = await JlptPracticeService.getVocabularyQuestions(
        level: _level,
      );
      final summary = await PracticeProgressService.getSummary(
        level: _level,
        section: 'vocabulary',
      );

      if (!mounted) return;

      setState(() {
        _availableQuestions = questions.length;
        _preparationPercent = summary.preparationPercent;
        _recentAttempts = summary.recentAttempts;
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

  Future<void> _startQuick(int count) async {
    setState(() => _questionCount = count);

    final questions = await JlptPracticeService.buildVocabularySession(
      level: _level,
      count: count,
    );

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeTestScreen(
          title: '$_level · Vocabulary · $count',
          questions: questions,
          examMode: false,
          mode: 'quick_$count',
          section: 'vocabulary',
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _questionCount = null);
    await _load();
  }

  Future<void> _startFull() async {
    setState(() => _questionCount = _availableQuestions);

    final questions = await JlptPracticeService.buildVocabularySession(
      level: _level,
      count: _availableQuestions,
      shuffle: false,
    );

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeTestScreen(
          title: '$_level · Full Vocabulary',
          questions: questions,
          examMode: true,
          mode: 'full',
          section: 'vocabulary',
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _questionCount = null);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$_level Vocabulary Practice')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          children: [
            _HeroCard(level: _level, availableQuestions: _availableQuestions),
            const SizedBox(height: 14),
            _PreparationCard(
              level: _level,
              percentage: _preparationPercent,
              attempts: _recentAttempts,
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              eyebrow: '$_level · 文字・語彙',
              title: 'Choose a practice mode',
            ),
            const SizedBox(height: 12),
            if (_loading)
              _PracticeLoadingCard(level: _level)
            else if (_error != null)
              _ErrorCard(error: _error!, onRetry: _load)
            else ...[
              _PracticeCard(
                icon: Icons.bolt_rounded,
                title: 'Quick practice',
                subtitle:
                    'Short random sessions with feedback after each answer.',
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _questionCount == null
                          ? () => _startQuick(5)
                          : null,
                      child: Text(
                        _questionCount == 5 ? 'Preparing…' : '5 questions',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _questionCount == null
                          ? () => _startQuick(10)
                          : null,
                      child: Text(
                        _questionCount == 10 ? 'Preparing…' : '10 questions',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PracticeCard(
                icon: Icons.timer_outlined,
                title: 'Full vocabulary test',
                subtitle:
                    'Use the full available $_level vocabulary question bank with results at the end.',
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _questionCount == null ? _startFull : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        _questionCount == _availableQuestions &&
                                _questionCount != null
                            ? 'Preparing…'
                            : '$_availableQuestions questions',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PracticeLoadingCard extends StatelessWidget {
  final String level;

  const _PracticeLoadingCard({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              '語',
              style: TextStyle(
                color: AppColors.primaryStrong,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loading $level vocabulary practice',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    color: AppColors.primaryStrong,
                    backgroundColor: AppColors.primarySoft,
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

class _HeroCard extends StatelessWidget {
  final String level;
  final int availableQuestions;

  const _HeroCard({required this.level, required this.availableQuestions});

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
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '語',
              style: TextStyle(
                color: AppColors.primaryStrong,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vocabulary practice',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '文字・語彙 · $level',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryStrong,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '$availableQuestions JLPT-style vocabulary questions available for $level.',
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

class _PreparationCard extends StatelessWidget {
  final String level;
  final double percentage;
  final List<PracticeAttempt> attempts;

  const _PreparationCard({
    required this.level,
    required this.percentage,
    required this.attempts,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (percentage / 100).clamp(0.0, 1.0);
    final display = percentage.round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.primaryStrong,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$level · Vocabulary practice',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                attempts.isEmpty ? '—' : '$display%',
                style: const TextStyle(
                  color: AppColors.primaryStrong,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: normalized,
            minHeight: 9,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 9),
          Text(
            attempts.isEmpty
                ? 'Complete your first session to start tracking your vocabulary practice score.'
                : 'Practice score based on your recent attempts, with more weight given to newer results.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (attempts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 13),
            const Text(
              'Recent practice',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...attempts.take(5).map((attempt) => _AttemptRow(attempt: attempt)),
          ],
        ],
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  final PracticeAttempt attempt;

  const _AttemptRow({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final date = attempt.completedAt.toLocal();
    final dateText =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    String modeLabel;
    switch (attempt.mode) {
      case 'quick_5':
        modeLabel = '5 questions';
        break;
      case 'quick_10':
        modeLabel = '10 questions';
        break;
      case 'full':
        modeLabel = 'Full vocabulary test';
        break;
      default:
        modeLabel = attempt.mode;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modeLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(dateText, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            '${attempt.correctCount}/${attempt.questionCount}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(
              '${attempt.percentage.round()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.primaryStrong,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;

  const _SectionHeader({required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppColors.primaryStrong,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _PracticeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primaryStrong),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(children: children),
        ],
      ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
