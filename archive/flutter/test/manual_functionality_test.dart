// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_we_have_for_lunch/main.dart';

/// Manual functionality tests -- converted from print-only reporting
/// to assertion-based verification.
///
/// Uses `pump()` instead of `pumpAndSettle()` because the app has periodic
/// timers that prevent pumpAndSettle from completing.
void main() {
  group('Manual Functionality Tests', () {
    testWidgets('App launches and shows a valid initial screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pump(const Duration(seconds: 1));

      // Verify at least one of the known initial screens appears
      final hasOnboarding =
          find.text('What We Have For Lunch').evaluate().isNotEmpty;
      final hasHome = find.text('Hello,').evaluate().isNotEmpty;

      expect(
        hasOnboarding || hasHome,
        isTrue,
        reason: 'App must show either onboarding or home screen',
      );
    });

    testWidgets('Core UI components render properly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(ProviderScope), findsOneWidget);
    });

    testWidgets('No rendering exceptions during startup',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });
  });
}
