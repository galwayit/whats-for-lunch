import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/domain/entities/user.dart';
import '../../../lib/domain/entities/user_preferences.dart';
import '../../../lib/domain/repositories/user_repository.dart';
import '../../../lib/presentation/pages/preferences_page.dart';
import '../../../lib/presentation/providers/simple_providers.dart';
import '../../../lib/presentation/providers/user_preferences_provider.dart';

void main() {
  group('PreferencesPage Tests', () {
    testWidgets('should load preferences without infinite loading', (WidgetTester tester) async {
      // Create a ProviderScope with initial state
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => 1),
            simpleUserPreferencesProvider.overrideWith((ref) {
              return SimpleUserPreferencesNotifier()..state = const UserPreferences(
                budgetLevel: 2,
                maxTravelDistance: 5.0,
                includeChains: true,
              );
            }),
          ],
          child: MaterialApp(
            home: const PreferencesPage(),
          ),
        ),
      );

      // Allow async operations to complete
      await tester.pumpAndSettle();

      // Verify that the page loads without showing loading indicator indefinitely
      expect(find.byType(CircularProgressIndicator), findsNothing);
      
      // Verify that the content is shown
      expect(find.text('Budget Preferences'), findsOneWidget);
      expect(find.text('Location Preferences'), findsOneWidget);
      expect(find.text('Restaurant Preferences'), findsOneWidget);
      
      // Verify that budget level controls are present
      expect(find.text('\$\$'), findsOneWidget); // Budget level 2
      
      // Verify that sliders are present
      expect(find.byType(Slider), findsAtLeast(2));
      
      // Verify that the save button is enabled
      final saveButton = find.text('Save');
      expect(saveButton, findsOneWidget);
      
      final saveWidget = tester.widget<TextButton>(
        find.ancestor(of: saveButton, matching: find.byType(TextButton))
      );
      expect(saveWidget.onPressed, isNotNull);
    });

    testWidgets('should handle null preferences gracefully', (WidgetTester tester) async {
      // Test with no existing preferences
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => null),
            simpleUserPreferencesProvider.overrideWith((ref) {
              return SimpleUserPreferencesNotifier()..state = null;
            }),
          ],
          child: MaterialApp(
            home: const PreferencesPage(),
          ),
        ),
      );

      // Show loading initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Allow async operations to complete
      await tester.pumpAndSettle();

      // Should show default preferences after loading
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Budget Preferences'), findsOneWidget);
    });

    testWidgets('should show Save button when preferences are loaded', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => 1),
            simpleUserPreferencesProvider.overrideWith((ref) {
              final notifier = SimpleUserPreferencesNotifier();
              notifier.state = const UserPreferences(
                budgetLevel: 2,
                maxTravelDistance: 5.0,
                includeChains: true,
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: const PreferencesPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the save button is present and enabled
      final saveButton = find.text('Save');
      expect(saveButton, findsOneWidget);
      
      final saveWidget = tester.widget<TextButton>(
        find.ancestor(of: saveButton, matching: find.byType(TextButton))
      );
      expect(saveWidget.onPressed, isNotNull);
    });
  });
}

// Test helper class
class TestUserPreferencesNotifier extends UserPreferencesNotifier {
  final VoidCallback onUpdate;
  
  TestUserPreferencesNotifier(this.onUpdate) : super(TestUserRepository());

  @override
  Future<void> updatePreferences(UserPreferences preferences) async {
    state = preferences;
    onUpdate();
  }
}

// Mock user repository for testing
class TestUserRepository implements UserRepository {
  @override
  Future<int> createUser(UserEntity user) async => 1;

  @override
  Future<UserEntity?> getUserById(int id) async => null;

  @override
  Future<List<UserEntity>> getAllUsers() async => [];

  @override
  Future<bool> updateUser(UserEntity user) async => true;

  @override
  Future<bool> deleteUser(int id) async => true;
}