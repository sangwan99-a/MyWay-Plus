# MyWay+ — Move beyond

A cinematic, 3D-first hybrid transit experience for Canberra. The product is designed as one shared application for the web, Android and iOS.

## Platforms

- Web: responsive browser experience via Expo Web / React Native Web.
- Android: native application via Expo and React Native.
- iOS: native application via Expo and React Native.

## Run locally

```bash
npm install
npx expo install --fix
npx expo start
```

Then press `w` for web, `a` for Android, or `i` for the iOS simulator (macOS with Xcode required for local iOS builds).

## Architecture

- Expo SDK 58 and Expo Router.
- React Native shared interface and application logic.
- React Native Web for browser support.
- Three.js / React Three Fiber for the shared 3D transit world.
- Platform-specific 3D Canvas adapters: web renderer with Bloom, Noise and Vignette; native renderer tuned for mobile GPU budgets.
- Expo native modules and platform-specific adapters for native interactions.

## Design direction

The visual language intentionally follows the existing premium-portfolio project: near-black monochrome palette, Inter Tight / Instrument Serif / JetBrains Mono typography, cinematic 3D scene composition, floating particles, atmospheric depth, smooth transitions and restrained editorial layouts. It is adapted for a transit product rather than copying portfolio content.

## Current state

The repository now contains the universal Expo foundation and first cross-platform visual experience. Route cards and journey inputs are sample UI data only. Live departures, vehicle positions, fares, payments, authentication and push notifications are not connected yet.

## Next milestones

1. Verify Expo SDK package compatibility with `npx expo install --check`, then run web, Android and iOS development builds.
2. Connect authoritative Transport Canberra / ACT open-data sources.
3. Implement map, stop discovery, live arrivals, journey alternatives and accessible routing.
4. Add secure accounts, favourites, travel history, native notifications and supported payment integrations.
5. Add automated tests, CI, EAS build profiles and store release configuration.

Never display sample arrival estimates as live data. Add data source attribution and freshness indicators when official feeds are integrated.
