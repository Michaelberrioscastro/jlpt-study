import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import '../study/study_catalog.dart';
import '../study/book_catalog.dart';
import 'progress_service.dart';
import '../study/expanded_content.dart';
import '../study/learning_engine.dart';
import 'sensei_chat_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;
  bool drawerOpen = false;
  final progress = ProgressService.instance;

  @override
  void initState() {
    super.initState();
    progress.load();
  }

  void openSession(SessionInfo s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonFlowPage(session: s, progress: progress),
      ),
    ).then((_) => setState(() {}));
  }

  void closeDrawer() {
    if (drawerOpen) setState(() => drawerOpen = false);
  }

  Future<void> selectLevel(String level) async {
    await progress.setLevel(level);
    if (!mounted) return;
    setState(() => drawerOpen = false);
  }

  Future<void> selectBook(String bookId) async {
    await progress.setBook(bookId);
    if (!mounted) return;
    setState(() => drawerOpen = false);
  }

  Future<void> openBook(String bookId) async {
    await progress.setBook(bookId);
    if (!mounted) return;
    setState(() {
      tab = 0;
      drawerOpen = false;
    });
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDashboardPage(progress: progress),
      ),
    );
    if (mounted) setState(() {});
  }

  String _currentSenseiContext() {
    switch (tab) {
      case 1:
        return 'El usuario esta en Camino. La proxima sesion es ${progress.nextUnlockedSession().titleEs}, con foco ${progress.nextUnlockedSession().focus}.';
      case 2:
        return 'El usuario esta en Repaso. Tiene ${progress.stats.openMistakes} errores pendientes y esta revisando sus puntos debiles.';
      case 3:
        return 'El usuario esta en Progreso. Lleva ${progress.completedCount} sesiones completadas, ${progress.stats.xp} XP y una precision del ${progress.stats.accuracy.round()}%.';
      default:
        final session = progress.nextUnlockedSession();
        return 'El usuario esta en Hoy. Su siguiente sesion es Dia ${session.day}: ${session.titleEs}. Foco: ${session.focus}.';
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    builder: (_, __) {
      final content = IndexedStack(
        index: tab,
        children: [
          StudioHomePage(
            progress: progress,
            onStart: () => openSession(progress.nextUnlockedSession()),
            onOpenBook: openBook,
            onOpenMenu: () => setState(() => drawerOpen = true),
          ),
          CoursePage(progress: progress, onOpen: openSession),
          ReviewPage(progress: progress, onOpen: openSession),
          ProgressPage(progress: progress),
        ],
      );
      final loadedContent = progress.isLoaded
          ? content
          : const Center(child: Text('Cargando...'));

      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Positioned.fill(child: _SakuraBackdrop(child: loadedContent)),
            if (!drawerOpen)
              Positioned(
                right: 20,
                bottom: 24,
                child: _SenseiBubble(
                  level: progress.studyLevel,
                  contextDescription: _currentSenseiContext(),
                ),
              ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: drawerOpen ? .56 : 0,
              child: IgnorePointer(
                ignoring: !drawerOpen,
                child: GestureDetector(
                  onTap: closeDrawer,
                  child: Container(color: Colors.black),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              left: drawerOpen ? 0 : -332,
              top: 0,
              bottom: 0,
              child: _SideMenu(
                selected: tab,
                level: progress.studyLevel,
                book: progress.book,
                progress: progress,
                onClose: closeDrawer,
                onTabChanged: (v) {
                  setState(() {
                    tab = v;
                    drawerOpen = false;
                  });
                },
                onLevelChanged: selectLevel,
                onBookChanged: (v) {
                  selectBook(v);
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _MenuOpenButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MenuOpenButton({required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Abrir camino',
    child: Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface.withOpacity(.92),
            border: Border.all(color: AppColors.violet.withOpacity(.35)),
            boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(.18), blurRadius: 18, offset: const Offset(0, 7))],
          ),
          child: const Icon(Icons.menu_rounded, color: AppColors.ink, size: 22),
        ),
      ),
    ),
  );
}

class _SenseiBubble extends StatelessWidget {
  final String level;
  final String contextDescription;

  const _SenseiBubble({required this.level, this.contextDescription = ''});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Preguntar al Sensei',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SenseiChatSheet(
            level: level,
            contextDescription: contextDescription,
          ),
        ),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.coral, AppColors.violet],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: Colors.white.withOpacity(.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.coral.withOpacity(.30),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: const Center(child: SenseiCatMark(size: 31)),
        ),
      ),
    ),
  );
}

class _SakuraBackdrop extends StatelessWidget {
  final Widget child;
  const _SakuraBackdrop({required this.child});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: child),
      const Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(painter: _SakuraAtmospherePainter()),
        ),
      ),
    ],
  );
}

class _SakuraAtmospherePainter extends CustomPainter {
  const _SakuraAtmospherePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = AppColors.sakura.withOpacity(.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    final bubble = Paint()
      ..color = AppColors.sakura.withOpacity(.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final bubbles = <({Offset center, double radius})>[
      (center: Offset(size.width * .92, size.height * .16), radius: 92),
      (center: Offset(size.width * .08, size.height * .72), radius: 68),
      (center: Offset(size.width * .72, size.height * .86), radius: 52),
    ];

    for (final item in bubbles) {
      canvas.drawCircle(item.center, item.radius, glow);
      canvas.drawCircle(item.center, item.radius, bubble);
      canvas.drawArc(Rect.fromCircle(center: item.center, radius: item.radius - 8), -.7, 1.4, false, bubble);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SideMenu extends StatelessWidget {
  final int selected;
  final String level;
  final StudyBook book;
  final ProgressService progress;
  final VoidCallback onClose;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<String> onBookChanged;

  const _SideMenu({
    required this.selected,
    required this.level,
    required this.book,
    required this.progress,
    required this.onClose,
    required this.onTabChanged,
    required this.onLevelChanged,
    required this.onBookChanged,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    elevation: 24,
    child: SizedBox(
      width: 316,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _SidebarMark(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kana / Path', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        SizedBox(height: 2),
                        Text('JLPT · Tu viaje hacia el japones', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Cerrar camino',
                    child: IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        backgroundColor: AppColors.surface2,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      const SizedBox(height: 10),
                      const Text('TU CAMINO', style: TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w900, letterSpacing: 1.8)),
                      const SizedBox(height: 8),
                      _LevelSwitcher(level: level, onChanged: onLevelChanged),
                      const SizedBox(height: 16),
                      const Text('LIBRO', style: TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w900, letterSpacing: 1.8)),
                      const SizedBox(height: 8),
                      _BookSwitcher(book: book, onChanged: onBookChanged),
                      const SizedBox(height: 22),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 12),
                      _SideNavItem(index: 0, selected: selected == 0, icon: Icons.sunny_snowing, label: 'Hoy', description: 'Resumen de hoy', onTap: onTabChanged),
                      _SideNavItem(index: 1, selected: selected == 1, icon: Icons.route_rounded, label: 'Camino', description: 'Dia actual disponible', onTap: onTabChanged),
                      _SideNavItem(index: 2, selected: selected == 2, icon: Icons.replay_rounded, label: 'Repaso', description: 'Errores pendientes', onTap: onTabChanged),
                      _SideNavItem(index: 3, selected: selected == 3, icon: Icons.auto_graph_rounded, label: 'Progreso', description: 'Actividad reciente', onTap: onTabChanged),
                      const SizedBox(height: 16),
                      _SidebarProgressModule(progress: progress, book: book),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SidebarMark extends StatelessWidget {
  const _SidebarMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [AppColors.coral, AppColors.violet],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.coral.withOpacity(.24),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
          ),
        ),
        const Text(
          '学',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _SideNavItem extends StatelessWidget {
  final int index;
  final bool selected;
  final IconData icon;
  final String label, description;
  final ValueChanged<int> onTap;

  const _SideNavItem({
    required this.index,
    required this.selected,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.violetSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.violet : AppColors.surface2,
                boxShadow: selected
                    ? [BoxShadow(color: AppColors.violet.withOpacity(.28), blurRadius: 15)]
                    : null,
              ),
              child: Icon(icon, size: 18, color: selected ? Colors.white : AppColors.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: selected ? AppColors.ink : AppColors.muted, fontWeight: selected ? FontWeight.w900 : FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? AppColors.muted : AppColors.muted.withOpacity(.72), fontSize: 9, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: selected ? const Icon(Icons.arrow_forward_ios_rounded, key: ValueKey('active'), size: 12, color: AppColors.violet) : const SizedBox(key: ValueKey('idle'), width: 12)),
          ],
        ),
      ),
    ),
  );
}

class _LevelSwitcher extends StatelessWidget {
  final String level;
  final ValueChanged<String> onChanged;
  const _LevelSwitcher({required this.level, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _LevelProgressChoice(level: 'N4', selected: level == 'N4', snapshot: ProgressService.instance.progressForBook(BookCatalog.defaultForLevel('N4')), onTap: () => onChanged('N4'))),
      const SizedBox(width: 8),
      Expanded(child: _LevelProgressChoice(level: 'N3', selected: level == 'N3', snapshot: ProgressService.instance.progressForBook(BookCatalog.defaultForLevel('N3')), onTap: () => onChanged('N3'))),
    ],
  );
}

class _LevelProgressChoice extends StatelessWidget {
  final bool selected;
  final LevelProgressSnapshot snapshot;
  final VoidCallback onTap;
  const _LevelProgressChoice({required this.level, required this.selected, required this.snapshot, required this.onTap});
  final String level;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: selected ? null : onTap,
    borderRadius: BorderRadius.circular(17),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.violetSoft : AppColors.background,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: selected ? AppColors.violet.withOpacity(.55) : AppColors.border),
      ),
      child: Column(children: [
        SizedBox(width: 38, height: 38, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: snapshot.progress.clamp(0.0, 1.0).toDouble(), strokeWidth: 3, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation<Color>(selected ? AppColors.violet : AppColors.muted)), Text(level, style: TextStyle(color: selected ? AppColors.ink : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w900))])),
        const SizedBox(height: 6),
        Text('${(snapshot.progress * 100).round()}%', style: TextStyle(color: selected ? AppColors.ink : AppColors.muted, fontSize: 9, fontWeight: FontWeight.w900)),
      ]),
    ),
  );
}

