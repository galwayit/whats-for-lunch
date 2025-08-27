// Widget tests for the What We Have For Lunch app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_we_have_for_lunch/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify that the app loads without error.
    // The app should have the MaterialApp with router configured.
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App has correct title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Allow animations to complete
    await tester.pumpAndSettle();

    // The app should be configured with the correct title.
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, equals('What We Have For Lunch'));
  });
}
