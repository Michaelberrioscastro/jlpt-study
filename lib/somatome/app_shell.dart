import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  int xp = 0;
  int streak = 1;

  final pages = const [_HomePage(), _CoursePage(), _ReviewPage(), _ProgressPage()];

  void openLesson(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _LessonFlowPage(onXp: (value) => setState(() => xp += value)),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: index, children: pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Curso'),
        NavigationDestination(icon: Icon(Icons.refresh_rounded), selectedIcon: Icon(Icons.refresh), label: 'Repaso'),
        NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Progreso'),
      ],
    ),
  );
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        Row(
          children: [
            Expanded(child: Text('N4 SOMATOME', style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w900, letterSpacing: 1.5,
            ))),
            const _Pill(icon: Icons.local_fire_department_rounded, text: '1 día'),
          ],
        ),
        const SizedBox(height: 8),
        Text('Tu próxima lección', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.text, fontWeight: FontWeight.w900,
        )),
        const SizedBox(height: 6),
        const Text('Aprende → responde → desbloquea → repasa.'),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Text('SEMANA 1 · DÍA 1', style: TextStyle(fontWeight: FontWeight.w900))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
                  child: const Text('+100 XP', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ]),
              const SizedBox(height: 14),
              Text('一日に二回、歯をみがきます。', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text('Frecuencia · ずつ · ほど'),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(value: .0, minHeight: 9),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _LessonFlowPage())),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('EMPEZAR LECCIÓN'),
              )),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        Row(children: const [
          Expanded(child: _StatCard(icon: Icons.bolt_rounded, value: '0', label: 'XP hoy')),
          SizedBox(width: 10),
          Expanded(child: _StatCard(icon: Icons.favorite_rounded, value: '5', label: 'vidas')),
          SizedBox(width: 10),
          Expanded(child: _StatCard(icon: Icons.local_fire_department_rounded, value: '1', label: 'racha')),
        ]),
        const SizedBox(height: 22),
        Text('Tu camino', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const _PathPreview(),
      ],
    ),
  );
}

class _CoursePage extends StatelessWidget {
  const _CoursePage();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Text('Curso', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Avanza por pequeñas lecciones y desbloquea la siguiente.'),
        const SizedBox(height: 20),
        const _CourseHeader(),
        const SizedBox(height: 18),
        for (var week = 1; week <= 6; week++)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: week == 1 ? AppColors.primarySoft : Colors.grey.shade200,
                child: Text('$week', style: TextStyle(fontWeight: FontWeight.w900, color: week == 1 ? AppColors.primary : AppColors.muted)),
              ),
              title: Text('Semana $week', style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(week <= 4 ? 'Gramática · 7 sesiones' : week == 5 ? 'Reading · 7 sesiones' : 'Listening · 7 sesiones'),
              trailing: week == 1 ? const Icon(Icons.play_arrow_rounded) : const Icon(Icons.lock_outline_rounded),
              onTap: week == 1 ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _WeekOnePage())) : null,
            ),
          ),
      ],
    ),
  );
}

class _CourseHeader extends StatelessWidget {
  const _CourseHeader();

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.primarySoft,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        const Icon(Icons.route_rounded, size: 34, color: AppColors.primary),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tu ruta N4', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 3),
          Text('0 / 42 sesiones completadas'),
        ])),
        SizedBox(width: 55, child: CircularProgressIndicator(value: 0)),
      ]),
    ),
  );
}

class _WeekOnePage extends StatelessWidget {
  const _WeekOnePage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Semana 1')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      children: [
        Text('Gramática', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        const Text('Tu primera ruta de 7 días'),
        const SizedBox(height: 18),
        for (final item in const [
          ('Día 1', '一日に二回、歯をみがきます。', 'Frecuencia · ずつ · ほど', true),
          ('Día 2', '漢字は少ししか書けません。', 'しか～ない · でも · で', false),
          ('Día 3', '9時までに来てください。', 'まで · までに · たり～たり · し', false),
          ('Día 4', '今、勉強しているところです。', 'ところ · 間に · とき · 前に · 後で', false),
          ('Día 5', '音楽を聞きながら勉強しています。', 'て · なくて · ないで · ても', false),
          ('Día 6', '雪を見たことがありません。', 'たことがある · ことにする · ことになる', false),
          ('Día 7', 'まとめ問題', 'Repaso de la semana', false),
        ])
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: item.$4 ? AppColors.primary : Colors.grey.shade200,
                child: Text(item.$1.substring(4), style: TextStyle(fontWeight: FontWeight.w900, color: item.$4 ? Colors.white : AppColors.muted)),
              ),
              title: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(item.$3),
              trailing: item.$4 ? const Icon(Icons.play_arrow_rounded) : const Icon(Icons.lock_outline_rounded),
              onTap: item.$4 ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _LessonFlowPage())) : null,
            ),
          ),
      ],
    ),
  );
}

