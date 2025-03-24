import 'package:flutter_test/flutter_test.dart';
import 'package:joy_bites/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('JoyBites'), findsOneWidget);
  });
}