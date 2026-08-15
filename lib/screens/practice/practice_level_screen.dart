import 'package:flutter/material.dart';

import '../../services/jlpt_practice_service.dart';
import '../../services/practice_progress_service.dart';
import '../../theme/app_colors.dart';
import 'practice_grammar_screen.dart';
import 'practice_reading_screen.dart';
import 'practice_vocabulary_screen.dart';

class PracticeLevelScreen extends StatefulWidget {
  const PracticeLevelScreen({super.key});

  @override
  State<PracticeLevelScreen> createState() => _PracticeLevelScreenState();
}

class _PracticeLevelScreenState extends State<PracticeLevelScreen> {
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
      final vocabularyQuestions =
          await JlptPracticeService.getN5VocabularyQuestions();
      final grammarQuestions =
          await JlptPracticeService.getN5GrammarQuestions();
      final readingQuestions =
          await JlptPracticeService.getN5ReadingQuestionCount();
      final vocabularySummary = await PracticeProgressService.getSummary(
        level: 'N5',
        section: 'vocabulary',
      );
      final grammarSummary = await PracticeProgressService.getSummary(
        level: 'N5',
        section: 'grammar',
      );
      final readingSummary = await PracticeProgressService.getSummary(
        level: 'N5',
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
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PracticeVocabularyScreen()));
    if (!mounted) return;
    await _load();
  }

  Future<void> _openGrammar() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PracticeGrammarScreen()));
    if (!mounted) return;
    await _load();
  }

  Future<void> _openReading() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PracticeReadingScreen()));
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('N5 · Preparación')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          children: [
            const _HeaderCard(),
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
              const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorCard(error: _error!, onRetry: _load)
            else ...[
              _SectionCard(
                icon: Icons.translate_rounded,
                title: 'Vocabulary',
                japanese: '文字・語彙',
                subtitle: '$_vocabularyQuestions preguntas disponibles',
                percentage: _vocabularyPreparation,
                attempts: _vocabularyAttempts,
                enabled: true,
                onTap: _openVocabulary,
              ),
              const SizedBox(height: 11),
              _SectionCard(
                icon: Icons.extension_rounded,
                title: 'Grammar',
                japanese: '文法',
                subtitle: '$_grammarQuestions preguntas disponibles',
                percentage: _grammarPreparation,
                attempts: _grammarAttempts,
                enabled: true,
                onTap: _openGrammar,
              ),
              const SizedBox(height: 11),
              _SectionCard(
                icon: Icons.menu_book_rounded,
                title: 'Reading',
                japanese: '読解',
                subtitle: '$_readingQuestions preguntas disponibles',
                percentage: _readingPreparation,
                attempts: _readingAttempts,
                enabled: true,
                onTap: _openReading,
              ),
              const SizedBox(height: 11),
              const _SectionCard(
                icon: Icons.headphones_rounded,
                title: 'Listening',
                japanese: '聴解',
                subtitle: 'Próximamente',
              ),
              const SizedBox(height: 22),
              const _MockExamCard(),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

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
              'N5',
              style: TextStyle(
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
                  'Preparación N5',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Practica cada sección y descubre dónde necesitas reforzar.',
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
          const Row(
            children: [
              Icon(Icons.insights_rounded, color: AppColors.primaryStrong),
              SizedBox(width: 9),
              Text(
                'Preparación general',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const LinearProgressIndicator(value: 0, minHeight: 9),
          const SizedBox(height: 9),
          Text(
            hasData
                ? 'Aún no calculamos un porcentaje general. ${hasVocabularyData ? 'Vocabulary: ${vocabularyPercent.round()}%. ' : ''}${hasGrammarData ? 'Grammar: ${grammarPercent.round()}%. ' : ''}${hasReadingData ? 'Reading: ${readingPercent.round()}%.' : ''}'
                : 'Completa secciones para comenzar a estimar tu preparación general.',
            style: Theme.of(context).textTheme.bodySmall,
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
          'SECCIONES',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.primaryStrong,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '¿Qué quieres practicar?',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
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
                      Text(
                        attempts == 0
                            ? 'Sin datos todavía'
                            : '${percentage.round()}% de preparación',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
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
  const _MockExamCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: const Row(
        children: [
          Icon(Icons.assignment_rounded, color: AppColors.textMuted, size: 28),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulacro N5 completo',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Vocabulary · Grammar · Reading · Listening\nPróximamente',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
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
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
