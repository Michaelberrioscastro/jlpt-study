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

  final pages = const [
    _HomePage(),
    _CoursePage(),
    _ReviewPage(),
    _ProgressPage(),
  ];

  void openLesson(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _LessonPage()));
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
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 14),
        Text('N4 SOMATOME', style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primary, fontWeight: FontWeight.w900, letterSpacing: 1.5,
        )),
        const SizedBox(height: 8),
        Text('Estudia un poco cada día.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.text, fontWeight: FontWeight.w900,
        )),
        const SizedBox(height: 26),
        Card(child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('HOY', style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.muted, fontWeight: FontWeight.w800, letterSpacing: 1.2,
            )),
            const SizedBox(height: 10),
            const Text('Semana 1 · Día 1', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('一日に二回、歯をみがきます。'),
            const SizedBox(height: 4),
            const Text('Frecuencia, distribución y ほど'),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _LessonPage())),
              child: const Text('COMENZAR'),
            )),
          ]),
        )),
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
        const SizedBox(height: 14),
        Text('Curso', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('6 semanas · 42 sesiones'),
        const SizedBox(height: 22),
        for (var week = 1; week <= 6; week++)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('Semana $week', style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(week <= 4 ? 'Gramática' : week == 5 ? 'Reading' : 'Listening'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                if (week == 1) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _WeekOnePage()));
                }
              },
            ),
          ),
      ],
    ),
  );
}

class _WeekOnePage extends StatelessWidget {
  const _WeekOnePage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Semana 1')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Gramática', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Páginas 18–31 · 6 días + repaso'),
        const SizedBox(height: 20),
        for (final item in const [
          ('Día 1', '一日に二回、歯をみがきます。', 'Frecuencia/ratio y ほど'),
          ('Día 2', '漢字は少ししか書けません。', 'しか～ない / でも / で'),
          ('Día 3', '9時までに来てください。', 'まで / までに / たり～たり / し'),
          ('Día 4', '今、勉強しているところです。', 'ところ / 間に / とき / 前に / 後で'),
          ('Día 5', '音楽を聞きながら勉強しています。', 'て / なくて / ないで / ても'),
          ('Día 6', '雪を見たことがありません。', 'たことがある / ことにする / ことになる'),
          ('Día 7', 'まとめ問題', 'Repaso'),
        ])
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${item.$2}\n${item.$3}'),
              isThreeLine: true,
              trailing: item.$1 == 'Día 1' ? const Icon(Icons.play_arrow_rounded) : const Icon(Icons.lock_outline_rounded),
              onTap: item.$1 == 'Día 1'
                  ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _LessonPage()))
                  : null,
            ),
          ),
      ],
    ),
  );
}

class _LessonPage extends StatefulWidget {
  const _LessonPage();
  @override
  State<_LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<_LessonPage> {
  Map<String, dynamic>? data;
  bool loading = true;

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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final session = data!['session'] as Map<String, dynamic>;
    final sections = data!['sections'] as List<dynamic>;
    final practice = data!['practice'] as List<dynamic>;
    final reflection = data!['reflection'] as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(title: const Text('Día 1')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text('Semana ${session['week']} · Día ${session['day']}', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(session['title_ja'] as String, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(session['title_es'] as String),
          const SizedBox(height: 12),
          _Tag(text: session['focus'] as String),
          const SizedBox(height: 24),
          for (final section in sections)
            _LessonSection(section: section as Map<String, dynamic>),
          const SizedBox(height: 12),
          Text('Practica', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          for (var i = 0; i < practice.length; i++)
            _PracticeCard(item: practice[i] as Map<String, dynamic>, number: i + 1),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Producción', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(reflection['prompt_es'] as String),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Text('Fuente: páginas 18–19 del Somatome N4 proporcionado.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _LessonSection extends StatelessWidget {
  final Map<String, dynamic> section;
  const _LessonSection({required this.section});

  @override
  Widget build(BuildContext context) {
    final items = section['items'] as List<dynamic>;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(section['title'] as String, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        for (final item in items)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['pattern'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(item['meaning_es'] as String),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['example_ja'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(item['example_es'] as String),
                  ]),
                ),
                const SizedBox(height: 8),
                Text(item['note_es'] as String, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted)),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _PracticeCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final int number;
  const _PracticeCard({required this.item, required this.number});

  @override
  State<_PracticeCard> createState() => _PracticeCardState();
}

class _PracticeCardState extends State<_PracticeCard> {
  int? selected;
  bool checked = false;

  @override
  Widget build(BuildContext context) {
    final options = widget.item['options'] as List<dynamic>;
    final answer = widget.item['answer'] as int;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pregunta ${widget.number}', style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(widget.item['prompt_es'] as String),
          const SizedBox(height: 8),
          for (var i = 0; i < options.length; i++)
            RadioListTile<int>(
              contentPadding: EdgeInsets.zero,
              value: i,
              groupValue: selected,
              title: Text(options[i] as String),
              onChanged: checked ? null : (value) => setState(() => selected = value),
            ),
          FilledButton.tonal(
            onPressed: selected == null ? null : () => setState(() => checked = true),
            child: const Text('COMPROBAR'),
          ),
          if (checked)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                selected == answer
                    ? '✓ Correcto. ${widget.item['explanation_es']}'
                    : '✗ Revisa la estructura. ${widget.item['explanation_es']}',
                style: TextStyle(fontWeight: FontWeight.w700, color: selected == answer ? Colors.green.shade700 : Colors.red.shade700),
              ),
            ),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

class _ReviewPage extends StatelessWidget {
  const _ReviewPage();

  @override
  Widget build(BuildContext context) => const SafeArea(
    child: Center(child: Padding(
      padding: EdgeInsets.all(30),
      child: Text('Aquí aparecerá tu repaso pendiente.'),
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
        const SizedBox(height: 14),
        Text('Progreso', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        for (final label in ['Curso', 'Gramática', 'Reading', 'Listening'])
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))),
                  const Text('0%'),
                ]),
                const SizedBox(height: 10),
                const LinearProgressIndicator(value: 0),
              ]),
            ),
          ),
      ],
    ),
  );
}
