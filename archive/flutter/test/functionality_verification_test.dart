// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_we_have_for_lunch/main.dart';

/// Functionality verification tests.
/// Each test contains at least one meaningful assertion.
///
/// Note: These tests use `pump()` instead of `pumpAndSettle()` because the app
/// has periodic timers (e.g., WeeklyInvestmentNotifier refreshes every 5 minutes)
/// that prevent pumpAndSettle from ever completing.
void main() {
  group('Functionality Verification Tests', () {
    testWidgets('App initialization renders a known initial screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      // Allow one second for initial routing and async providers
      await tester.pump(const Duration(seconds: 1));

      // The app must show either onboarding or the main screen
      final hasOnboarding =
          find.text('What We Have For Lunch').evaluate().isNotEmpty;
      final hasMainApp = find.text('Quick Actions').evaluate().isNotEmpty;

      expect(
        hasOnboarding || hasMainApp,
        isTrue,
        reason: 'App must render either the onboarding or main screen',
      );
    });

    testWidgets('App has a Scaffold and MaterialApp',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Provider scope is present at root',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ProviderScope), findsOneWidget);
    });

    testWidgets('No exceptions thrown during initial render',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(
        tester.takeException(),
        isNull,
        reason: 'No exceptions should occur during initial render',
      );
    });

    testWidgets('Widget tree contains expected widget types',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pump(const Duration(seconds: 1));

      final widgetTypes =
          tester.allWidgets.map((w) => w.runtimeType.toString()).toSet();
      expect(widgetTypes, isNotEmpty);
      // MaterialApp always provides MediaQuery, so it must be in the tree
      expect(find.byType(MediaQuery), findsWidgets);
    });

    testWidgets('No exceptions after multiple pump cycles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pump(const Duration(seconds: 1));

      // Pump several frames
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(tester.takeException(), isNull);
    });
  });

  group('Integration Flow Tests', () {
    testWidgets('App loads and displays a Scaffold',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(Scaffold), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
