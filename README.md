# What We Have For Lunch

Native iOS and Android apps over one Kotlin Multiplatform core, a Supabase backend, and a
usage-limited free tier with a Lunch Pro subscription. Built by iAPP.

The Flutter app that preceded this is kept buildable in `archive/flutter/` and tagged
`flutter-baseline`. The evaluation and the migration playbook that led here are linked from
`archive/flutter/README.md` history and the project notes.

New to the project? Read [HANDOFF.md](HANDOFF.md) after this file.

## Layout

```
shared/        Kotlin Multiplatform core: domain rules, SQLite (same file as the Flutter app),
               backend client, purchases, auth, groups. Consumed by both apps.
androidApp/    Jetpack Compose app (applicationId au.iapp.guess_what.what_we_have_for_lunch)
iosApp/        SwiftUI app (`au.iapp.lunch`) linking the shared LunchCore framework
backend/       Supabase project: migrations, Edge Functions, invitation web page, .well-known files
design/        tokens.json (single source of truth), generate_tokens.py, Stitch reference screens
maestro/       End-to-end flows that run unchanged on iOS and Android
archive/       The Flutter app and its documents, frozen
```

## Toolchain

- JDK 21 (`export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home`)
- Gradle 8.14.4 via `./gradlew`; Android SDK path in `local.properties`
- Xcode 27 (Swift 6.4) for `iosApp`
- Deno 2 for backend checks and tests; Supabase CLI for deploys

Kotlin, SKIE, RevenueCat and the Xcode package pin move as one chain. Read `HANDOFF.md`
before changing any of them.

## Everyday commands

```bash
./gradlew :shared:desktopTest                       # core rules and SQLite on the JVM
./gradlew :shared:testDebugUnitTest                 # core on Android
./gradlew :androidApp:assembleDebug                 # Android app
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64   # LunchCore for the iOS simulator
xcodebuild -project iosApp/LunchApp.xcodeproj -scheme LunchApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
cd backend && make check && make test               # backend
python3 design/generate_tokens.py                   # after editing design/tokens.json
```

## Configuration and secrets

Apps read their configuration from generated files that are not committed:

- `androidApp/src/main/assets/lunch.properties` and `iosApp/LunchApp/Config/Lunch.plist`
  with `supabaseUrl`, `supabaseAnonKey`, `backendBaseUrl`, `revenueCatApiKey`, `inviteLinkBase`.
- `androidApp/google-services.json` and `iosApp/LunchApp/GoogleService-Info.plist` for push.
- Backend secrets are set with `supabase secrets set` (see `backend/README.md`).

Copy the `.example` files next to each of these to get started.

## Database compatibility

Both apps open the `diet_buddy.sqlite` file the Flutter app wrote (schema version 6). The rules
that keep this working are in `shared/README.md`. Never change a column in an existing table
without a migration that runs on both platforms.
