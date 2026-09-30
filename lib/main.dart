import 'package:flutter/material.dart';
import 'somatome/app_shell.dart';
import 'somatome/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JLPTN3StudyApp());
}

class JLPTN4StudyApp extends StatelessWidget {
  const JLPTN4StudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JLPT N3 Study',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
