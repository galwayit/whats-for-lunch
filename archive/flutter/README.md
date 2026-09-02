# What We Have For Lunch

An AI-powered Flutter mobile app that revolutionizes dining decisions through personalized restaurant recommendations based on dietary preferences, budget constraints, and real-time location data.

## Project Status

**Current Stage**: Stage 1 (Foundation) - 85% Complete  
**Next Milestone**: Complete compilation fixes and begin Stage 2 (Diet Tracking)

### Completed Features
- ✅ Complete database schema with Drift ORM
- ✅ User preference management with JSON storage
- ✅ Repository pattern with comprehensive CRUD operations
- ✅ Accessible UX component library
- ✅ Comprehensive test suite (18+ tests passing)
- ✅ Clean Architecture with domain/data/presentation separation

## Prerequisites

- Flutter SDK 3.5.4 or later
- Dart SDK 3.5.4 or later
- Android Studio with Android SDK (for Android development)
- Xcode (for iOS development on macOS)

## Setup Instructions

### 1. Clone Repository
```bash
git clone <repository-url>
cd what_we_have_for_lunch
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Database Code
```bash
dart run build_runner build
```

### 4. Run Tests
```bash
flutter test
```

### 5. Run Application
```bash
# For development
flutter run

# For release build
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## Project Structure

```
lib/
├── core/                    # Core application utilities
│   ├── constants/          # App-wide constants and routes
│   ├── theme/              # Material Design 3 theme configuration
│   └── utils/              # Utility functions and helpers
│
├── data/                    # Data layer implementation
│   ├── database/           # Drift database implementation
│   │   ├── database.dart   # Database schema and operations
│   │   └── database.g.dart # Generated Drift code
│   └── repositories/       # Repository implementations
│       ├── budget_repository_impl.dart
│       ├── meal_repository_impl.dart
│       ├── restaurant_repository_impl.dart
│       └── user_repository_impl.dart
│
├── domain/                  # Business logic layer
│   ├── entities/           # Domain models
│   │   ├── budget_tracking.dart
│   │   ├── meal.dart
│   │   ├── restaurant.dart
│   │   ├── user.dart
│   │   └── user_preferences.dart
│   └── repositories/       # Repository interfaces
│       ├── budget_repository.dart
│       ├── meal_repository.dart
│       ├── restaurant_repository.dart
│       └── user_repository.dart
│
├── presentation/           # UI layer
│   ├── pages/             # Screen implementations
│   │   ├── discover_page.dart
│   │   ├── home_page.dart
│   │   ├── hungry_page.dart
│   │   ├── onboarding_page.dart
│   │   ├── preferences_page.dart
│   │   ├── profile_page.dart
│   │   └── track_page.dart
│   ├── providers/         # Riverpod state management
│   │   ├── database_provider.dart
│   │   ├── router_provider.dart
│   │   ├── simple_providers.dart
│   │   └── user_preferences_provider.dart
│   └── widgets/           # Reusable UI components
│       ├── main_scaffold.dart
│       └── ux_components.dart
│
└── main.dart              # Application entry point
```

## Testing

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/data/database/database_test.dart
```

### Test Coverage
The project includes comprehensive testing for:
- Database operations (CRUD for all entities)
- User preference management
- Entity conversion between domain and database layers
- Repository pattern implementation

## Key Dependencies

### Core Dependencies
- **flutter_riverpod**: State management and dependency injection
- **drift**: Type-safe database ORM with code generation
- **go_router**: Declarative routing solution
- **geolocator**: Location services (for future stages)
- **dio**: HTTP client for API integration
- **cached_network_image**: Optimized image loading

### Development Dependencies
- **flutter_test**: Testing framework
- **drift_dev**: Code generation for Drift
- **build_runner**: Build system for code generation
- **flutter_lints**: Dart/Flutter linting rules

## Database Schema

### Tables
- **users**: User profiles with JSON preferences
- **meals**: Meal logging with restaurant association  
- **budget_trackings**: Budget management with categories
- **restaurants**: Restaurant data caching

### Key Features
- Foreign key relationships for data integrity
- JSON storage for flexible user preferences
- Optimized queries for date range filtering
- In-memory database support for testing

## Architecture Patterns

### Clean Architecture
- **Domain Layer**: Business logic and entities
- **Data Layer**: Database and repository implementations
- **Presentation Layer**: UI components and state management

### Repository Pattern
- Abstract interfaces in domain layer
- Concrete implementations in data layer
- Dependency injection through Riverpod providers

### State Management
- Riverpod for dependency injection and state management
- Repository pattern for data access abstraction
- Reactive UI updates through provider listeners

## UX Component Library

### Accessible Components
All UI components follow WCAG 2.1 accessibility guidelines:
- **UXPrimaryButton**: Main CTAs with loading states
- **UXSecondaryButton**: Secondary actions with haptic feedback
- **UXTextInput**: Form inputs with validation
- **UXProgressIndicator**: Onboarding progress tracking
- **UXLoadingOverlay**: Non-blocking loading states
- **UXErrorState**: Consistent error handling
- **UXCard**: Accessible container components

### Design Principles
- 44px minimum touch targets for mobile accessibility
- Haptic feedback for all interactive elements
- Semantic labeling for screen readers
- Material Design 3 theming with dynamic colors

## Known Issues

### Compilation Issues
1. **Geolocator Plugin**: Android configuration conflicts requiring Gradle updates
2. **SDK Compatibility**: Minor dependency version updates needed

### Test Issues
1. **Timer Disposal**: UXFadeIn component timer management in test environment

### Resolution Status
These issues are currently being addressed and will be resolved before Stage 2 begins.

## Development Guidelines

### Code Quality
- Follow Clean Architecture principles
- Comprehensive test coverage for new features
- Accessible-first UI component development
- Type-safe database operations through Drift

### Performance Standards
- App launch time: < 3 seconds
- Database queries: < 10ms for common operations
- UI animations: 60 FPS with proper lifecycle management
- Memory usage: Optimized for large meal datasets

## API Integration (Future Stages)

### Planned Integrations
- **Google Maps Platform**: Restaurant discovery and location services
- **Google Gemini**: AI-powered recommendation engine
- **Places API**: Restaurant details and reviews

### Cost Optimization
- Aggressive local caching (24-hour expiry)
- Batch processing for AI recommendations
- Rate limiting and request debouncing
- Offline-first architecture with graceful degradation

## Contributing

1. Follow the established architecture patterns
2. Write tests for all new functionality
3. Ensure accessibility compliance for UI components
4. Document technical decisions in TECHNICAL_DECISIONS.md
5. Update this README for any setup changes

## Documentation

- **PROJECT_SUMMARY.md**: Executive overview and market analysis
- **IMPLEMENTATION_PLAN.md**: Detailed development roadmap
- **TECHNICAL_DECISIONS.md**: Architecture and design decisions
- **RELEASE_NOTES.md**: Version history and deliverables

## Support

For development questions or technical issues, refer to:
- Flutter documentation: https://docs.flutter.dev/
- Drift documentation: https://drift.simonbinder.eu/
- Riverpod documentation: https://riverpod.dev/

---

**Last Updated**: Stage 1 Development Completion  
**Project Timeline**: 16-20 weeks total development  
**Current Phase**: Foundation & Core Infrastructure
