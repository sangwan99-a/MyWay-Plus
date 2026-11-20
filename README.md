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

## Global transit discovery (initial integration)

- Device GPS is requested only after the user opens the global transit explorer. Location permission is optional; the user can deny it.
- Nearby stops and bus routes are queried from the Transitland v2 REST API using the project-configured API key, then supplemented with OpenStreetMap Overpass results. Stop discovery uses a 1.2 km radius and route search uses up to a 10 km radius.
- The Flutter map uses OpenStreetMap tiles and displays map attribution.
- Transitland and OpenStreetMap results are primarily mapped/scheduled transit data. This integration does **not** yet display live vehicle GPS positions or real-time ETAs. Those require accessible GTFS Realtime VehiclePositions and TripUpdates feeds.
- Global real-time coverage requires agency-published GTFS Realtime feeds (VehiclePositions, TripUpdates and Alerts), or a licensed aggregator. Mobility Database catalogs thousands of feeds across 100+ countries. Transitland API usage is subject to plan quotas. Provider-specific realtime feed ingestion, caching and live vehicle markers remain future work.
- Coverage varies by city and by what local operators publish. If a city has no mapped stops or an agency does not publish an accessible feed, MyWay+ must say so rather than fabricate buses or arrival times.

### Location permissions

After generating native folders with `flutter create . --platforms=web,android,ios`, configure Android location permissions (`ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION`) and iOS `NSLocationWhenInUseUsageDescription`. Browser geolocation requires HTTPS. Ask for permission only when the user invokes nearby discovery.

### Data providers and references

- [GTFS Schedule and GTFS Realtime specifications](https://gtfs.org/documentation/overview/)
- [Mobility Database global feed catalog](https://mobilitydatabase.org/)
- [Transitland API documentation](https://www.transit.land/documentation/rest-api)
- [OpenStreetMap and Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API)

Respect each provider's rate limits, terms, attribution and data freshness. The Transitland key is currently embedded in the Flutter client at the project owner's request for zero-config deployment; it is extractable from distributed app builds and should be rotated if abused. A backend proxy is recommended before public production use.