class _SidebarProgressModule extends StatelessWidget {
  final ProgressService progress;
  final StudyBook book;

  const _SidebarProgressModule({required this.progress, required this.book});

  @override
  Widget build(BuildContext context) {
    final snapshot = progress.progressForBook(book);
    final achievement = progress.completedCount == 0
        ? 'Primer paso'
        : 'Día ${progress.completedCount} conquistado';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navySoft, AppColors.surface2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.violet.withOpacity(.26)),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withOpacity(.10),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_graph_rounded, color: AppColors.yellow, size: 18),
            const SizedBox(width: 7),
            const Expanded(child: Text('TU IMPULSO', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.4))),
            Text('${(snapshot.progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: snapshot.progress.clamp(0.0, 1.0).toDouble(), minHeight: 6, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow))),
          const SizedBox(height: 12),
          Text(book.shortTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          Row(children: [const Icon(Icons.local_fire_department_rounded, color: AppColors.coral, size: 15), const SizedBox(width: 4), Text('${progress.stats.streak} dias', style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800)), const SizedBox(width: 10), const Icon(Icons.bolt_rounded, color: AppColors.yellow, size: 15), const SizedBox(width: 4), Text('${progress.stats.xp} XP', style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 10),
          Row(children: [const Icon(Icons.emoji_events_rounded, color: AppColors.yellow, size: 15), const SizedBox(width: 5), Expanded(child: Text(achievement, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))]),
        ],
      ),
    );
  }
}

class _BookSwitcher extends StatelessWidget {
  final StudyBook book;
  final ValueChanged<String> onChanged;
  const _BookSwitcher({required this.book, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final books = BookCatalog.forLevel(book.level);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: book.id,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 19, color: AppColors.muted),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          items: [
            for (final item in books)
              DropdownMenuItem<String>(
                value: item.id,
                child: Text(
                  item.shortTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _SmartStudyCard extends StatelessWidget {
  final ProgressService progress;
  final VoidCallback onStart;

  const _SmartStudyCard({
    required this.progress,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final plan = progress.smartPlan;
    final intelligence = progress.learningSnapshot;
    final hasData = intelligence.hasIntelligenceData;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.violetSoft, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.violet.withOpacity(.28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withOpacity(.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.violet.withOpacity(.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.violet,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ESTUDIO INTELIGENTE',
                  style: TextStyle(
                    color: AppColors.violet,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              Text(
                '≈ ${plan.estimatedMinutes} min',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            plan.title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            plan.reason,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _SmartMetric(
                label: 'Conceptos',
                value: intelligence.trackedConcepts.toString(),
              ),
              const SizedBox(width: 8),
              _SmartMetric(
                label: 'Pendientes',
                value: intelligence.dueConcepts.toString(),
              ),
              const SizedBox(width: 8),
              _SmartMetric(
                label: 'En riesgo',
                value: intelligence.atRiskConcepts.toString(),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: plan.hasPlan ? onStart : null,
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: Text(plan.actionLabel),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.violet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          if (!hasData) ...[
            const SizedBox(height: 8),
            const Text(
              'La app empezará a personalizar esta tarjeta a medida que respondas preguntas.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmartMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SmartMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

void onStartSmart(BuildContext context, SessionInfo session) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => LessonFlowPage(
        session: session,
        progress: ProgressService.instance,
      ),
    ),
  );
}

class StudioHomePage extends StatelessWidget {
  final ProgressService progress;
  final VoidCallback onStart;
  final VoidCallback onOpenMenu;
  final ValueChanged<String> onOpenBook;

  const StudioHomePage({
    super.key,
    required this.progress,
    required this.onStart,
    required this.onOpenMenu,
    required this.onOpenBook,
  });

  @override
  Widget build(BuildContext context) {
    final stats = progress.stats;
    final next = progress.nextUnlockedSession();
    final currentWeek = next.week;
    final sessions = StudyCatalog.sessions
      .where((session) => session.week == currentWeek)
      .toList();

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final horizontal = wide ? 42.0 : 20.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 44),
            children: [
              _StudioHeader(
                progress: progress,
                stats: stats,
                onOpenMenu: onOpenMenu,
              ),
              const SizedBox(height: 22),
              _TodayHero(
                progress: progress,
                session: next,
                onStart: onStart,
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: _SectionHeading(
                      eyebrow: 'TU RUTA',
                      title: 'Sigue el hilo',
                      subtitle: 'Pequeños pasos. Un gran salto al N3.',
                    ),
                  ),
                  Text(
                    '${progress.completedCount}/${StudyCatalog.totalSessions}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _LearningPath(
                week: currentWeek,
                sessions: sessions,
                progress: progress,
                onOpen: (session) => onStartSession(context, session, progress),
              ),
              const SizedBox(height: 28),
              const _SectionHeading(
                eyebrow: 'DESPUES DE ESTUDIAR',
                title: 'Desafios opcionales',
                subtitle: 'Pequenos retos para profundizar y coleccionar dominio.',
              ),
              const SizedBox(height: 14),
              if (wide)
                Row(
                  children: [
                    Expanded(child: _MissionCard(icon: Icons.translate_rounded, color: AppColors.violet, title: 'Dominio Kanji', detail: 'Escribe 10 kanjis correctamente', reward: '+40 XP')),
                    SizedBox(width: 10),
                    Expanded(child: _MissionCard(icon: Icons.auto_awesome_rounded, color: AppColors.coral, title: 'Desafio rapido', detail: 'Completa una actividad extra', reward: '+25 XP')),
                    SizedBox(width: 10),
                    Expanded(child: _MissionCard(icon: Icons.local_fire_department_rounded, color: AppColors.yellow, title: 'Protege tu racha', detail: 'Estudia durante 5 minutos', reward: 'Cofre')),
                  ],
                )
              else
                Column(
                  children: [
                    _MissionCard(icon: Icons.translate_rounded, color: AppColors.violet, title: 'Dominio Kanji', detail: 'Escribe 10 kanjis correctamente', reward: '+40 XP'),
                    SizedBox(height: 10),
                    _MissionCard(icon: Icons.auto_awesome_rounded, color: AppColors.coral, title: 'Desafio rapido', detail: 'Completa una actividad extra', reward: '+25 XP'),
                    SizedBox(height: 10),
                    _MissionCard(icon: Icons.local_fire_department_rounded, color: AppColors.yellow, title: 'Protege tu racha', detail: 'Estudia durante 5 minutos', reward: 'Cofre'),
                  ],
                ),
              const SizedBox(height: 28),
              _ProgressPulse(progress: progress),
              const SizedBox(height: 14),
              _CollectionStrip(progress: progress),
              const SizedBox(height: 14),
              _WeeklyMomentum(progress: progress),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => onOpenBook(progress.book.id),
                icon: const Icon(Icons.auto_stories_rounded, size: 18),
                label: Text('Explorar ${progress.book.shortTitle}'),
              ),
            ],
          );
        },
      ),
    );
  }
}

void onStartSession(BuildContext context, SessionInfo session, ProgressService progress) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => LessonFlowPage(session: session, progress: progress),
    ),
  );
}

class _StudioHeader extends StatelessWidget {
  final ProgressService progress;
  final StudyStats stats;
  final VoidCallback onOpenMenu;

  const _StudioHeader({required this.progress, required this.stats, required this.onOpenMenu});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _MenuOpenButton(onTap: onOpenMenu),
      const SizedBox(width: 12),
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.coral, AppColors.sakura]),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [BoxShadow(color: AppColors.coral.withOpacity(.28), blurRadius: 18, offset: const Offset(0, 7))],
        ),
        child: const Center(child: Text('あ', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BUENOS DÍAS, ESTUDIANTE', style: TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.35)),
            const SizedBox(height: 4),
            Text(progress.book.shortTitle, style: const TextStyle(color: AppColors.ink, fontSize: 19, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.coralSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.coral.withOpacity(.24))),
        child: Row(children: [const Icon(Icons.local_fire_department_rounded, color: AppColors.coral, size: 18), const SizedBox(width: 5), Text('${stats.streak}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))]),
      ),
    ],
  );
}

class _TodayHero extends StatelessWidget {
  final ProgressService progress;
  final SessionInfo session;
  final VoidCallback onStart;

  const _TodayHero({required this.progress, required this.session, required this.onStart});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.violet, Color(0xFF5142A7), AppColors.navySoft], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withOpacity(.12)),
      boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(.22), blurRadius: 30, offset: const Offset(0, 14))],
    ),
    child: Stack(
      children: [
        Positioned(right: -28, top: -35, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.07)))),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.wb_sunny_rounded, color: AppColors.yellow, size: 18), const SizedBox(width: 7), const Text('TU PRÓXIMO PASO', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)), const Spacer(), Text('NIVEL ${progress.studyLevel}', style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900))]),
            const SizedBox(height: 18),
            Text('Día ${session.day}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 6),
            Text(session.focus, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(session.titleEs, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, height: 1.35)),
            const SizedBox(height: 18),
            Row(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress.sessionProgress.clamp(0.0, 1.0).toDouble(), minHeight: 7, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow)))), const SizedBox(width: 10), Text('${(progress.sessionProgress * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900))]),
            const SizedBox(height: 18),
            Row(children: [const Icon(Icons.schedule_rounded, color: Colors.white70, size: 16), const SizedBox(width: 5), Text('${session.durationMinutes} min', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800)), const SizedBox(width: 14), const Icon(Icons.bolt_rounded, color: AppColors.yellow, size: 17), const SizedBox(width: 4), Text('+${session.xpReward} XP', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800))]),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.play_arrow_rounded, size: 19), label: Text('Comenzar Día ${session.day}'), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.violet, padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13), minimumSize: Size.zero)),
          ],
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow, title, subtitle;
  const _SectionHeading({required this.eyebrow, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(eyebrow, style: const TextStyle(color: AppColors.coral, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.6)), const SizedBox(height: 5), Text(title, style: const TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w700))]);
}

