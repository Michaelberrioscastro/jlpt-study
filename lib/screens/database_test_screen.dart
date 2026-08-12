import 'package:flutter/material.dart';

import '../models/study_item.dart';
import '../services/database_service.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  bool loading = true;
  String? error;

  List<StudyItem> items = [];
  Map<String, int> counts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loadedItems = await DatabaseService.getItemsByLevel('N5');

      final loadedCounts = await DatabaseService.getN5Counts();

      if (!mounted) return;

      setState(() {
        items = loadedItems;
        counts = loadedCounts;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JLPT Study · Database Test')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Text('ERROR\n\n$error'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Base N5 cargada 🌸',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Vocabulario: ${counts['vocab'] ?? 0}'),
                          Text('Kanji: ${counts['kanji'] ?? 0}'),
                          Text('Gramática: ${counts['grammar'] ?? 0}'),
                          Text(
                            'TOTAL: ${items.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return ListTile(
                        title: Text(item.front),
                        subtitle: Text(
                          [
                            item.type,
                            item.reading,
                            item.meaning,
                          ].where((value) => value.isNotEmpty).join(' · '),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
