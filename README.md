# MyWay+ — Move beyond

A premium, 3D-first transit experience concept for Canberra. Built with React, Vite, Three.js and React Three Fiber.

## Run locally

```bash
npm install
npm run dev
```

## Build

```bash
npm run build
```

## Current experience

- Cinematic 3D transit scene with an animated bus, procedural city blocks, orbital route lines and atmospheric lighting.
- Responsive dashboard with journey planner interaction, service cards, saved routes and navigation.
- Motion design and a dark, high-contrast visual system.
- Clearly labelled sample data; no live vehicle feed or fare integration is claimed yet.

## Roadmap

1. Connect authoritative Transport Canberra / ACT open-data feeds for routes, stops, timetables, service alerts and vehicle positions where available.
2. Replace sample departures with live arrival predictions and freshness indicators.
3. Add an interactive geographic map, stop search, accessible journey options and multi-leg trip planning.
4. Add secure accounts, saved journeys, notifications and travel/payment integrations where supported by official providers.
5. Add an admin/operations view, observability, automated tests and production deployment.

## Important data note

The initial route cards and arrival times are illustrative UI data. Before public launch, integrate verified official data sources and show timestamps, source attribution and stale-data states. Do not use this concept UI to make real-world travel decisions.

## Stack

React 18 · Vite · Three.js · React Three Fiber · Drei · Framer Motion · Lucide