class _LearningPath extends StatelessWidget {
  final int week;
  final List<SessionInfo> sessions;
  final ProgressService progress;
  final ValueChanged<SessionInfo> onOpen;
  const _LearningPath({required this.week, required this.sessions, required this.progress, required this.onOpen});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(17, 18, 17, 9),
    decoration: BoxDecoration(color: AppColors.surface.withOpacity(.82), borderRadius: BorderRadius.circular(25), border: Border.all(color: AppColors.border)),
    child: Column(
      children: [
        Row(children: [
          _RegionBadge(week: week),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('SEMANA $week', style: const TextStyle(color: AppColors.coral, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)), const SizedBox(height: 3), Text(_weekTitle(week), style: const TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w900))])),
          const Icon(Icons.explore_rounded, color: AppColors.muted, size: 19),
        ]),
        const SizedBox(height: 13),
        for (var i = 0; i < sessions.length; i++) _PathStep(session: sessions[i], progress: progress, isLast: i == sessions.length - 1, onOpen: onOpen),
        _RegionFinish(week: week, complete: sessions.isNotEmpty && sessions.every((session) => progress.isCompleted(session.id))),
      ],
    ),
  );
}

String _weekTitle(int week) => switch (week) {
  1 => 'Primeras estructuras',
  2 => 'Hablar con precision',
  3 => 'Construir confianza',
  4 => 'Leer entre lineas',
  5 => 'Mirar mas lejos',
  _ => 'Consolidar el viaje',
};

class _RegionBadge extends StatelessWidget {
  final int week;
  const _RegionBadge({required this.week});
  @override
  Widget build(BuildContext context) => Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.coral, AppColors.violet], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: AppColors.violet.withOpacity(.22), blurRadius: 14)]), child: Center(child: Text('$week', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900))));
}

class _RegionFinish extends StatelessWidget {
  final int week;
  final bool complete;
  const _RegionFinish({required this.week, required this.complete});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 7, left: 42), child: Row(children: [Icon(complete ? Icons.emoji_events_rounded : Icons.flag_rounded, color: complete ? AppColors.yellow : AppColors.border, size: 19), const SizedBox(width: 10), Text(complete ? 'Semana $week conquistada' : 'Cierre de la semana', style: TextStyle(color: complete ? AppColors.yellow : AppColors.muted, fontSize: 10, fontWeight: FontWeight.w900))]));
}

class _PathStep extends StatelessWidget {
  final SessionInfo session;
  final ProgressService progress;
  final bool isLast;
  final ValueChanged<SessionInfo> onOpen;
  const _PathStep({required this.session, required this.progress, required this.isLast, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final done = progress.isCompleted(session.id);
    final unlocked = progress.isUnlocked(session.id);
    final accent = done ? AppColors.mint : unlocked ? AppColors.violet : AppColors.border;
    return InkWell(
      onTap: unlocked ? () => onOpen(session) : null,
      borderRadius: BorderRadius.circular(17),
      child: SizedBox(
        height: 69,
        child: Row(children: [
          SizedBox(width: 42, child: Stack(alignment: Alignment.center, children: [if (!isLast) Positioned(top: 38, bottom: 0, child: Container(width: 2, color: AppColors.border)), Container(width: 34, height: 34, decoration: BoxDecoration(shape: BoxShape.circle, color: done ? AppColors.mint : unlocked ? AppColors.violetSoft : AppColors.surface2, border: Border.all(color: accent.withOpacity(.7))), child: Icon(done ? Icons.check_rounded : unlocked ? Icons.play_arrow_rounded : Icons.lock_rounded, size: 16, color: done || unlocked ? Colors.white : AppColors.muted))])),
          const SizedBox(width: 11),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('DÍA ${session.day} · ${session.focus}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: unlocked ? AppColors.ink : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(session.titleEs, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w600))])),
          Icon(done ? Icons.verified_rounded : unlocked ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded, color: accent, size: 18),
        ]),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, detail, reward;
  const _MissionCard({required this.icon, required this.color, required this.title, required this.detail, required this.reward});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(21), border: Border.all(color: AppColors.border)), child: Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 19)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(detail, style: const TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.w700))])), Text(reward, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900))]));
}

class _CollectionStrip extends StatelessWidget {
  final ProgressService progress;
  const _CollectionStrip({required this.progress});
  @override
  Widget build(BuildContext context) {
    final snapshot = progress.learningSnapshot;
    return Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('COLECCION DESCUBIERTA', style: TextStyle(color: AppColors.mint, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)), const SizedBox(height: 5), const Text('Construye tu japonés pieza a pieza', style: TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w900)), const SizedBox(height: 14), Row(children: [_CollectionStat(icon: Icons.translate_rounded, value: snapshot.trackedConcepts.toString(), label: 'conceptos'), const SizedBox(width: 8), _CollectionStat(icon: Icons.auto_awesome_rounded, value: progress.completedCount.toString(), label: 'sesiones'), const SizedBox(width: 8), _CollectionStat(icon: Icons.menu_book_rounded, value: '${(progress.sessionProgress * 100).round()}%', label: 'libro')]) ]));
  }
}

class _CollectionStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _CollectionStat({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [Icon(icon, color: AppColors.mint, size: 18), const SizedBox(height: 4), Text(value, style: const TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 8, fontWeight: FontWeight.w800))]));
}

class _WeeklyMomentum extends StatelessWidget {
  final ProgressService progress;
  const _WeeklyMomentum({required this.progress});
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: _MomentumItem(icon: Icons.local_fire_department_rounded, color: AppColors.coral, value: '${progress.stats.streak}', label: 'dias de racha')), const SizedBox(width: 9), Expanded(child: _MomentumItem(icon: Icons.bolt_rounded, color: AppColors.yellow, value: '${progress.stats.xp}', label: 'XP acumulados')), const SizedBox(width: 9), Expanded(child: _MomentumItem(icon: Icons.percent_rounded, color: AppColors.violet, value: '${progress.stats.accuracy.round()}%', label: 'precision'))]);
}

class _MomentumItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value, label;
  const _MomentumItem({required this.icon, required this.color, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6), decoration: BoxDecoration(color: AppColors.surface2.withOpacity(.8), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)), child: Column(children: [Icon(icon, color: color, size: 18), const SizedBox(height: 4), Text(value, style: const TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w900)), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 8, fontWeight: FontWeight.w800))]));
}

class _ProgressPulse extends StatelessWidget {
  final ProgressService progress;
  const _ProgressPulse({required this.progress});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)), child: Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.bolt_rounded, color: AppColors.yellow)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('IMPULSO DE HOY', style: TextStyle(color: AppColors.yellow, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.4)), const SizedBox(height: 5), Text('${progress.stats.xp} XP acumulados · nivel ${progress.stats.level}', style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w800))])), const Icon(Icons.chevron_right_rounded, color: AppColors.muted)]));
}

class HomePage extends StatelessWidget {
  final ProgressService progress;
  final VoidCallback onStart;
  final ValueChanged<String> onBookSelected;
  final ValueChanged<String> onOpenBook;

  const HomePage({
    super.key,
    required this.progress,
    required this.onStart,
    required this.onBookSelected,
    required this.onOpenBook,
  });

  Color _accent(StudyBook book) {
    switch (book.id) {
      case 'shinkanzen_n4_dokkai':
        return AppColors.mint;
      case 'shinkanzen_n3_grammar':
        return AppColors.coral;
      default:
        return AppColors.violet;
    }
  }

