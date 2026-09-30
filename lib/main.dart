import 'package:flutter/material.dart';
import 'somatome/app_shell.dart';
import 'somatome/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JLPTStudyApp());
}

class JLPTStudyApp extends StatelessWidget {
  const JLPTStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JLPT Study',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
