import 'package:flutter_test/flutter_test.dart';
import 'package:signalpro/app/app.dart';

void main() {
  testWidgets('SignalPro shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SignalProApp());
    await tester.pumpAndSettle();

    expect(find.text('SignalPro'), findsWidgets);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