  Widget _bookCard(StudyBook book) {
    final snapshot = progress.progressForBook(book);
    final selected = progress.book.id == book.id;
    final percent = (snapshot.progress * 100).round();
    final accent = _accent(book);

    return InkWell(
      onTap: () => onBookSelected(book.id),
      borderRadius: BorderRadius.circular(25),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: selected
                ? [AppColors.navySoft, AppColors.surface]
                : [AppColors.surface2, AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? accent.withOpacity(.68) : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withOpacity(.62)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      book.level,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? accent : AppColors.border,
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${percent}%',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: snapshot.progress.clamp(0.0, 1.0).toDouble(),
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.mint, size: 15),
                const SizedBox(width: 6),
                Text(
                  '${snapshot.completed}/${snapshot.total} sesiones',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.bolt_rounded, color: AppColors.yellow, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${snapshot.xp} XP',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onOpenBook(book.id),
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text('Abrir libro'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withOpacity(.38)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = progress.book;
    final selectedSnapshot = progress.progressForBook(selected);
    final stats = progress.stats;
    final percent = (selectedSnapshot.progress * 100).round();
    final books = BookCatalog.books;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final compact = constraints.maxWidth < 650;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 42,
              78,
              compact ? 20 : 42,
              50,
            ),
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _ContinueCard(
                        progress: progress,
                        percent: percent,
                        onStart: onStart,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(flex: 4, child: _NextSessionCard()),
                  ],
                )
              else
                _ContinueCard(
                  progress: progress,
                  percent: percent,
                  onStart: onStart,
                ),
              const SizedBox(height: 14),
              _SmartStudyCard(
                progress: progress,
                onStart: () {
                  final sessions = progress.smartPlan.sessions;
                  if (sessions.isNotEmpty) onStartSmart(context, sessions.first);
                },
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tus libros',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Text(
                    'ELIGE PARA ESTUDIAR',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _bookCard(books[0])),
                    const SizedBox(width: 14),
                    Expanded(child: _bookCard(books[1])),
                  ],
                )
              else
                Column(
                  children: [
                    _bookCard(books[0]),
                    const SizedBox(height: 12),
                    _bookCard(books[1]),
                  ],
                ),
              const SizedBox(height: 12),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _bookCard(books[2])),
                    const Expanded(child: SizedBox()),
                  ],
                )
              else
                _bookCard(books[2]),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Libro seleccionado',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    selected.level,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.title,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selected.description,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${percent}%',
                      style: const TextStyle(
                        color: AppColors.violet,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mis metas',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Text(
                    'PROGRESO',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              if (wide)
                Row(
                  children: [
                    Expanded(child: _goalCard('Estudiar hoy', selectedSnapshot.answers > 0 ? '✓ sesión' : '0/1 sesión', Icons.menu_book_rounded, AppColors.violet)),
                    const SizedBox(width: 10),
                    Expanded(child: _goalCard('Mantener la racha', '${stats.streak}/7 días', Icons.local_fire_department_rounded, AppColors.coral)),
                    const SizedBox(width: 10),
                    Expanded(child: _goalCard('Precisión', '${selectedSnapshot.accuracy.round()}%', Icons.gps_fixed_rounded, AppColors.mint)),
                    const SizedBox(width: 10),
                    Expanded(child: _goalCard('Ganar XP', '${selectedSnapshot.xp}/100 XP', Icons.bolt_rounded, AppColors.yellow)),
                  ],
                )
              else
                Column(
                  children: [
                    _goalCard('Estudiar hoy', selectedSnapshot.answers > 0 ? '✓ sesión' : '0/1 sesión', Icons.menu_book_rounded, AppColors.violet),
                    const SizedBox(height: 9),
                    _goalCard('Mantener la racha', '${stats.streak}/7 días', Icons.local_fire_department_rounded, AppColors.coral),
                    const SizedBox(height: 9),
                    _goalCard('Precisión', '${selectedSnapshot.accuracy.round()}%', Icons.gps_fixed_rounded, AppColors.mint),
                    const SizedBox(height: 9),
                    _goalCard('Ganar XP', '${selectedSnapshot.xp}/100 XP', Icons.bolt_rounded, AppColors.yellow),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class BookDashboardPage extends StatelessWidget {
  final ProgressService progress;

  const BookDashboardPage({super.key, required this.progress});

  Color _accent(StudyBook book) {
    switch (book.id) {
      case 'shinkanzen_n4_dokkai':
        return AppColors.mint;
      case 'shinkanzen_n3_grammar':
        return AppColors.coral;
      default:
        return AppColors.violet;
    }
  }

  String _typeLabel(StudyBook book) {
    switch (book.id) {
      case 'shinkanzen_n4_dokkai':
        return 'N4 · COMPRENSIÓN LECTORA';
      case 'shinkanzen_n3_grammar':
        return 'N3 · GRAMÁTICA';
      default:
        return 'N4 · CURSO COMPLETO';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final book = progress.book;
        final snapshot = progress.progressForBook(book);
        final accent = _accent(book);
        final percent = (snapshot.progress * 100).round();
        final sessions = StudyCatalog.sessions;
        final next = sessions.isEmpty
            ? null
            : sessions.firstWhere(
                (session) => !progress.isCompleted(session.id),
                orElse: () => sessions.last,
              );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              book.shortTitle,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                return ListView(
                  padding: EdgeInsets.fromLTRB(wide ? 42 : 20, 24, wide ? 42 : 20, 44),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent.withOpacity(.18), AppColors.surface],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: accent.withOpacity(.34)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _typeLabel(book),
                            style: TextStyle(
                              color: accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.title,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            book.subtitle,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: snapshot.progress.clamp(0.0, 1.0).toDouble(),
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${percent}% · ${snapshot.completed}/${snapshot.total} sesiones',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (wide)
                      Row(
                        children: [
                          Expanded(child: _DashboardStatCard(icon: Icons.check_circle_rounded, value: '${snapshot.completed}', label: 'Completadas', color: accent)),
                          const SizedBox(width: 10),
                          Expanded(child: _DashboardStatCard(icon: Icons.percent_rounded, value: '${snapshot.accuracy.round()}%', label: 'Precisión', color: AppColors.mint)),
                          const SizedBox(width: 10),
                          Expanded(child: _DashboardStatCard(icon: Icons.bolt_rounded, value: '${snapshot.xp}', label: 'XP', color: AppColors.yellow)),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _DashboardStatCard(icon: Icons.check_circle_rounded, value: '${snapshot.completed}', label: 'Completadas', color: accent),
                          const SizedBox(height: 9),
                          _DashboardStatCard(icon: Icons.percent_rounded, value: '${snapshot.accuracy.round()}%', label: 'Precisión', color: AppColors.mint),
                          const SizedBox(height: 9),
                          _DashboardStatCard(icon: Icons.bolt_rounded, value: '${snapshot.xp}', label: 'XP', color: AppColors.yellow),
                        ],
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: next == null
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LessonFlowPage(
                                      session: next,
                                      progress: progress,
                                    ),
                                  ),
                                ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(snapshot.completed == 0 ? 'Comenzar libro' : 'Continuar aprendiendo'),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Contenido',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Avanza en orden. Las sesiones siguientes se desbloquean al completar la anterior.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: _BookPath(
                          sessions: sessions,
                          progress: progress,
                          accent: accent,
                          onOpen: (session) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LessonFlowPage(
                                session: session,
                                progress: progress,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _DashboardStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(.13),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    ),
  );
}

class _BookPath extends StatelessWidget {
  final List<SessionInfo> sessions;
  final ProgressService progress;
  final Color accent;
  final ValueChanged<SessionInfo> onOpen;

  const _BookPath({
    required this.sessions,
    required this.progress,
    required this.accent,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final weeks = sessions.map((session) => session.week).toSet().toList()..sort();

    return Column(
      children: [
        for (var weekIndex = 0; weekIndex < weeks.length; weekIndex++)
          _BookPathWeek(
            week: weeks[weekIndex],
            sessions: sessions.where((session) => session.week == weeks[weekIndex]).toList(),
            progress: progress,
            accent: accent,
            onOpen: onOpen,
            isLast: weekIndex == weeks.length - 1,
          ),
      ],
    );
  }
}

class _BookPathWeek extends StatelessWidget {
  final int week;
  final List<SessionInfo> sessions;
  final ProgressService progress;
  final Color accent;
  final ValueChanged<SessionInfo> onOpen;
  final bool isLast;

  const _BookPathWeek({
    required this.week,
    required this.sessions,
    required this.progress,
    required this.accent,
    required this.onOpen,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final completed = sessions.where((session) => progress.isCompleted(session.id)).length;
    final weekUnlocked = sessions.any((session) => progress.isUnlocked(session.id));

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: weekUnlocked ? accent.withOpacity(.16) : AppColors.surface2,
                border: Border.all(color: weekUnlocked ? accent.withOpacity(.55) : AppColors.border, width: 1.5),
              ),
              child: Center(child: Text('$week', style: TextStyle(color: weekUnlocked ? accent : AppColors.muted, fontSize: 15, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SEMANA $week', style: TextStyle(color: weekUnlocked ? accent : AppColors.muted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 3),
                  Text('${completed}/${sessions.length} sesiones desbloqueadas', style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Icon(weekUnlocked ? Icons.explore_rounded : Icons.lock_outline_rounded, color: weekUnlocked ? accent : AppColors.muted, size: 19),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Column(
            children: [
              for (var index = 0; index < sessions.length; index++)
                _BookPathNode(
                  session: sessions[index],
                  progress: progress,
                  accent: accent,
                  onOpen: onOpen,
                  isLast: index == sessions.length - 1,
                ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 1, bottom: 16),
            child: Align(alignment: Alignment.centerLeft, child: Container(width: 2, height: 18, color: AppColors.border)),
          ),
      ],
    );
  }
}

class _BookPathNode extends StatelessWidget {
  final SessionInfo session;
  final ProgressService progress;
  final Color accent;
  final ValueChanged<SessionInfo> onOpen;
  final bool isLast;

  const _BookPathNode({
    required this.session,
    required this.progress,
    required this.accent,
    required this.onOpen,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final completed = progress.isCompleted(session.id);
    final unlocked = progress.isUnlocked(session.id);
    final locked = !completed && !unlocked;
    final nodeColor = completed ? AppColors.mint : unlocked ? accent : AppColors.border;

    return InkWell(
      onTap: unlocked ? () => onOpen(session) : null,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 76,
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!isLast) Positioned(top: 39, bottom: 0, child: Container(width: 2, color: nodeColor.withOpacity(.32))),
                  Container(
                    width: unlocked || completed ? 36 : 32,
                    height: unlocked || completed ? 36 : 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed ? AppColors.mint : unlocked ? accent.withOpacity(.18) : AppColors.surface2,
                      border: Border.all(color: nodeColor.withOpacity(.75), width: 1.5),
                      boxShadow: unlocked ? [BoxShadow(color: accent.withOpacity(.22), blurRadius: 14)] : null,
                    ),
                    child: Icon(
                      completed ? Icons.check_rounded : session.review ? Icons.star_rounded : unlocked ? Icons.play_arrow_rounded : Icons.lock_rounded,
                      color: completed || unlocked ? (completed ? Colors.white : accent) : AppColors.muted,
                      size: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                decoration: BoxDecoration(
                  color: completed ? AppColors.mintSoft.withOpacity(.30) : unlocked ? accent.withOpacity(.10) : AppColors.surface2.withOpacity(.48),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: completed ? AppColors.mint.withOpacity(.28) : unlocked ? accent.withOpacity(.28) : AppColors.border.withOpacity(.55)),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(session.review ? 'REPASO · Día ${session.day}' : 'Día ${session.day}', style: TextStyle(color: locked ? AppColors.muted : AppColors.ink, fontSize: 12, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(session.titleEs, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: locked ? AppColors.muted.withOpacity(.75) : AppColors.muted, fontSize: 10, fontWeight: FontWeight.w700))])),
                  Icon(completed ? Icons.verified_rounded : unlocked ? Icons.arrow_forward_rounded : Icons.lock_outline_rounded, color: completed ? AppColors.mint : unlocked ? accent : AppColors.muted, size: 17),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookSessionCard extends StatelessWidget {
  final SessionInfo session;
  final ProgressService progress;
  final Color accent;
  final int index;
  final VoidCallback onOpen;

  const _BookSessionCard({
    required this.session,
    required this.progress,
    required this.accent,
    required this.index,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final completed = progress.isCompleted(session.id);
    final unlocked = progress.isUnlocked(session.id);
    final locked = !completed && !unlocked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: unlocked ? onOpen : null,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: completed
                  ? AppColors.mintSoft.withOpacity(.35)
                  : unlocked
                      ? accent.withOpacity(.10)
                      : AppColors.surface2.withOpacity(.55),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: completed
                    ? AppColors.mint.withOpacity(.28)
                    : unlocked
                        ? accent.withOpacity(.28)
                        : AppColors.border.withOpacity(.55),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed
                        ? AppColors.mint
                        : unlocked
                            ? accent
                            : AppColors.surface,
                    border: Border.all(
                      color: locked ? AppColors.border : accent.withOpacity(.45),
                    ),
                  ),
                  child: Icon(
                    completed
                        ? Icons.check_rounded
                        : unlocked
                            ? Icons.play_arrow_rounded
                            : Icons.lock_rounded,
                    color: completed || unlocked ? Colors.white : AppColors.muted,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sesión ${index + 1} · ${session.titleJa}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: locked ? AppColors.muted : AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        session.titleEs,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: locked
                              ? AppColors.muted.withOpacity(.72)
                              : AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  completed
                      ? Icons.verified_rounded
                      : unlocked
                          ? Icons.arrow_forward_rounded
                          : Icons.lock_outline_rounded,
                  color: completed
                      ? AppColors.mint
                      : unlocked
                          ? accent
                          : AppColors.muted.withOpacity(.6),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: AppColors.surface.withOpacity(.82), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      const Text('🔥', style: TextStyle(fontSize: 18)),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$streak', style: const TextStyle(color: AppColors.ink, fontSize: 16, fontWeight: FontWeight.w900)),
        const Text('días de racha', style: TextStyle(color: AppColors.muted, fontSize: 8, fontWeight: FontWeight.w700)),
      ]),
    ]),
  );
}

class _ContinueCard extends StatelessWidget {
  final ProgressService progress;
  final int percent;
  final VoidCallback onStart;

  const _ContinueCard({required this.progress, required this.percent, required this.onStart});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.surface2, AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: AppColors.violet.withOpacity(.34)),
    ),
    child: Row(
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.violet, Color(0xFF6655D8)]), borderRadius: BorderRadius.circular(17)),
          child: Center(child: Text(progress.studyLevel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CONTINÚA ESTUDIANDO', style: TextStyle(color: AppColors.violet, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 5),
              Text(progress.book.shortTitle, style: const TextStyle(color: AppColors.ink, fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(progress.book.subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: progress.sessionProgress.clamp(0.0, 1.0).toDouble(),
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.coral),
                ),
              ),
              const SizedBox(height: 6),
              Text('${progress.completedCount}/${StudyCatalog.totalSessions} sesiones · ${percent}%', style: const TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded, size: 19),
          label: const Text('Continuar'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15), minimumSize: Size.zero),
        ),
      ],
    ),
  );
}

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(25), border: Border.all(color: AppColors.border)),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PRÓXIMA SESIÓN', style: TextStyle(color: AppColors.coral, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        SizedBox(height: 11),
        Text('Tu siguiente lección', style: TextStyle(color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w900)),
        SizedBox(height: 7),
        Text('Continúa tu ruta desde donde la dejaste.', style: TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w700, height: 1.35)),
        SizedBox(height: 18),
        Row(children: [
          Icon(Icons.auto_awesome_rounded, color: AppColors.violet, size: 18),
          SizedBox(width: 7),
          Text('Lista para empezar', style: TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.w800)),
        ]),
      ],
    ),
  );
}

