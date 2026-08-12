import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

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
      home: const AppSplashScreen(),
    );
  }
}
