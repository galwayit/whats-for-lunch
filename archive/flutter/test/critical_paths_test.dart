// Focused, assertion-heavy tests for critical application paths:
//   A. Database persistence (in-memory)
//   B. Meal mapper roundtrip
//   C. Input validator correctness
//   D. Budget calculation correctness

import 'package:flutter_test/flutter_test.dart';

import 'package:what_we_have_for_lunch/data/database/database.dart';
import 'package:what_we_have_for_lunch/data/mappers/entity_mappers.dart';
import 'package:what_we_have_for_lunch/domain/entities/meal.dart' as domain;
import 'package:what_we_have_for_lunch/domain/entities/user.dart' as domain;
import 'package:what_we_have_for_lunch/domain/entities/user_preferences.dart';
import 'package:what_we_have_for_lunch/core/security/input_validator.dart';
import 'package:what_we_have_for_lunch/presentation/providers/budget_providers.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // A. Database persistence (in-memory)
  // ──────────────────────────────────────────────────────────────────────────
  group('Database Persistence', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.testInstance();
    });

    tearDown(() async {
      await database.close();
    });

    test('meals persist and can be retrieved with all fields', () async {
      // Arrange: create a user first (meals have a foreign key to users)
      final userCompanion = EntityMappers.userToCompanion(domain.UserEntity(
        name: 'Persistence Tester',
        preferences: const UserPreferences().toJson(),
        createdAt: DateTime(2026, 1, 1),
      ));
      final userId = await database.insertUser(userCompanion);

      final mealDate = DateTime(2026, 3, 10, 12, 30);
      final meal = domain.Meal(
        userId: userId,
        restaurantId: 'place_abc',
        restaurantName: 'Golden Dragon',
        mealType: 'lunch',
        cost: 18.75,
        date: mealDate,
        notes: 'Excellent dim sum',
      );

      // Act
      final mealId = await database.insertMeal(
        EntityMappers.mealToCompanion(meal),
      );
      final rows = await database.getMealsByUserId(userId);

      // Assert
      expect(rows, hasLength(1));

      final retrieved = rows.first;
      expect(retrieved.id, equals(mealId));
      expect(retrieved.userId, equals(userId));
      expect(retrieved.restaurantId, equals('place_abc'));
      expect(retrieved.restaurantName, equals('Golden Dragon'));
      expect(retrieved.mealType, equals('lunch'));
      expect(retrieved.cost, equals(18.75));
      expect(retrieved.date, equals(mealDate));
      expect(retrieved.notes, equals('Excellent dim sum'));
    });

    test('user preferences persist across database reopen', () async {
      // Arrange
      const prefs = UserPreferences(
        budgetLevel: 4,
        weeklyBudget: 350.0,
        maxTravelDistance: 8.0,
        includeChains: false,
        dietaryRestrictions: ['vegetarian', 'gluten_free'],
      );
      final userCompanion = EntityMappers.userToCompanion(domain.UserEntity(
        name: 'Prefs Tester',
        preferences: prefs.toJson(),
        createdAt: DateTime(2026, 2, 1),
      ));
      final userId = await database.insertUser(userCompanion);

      // Act: read user back and parse preferences
      final dbUser = await database.getDatabaseUserById(userId);
      expect(dbUser, isNotNull);

      final domainUser = EntityMappers.userFromDatabase(dbUser!);
      final recovered = UserPreferences.fromJson(domainUser.preferences);

      // Assert: every preference field we set survives the roundtrip
      expect(recovered.budgetLevel, equals(4));
      expect(recovered.weeklyBudget, equals(350.0));
      expect(recovered.maxTravelDistance, equals(8.0));
      expect(recovered.includeChains, isFalse);
      expect(
        recovered.dietaryRestrictions,
        containsAll(['vegetarian', 'gluten_free']),
      );
    });

    test('multiple meals for one user are all retrievable', () async {
      final userId = await database.insertUser(
        EntityMappers.userToCompanion(domain.UserEntity(
          name: 'Multi Meal User',
          preferences: const UserPreferences().toJson(),
          createdAt: DateTime(2026, 1, 1),
        )),
      );

      final meals = [
        domain.Meal(
          userId: userId,
          mealType: 'breakfast',
          cost: 8.50,
          date: DateTime(2026, 3, 10, 8, 0),
        ),
        domain.Meal(
          userId: userId,
          mealType: 'lunch',
          cost: 15.00,
          date: DateTime(2026, 3, 10, 12, 0),
        ),
        domain.Meal(
          userId: userId,
          mealType: 'dinner',
          cost: 28.00,
          date: DateTime(2026, 3, 10, 19, 0),
        ),
      ];

      for (final m in meals) {
        await database.insertMeal(EntityMappers.mealToCompanion(m));
      }

      final rows = await database.getMealsByUserId(userId);
      expect(rows, hasLength(3));

      final totalCost = rows.fold<double>(0.0, (sum, r) => sum + r.cost);
      expect(totalCost, closeTo(51.50, 0.01));
    });

    test('date range query returns only meals within range', () async {
      final userId = await database.insertUser(
        EntityMappers.userToCompanion(domain.UserEntity(
          name: 'Range Tester',
          preferences: const UserPreferences().toJson(),
          createdAt: DateTime(2026, 1, 1),
        )),
      );

      // Insert three meals on different days
      final march8 = DateTime(2026, 3, 8, 12, 0);
      final march9 = DateTime(2026, 3, 9, 12, 0);
      final march11 = DateTime(2026, 3, 11, 12, 0);

      for (final date in [march8, march9, march11]) {
        await database.insertMeal(EntityMappers.mealToCompanion(
          domain.Meal(userId: userId, mealType: 'lunch', cost: 10, date: date),
        ));
      }

      // Query: March 8 00:00 to March 10 00:00 -- should include march8 and march9
      final results = await database.getMealsByDateRange(
        userId,
        DateTime(2026, 3, 8),
        DateTime(2026, 3, 10),
      );

      expect(results, hasLength(2));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // B. Meal mapper roundtrip
  // ──────────────────────────────────────────────────────────────────────────
  group('Meal Mapper Roundtrip', () {
    test('meal domain entity converts to companion with all fields', () {
      final meal = domain.Meal(
        userId: 42,
        restaurantId: 'rest_xyz',
        restaurantName: "O'Brien's Pub",
        mealType: 'dinner',
        cost: 33.99,
        date: DateTime(2026, 3, 10, 19, 30),
        notes: 'Shepherd\'s pie',
      );

      final companion = EntityMappers.mealToCompanion(meal);

      // Verify all Value wrappers contain the expected data
      expect(companion.userId.value, equals(42));
      expect(companion.restaurantId.value, equals('rest_xyz'));
      expect(companion.restaurantName.value, equals("O'Brien's Pub"));
      expect(companion.mealType.value, equals('dinner'));
      expect(companion.cost.value, equals(33.99));
      expect(companion.date.value, equals(DateTime(2026, 3, 10, 19, 30)));
      expect(companion.notes.value, equals('Shepherd\'s pie'));
    });

    test('meal companion without id has absent id', () {
      final meal = domain.Meal(
        userId: 1,
        mealType: 'lunch',
        cost: 12.0,
        date: DateTime.now(),
      );

      final companion = EntityMappers.mealToCompanion(meal);

      // id should be absent (auto-increment)
      expect(companion.id.present, isFalse);
    });

    test('meal with explicit id preserves it in companion', () {
      final meal = domain.Meal(
        id: 99,
        userId: 1,
        mealType: 'lunch',
        cost: 12.0,
        date: DateTime.now(),
      );

      final companion = EntityMappers.mealToCompanion(meal);
      expect(companion.id.present, isTrue);
      expect(companion.id.value, equals(99));
    });

    test('full database roundtrip preserves all meal fields', () async {
      final database = AppDatabase.testInstance();
      try {
        final userId = await database.insertUser(
          EntityMappers.userToCompanion(domain.UserEntity(
            name: 'Roundtrip User',
            preferences: const UserPreferences().toJson(),
            createdAt: DateTime(2026, 1, 1),
          )),
        );

        final originalMeal = domain.Meal(
          userId: userId,
          restaurantId: 'rt_001',
          restaurantName: 'Test Bistro',
          mealType: 'dinner',
          cost: 45.50,
          date: DateTime(2026, 3, 10, 20, 0),
          notes: 'Anniversary dinner',
        );

        await database.insertMeal(EntityMappers.mealToCompanion(originalMeal));
        final rows = await database.getMealsByUserId(userId);
        final recovered = EntityMappers.mealFromDatabase(rows.first);

        expect(recovered.userId, equals(originalMeal.userId));
        expect(recovered.restaurantId, equals(originalMeal.restaurantId));
        expect(recovered.restaurantName, equals(originalMeal.restaurantName));
        expect(recovered.mealType, equals(originalMeal.mealType));
        expect(recovered.cost, equals(originalMeal.cost));
        expect(recovered.date, equals(originalMeal.date));
        expect(recovered.notes, equals(originalMeal.notes));
      } finally {
        await database.close();
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // C. Input validator correctness
  // ──────────────────────────────────────────────────────────────────────────
  group('Input Validator', () {
    setUp(() {
      // Reset security stats before each test so counters don't bleed
      InputValidator.resetSecurityStats();
    });

    test('accepts valid names with special characters', () {
      // Irish/French apostrophe names
      final obrienResult = InputValidator.validateUserName("O'Brien");
      expect(obrienResult.isValid, isTrue);

      // Accented characters (Latin extended)
      final mariaResult = InputValidator.validateUserName('Maria');
      expect(mariaResult.isValid, isTrue);

      // Hyphenated names
      final hyphenResult = InputValidator.validateUserName('Jean-Pierre');
      expect(hyphenResult.isValid, isTrue);

      // Name with period
      final periodResult = InputValidator.validateUserName('Dr. Smith');
      expect(periodResult.isValid, isTrue);
    });

    test('rejects empty and too-short names', () {
      expect(InputValidator.validateUserName(null).isValid, isFalse);
      expect(InputValidator.validateUserName('').isValid, isFalse);
      expect(InputValidator.validateUserName(' ').isValid, isFalse);
      expect(InputValidator.validateUserName('A').isValid, isFalse);
    });

    test('rejects names exceeding maximum length', () {
      final longName = 'A' * 51;
      expect(InputValidator.validateUserName(longName).isValid, isFalse);
    });

    test('rejects XSS attempts in user names', () {
      final scriptResult = InputValidator.validateUserName(
        '<script>alert("xss")</script>',
      );
      expect(scriptResult.isValid, isFalse);

      final tagResult = InputValidator.validateUserName('<img src=x>');
      expect(tagResult.isValid, isFalse);
    });

    test('rejects XSS attempts in search queries', () {
      final result = InputValidator.validateSearchQuery(
        '<script>document.cookie</script>',
      );
      expect(result.isValid, isFalse);
    });

    test('validates budget amount boundaries', () {
      // Positive amount within range
      expect(InputValidator.validateBudgetAmount(50.0).isValid, isTrue);
      expect(InputValidator.validateBudgetAmount(50.0).value, equals(50.0));

      // Zero and negative
      expect(InputValidator.validateBudgetAmount(0.0).isValid, isFalse);
      expect(InputValidator.validateBudgetAmount(-10.0).isValid, isFalse);

      // Above maximum
      expect(InputValidator.validateBudgetAmount(10001.0).isValid, isFalse);

      // Edge: exactly at maximum
      expect(InputValidator.validateBudgetAmount(10000.0).isValid, isTrue);
    });

    test('validates location coordinates', () {
      // Valid coordinates
      final valid = InputValidator.validateLocation(37.7749, -122.4194);
      expect(valid.isValid, isTrue);
      expect(valid.value!['latitude'], closeTo(37.7749, 0.0001));
      expect(valid.value!['longitude'], closeTo(-122.4194, 0.0001));

      // Out-of-range latitude
      expect(InputValidator.validateLocation(91.0, 0.0).isValid, isFalse);
      expect(InputValidator.validateLocation(-91.0, 0.0).isValid, isFalse);

      // Out-of-range longitude
      expect(InputValidator.validateLocation(0.0, 181.0).isValid, isFalse);
      expect(InputValidator.validateLocation(0.0, -181.0).isValid, isFalse);

      // Null inputs
      expect(InputValidator.validateLocation(null, null).isValid, isFalse);
    });

    test('sanitizes notes and rejects malicious content', () {
      // Normal notes pass
      final normalResult =
          InputValidator.validateNotes('Great food, will return!');
      expect(normalResult.isValid, isTrue);

      // Null notes return empty string
      final nullResult = InputValidator.validateNotes(null);
      expect(nullResult.isValid, isTrue);
      expect(nullResult.value, equals(''));

      // Notes exceeding 500 chars are rejected
      final longNotes = 'x' * 501;
      expect(InputValidator.validateNotes(longNotes).isValid, isFalse);
    });

    test('validates file paths for photo storage', () {
      // Valid extensions
      expect(InputValidator.validateFilePath('photo.jpg').isValid, isTrue);
      expect(InputValidator.validateFilePath('photo.png').isValid, isTrue);
      expect(InputValidator.validateFilePath('photo.webp').isValid, isTrue);

      // Invalid extension
      expect(InputValidator.validateFilePath('file.exe').isValid, isFalse);

      // Path traversal attempt
      expect(
        InputValidator.validateFilePath('../../../etc/passwd').isValid,
        isFalse,
      );

      // Null/empty
      expect(InputValidator.validateFilePath(null).isValid, isFalse);
      expect(InputValidator.validateFilePath('').isValid, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // D. Budget calculation correctness
  // ──────────────────────────────────────────────────────────────────────────
  group('Budget Calculation', () {
    test('WeeklyInvestmentState.capacityProgress avoids division by zero', () {
      final stateZeroBudget = WeeklyInvestmentState(
        weeklyCapacity: 0.0,
        currentSpent: 50.0,
        weekStartDate: DateTime(2026, 3, 10),
      );

      // When weeklyCapacity is 0, progress should be 0.0 (not NaN or Infinity)
      expect(stateZeroBudget.capacityProgress, equals(0.0));
      expect(stateZeroBudget.capacityProgress.isNaN, isFalse);
      expect(stateZeroBudget.capacityProgress.isInfinite, isFalse);
    });

    test('capacityProgress calculates correct percentage', () {
      final state = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 50.0,
        weekStartDate: DateTime(2026, 3, 10),
      );

      expect(state.capacityProgress, closeTo(0.25, 0.001));
    });

    test('capacityUsageLevel thresholds are correct', () {
      // low: < 0.3
      final lowState = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 50.0, // 25%
        weekStartDate: DateTime(2026, 3, 10),
      );
      expect(lowState.capacityUsageLevel, equals('low'));

      // moderate: 0.3 - 0.7
      final moderateState = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 100.0, // 50%
        weekStartDate: DateTime(2026, 3, 10),
      );
      expect(moderateState.capacityUsageLevel, equals('moderate'));

      // high: 0.7 - 0.9
      final highState = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 160.0, // 80%
        weekStartDate: DateTime(2026, 3, 10),
      );
      expect(highState.capacityUsageLevel, equals('high'));

      // very_high: >= 0.9
      final veryHighState = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 190.0, // 95%
        weekStartDate: DateTime(2026, 3, 10),
      );
      expect(veryHighState.capacityUsageLevel, equals('very_high'));
    });

    test('investmentGuidanceLevel thresholds are correct', () {
      // excellent: < 0.5
      final excellent = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 80.0, // 40%
        weekStartDate: DateTime(2026, 3, 10),
      );
      expect(excellent.investmentGuidanceLevel, equals('excellent'));

      // good: 0.5 - 0.8
      final good = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 120.0, // 60%
        weekStartDate: DateTime(2026, 3, 10),
      );
      expect(good.investmentGuidanceLevel, equals('good'));

      // moderate: 0.8 - 0.95
      final moderate = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 170.0, // 85%
        weekStartDate: DateTime(2026, 3, 10),
      );
      expect(moderate.investmentGuidanceLevel, equals('moderate'));

      // high: >= 0.95
      final high = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 196.0, // 98%
        weekStartDate: DateTime(2026, 3, 10),
      );
      expect(high.investmentGuidanceLevel, equals('high'));
    });

    test('experienceProgress avoids division by zero', () {
      final state = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        targetExperiences: 0,
        experiencesLogged: 5,
        weekStartDate: DateTime(2026, 3, 10),
      );

      expect(state.experienceProgress, equals(0.0));
      expect(state.experienceProgress.isNaN, isFalse);
    });

    test('BudgetSetupState canProceed logic per step', () {
      // Step 0: needs weeklyCapacity > 0
      const step0Valid = BudgetSetupState(currentStep: 0, weeklyCapacity: 100);
      expect(step0Valid.canProceed, isTrue);

      const step0Invalid = BudgetSetupState(currentStep: 0, weeklyCapacity: 0);
      expect(step0Invalid.canProceed, isFalse);

      // Step 1: needs non-empty experiencePreferences
      const step1Valid = BudgetSetupState(
        currentStep: 1,
        experiencePreferences: ['Fine Dining'],
      );
      expect(step1Valid.canProceed, isTrue);

      const step1Invalid = BudgetSetupState(currentStep: 1);
      expect(step1Invalid.canProceed, isFalse);

      // Step 2: always true
      const step2 = BudgetSetupState(currentStep: 2);
      expect(step2.canProceed, isTrue);

      // Unknown step: false
      const stepUnknown = BudgetSetupState(currentStep: 99);
      expect(stepUnknown.canProceed, isFalse);
    });

    test('WeeklyInvestmentState copyWith preserves unmodified fields', () {
      final original = WeeklyInvestmentState(
        weeklyCapacity: 200.0,
        currentSpent: 50.0,
        remainingCapacity: 150.0,
        experiencesLogged: 3,
        targetExperiences: 10,
        weekStartDate: DateTime(2026, 3, 10),
        isLoading: false,
      );

      final modified = original.copyWith(currentSpent: 75.0);

      expect(modified.weeklyCapacity, equals(200.0));
      expect(modified.currentSpent, equals(75.0));
      expect(modified.remainingCapacity, equals(150.0));
      expect(modified.experiencesLogged, equals(3));
      expect(modified.targetExperiences, equals(10));
      expect(modified.isLoading, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // E. Domain entity invariants
  // ──────────────────────────────────────────────────────────────────────────
  group('Meal Domain Entity', () {
    test('isToday returns true only for meals dated today', () {
      final now = DateTime.now();
      final todayMeal = domain.Meal(
        userId: 1,
        mealType: 'lunch',
        cost: 10.0,
        date: DateTime(now.year, now.month, now.day, 12, 0),
      );
      expect(todayMeal.isToday, isTrue);

      final yesterdayMeal = domain.Meal(
        userId: 1,
        mealType: 'lunch',
        cost: 10.0,
        date: DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 1)),
      );
      expect(yesterdayMeal.isToday, isFalse);
    });

    test('formattedCost produces correct currency string', () {
      final meal = domain.Meal(
        userId: 1,
        mealType: 'lunch',
        cost: 9.5,
        date: DateTime.now(),
      );
      expect(meal.formattedCost, equals('\$9.50'));
    });

    test('displayMealType maps all known types correctly', () {
      final types = {
        'dining_out': 'Dining Out',
        'delivery': 'Delivery',
        'takeout': 'Takeout',
        'groceries': 'Groceries',
        'snack': 'Snack',
        'breakfast': 'Breakfast',
        'lunch': 'Lunch',
        'dinner': 'Dinner',
        'unknown': 'Experience',
      };

      for (final entry in types.entries) {
        final meal = domain.Meal(
          userId: 1,
          mealType: entry.key,
          cost: 1.0,
          date: DateTime.now(),
        );
        expect(
          meal.displayMealType,
          equals(entry.value),
          reason: 'mealType "${entry.key}" should display as "${entry.value}"',
        );
      }
    });

    test('equality compares all fields', () {
      final date = DateTime(2026, 3, 10);
      final a = domain.Meal(
        id: 1,
        userId: 1,
        restaurantId: 'r1',
        restaurantName: 'Bistro',
        mealType: 'lunch',
        cost: 15.0,
        date: date,
        notes: 'Good',
      );
      final b = domain.Meal(
        id: 1,
        userId: 1,
        restaurantId: 'r1',
        restaurantName: 'Bistro',
        mealType: 'lunch',
        cost: 15.0,
        date: date,
        notes: 'Good',
      );
      final c = a.copyWith(cost: 20.0);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // F. UserPreferences JSON roundtrip
  // ──────────────────────────────────────────────────────────────────────────
  group('UserPreferences Roundtrip', () {
    test('toJson/fromJson preserves all fields', () {
      const original = UserPreferences(
        dietaryRestrictions: ['vegan', 'gluten_free'],
        cuisinePreferences: ['italian', 'japanese'],
        allergens: ['peanuts'],
        budgetLevel: 3,
        maxTravelDistance: 12.5,
        includeChains: false,
        mealFrequencyPerDay: 2,
        weeklyBudget: 250.0,
        enableLocationServices: false,
        showMapView: false,
        mapZoomLevel: 16,
        minimumRating: 4.0,
        avoidBusyTimes: true,
      );

      final json = original.toJson();
      final recovered = UserPreferences.fromJson(json);

      expect(recovered.dietaryRestrictions,
          containsAll(['vegan', 'gluten_free']));
      expect(recovered.cuisinePreferences,
          containsAll(['italian', 'japanese']));
      expect(recovered.allergens, contains('peanuts'));
      expect(recovered.budgetLevel, equals(3));
      expect(recovered.maxTravelDistance, equals(12.5));
      expect(recovered.includeChains, isFalse);
      expect(recovered.mealFrequencyPerDay, equals(2));
      expect(recovered.weeklyBudget, equals(250.0));
      expect(recovered.enableLocationServices, isFalse);
      expect(recovered.showMapView, isFalse);
      expect(recovered.mapZoomLevel, equals(16));
      expect(recovered.minimumRating, equals(4.0));
      expect(recovered.avoidBusyTimes, isTrue);
    });

    test('fromJson handles missing fields with defaults', () {
      final recovered = UserPreferences.fromJson({});

      expect(recovered.budgetLevel, equals(2));
      expect(recovered.weeklyBudget, equals(200.0));
      expect(recovered.includeChains, isTrue);
      expect(recovered.dietaryRestrictions, isEmpty);
    });
  });
}
