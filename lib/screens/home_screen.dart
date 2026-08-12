import 'package:flutter/material.dart';

import '../services/database_service.dart';
import 'level_screen.dart';
import 'kana_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  String _selectedLevel = 'N5';
  Map<String, int>? _counts;
  Map<String, int>? _kanaCounts;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await DatabaseService.getStudyCounts(_selectedLevel);
      final kanaResult = await DatabaseService.getKanaOverallCounts();

      if (!mounted) return;

      setState(() {
        _counts = result;
        _kanaCounts = kanaResult;
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

  Future<void> _openKana() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const KanaScreen()));

    if (!mounted) return;
    await _loadCounts();
  }

  Future<void> _openLevel() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LevelScreen(level: _selectedLevel)),
    );

    if (!mounted) return;
    await _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final total = _counts?['total'] ?? 0;
    final learned = _counts?['learned'] ?? 0;
    final learning = _counts?['learning'] ?? 0;
    final due = _counts?['due'] ?? 0;
    final newItems = _counts?['new'] ?? 0;

    // El porcentaje del nivel representa únicamente el contenido
    // marcado explícitamente por el usuario como "Aprendida".
    final progress = total == 0 ? 0.0 : learned / total;

    final kanaTotal = _kanaCounts?['total'] ?? 0;
    final kanaLearned = _kanaCounts?['learned'] ?? 0;
    final kanaLearning = _kanaCounts?['learning'] ?? 0;
    final kanaDue = _kanaCounts?['due'] ?? 0;
    final kanaNew = _kanaCounts?['new'] ?? 0;
    final kanaProgress = kanaTotal == 0 ? 0.0 : kanaLearned / kanaTotal;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9FA),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'JLPT Study',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const Text(
              '今日は何を勉強する？',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Estudia Kana o entra al nivel JLPT que quieras trabajar.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),
            const SizedBox(height: 24),
            const Text(
              'Kana',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            _KanaHomeCard(
              progress: kanaProgress,
              total: kanaTotal,
              learned: kanaLearned,
              learning: kanaLearning,
              due: kanaDue,
              newItems: kanaNew,
              onTap: kanaTotal == 0 ? null : _openKana,
            ),
            const SizedBox(height: 26),
            const Text(
              'Niveles JLPT',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _levels.map((level) {
                return ChoiceChip(
                  label: Text(
                    level,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  selected: _selectedLevel == level,
                  onSelected: (_) {
                    if (_selectedLevel == level) return;

                    setState(() {
                      _selectedLevel = level;
                    });

                    _loadCounts();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 36),
                      const SizedBox(height: 12),
                      const Text(
                        'No pude cargar el progreso.',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _loadCounts,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Card(
                elevation: 0,
                color: const Color(0xFFFBE8EE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _selectedLevel,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              icon: Icons.check_circle_rounded,
                              label: 'Aprendidas',
                              value: learned,
                            ),
                          ),
                          Expanded(
                            child: _StatItem(
                              icon: Icons.school_outlined,
                              label: 'Estudiando',
                              value: learning,
                            ),
                          ),
                          Expanded(
                            child: _StatItem(
                              icon: Icons.schedule_rounded,
                              label: 'Repasos',
                              value: due,
                            ),
                          ),
                          Expanded(
                            child: _StatItem(
                              icon: Icons.auto_awesome_rounded,
                              label: 'Nuevas',
                              value: newItems,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$learned de $total elementos marcados como aprendidos',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: total == 0 ? null : _openLevel,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Entrar a $_selectedLevel',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Entra al perfil del nivel para ver el progreso de vocabulario, kanji y gramática, y elegir qué quieres estudiar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KanaHomeCard extends StatelessWidget {
  final double progress;
  final int total;
  final int learned;
  final int learning;
  final int due;
  final int newItems;
  final VoidCallback? onTap;

  const _KanaHomeCard({
    required this.progress,
    required this.total,
    required this.learned,
    required this.learning,
    required this.due,
    required this.newItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE8EE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'あア',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kana',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Hiragana · Katakana · Mix',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CompactStat(label: 'Aprendidas', value: learned),
                  ),
                  Expanded(
                    child: _CompactStat(label: 'Estudiando', value: learning),
                  ),
                  Expanded(
                    child: _CompactStat(label: 'Repasos', value: due),
                  ),
                  Expanded(
                    child: _CompactStat(label: 'Nuevas', value: newItems),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$learned de $total kana aprendidos',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final int value;

  const _CompactStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 21),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
      ],
    );
  }
}
