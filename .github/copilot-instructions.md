<!-- Auto-generated guidance for AI coding agents. Edit with care. -->
# Copilot instructions — firstly (Flutter app)

Purpose
- Short, actionable guidance for an AI coding agent to be productive in this repo.

Big picture (what this repo is)
- A vanilla Flutter application scaffolded from `flutter create` (single-package app).
- UI code lives under `lib/` (entry: `lib/main.dart`). Platform integrations and native hooks live in `android/`, `ios/`, `windows/`, `macos/`, and `linux/`.
- Build artifacts and generated files are under `build/` and platform-specific `*/flutter/` folders. Do not modify generated files directly.

Key files to inspect
- `lib/main.dart` — app entry and simple stateful counter example.
- `pubspec.yaml` — dependencies (uses `flutter_lints`) and assets configuration.
- `test/widget_test.dart` — example widget test demonstrating `flutter_test` usage.
- `android/app/build.gradle.kts` — Kotlin + Gradle KTS Android config (Java 17 target). Use `gradlew.bat` on Windows.
- `ios/Runner/` and `macos/Runner/` — platform entry points and generated plugin registrants.

Developer workflows & important commands
- Install deps / fetch packages:
```bash
flutter pub get
```
- Run app (choose device):
```bash
flutter run            # default device
flutter run -d windows # run desktop on Windows
flutter run -d android # run on Android device/emulator
```
- Hot reload / restart when running from terminal: press `r` (reload) or `R` (restart).
- Build artifacts:
```bash
flutter build apk      # Android
flutter build windows  # Windows desktop
flutter build ios      # iOS (macOS host required)
```
- Run tests:
```bash
flutter test
```
- Android CI/Gradle notes: use `cd android && .\gradlew.bat assembleDebug` on Windows or `./gradlew assembleDebug` on Unix CI.

Project-specific conventions & patterns
- Linting: repository uses `flutter_lints` and `analysis_options.yaml`. Prefer to keep small, focused changes to avoid lint churn.
- Do not edit generated plugin registrant files under platform folders; change Dart plugin usage in `pubspec.yaml` or `lib/` instead.
- Keep UI code inside `lib/` and platform-specific code inside the respective platform directories.

Integration points & external dependencies
- Native bindings: `android/` uses Kotlin + Gradle KTS; `ios/` uses Swift/Obj-C generated registrants. If adding native code, update the platform project files accordingly.
- No third-party packages are currently declared beyond `cupertino_icons` and `flutter_lints` in `pubspec.yaml`.

Examples (use cases for code edits)
- Add a new feature: update `lib/` code, add any assets to `pubspec.yaml` `flutter/assets`, run `flutter pub get`, then `flutter run`.
- Add an Android manifest or permission: update `android/app/src/main/AndroidManifest.xml` and ensure Gradle sync via `cd android && .\gradlew.bat assembleDebug`.

When in doubt
- Run the app locally first (`flutter run`) to reproduce behavior before changing platform files.
- Prefer minimal, testable changes. Use `flutter test` for unit/widget tests and manual `flutter run` for integration verification.

Follow-up
- After making edits, ask the repo maintainer what CI or device matrix they expect (desktop, mobile, iOS simulator), since building iOS requires macOS.
