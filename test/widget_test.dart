import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy_bites/main.dart';
import 'package:joy_bites/screens/entry_screen.dart';

void main() {
  testWidgets('MyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(home: EntryScreen()));
    expect(find.byType(MyApp), findsOneWidget);
  });
}