class _HomeScenePainter extends CustomPainter {
  const _HomeScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final moon = Paint()..color = const Color(0xFFFFDCCF).withOpacity(.72);
    final glow = Paint()..color = const Color(0xFFF09BB6).withOpacity(.07);
    final hill = Paint()..color = const Color(0xFF111B33);
    final temple = Paint()..color = const Color(0xFF202A49);
    final sakura = Paint()..color = AppColors.sakura.withOpacity(.45);
    final torii = Paint()..color = AppColors.violet.withOpacity(.35)..strokeWidth = 5..style = PaintingStyle.stroke;

    final moonCenter = Offset(size.width * .80, size.height * .27);
    canvas.drawCircle(moonCenter, 36, moon);
    canvas.drawCircle(moonCenter, 75, glow);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * .72, size.height * .88), width: size.width * .72, height: size.height * .48), hill);

    final roof = Path()
      ..moveTo(size.width * .73, size.height * .58)
      ..lineTo(size.width * .83, size.height * .45)
      ..lineTo(size.width * .93, size.height * .58)
      ..close();
    canvas.drawPath(roof, temple);
    canvas.drawRect(Rect.fromLTWH(size.width * .77, size.height * .57, size.width * .12, size.height * .22), temple);

    canvas.drawLine(Offset(size.width * .62, size.height * .69), Offset(size.width * .91, size.height * .69), torii);
    canvas.drawLine(Offset(size.width * .64, size.height * .76), Offset(size.width * .89, size.height * .76), torii);
    canvas.drawLine(Offset(size.width * .67, size.height * .68), Offset(size.width * .67, size.height * .90), torii);
    canvas.drawLine(Offset(size.width * .87, size.height * .68), Offset(size.width * .87, size.height * .90), torii);

    final petals = <Offset>[
      Offset(size.width * .60, size.height * .22),
      Offset(size.width * .70, size.height * .15),
      Offset(size.width * .88, size.height * .16),
      Offset(size.width * .92, size.height * .34),
      Offset(size.width * .53, size.height * .40),
      Offset(size.width * .79, size.height * .50),
      Offset(size.width * .64, size.height * .55),
    ];
    for (final p in petals) {
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(-.35);
      for (var i = 0; i < 5; i++) {
        canvas.save();
        canvas.rotate(i * 1.2566);
        canvas.drawOval(const Rect.fromLTWH(-2.5, -10, 5, 12), sakura);
        canvas.restore();
      }
      canvas.restore();
    }

    final catBody = Paint()..color = const Color(0xFFF7EDE8);
    final ear1 = Path()
      ..moveTo(size.width * .57, size.height * .61)
      ..lineTo(size.width * .60, size.height * .49)
      ..lineTo(size.width * .65, size.height * .60)
      ..close();
    final ear2 = Path()
      ..moveTo(size.width * .66, size.height * .60)
      ..lineTo(size.width * .71, size.height * .49)
      ..lineTo(size.width * .74, size.height * .62)
      ..close();
    canvas.drawPath(ear1, catBody);
    canvas.drawPath(ear2, catBody);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * .65, size.height * .68), width: 105, height: 92), catBody);

    final scarf = Paint()..color = AppColors.coral;
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * .65, size.height * .75), width: 105, height: 20), scarf);

    final eye = Paint()..color = const Color(0xFF1D2030);
    canvas.drawCircle(Offset(size.width * .62, size.height * .67), 3, eye);
    canvas.drawCircle(Offset(size.width * .68, size.height * .67), 3, eye);
    canvas.drawCircle(Offset(size.width * .65, size.height * .70), 2.5, scarf);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class CoursePage extends StatelessWidget {
  final ProgressService progress;
  final void Function(SessionInfo) onOpen;

  const CoursePage({
    super.key,
    required this.progress,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 78, 20, 30),
      children: [
        Text(
          'Curso',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        const Text(
          'Cada sesión se desbloquea al superar la anterior con 80% o más.',
        ),
        const SizedBox(height: 18),
        _CourseSummary(progress: progress),
        const SizedBox(height: 22),
        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _BookPath(
              sessions: StudyCatalog.sessions,
              progress: progress,
              accent: AppColors.violet,
              onOpen: onOpen,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CourseSummary extends StatelessWidget {
  final ProgressService progress;

  const _CourseSummary({required this.progress});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.surface2, AppColors.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress.sessionProgress,
                strokeWidth: 8,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.violet),
              ),
              Text(
                '${(progress.sessionProgress * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${progress.completedCount} / ${StudyCatalog.totalSessions} sesiones',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                'Nivel ${progress.stats.level} · ${progress.stats.xp} XP',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 9),
              Text(
                'Tu ruta de aprendizaje',
                style: TextStyle(
                  color: AppColors.violet.withOpacity(.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WeekCard extends StatelessWidget {
  final int week;
  final ProgressService progress;
  final void Function(SessionInfo) onOpen;

  const _WeekCard({
    required this.week,
    required this.progress,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final sessions = StudyCatalog.sessions
        .where((s) => s.week == week)
        .toList();
    final done = sessions.where((s) => progress.isCompleted(s.id)).length;
    final unlocked = sessions.any((s) => progress.isUnlocked(s.id));

    final category = BookCatalog.forId(StudyCatalog.activeBookId).category;
    final type = category == 'kanji'
      ? 'Kanji'
      : category == 'vocabulary'
        ? 'Vocabulario'
        : StudyCatalog.activeBookId == 'shinkanzen_n4_dokkai'
        ? (week == 1
            ? 'Lectura estratégica'
            : week == 2
                ? 'Tipos de preguntas'
                : week == 3
                    ? 'Práctica intensiva'
                    : 'Simulacro')
            : progress.studyLevel == 'N3'
            ? (week <= 2
                ? 'Gramática'
                : week <= 4
                    ? 'Consolidación'
                    : week == 5
                        ? 'Construcción'
                        : week <= 7
                            ? 'Gramática textual'
                            : 'Repaso y simulacros')
            : (week <= 4
                ? 'Gramática'
                : week == 5
                    ? 'Reading'
                    : 'Reading');

    final progressValue = sessions.isEmpty ? 0.0 : done / sessions.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: unlocked
              ? AppColors.violet.withOpacity(.20)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _WeekBadge(
                week: week,
                unlocked: unlocked,
                completed: sessions.isNotEmpty && done == sessions.length,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${StudyCatalog.blockLabel} ${week}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${type}  ·  ${done}/${sessions.length}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progressValue * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: unlocked ? AppColors.violet : AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                done == sessions.length && sessions.isNotEmpty
                    ? AppColors.mint
                    : AppColors.violet,
              ),
            ),
          ),
          const SizedBox(height: 11),
          Column(
            children: [
              for (var i = 0; i < sessions.length; i++)
                _SessionTile(
                  session: sessions[i],
                  progress: progress,
                  onOpen: onOpen,
                  isFirst: i == 0,
                  isLast: i == sessions.length - 1,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekBadge extends StatelessWidget {
  final int week;
  final bool unlocked;
  final bool completed;

  const _WeekBadge({
    required this.week,
    required this.unlocked,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? AppColors.mint
        : unlocked
            ? AppColors.violet
            : AppColors.border;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: unlocked ? color.withOpacity(.13) : AppColors.surface2,
        border: Border.all(
          color: color.withOpacity(unlocked ? .55 : .9),
          width: 1.5,
        ),
      ),
      child: Center(
        child: completed
            ? const Icon(Icons.check_rounded, color: AppColors.mint, size: 21)
            : Text(
                '${week}',
                style: TextStyle(
                  color: unlocked ? color : AppColors.muted,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionInfo session;
  final ProgressService progress;
  final void Function(SessionInfo) onOpen;
  final bool isFirst;
  final bool isLast;

  const _SessionTile({
    required this.session,
    required this.progress,
    required this.onOpen,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final done = progress.isCompleted(session.id);
    final unlocked = progress.isUnlocked(session.id);
    final locked = !done && !unlocked;

    final nodeColor = done
        ? AppColors.mint
        : unlocked
            ? AppColors.violet
            : AppColors.border;

    final titleColor = locked ? AppColors.muted : AppColors.ink;

    return InkWell(
      onTap: unlocked ? () => onOpen(session) : null,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!isFirst)
                    Positioned(
                      top: 0,
                      bottom: 36,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: locked
                              ? AppColors.border.withOpacity(.65)
                              : nodeColor.withOpacity(.30),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  if (!isLast)
                    Positioned(
                      top: 36,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: locked
                              ? AppColors.border.withOpacity(.65)
                              : nodeColor.withOpacity(.30),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: unlocked ? 42 : 38,
                    height: unlocked ? 42 : 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? AppColors.mint
                          : unlocked
                              ? AppColors.violet
                              : AppColors.surface2,
                      border: Border.all(
                        color: nodeColor.withOpacity(locked ? .9 : .35),
                        width: locked ? 1.5 : 1,
                      ),
                      boxShadow: unlocked
                          ? [
                              BoxShadow(
                                color: AppColors.violet.withOpacity(.20),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      done
                          ? Icons.check_rounded
                          : unlocked
                              ? Icons.play_arrow_rounded
                              : Icons.lock_rounded,
                      size: unlocked ? 19 : 16,
                      color: done || unlocked
                          ? Colors.white
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.fromLTRB(13, 11, 12, 11),
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.mintSoft.withOpacity(.42)
                      : unlocked
                          ? AppColors.violetSoft.withOpacity(.44)
                          : AppColors.surface2.withOpacity(.42),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: done
                        ? AppColors.mint.withOpacity(.20)
                        : unlocked
                            ? AppColors.violet.withOpacity(.18)
                            : AppColors.border.withOpacity(.42),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Día ${session.day} · ${session.titleJa}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            session.focus,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: locked
                                  ? AppColors.muted.withOpacity(.72)
                                  : AppColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (done)
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.green,
                        size: 19,
                      )
                    else if (unlocked)
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.violet,
                        size: 18,
                      )
                    else
                      Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.muted.withOpacity(.55),
                        size: 17,
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

class LessonFlowPage extends StatefulWidget {
  final SessionInfo session; final ProgressService progress;
  const LessonFlowPage({super.key,required this.session,required this.progress});
  @override State<LessonFlowPage> createState()=>_LessonFlowPageState();
}

class _LessonFlowPageState extends State<LessonFlowPage> {
  late Future<LessonPacket> future;
  LessonPacket? packet;
  int step=0,correct=0,wrong=0;
  int? selected; bool checked=false;
  String writingAnswer = '';
  bool writingChecked = false;
  DateTime questionStartedAt = DateTime.now();

  @override void initState(){super.initState();future=_load();}
  Future<LessonPacket> _load() async {
    final asset = switch (StudyCatalog.activeBookId) {
      'shinkanzen_n4_dokkai' =>
        'assets/content/shinkanzen_n4_dokkai/lessons/' + widget.session.id + '.json',
      'shinkanzen_n3_grammar' =>
        'assets/content/n3/lessons/' + widget.session.id + '.json',
      _ => 'assets/content/somatome_n4/lessons/' + widget.session.id + '.json',
    };

    try {
      final raw = await rootBundle.loadString(asset);
      packet = LessonPacket.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
        widget.session,
      );
    } catch (_) {
      packet = StudyCatalog.buildPacket(widget.session);
    }

    packet = ExpandedContentService.enrich(
      packet!,
      level: widget.progress.studyLevel,
      bookId: StudyCatalog.activeBookId,
    );
    packet = ExpandedContentService.randomize(packet!);
    packet = _addWritingStep(packet!, widget.session);

    return packet!;
  }

  LessonPacket _addWritingStep(LessonPacket source, SessionInfo session) {
    return LessonPacket(source.session, [
      ...source.steps,
      WriteStep(
        id: '${session.id}-write',
        title: 'Escritura activa',
        prompt: session.titleEs,
        answer: session.titleJa,
        hint: session.focus,
      ),
    ]);
  }

  Future<void> answer(int value,QuestionStep q) async {
    if(checked)return;
    final ok=value==q.answer;
    final responseMs = DateTime.now().difference(questionStartedAt).inMilliseconds;
    setState(() { selected=value; checked=true; });
    if(ok) correct++; else wrong++;
    await widget.progress.recordAnswer(
      sessionId: widget.session.id,
      questionId: q.id,
      prompt: q.question,
      correct: ok,
      conceptIds: LearningEngine.conceptsForFocus(widget.session.focus),
      responseMs: responseMs,
    );
    setState((){});
  }

  Future<void> submitWriting(WriteStep writeStep) async {
    if (writingChecked) return;
    final expected = _normalizeJapanese(writeStep.answer);
    final actual = _normalizeJapanese(writingAnswer);
    final ok = actual == expected && actual.isNotEmpty;
    setState(() => writingChecked = true);
    if (ok) {
      correct++;
    } else {
      wrong++;
    }
    await widget.progress.recordAnswer(
      sessionId: widget.session.id,
      questionId: writeStep.id,
      prompt: writeStep.prompt,
      correct: ok,
      conceptIds: LearningEngine.conceptsForFocus(widget.session.focus),
      responseMs: DateTime.now().difference(questionStartedAt).inMilliseconds,
    );
    if (mounted) setState(() {});
  }

  String _normalizeJapanese(String value) => value
      .trim()
      .replaceAll(RegExp(r'[。、！？!?\s]+'), '');

  Future<void> next() async {
    if(step<packet!.steps.length-1){setState(() { step++; selected=null; checked=false; writingAnswer=''; writingChecked=false; questionStartedAt=DateTime.now(); });return;}
    final total=correct+wrong;
    final passed=total>0 && correct/total>=.80;
    if(passed) await widget.progress.completeSession(widget.session.id,correct,wrong);
    if(!mounted)return;
    showDialog(context:context,barrierDismissible:false,builder:(_)=>_ResultDialog(passed:passed,correct:correct,wrong:wrong,onClose:(){Navigator.pop(context);if(passed){Navigator.pop(context);}else{setState((){step=0;correct=0;wrong=0;selected=null;checked=false;writingAnswer='';writingChecked=false;questionStartedAt=DateTime.now();});}}));
  }

  String _lessonSenseiContext(LessonStep item) {
    if (item is TeachStep) {
      return 'Leccion Dia ${widget.session.day}. Tema: ${item.title}. Patron: ${item.pattern}. Ejemplo visible: ${item.exampleJa} — ${item.exampleEs}.';
    }
    if (item is WriteStep) {
      return 'Ejercicio de escritura del Dia ${widget.session.day}. El usuario debe expresar en japones esta idea: ${item.prompt}. Pista visible: ${item.hint}.';
    }
    final question = item as QuestionStep;
    return 'Pregunta actual del Dia ${widget.session.day}: ${question.title}. Enunciado visible: ${question.question}.';
  }

  @override Widget build(BuildContext context)=>FutureBuilder<LessonPacket>(future:future,builder:(_,snap){
    if(!snap.hasData)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final item=packet!.steps[step];
    return Scaffold(
      appBar:AppBar(title:Text('Día '+widget.session.day.toString()),actions:[Padding(padding:const EdgeInsets.only(right:16),child:Text('+'+widget.progress.stats.xp.toString()+' XP'))]),
      floatingActionButton: _SenseiBubble(
        level: widget.progress.studyLevel,
        contextDescription: _lessonSenseiContext(item),
      ),
      body:Column(children:[
        Padding(
          padding:const EdgeInsets.symmetric(horizontal:18,vertical:8),
          child:Row(children:[
            Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:(step+1)/packet!.steps.length,minHeight:8,backgroundColor:AppColors.border))),
            const SizedBox(width:10),
            Text((step+1).toString()+'/'+packet!.steps.length.toString(),style:const TextStyle(fontSize:11,fontWeight:FontWeight.w900,color:AppColors.muted)),
          ]),
        ),
        Expanded(child:AnimatedSwitcher(duration:const Duration(milliseconds:220),child:item is TeachStep?_TeachCard(key:ValueKey(step),step:item,onNext:()=>setState(() { step++; questionStartedAt=DateTime.now(); })) : item is WriteStep ? _WritingCard(key:ValueKey(step),step:item,value:writingAnswer,checked:writingChecked,onChanged:(value)=>setState(() => writingAnswer=value),onSubmit:()=>submitWriting(item),onNext:next) : _QuestionCard(key:ValueKey(step),step:item as QuestionStep,selected:selected,checked:checked,onAnswer:answer,onNext:next))),
      ]),
    );
  });
}

class _TeachCard extends StatelessWidget {
  final TeachStep step; final VoidCallback onNext;
  const _TeachCard({super.key,required this.step,required this.onNext});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(22,26,22,30),children:[
    _Label(text:step.label),const SizedBox(height:12),
    Text(step.title,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),
    const SizedBox(height:12),Text(step.body,style:const TextStyle(fontSize:17,height:1.45)),
    const SizedBox(height:18),
    Container(
      padding:const EdgeInsets.all(22),
      decoration:BoxDecoration(
        gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[AppColors.violetSoft,AppColors.surface2]),
        borderRadius:BorderRadius.circular(26),
        border:Border.all(color:AppColors.violet.withOpacity(.10)),
        boxShadow:[BoxShadow(color:AppColors.violet.withOpacity(.08),blurRadius:24,offset:const Offset(0,10))],
      ),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(step.pattern,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:13),Text(step.exampleJa,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900)),const SizedBox(height:5),Text(step.exampleEs),
    ])),
    const SizedBox(height:14),Card(child:Padding(padding:const EdgeInsets.all(15),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.lightbulb_rounded,color:AppColors.primary),const SizedBox(width:10),Expanded(child:Text(step.tip))]))),
    const SizedBox(height:24),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:onNext,icon:const Icon(Icons.arrow_forward_rounded),label:const Text('CONTINUAR'))),
  ]);
}

class _WritingCard extends StatelessWidget {
  final WriteStep step;
  final String value;
  final bool checked;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onNext;

  const _WritingCard({
    super.key,
    required this.step,
    required this.value,
    required this.checked,
    required this.onChanged,
    required this.onSubmit,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final correct = checked && value.trim().replaceAll(RegExp(r'[。、！？!?\s]+'), '') == step.answer.trim().replaceAll(RegExp(r'[。、！？!?\s]+'), '');

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
      children: [
        const _Label(text: 'ESCRITURA ACTIVA'),
        const SizedBox(height: 12),
        Text(
          step.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        const Text('Escribe esta idea en japones:', style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.violet.withOpacity(.24)),
          ),
          child: Text(step.prompt, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.3)),
        ),
        const SizedBox(height: 10),
        Text('Pista: ${step.hint}', style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        TextField(
          enabled: !checked,
          autofocus: true,
          onChanged: onChanged,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Escribe aqui en japones',
            prefixIcon: const Icon(Icons.edit_rounded),
            suffixIcon: checked ? Icon(correct ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: correct ? AppColors.mint : AppColors.coral) : null,
          ),
        ),
        if (checked) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: correct ? AppColors.mintSoft : AppColors.roseSoft, borderRadius: BorderRadius.circular(18)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(correct ? Icons.check_circle_rounded : Icons.auto_awesome_rounded, color: correct ? AppColors.mint : AppColors.coral), const SizedBox(width: 10), Expanded(child: Text(correct ? 'Perfecto. La frase coincide.' : 'La respuesta esperada era: ${step.answer}', style: const TextStyle(fontWeight: FontWeight.w800)))]),
          ),
          const SizedBox(height: 15),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onNext, icon: const Icon(Icons.arrow_forward_rounded), label: const Text('CONTINUAR'))),
        ] else ...[
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: value.trim().isEmpty ? null : onSubmit, icon: const Icon(Icons.check_rounded), label: const Text('COMPROBAR'))),
        ],
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QuestionStep step;
  final int? selected;
  final bool checked;
  final Future<void> Function(int, QuestionStep) onAnswer;
  final VoidCallback onNext;

  const _QuestionCard({
    super.key,
    required this.step,
    required this.selected,
    required this.checked,
    required this.onAnswer,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final ok = checked && selected == step.answer;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
      children: [
        _Label(text: 'TU TURNO'),
        const SizedBox(height: 12),
        Text(
          step.title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Text(
          step.question,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),

        for (var i = 0; i < step.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                side: BorderSide(
                  color: checked && i == step.answer
                      ? const Color(0xFF4B8A5A)
                      : checked && i == selected
                          ? const Color(0xFFC85A5A)
                          : AppColors.border,
                  width: checked && (i == step.answer || i == selected)
                      ? 2
                      : 1,
                ),
              ),
              onPressed: checked ? null : () => onAnswer(i, step),
              child: Text(
                step.options[i],
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),

        if (checked) ...[
          const SizedBox(height: 4),
          Card(
            color: ok ? AppColors.sageSoft : AppColors.roseSoft,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    ok
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: ok
                        ? const Color(0xFF4B8A5A)
                        : const Color(0xFFC85A5A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(step.explanation)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: const Text('SIGUIENTE'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ResultDialog extends StatelessWidget {
  final bool passed; final int correct,wrong; final VoidCallback onClose;
  const _ResultDialog({required this.passed,required this.correct,required this.wrong,required this.onClose});
  @override Widget build(BuildContext context)=>Dialog(
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(32)),
    child:Padding(
      padding:const EdgeInsets.fromLTRB(26,30,26,24),
      child:TweenAnimationBuilder<double>(
        tween:Tween(begin:.88,end:1),
        duration:const Duration(milliseconds:420),
        curve:Curves.easeOutBack,
        builder:(context,scale,child)=>Transform.scale(scale:scale,child:child),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          Container(
            width:82,height:82,
            decoration:BoxDecoration(
              shape:BoxShape.circle,
              gradient:LinearGradient(colors:passed?[AppColors.yellow,AppColors.coral]:[AppColors.violet,AppColors.navySoft]),
              boxShadow:[BoxShadow(color:(passed?AppColors.coral:AppColors.violet).withOpacity(.25),blurRadius:25,offset:const Offset(0,8))],
            ),
            child:Icon(passed?Icons.emoji_events_rounded:Icons.refresh_rounded,size:42,color:Colors.white),
          ),
          const SizedBox(height:18),
          Text(passed?'¡Sesión completada!':'Casi lo tienes',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),
          const SizedBox(height:8),
          if(passed) const Text('+ XP  ·  Racha en marcha',style:TextStyle(color:AppColors.coral,fontWeight:FontWeight.w900)),
          const SizedBox(height:8),
          Text(correct.toString()+' correctas  ·  '+wrong.toString()+' errores',style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800)),
          const SizedBox(height:8),
          Text(passed?'Siguiente sesión desbloqueada.':'Necesitas 80% para desbloquear la siguiente sesión.',textAlign:TextAlign.center,style:const TextStyle(color:AppColors.muted)),
          const SizedBox(height:22),
          SizedBox(width:double.infinity,child:FilledButton(onPressed:onClose,child:Text(passed?'CONTINUAR':'REINTENTAR'))),
        ]),
      ),
    ),
  );
}

class ReviewPage extends StatelessWidget {
  final ProgressService progress; final void Function(SessionInfo) onOpen;
  const ReviewPage({super.key,required this.progress,required this.onOpen});
  @override Widget build(BuildContext context){final s=progress.stats;return SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(20,78,20,30),children:[
    Text('Repaso inteligente',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:5),const Text('Convierte tus errores en puntos fuertes.'),const SizedBox(height:18),
    Card(color:AppColors.primarySoft,child:Padding(padding:const EdgeInsets.all(19),child:Row(children:[const Icon(Icons.auto_awesome_rounded,size:34,color:AppColors.primary),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(s.openMistakes.toString()+' errores pendientes',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900)),Text(s.corrected.toString()+' errores ya corregidos',style:const TextStyle(color:AppColors.muted))]))] ))),
    const SizedBox(height:14),_StatsRow(stats:s),const SizedBox(height:14),
    _LearningPriorityCard(progress: progress),
    const SizedBox(height:18),
    if(s.openMistakes>0) for(final m in progress.mistakePrompts.take(8)) Card(margin:const EdgeInsets.only(bottom:8),child:ListTile(leading:const Icon(Icons.replay_rounded),title:Text(m,maxLines:2,overflow:TextOverflow.ellipsis),subtitle:const Text('Pendiente de reforzar')))
    else Card(child:Padding(padding:const EdgeInsets.all(22),child:Column(children:const[Icon(Icons.celebration_rounded,size:48,color:AppColors.primary),SizedBox(height:10),Text('No tienes errores pendientes',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18)),SizedBox(height:5),Text('Sigue avanzando y vuelve aquí para reforzar lo difícil.',textAlign:TextAlign.center)]))),
    const SizedBox(height:18),Text('Próxima sesión',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:8),
    _SessionTile(session:progress.nextUnlockedSession(),progress:progress,onOpen:onOpen),
  ]));}
}

