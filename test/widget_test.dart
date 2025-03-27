import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joy_bites/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Remove the "home" parameter, just call MyApp directly.
    await tester.pumpWidget(const MyApp());
    // Your test expectations here.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
