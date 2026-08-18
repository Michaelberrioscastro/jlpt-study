import 'package:flutter/material.dart';

import '../../services/jlpt_practice_service.dart';
import '../../services/practice_progress_service.dart';
import '../../theme/app_colors.dart';
import 'reading_test_screen.dart';

class PracticeReadingScreen extends StatefulWidget {
  final String level;

  const PracticeReadingScreen({super.key, this.level = 'N5'});

  @override
  State<PracticeReadingScreen> createState() => _PracticeReadingScreenState();
}

class _PracticeReadingScreenState extends State<PracticeReadingScreen> {
  String get _level => widget.level.toUpperCase();

  bool _loading = true;
  double _preparation = 0;
  int _questionCount = 0;
  List<PracticeAttempt> _attempts = const [];
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
      final count = await JlptPracticeService.getReadingQuestionCount(
        level: _level,
      );
      final summary = await PracticeProgressService.getSummary(
        level: _level,
        section: 'reading',
      );

      if (!mounted) return;
      setState(() {
        _questionCount = count;
        _preparation = summary.preparationPercent;
        _attempts = summary.recentAttempts;
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

  Future<void> _start({
    required int count,
    required String mode,
    required bool examMode,
  }) async {
    final passages = await JlptPracticeService.buildReadingSession(
      level: _level,
      questionCount: count,
      shufflePassages: !examMode,
    );

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReadingTestScreen(
          title: examMode ? '$_level · Reading completo' : '$_level · Reading',
          level: _level,
          passages: passages,
          mode: mode,
          examMode: examMode,
          maxQuestions: count,
        ),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$_level · Reading')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          children: [
            _HeaderCard(
              level: _level,
              percentage: _preparation,
              attempts: _attempts.length,
            ),
            const SizedBox(height: 22),
            if (_loading)
              const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorCard(error: _error!, onRetry: _load)
            else ...[
              Text(
                'PRÁCTICA',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryStrong,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Elige una sesión',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 13),
              _ActionCard(
                icon: Icons.bolt_rounded,
                title: 'Práctica rápida',
                subtitle: '5 preguntas · pasajes seleccionados al azar',
                onTap: () => _start(count: 5, mode: 'quick_5', examMode: false),
              ),
              const SizedBox(height: 11),
              _ActionCard(
                icon: Icons.assignment_rounded,
                title: 'Reading completo',
                subtitle: '$_questionCount preguntas disponibles',
                onTap: () =>
                    _start(count: _questionCount, mode: 'full', examMode: true),
              ),
              if (_attempts.isNotEmpty) ...[
                const SizedBox(height: 26),
                Text(
                  'ÚLTIMOS INTENTOS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryStrong,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                ..._attempts.map((attempt) => _AttemptTile(attempt: attempt)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String level;
  final double percentage;
  final int attempts;

  const _HeaderCard({
    required this.level,
    required this.percentage,
    required this.attempts,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (percentage / 100).clamp(0.0, 1.0);

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
              Icon(
                Icons.menu_book_rounded,
                color: AppColors.primaryStrong,
                size: 30,
              ),
              SizedBox(width: 10),
              Text(
                '$level · Reading · 読解',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${percentage.round()}%',
                style: const TextStyle(
                  color: AppColors.primaryStrong,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 9),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  attempts == 0 ? 'Sin intentos todavía' : 'de preparación',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 10),
          Text(
            'Lee el pasaje completo y responde sin perder el texto de vista.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(20),
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
                child: Icon(icon, color: AppColors.primaryStrong),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryStrong,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  final PracticeAttempt attempt;

  const _AttemptTile({required this.attempt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: AppColors.textMuted),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              '${attempt.correctCount}/${attempt.questionCount} correctas',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '${attempt.percentage.round()}%',
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
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
