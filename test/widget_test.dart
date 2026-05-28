import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/widgets/premium_ui.dart';

void main() {
  testWidgets('PremiumBadge displays text and uses color', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PremiumBadge(text: 'test_badge', color: Colors.blue),
        ),
      ),
    );

    expect(find.text('test_badge'), findsOneWidget);
  });
}
