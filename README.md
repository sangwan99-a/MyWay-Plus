# MyWay+ — Move beyond

A cinematic transit companion built with **Flutter and Dart**. The same Flutter application targets web, Android and iOS.

## Stack

- Flutter / Dart (single shared codebase)
- Material 3 with a custom near-black, graphite and electric-lime design system
- Animated city and route illustration rendered with Flutter CustomPainter
- No React, React Native, Expo, npm runtime dependencies or third-party UI packages

## Run locally

Install the Flutter SDK, then:

```bash
flutter doctor
flutter pub get
flutter analyze
flutter run -d chrome
```

For Android, connect a device or start an emulator and run `flutter run`.
For iOS, use macOS with Xcode installed and run `flutter run`.

## Build

```bash
flutter build web --release
flutter build apk --release
flutter build ios --release
```

The web build is generated in `build/web`. Android and iOS builds require their respective Flutter platform toolchains. If this repository was not generated with platform folders, run `flutter create . --platforms=web,android,ios` once after installing Flutter.

## Vercel

The repository includes a Vercel build script that installs the Flutter stable SDK, resolves Dart packages from `pubspec.yaml`, and builds Flutter Web into `build/web`. No npm install is needed.

## Current product scope

The current screen includes a responsive journey planner, sample nearby departures, and an animated city/route scene. The departure times and location labels are illustrative only. Live transport APIs, real GPS, ticketing, accounts, and push notifications are future integration work.
