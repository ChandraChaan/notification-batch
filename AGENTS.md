# AGENTS.md: Notification Batch

Rules for people and coding agents working on this repository. Based on
[flutter-agent-skills](https://github.com/ChandraChaan/flutter-agent-skills).

## This project

- **What runs where:** the notification listener, the store, the alarms and the batch
  notification are Kotlin (`android/app/src/main/kotlin/.../`), because they must keep working
  while the Flutter UI is closed. Pure logic lives in `core/` with JVM unit tests; Android glue
  lives in `platform/`.
- **The seam:** Flutter talks to Android only through `lib/core/platform/batch_platform.dart`
  (a Dart interface) and its method channel implementation. Tests use `FakeBatchPlatform`.
- **Shared format:** settings travel as JSON. `spec/settings.json` is read by both the Dart and
  the Kotlin tests; change both sides together.
- **State management:** Riverpod 3 (`AsyncNotifier`). **Navigation:** go_router.
- **Folders:** `lib/features/<feature>/{domain,presentation}`, shared code in `lib/core/`.
- **Generated code:** `lib/l10n/app_localizations*.dart` from `lib/l10n/app_en.arb`
  (`flutter gen-l10n`). Never edit by hand.
- **Supported:** Android 8.0 (API 26) and later.

## Before you finish any change

```bash
dart format .
flutter analyze
flutter test
(cd android && ./gradlew :app:testDebugUnitTest)
```

## Rules that matter most here

- **When unsure, let it through.** Missing an important notification is worse than an extra
  ping. Every new rule in `BatchPolicy` needs a test that shows what it lets through.
- **Nothing leaves the phone.** No INTERNET permission in the main manifest, no analytics, no
  crash reporting, no network packages.
- Never log notification text, codes or contact details.
- No hard-coded colours or strings in widgets: use the theme and `AppLocalizations`.
- Screens have loading, error (with retry) and empty states, and work at 320 px wide with text at
  200%.
