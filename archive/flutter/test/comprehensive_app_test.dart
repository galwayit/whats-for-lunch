// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:what_we_have_for_lunch/main.dart';

/// Comprehensive app tests -- converted from integration-test-binding
/// reporting tests to proper widget tests with real assertions.
///
/// The original file used IntegrationTestWidgetsFlutterBinding which is
/// inappropriate for `flutter test` (unit/widget tests). The first test
/// also unconditionally tapped `find.text('Next').first` which crashes
/// if the widget is absent. Both issues are now fixed.
///
/// Uses `pump()` instead of `pumpAndSettle()` because the app has periodic
/// timers that prevent pumpAndSettle from completing.
void main() {
  group('Comprehensive App Testing', () {
    testWidgets('App renders an initial screen without exceptions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pump(const Duration(seconds: 1));

      // Must have at least a Scaffold and no rendering exceptions
      expect(find.byType(Scaffold), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('UI components include MaterialApp and Scaffold',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('No rendering exceptions during initial load',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });

    testWidgets('ProviderScope is present at root',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ProviderScope), findsOneWidget);
    });
  });

  group('Performance Tests', () {
    testWidgets('No exceptions after multiple pump cycles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MyApp()),
      );
      await tester.pump(const Duration(seconds: 1));

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(tester.takeException(), isNull);
    });
  });
}