class _LearningPriorityCard extends StatelessWidget {
  final ProgressService progress;

  const _LearningPriorityCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final snapshot = progress.learningSnapshot;
    final items = snapshot.due.isNotEmpty
        ? snapshot.due.take(4).toList()
        : snapshot.weakest.take(4).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.violet,
                  size: 19,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Prioridades detectadas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  snapshot.dueConcepts > 0
                      ? 'REPASO'
                      : 'DIAGNÓSTICO',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              snapshot.dueConcepts > 0
                  ? 'Estos conceptos ya entraron en la ventana de repaso.'
                  : 'A medida que acumules respuestas, aquí aparecerán tus áreas prioritarias.',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.isDue
                              ? AppColors.coral
                              : AppColors.yellow,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          item.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        item.mastery.round().toString() + '%',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProgressPage extends StatelessWidget {
  final ProgressService progress; const ProgressPage({super.key,required this.progress});
  @override Widget build(BuildContext context){final s=progress.stats;return SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(20,78,20,30),children:[
    Text('Tu progreso',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:5),const Text('Buenas, malas y lo que ya lograste corregir.'),const SizedBox(height:18),
    Card(child:Padding(padding:const EdgeInsets.all(20),child:Row(children:[SizedBox(width:82,height:82,child:Stack(alignment:Alignment.center,children:[CircularProgressIndicator(value:progress.sessionProgress,strokeWidth:9),Text((progress.sessionProgress*100).round().toString()+'%',style:const TextStyle(fontWeight:FontWeight.w900))])),const SizedBox(width:17),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(progress.completedCount.toString()+' / '+StudyCatalog.totalSessions.toString()+' sesiones',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),Text('Nivel '+s.level.toString()+' · '+s.xp.toString()+' XP',style:const TextStyle(color:AppColors.muted))]))]))),
    const SizedBox(height:14),_StatsRow(stats:s),const SizedBox(height:18),
    _LearningOverviewCard(progress: progress),
    const SizedBox(height:22),
    Text('Recuperación',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:8),
    Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
      _Bar(label:'Buenas respuestas',value:s.correct,max:s.totalAnswers==0?1:s.totalAnswers),_Bar(label:'Malas respuestas',value:s.wrong,max:s.totalAnswers==0?1:s.totalAnswers),_Bar(label:'Errores corregidos',value:s.corrected,max:s.wrong==0?1:s.wrong),
    ]))),
    const SizedBox(height:22),Text('Por semana',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:8),
    for(var w=1;w<=StudyCatalog.totalBlocks;w++) _WeekRow(week:w,progress:progress),
  ]));}
}

