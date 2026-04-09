import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:igloo_dio_logger_example/main.dart';

void main() {
  testWidgets('App renders with correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Igloo Dio Logger'), findsOneWidget);
  });

  testWidgets('All action buttons are visible', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.textContaining('GET /posts/1'), findsOneWidget);
    expect(find.textContaining('Items count'), findsOneWidget);
    expect(find.textContaining('Query params'), findsOneWidget);
    expect(find.textContaining('POST /posts/add'), findsWidgets);
    expect(find.textContaining('cURL'), findsOneWidget);
    expect(find.textContaining('404'), findsOneWidget);
  });

  testWidgets('Status text shows initial instruction', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.textContaining('Press a button'), findsOneWidget);
  });

  testWidgets('All buttons are enabled', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final buttons = tester
        .widgetList<ElevatedButton>(find.byType(ElevatedButton))
        .toList();

    expect(buttons, isNotEmpty);
    for (final button in buttons) {
      expect(button.onPressed, isNotNull);
    }
  });
}
