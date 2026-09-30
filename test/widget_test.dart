import 'package:flutter_test/flutter_test.dart';
import 'package:jlpt_study/main.dart';

void main() {
  testWidgets('JLPT Study launches with unified level selector', (WidgetTester tester) async {
    await tester.pumpWidget(const JLPTStudyApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('JLPT'), findsWidgets);
    expect(find.text('N4'), findsWidgets);
    expect(find.text('N3'), findsWidgets);
  });
}