class _LearningOverviewCard extends StatelessWidget {
  final ProgressService progress;

  const _LearningOverviewCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final snapshot = progress.learningSnapshot;
    final mastery = snapshot.mastery.round();

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surface2, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.violet.withOpacity(.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_alt_rounded,
                color: AppColors.violet,
                size: 22,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Lo que la app ha aprendido de ti',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                snapshot.hasIntelligenceData ? '$mastery%' : '—',
                style: const TextStyle(
                  color: AppColors.violet,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            snapshot.hasIntelligenceData
                ? 'Dominio estimado a partir de tus respuestas, rachas y repasos.'
                : 'Todavía no hay suficiente historial. Tus respuestas irán creando tu perfil.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _LearningStat(
                icon: Icons.hub_rounded,
                value: snapshot.trackedConcepts.toString(),
                label: 'conceptos',
              ),
              const SizedBox(width: 8),
              _LearningStat(
                icon: Icons.schedule_rounded,
                value: snapshot.dueConcepts.toString(),
                label: 'para repasar',
              ),
              const SizedBox(width: 8),
              _LearningStat(
                icon: Icons.warning_amber_rounded,
                value: snapshot.weakConcepts.toString(),
                label: 'débiles',
              ),
              const SizedBox(width: 8),
              _LearningStat(
                icon: Icons.shield_moon_rounded,
                value: snapshot.atRiskConcepts.toString(),
                label: 'en riesgo',
              ),
            ],
          ),
          if (snapshot.weakest.isNotEmpty) ...[
            const SizedBox(height: 15),
            const Text(
              'PRIORIDADES',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final concept in snapshot.weakest.take(3))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.roseSoft.withOpacity(.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      concept.id,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LearningStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _LearningStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(.58),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.violet, size: 16),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatsRow extends StatelessWidget {
  final StudyStats stats; const _StatsRow({required this.stats});
  @override Widget build(BuildContext context)=>Row(children:[
    Expanded(child:_Metric(icon:Icons.check_circle_rounded,value:stats.correct.toString(),label:'Buenas')),
    const SizedBox(width:7),Expanded(child:_Metric(icon:Icons.close_rounded,value:stats.wrong.toString(),label:'Malas')),
    const SizedBox(width:7),Expanded(child:_Metric(icon:Icons.healing_rounded,value:stats.corrected.toString(),label:'Corregidas')),
    const SizedBox(width:7),Expanded(child:_Metric(icon:Icons.percent_rounded,value:stats.accuracy.round().toString()+'%',label:'Precisión')),
  ]);
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Metric({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 3),
      child: Column(
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ],
      ),
    ),
  );
}

