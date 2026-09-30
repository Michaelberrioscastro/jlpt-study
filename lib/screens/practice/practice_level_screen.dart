import 'package:flutter/material.dart';

import '../../services/jlpt_practice_service.dart';
import '../../services/practice_progress_service.dart';
import '../../theme/app_colors.dart';
import 'practice_grammar_screen.dart';
import 'practice_reading_screen.dart';
import 'practice_vocabulary_screen.dart';

class PracticeLevelScreen extends StatefulWidget {
  final String level;

  const PracticeLevelScreen({super.key, this.level = 'N5'});

  @override
  State<PracticeLevelScreen> createState() => _PracticeLevelScreenState();
}

class _PracticeLevelScreenState extends State<PracticeLevelScreen> {
  String get _level => widget.level.toUpperCase();
  bool get _hasPracticeContent =>
      _level == 'N5' ||
      _level == 'N4' ||
      _level == 'N3' ||
      _level == 'N2' ||
      _level == 'N1';

  bool _loading = true;
  double _vocabularyPreparation = 0;
  int _vocabularyAttempts = 0;
  int _vocabularyQuestions = 0;
  double _grammarPreparation = 0;
  int _grammarAttempts = 0;
  int _grammarQuestions = 0;
  double _readingPreparation = 0;
  int _readingAttempts = 0;
  int _readingQuestions = 0;
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
      if (!_hasPracticeContent) {
        if (!mounted) return;
        setState(() {
          _vocabularyQuestions = 0;
          _vocabularyPreparation = 0;
          _vocabularyAttempts = 0;
          _grammarQuestions = 0;
          _grammarPreparation = 0;
          _grammarAttempts = 0;
          _readingQuestions = 0;
          _readingPreparation = 0;
          _readingAttempts = 0;
          _loading = false;
        });
        return;
      }

      final vocabularyQuestions =
          await JlptPracticeService.getVocabularyQuestions(level: _level);
      final grammarQuestions = await JlptPracticeService.getGrammarQuestions(
        level: _level,
      );
      final readingQuestions =
          await JlptPracticeService.getReadingQuestionCount(level: _level);

      final vocabularySummary = await PracticeProgressService.getSummary(
        level: _level,
        section: 'vocabulary',
      );
      final grammarSummary = await PracticeProgressService.getSummary(
        level: _level,
        section: 'grammar',
      );
      final readingSummary = await PracticeProgressService.getSummary(
        level: _level,
        section: 'reading',
      );

