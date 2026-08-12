import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/home_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE9A5B6)),
        scaffoldBackgroundColor: const Color(0xFFFFF9FA),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