class _Bar extends StatelessWidget {
  final String label; final int value,max; const _Bar({required this.label,required this.value,required this.max});
  @override Widget build(BuildContext context){final v=(value/max).clamp(0.0,1.0);return Padding(padding:const EdgeInsets.only(bottom:14),child:Column(children:[Row(children:[Expanded(child:Text(label,style:const TextStyle(fontWeight:FontWeight.w700))),Text(value.toString(),style:const TextStyle(fontWeight:FontWeight.w900))]),const SizedBox(height:6),ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:v,minHeight:7))]));}
}

class _WeekRow extends StatelessWidget {
  final int week; final ProgressService progress; const _WeekRow({required this.week,required this.progress});
  @override Widget build(BuildContext context){final sessions=StudyCatalog.sessions.where((s)=>s.week==week).toList();final done=sessions.where((s)=>progress.isCompleted(s.id)).length;return Padding(padding:const EdgeInsets.only(bottom:10),child:Row(children:[SizedBox(width:82,child:Text((StudyCatalog.blockLabel + ' ')+week.toString(),style:const TextStyle(fontWeight:FontWeight.w800))),Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:done/sessions.length,minHeight:8))),const SizedBox(width:10),Text(done.toString()+'/'+sessions.length.toString(),style:const TextStyle(fontWeight:FontWeight.w900))]));}
}

class _Path extends StatelessWidget {
  final ProgressService progress;

  const _Path({required this.progress});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (var i = 1; i <= StudyCatalog.totalBlocks; i++) {
      children.add(
        Column(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: progress.weekCompleted(i)
                  ? AppColors.sageSoft
                  : progress.weekUnlocked(i)
                      ? AppColors.primarySoft
                      : const Color(0xFFEDEAE7),
              child: Icon(
                progress.weekCompleted(i)
                    ? Icons.check_rounded
                    : progress.weekUnlocked(i)
                        ? Icons.play_arrow_rounded
                        : Icons.lock_rounded,
                size: 17,
                color: progress.weekCompleted(i)
                    ? const Color(0xFF4B8A5A)
                    : progress.weekUnlocked(i)
                        ? AppColors.primary
                        : AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'S' + i.toString(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );

      if (i < StudyCatalog.totalBlocks) {
        children.add(const Expanded(child: Divider()));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: children),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon; final String text; const _Pill({required this.icon,required this.text});
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),decoration:BoxDecoration(color:Colors.white.withOpacity(.72),borderRadius:BorderRadius.circular(20)),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:15,color:AppColors.primary),const SizedBox(width:4),Text(text,style:const TextStyle(fontWeight:FontWeight.w800))]));
}

class _Label extends StatelessWidget {
  final String text; const _Label({required this.text});
  @override Widget build(BuildContext context)=>Text(text,style:Theme.of(context).textTheme.labelLarge?.copyWith(color:AppColors.primary,fontWeight:FontWeight.w900,letterSpacing:1.3));
}