class _LessonFlowPage extends StatefulWidget {
  final void Function(int value)? onXp;
  const _LessonFlowPage({this.onXp});
  @override
  State<_LessonFlowPage> createState() => _LessonFlowPageState();
}

class _LessonFlowPageState extends State<_LessonFlowPage> {
  Map<String, dynamic>? data;
  bool loading = true;
  int step = 0;
  int xp = 0;
  int hearts = 3;
  int? selected;
  bool checked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/content/somatome_n4/lessons/W01D01.json');
    setState(() {
      data = jsonDecode(raw) as Map<String, dynamic>;
      loading = false;
    });
  }

  void answer(int value, int correct) {
    if (checked) return;
    setState(() {
      selected = value;
      checked = true;
      if (value == correct) {
        xp += 10;
      } else if (hearts > 0) {
        hearts -= 1;
      }
    });
  }

  void next() {
    final steps = data!['steps'] as List<dynamic>;
    if (step < steps.length - 1) {
      setState(() {
        step++;
        selected = null;
        checked = false;
      });
    } else {
      setState(() => step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final steps = data!['steps'] as List<dynamic>;
    final done = step >= steps.length;
    final progress = done ? 1.0 : step / steps.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(done ? '¡Lección completada!' : 'Día 1 · $xp XP'),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 16), child: Row(children: [
            const Icon(Icons.favorite_rounded, size: 19),
            const SizedBox(width: 4),
            Text('$hearts'),
          ])),
        ],
      ),
      body: done ? _CompletionView(xp: xp, onDone: () => Navigator.pop(context)) : Column(
        children: [
          LinearProgressIndicator(value: progress, minHeight: 6),
          Expanded(child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _StepView(
              key: ValueKey(step),
              step: steps[step] as Map<String, dynamic>,
              selected: selected,
              checked: checked,
              onAnswer: answer,
              onNext: next,
            ),
          )),
        ],
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  final Map<String, dynamic> step;
  final int? selected;
  final bool checked;
  final void Function(int value, int correct) onAnswer;
  final VoidCallback onNext;

  const _StepView({
    super.key,
    required this.step,
    required this.selected,
    required this.checked,
    required this.onAnswer,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final type = step['type'] as String;
    if (type == 'teach') return _TeachStep(step: step, onNext: onNext);
    return _QuestionStep(step: step, selected: selected, checked: checked, onAnswer: onAnswer, onNext: onNext);
  }
}

class _TeachStep extends StatelessWidget {
  final Map<String, dynamic> step;
  final VoidCallback onNext;
  const _TeachStep({required this.step, required this.onNext});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
    children: [
      _StepLabel(text: 'APRENDE'),
      const SizedBox(height: 14),
      Text(step['title'] as String, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 14),
      Text(step['body'] as String, style: const TextStyle(fontSize: 17, height: 1.45)),
      const SizedBox(height: 20),
      Card(
        color: AppColors.primarySoft,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(step['pattern'] as String, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Text(step['example_ja'] as String, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(step['example_es'] as String),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(step['tip'] as String)),
        ]),
      ),
      const SizedBox(height: 26),
      SizedBox(width: double.infinity, child: FilledButton(
        onPressed: onNext,
        child: const Text('LO ENTIENDO · CONTINUAR'),
      )),
    ],
  );
}

class _QuestionStep extends StatelessWidget {
  final Map<String, dynamic> step;
  final int? selected;
  final bool checked;
  final void Function(int value, int correct) onAnswer;
  final VoidCallback onNext;

