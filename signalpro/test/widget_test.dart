import 'package:flutter_test/flutter_test.dart';
import 'package:signalpro/app/app.dart';

void main() {
  testWidgets('GoldX shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(const GoldXApp());
    await tester.pumpAndSettle();

    expect(find.text('GoldX'), findsWidgets);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