      if (!mounted) return;
      setState(() {
        _vocabularyQuestions = vocabularyQuestions.length;
        _vocabularyPreparation = vocabularySummary.preparationPercent;
        _vocabularyAttempts = vocabularySummary.recentAttempts.length;
        _grammarQuestions = grammarQuestions.length;
        _grammarPreparation = grammarSummary.preparationPercent;
        _grammarAttempts = grammarSummary.recentAttempts.length;
        _readingQuestions = readingQuestions;
        _readingPreparation = readingSummary.preparationPercent;
        _readingAttempts = readingSummary.recentAttempts.length;
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

  Future<void> _openVocabulary() async {
    if (!_hasPracticeContent) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeVocabularyScreen(level: _level),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _openGrammar() async {
    if (!_hasPracticeContent) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PracticeGrammarScreen(level: _level)),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _openReading() async {
    if (!_hasPracticeContent) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PracticeReadingScreen(level: _level)),
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$_level Practice')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          children: [
            _HeaderCard(level: _level),
            const SizedBox(height: 18),
            _GeneralPreparationCard(
              hasData:
                  _vocabularyAttempts > 0 ||
                  _grammarAttempts > 0 ||
                  _readingAttempts > 0,
              vocabularyPercent: _vocabularyPreparation,
              grammarPercent: _grammarPreparation,
              hasVocabularyData: _vocabularyAttempts > 0,
              hasGrammarData: _grammarAttempts > 0,
              readingPercent: _readingPreparation,
              hasReadingData: _readingAttempts > 0,
            ),
            const SizedBox(height: 26),
            const _SectionTitle(),
            const SizedBox(height: 12),
            if (_loading)
              _PracticeLoadingCard(level: _level)
            else if (_error != null)
              _ErrorCard(error: _error!, onRetry: _load)
            else ...[
              _SectionCard(
                icon: Icons.translate_rounded,
                title: 'Vocabulary',
                japanese: '文字・語彙',
                subtitle: _hasPracticeContent
                    ? '$_vocabularyQuestions questions available'
                    : 'Coming soon',
                percentage: _vocabularyPreparation,
                attempts: _vocabularyAttempts,
                enabled: _hasPracticeContent,
                onTap: _hasPracticeContent ? _openVocabulary : null,
              ),
              const SizedBox(height: 11),
              _SectionCard(
                icon: Icons.extension_rounded,
                title: 'Grammar',
                japanese: '文法',
                subtitle: _hasPracticeContent
                    ? '$_grammarQuestions questions available'
                    : 'Coming soon',
                percentage: _grammarPreparation,
                attempts: _grammarAttempts,
                enabled: _hasPracticeContent,
                onTap: _hasPracticeContent ? _openGrammar : null,
              ),
              const SizedBox(height: 11),
              _SectionCard(
                icon: Icons.menu_book_rounded,
                title: 'Reading',
                japanese: '読解',
                subtitle: _hasPracticeContent
                    ? '$_readingQuestions questions available'
                    : 'Coming soon',
                percentage: _readingPreparation,
                attempts: _readingAttempts,
                enabled: _hasPracticeContent,
                onTap: _hasPracticeContent ? _openReading : null,
              ),
              const SizedBox(height: 22),
              _MockExamCard(level: _level),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String level;

  const _HeaderCard({required this.level});

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
            child: Text(
              level,
              style: const TextStyle(
                color: AppColors.primaryStrong,
                fontSize: 25,
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
                  'Practice your $level knowledge',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Use JLPT-style questions to check what you can actually recognize and apply.',
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

class _GeneralPreparationCard extends StatelessWidget {
  final bool hasData;
  final double vocabularyPercent;
  final double grammarPercent;
  final bool hasVocabularyData;
  final bool hasGrammarData;
  final double readingPercent;
  final bool hasReadingData;

  const _GeneralPreparationCard({
    required this.hasData,
    required this.vocabularyPercent,
    required this.grammarPercent,
    required this.hasVocabularyData,
    required this.hasGrammarData,
    required this.readingPercent,
    required this.hasReadingData,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice snapshot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasData
                          ? 'Your latest practice performance by section.'
                          : 'Complete a practice section to start building this view.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PracticeMetric(
                  label: 'Vocabulary',
                  value: hasVocabularyData
                      ? '${vocabularyPercent.round()}%'
                      : '—',
                  active: hasVocabularyData,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PracticeMetric(
                  label: 'Grammar',
                  value: hasGrammarData ? '${grammarPercent.round()}%' : '—',
                  active: hasGrammarData,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PracticeMetric(
                  label: 'Reading',
                  value: hasReadingData ? '${readingPercent.round()}%' : '—',
                  active: hasReadingData,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PracticeMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool active;

  const _PracticeMetric({
    required this.label,
    required this.value,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: active ? AppColors.primarySoft : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: active ? AppColors.primaryStrong : AppColors.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRACTICE YOUR KNOWLEDGE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.primaryStrong,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose a section',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
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
            child: Text(
              level,
              style: const TextStyle(
                color: AppColors.primaryStrong,
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
                  'Loading $level practice',
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

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String japanese;
  final String subtitle;
  final double percentage;
  final int attempts;
  final bool enabled;
  final VoidCallback? onTap;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.japanese,
    required this.subtitle,
    this.percentage = 0,
    this.attempts = 0,
    this.enabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (percentage / 100).clamp(0.0, 1.0);

    return Material(
      color: enabled ? AppColors.surface : AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.primarySoft
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? AppColors.primaryStrong
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: enabled
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          japanese,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (enabled) ...[
                      const SizedBox(height: 9),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              attempts == 0
                                  ? 'No attempts yet'
                                  : '${percentage.round()}% practice score · $attempts recent attempt${attempts == 1 ? '' : 's'}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Practice',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.primaryStrong,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                enabled
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,
                color: enabled ? AppColors.primaryStrong : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockExamCard extends StatelessWidget {
  final String level;

  const _MockExamCard({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.assignment_rounded,
            color: AppColors.textMuted,
            size: 28,
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$level Mock Exam',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                const Text(
                  'Full exam simulation · Coming soon',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
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