  const _QuestionStep({required this.step, required this.selected, required this.checked, required this.onAnswer, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final options = step['options'] as List<dynamic>;
    final correct = step['answer'] as int;
    final isCorrect = checked && selected == correct;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
      children: [
        _StepLabel(text: step['type'] == 'mixed' ? 'RETO' : 'TU TURNO'),
        const SizedBox(height: 14),
        Text(step['title'] as String, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        Text(step['question'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.4)),
        const SizedBox(height: 18),
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                side: BorderSide(
                  color: checked && i == correct ? Colors.green : checked && i == selected ? Colors.red : AppColors.border,
                  width: checked && (i == correct || i == selected) ? 2 : 1,
                ),
              ),
              onPressed: checked ? null : () => onAnswer(i, correct),
              child: Text(options[i] as String, style: const TextStyle(fontSize: 16)),
            ),
          ),
        if (checked) ...[
          const SizedBox(height: 8),
          Card(
            color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: isCorrect ? Colors.green.shade700 : Colors.red.shade700),
                const SizedBox(width: 10),
                Expanded(child: Text(step['explanation'] as String)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: onNext,
            child: const Text('CONTINUAR'),
          )),
        ],
      ],
    );
  }
}

class _CompletionView extends StatelessWidget {
  final int xp;
  final VoidCallback onDone;
  const _CompletionView({required this.xp, required this.onDone});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.emoji_events_rounded, size: 76, color: AppColors.primary),
        const SizedBox(height: 18),
        Text('¡Día 1 completado!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Has ganado $xp XP', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const Text('Siguiente paso: reforzar lo aprendido y mantener la racha.'),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: onDone, child: const Text('VOLVER AL CURSO'))),
      ]),
    ),
  );
}

class _StepLabel extends StatelessWidget {
  final String text;
  const _StepLabel({required this.text});

  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(
    color: AppColors.primary, fontWeight: FontWeight.w900, letterSpacing: 1.3,
  ));
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: AppColors.primary), const SizedBox(width: 4), Text(text, style: const TextStyle(fontWeight: FontWeight.w800))]),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(children: [Icon(icon, size: 20, color: AppColors.primary), const SizedBox(height: 6), Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), Text(label, style: Theme.of(context).textTheme.bodySmall)]),
    ),
  );
}

class _PathPreview extends StatelessWidget {
  const _PathPreview();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        _PathDot(active: true, label: 'D1'),
        const Expanded(child: Divider(indent: 6, endIndent: 6)),
        _PathDot(active: false, label: 'D2'),
        const Expanded(child: Divider(indent: 6, endIndent: 6)),
        _PathDot(active: false, label: 'D3'),
        const Expanded(child: Divider(indent: 6, endIndent: 6)),
        _PathDot(active: false, label: 'D4'),
      ]),
    ),
  );
}

class _PathDot extends StatelessWidget {
  final bool active;
  final String label;
  const _PathDot({required this.active, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
    CircleAvatar(radius: 17, backgroundColor: active ? AppColors.primary : Colors.grey.shade200, child: Icon(active ? Icons.play_arrow_rounded : Icons.lock_outline_rounded, size: 18, color: active ? Colors.white : AppColors.muted)),
    const SizedBox(height: 5),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
  ]);
}

class _ReviewPage extends StatelessWidget {
  const _ReviewPage();
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Icon(Icons.refresh_rounded, size: 52),
        SizedBox(height: 14),
        Text('Repaso inteligente', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        SizedBox(height: 8),
        Text('Aquí aparecerán preguntas de las lecciones que necesiten refuerzo.', textAlign: TextAlign.center),
      ]),
    )),
  );
}

class _ProgressPage extends StatelessWidget {
  const _ProgressPage();
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Text('Progreso', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        Card(child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            const CircularProgressIndicator(value: 0),
            const SizedBox(width: 18),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nivel 1', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              SizedBox(height: 3),
              Text('0 XP · comienza tu camino N4'),
            ])),
          ]),
        )),
        const SizedBox(height: 12),
        for (final label in ['Curso', 'Gramática', 'Reading', 'Listening'])
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))), const Text('0%')]),
                const SizedBox(height: 9),
                const LinearProgressIndicator(value: 0, minHeight: 7),
              ]),
            ),
          ),
      ],
    ),
  );
}
