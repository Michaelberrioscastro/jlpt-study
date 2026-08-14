import 'package:flutter/material.dart';

import '../../models/beginner_course.dart';
import '../../services/beginner_course_service.dart';
import '../../services/beginner_progress_service.dart';
import '../../theme/app_colors.dart';
import 'beginner_lesson_screen.dart';

class BeginnerPathScreen extends StatefulWidget {
  const BeginnerPathScreen({super.key});

  @override
  State<BeginnerPathScreen> createState() => _BeginnerPathScreenState();
}

class _BeginnerPathScreenState extends State<BeginnerPathScreen> {
  BeginnerCourse? _course;
  Map<String, BeginnerLessonProgress> _progress = const {};
  bool _loading = true;
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
      final course = await BeginnerCourseService.load();
      final progress = await BeginnerProgressService.getAll();

      if (!mounted) return;

      setState(() {
        _course = course;
        _progress = progress;
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

  List<BeginnerLesson> get _orderedLessons {
    final course = _course;
    if (course == null) return const [];

    return [for (final unit in course.units) ...unit.lessons];
  }

  bool _isUnlocked(String lessonId) {
    final lessons = _orderedLessons;
    final index = lessons.indexWhere((lesson) => lesson.id == lessonId);

    if (index <= 0) return true;

    final previous = lessons[index - 1];
    return _progress[previous.id]?.passed == true;
  }

  Future<void> _openLesson(BeginnerUnit unit, BeginnerLesson lesson) async {
    if (!_isUnlocked(lesson.id)) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BeginnerLessonScreen(
          course: _course!,
          unitTitle: unit.title,
          lesson: lesson,
        ),
      ),
    );

    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Empezar japonés')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 500,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_error != null || _course == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.error_outline_rounded, size: 42),
          const SizedBox(height: 14),
          const Text(
            'No se pudo cargar Beginner Mode.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(_error ?? '', textAlign: TextAlign.center),
          const SizedBox(height: 18),
          OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
        ],
      );
    }

    final course = _course!;
    final totalLessons = _orderedLessons.length;
    final passedLessons = _orderedLessons
        .where((l) => _progress[l.id]?.passed == true)
        .length;
    final overall = totalLessons == 0 ? 0.0 : passedLessons / totalLessons;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        _CourseHero(
          course: course,
          passed: passedLessons,
          total: totalLessons,
          progress: overall,
        ),
        const SizedBox(height: 28),
        ...course.units.asMap().entries.map((entry) {
          final unit = entry.value;
          final passed = unit.lessons
              .where((lesson) => _progress[lesson.id]?.passed == true)
              .length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _UnitCard(
              number: entry.key + 1,
              unit: unit,
              passed: passed,
              progress: _progress,
              isUnlocked: _isUnlocked,
              onTap: (lesson) => _openLesson(unit, lesson),
            ),
          );
        }),
      ],
    );
  }
}

class _CourseHero extends StatelessWidget {
  final BeginnerCourse course;
  final int passed;
  final int total;
  final double progress;

  const _CourseHero({
    required this.course,
    required this.passed,
    required this.total,
    required this.progress,
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
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('🌸', style: TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      course.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                '$passed de $total lecciones',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
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
            minHeight: 9,
            borderRadius: BorderRadius.circular(99),
          ),
        ],
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  final int number;
  final BeginnerUnit unit;
  final int passed;
  final Map<String, BeginnerLessonProgress> progress;
  final bool Function(String lessonId) isUnlocked;
  final ValueChanged<BeginnerLesson> onTap;

  const _UnitCard({
    required this.number,
    required this.unit,
    required this.passed,
    required this.progress,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unitProgress = unit.lessons.isEmpty
        ? 0.0
        : passed / unit.lessons.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(unit.emoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNIDAD $number',
                        style: const TextStyle(
                          color: AppColors.primaryStrong,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        unit.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                Text(
                  '$passed/${unit.lessons.length}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              unit.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: unitProgress,
              minHeight: 6,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 8),
            ...unit.lessons.asMap().entries.map((entry) {
              final lesson = entry.value;
              final lessonProgress = progress[lesson.id];
              final unlocked = isUnlocked(lesson.id);

              return _LessonRow(
                lesson: lesson,
                unlocked: unlocked,
                passed: lessonProgress?.passed == true,
                bestScore: lessonProgress?.bestScore,
                bestTotal: lessonProgress?.bestTotal,
                onTap: () => onTap(lesson),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final BeginnerLesson lesson;
  final bool unlocked;
  final bool passed;
  final int? bestScore;
  final int? bestTotal;
  final VoidCallback onTap;

  const _LessonRow({
    required this.lesson,
    required this.unlocked,
    required this.passed,
    required this.bestScore,
    required this.bestTotal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scoreText = bestTotal != null && bestTotal! > 0
        ? '$bestScore/$bestTotal'
        : null;

    return Opacity(
      opacity: unlocked ? 1 : .48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: unlocked ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: passed
                        ? AppColors.sageSoft
                        : unlocked
                        ? AppColors.primarySoft
                        : AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    passed
                        ? Icons.check_rounded
                        : unlocked
                        ? Icons.play_arrow_rounded
                        : Icons.lock_rounded,
                    size: 18,
                    color: passed
                        ? AppColors.success
                        : unlocked
                        ? AppColors.primaryStrong
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        passed && scoreText != null
                            ? 'Quiz aprobado · $scoreText'
                            : unlocked
                            ? '${lesson.estimatedMinutes} min · ${lesson.goal}'
                            : 'Completa la lección anterior para desbloquear',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (unlocked)
                  Icon(
                    passed
                        ? Icons.verified_rounded
                        : Icons.chevron_right_rounded,
                    color: passed ? AppColors.success : AppColors.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
