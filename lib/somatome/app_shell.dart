import 'package:flutter/material.dart';
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
            const Text('Una sesión corta para avanzar sin complicarte.'),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () {},
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
              onTap: () {},
            ),
          ),
      ],
    ),
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
