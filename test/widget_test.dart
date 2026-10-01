import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jlpt_study/main.dart';
import 'package:jlpt_study/somatome/app_shell.dart';
import 'package:jlpt_study/somatome/progress_service.dart';

void main() {
  testWidgets('JLPT Study launches with unified level selector', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const JLPTStudyApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('JLPT'), findsWidgets);
    expect(find.text('N4'), findsWidgets);
    expect(find.text('N3'), findsWidgets);
  });

  testWidgets('Camino renders the weekly path without locking', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final progress = ProgressService.instance;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CoursePage(progress: progress, onOpen: (_) {}))));
    await tester.pump();

    expect(find.text('Curso'), findsOneWidget);
  });
}
