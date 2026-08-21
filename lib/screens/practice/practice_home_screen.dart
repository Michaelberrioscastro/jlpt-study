import 'package:flutter/material.dart';

import '../../services/practice_progress_service.dart';
import '../../theme/app_colors.dart';
import 'practice_level_screen.dart';

class PracticeHomeScreen extends StatefulWidget {
  const PracticeHomeScreen({super.key});

  @override
  State<PracticeHomeScreen> createState() => _PracticeHomeScreenState();
}

class _PracticeHomeScreenState extends State<PracticeHomeScreen> {
  bool _loading = true;
  double _n5Preparation = 0;
  int _n5Attempts = 0;
  double _n4Preparation = 0;
  int _n4Attempts = 0;
  double _n3Preparation = 0;
  int _n3Attempts = 0;
  double _n2Preparation = 0;
  int _n2Attempts = 0;
  double _n1Preparation = 0;
  int _n1Attempts = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final n5Summary = await PracticeProgressService.getSummary(
      level: 'N5',
      section: 'vocabulary',
    );
    final n4Summary = await PracticeProgressService.getSummary(
      level: 'N4',
      section: 'vocabulary',
    );
    final n3Summary = await PracticeProgressService.getSummary(
      level: 'N3',
      section: 'vocabulary',
    );
    final n2Summary = await PracticeProgressService.getSummary(
      level: 'N2',
      section: 'vocabulary',
    );

    final n1Summary = await PracticeProgressService.getSummary(
      level: 'N1',
      section: 'vocabulary',
    );

    if (!mounted) return;

    setState(() {
      _n5Preparation = n5Summary.preparationPercent;
      _n5Attempts = n5Summary.recentAttempts.length;
      _n4Preparation = n4Summary.preparationPercent;
      _n4Attempts = n4Summary.recentAttempts.length;
      _n3Preparation = n3Summary.preparationPercent;
      _n3Attempts = n3Summary.recentAttempts.length;
      _n2Preparation = n2Summary.preparationPercent;
      _n2Attempts = n2Summary.recentAttempts.length;
      _n1Preparation = n1Summary.preparationPercent;
      _n1Attempts = n1Summary.recentAttempts.length;
      _loading = false;
    });
  }

  Future<void> _openLevel(String level) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PracticeLevelScreen(level: level)),
    );

    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JLPT Practice')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          children: [
            const _PracticeHero(),
            const SizedBox(height: 26),
            Text(
              'CHOOSE YOUR LEVEL',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primaryStrong,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Preparation by level',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _LevelCard(
                level: 'N5',
                japanese: '日本語能力試験 N5',
                subtitle: 'Vocabulary · Grammar · Reading',
                percentage: _n5Preparation,
                attempts: _n5Attempts,
                enabled: true,
                onTap: () => _openLevel('N5'),
              ),
              const SizedBox(height: 11),
              _LevelCard(
                level: 'N4',
                japanese: '日本語能力試験 N4',
                subtitle: 'Vocabulary · Grammar · Reading',
                percentage: _n4Preparation,
                attempts: _n4Attempts,
                enabled: true,
                onTap: () => _openLevel('N4'),
              ),
              const SizedBox(height: 11),
              _LevelCard(
                level: 'N3',
                japanese: '日本語能力試験 N3',
                subtitle: 'Vocabulary · Grammar · Reading',
                percentage: _n3Preparation,
                attempts: _n3Attempts,
                enabled: true,
                onTap: () => _openLevel('N3'),
              ),
              const SizedBox(height: 11),
              _LevelCard(
                level: 'N2',
                japanese: '日本語能力試験 N2',
                subtitle: 'Vocabulary · Grammar · Reading',
                percentage: _n2Preparation,
                attempts: _n2Attempts,
                enabled: true,
                onTap: () => _openLevel('N2'),
              ),
              const SizedBox(height: 11),
              _LevelCard(
                level: 'N1',
                japanese: '日本語能力試験 N1',
                subtitle: 'Vocabulary · Grammar · Reading',
                percentage: _n1Preparation,
                attempts: _n1Attempts,
                enabled: true,
                onTap: () => _openLevel('N1'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PracticeHero extends StatelessWidget {
  const _PracticeHero();

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
            child: const Icon(
              Icons.fact_check_rounded,
              color: AppColors.primaryStrong,
              size: 31,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prepare for the JLPT',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Practice by level and track your preparation as you complete tests.',
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

class _LevelCard extends StatelessWidget {
  final String level;
  final String japanese;
  final String subtitle;
  final double percentage;
  final int attempts;
  final bool enabled;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.level,
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
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.primarySoft
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    color: enabled
                        ? AppColors.primaryStrong
                        : AppColors.textMuted,
                    fontSize: 20,
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
                      japanese,
                      style: TextStyle(
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (enabled) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        attempts == 0
                            ? 'No attempts yet'
                            : '${percentage.round()}% · $attempts recent attempts',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
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
