---
type: Entry Point
title: main.qml
description: The MapLibreEarth QML UI — the map, its dialogs, its gestures and the persisted settings.
tags: [ entry-point, qml ]
status: draft
---
## Summary

`main.qml` is the entire UI: a [`MapLibre` map item](../concepts/qml-map-item.md) plus the controls and dialogs layered over it. It does not import its own module — it imports the map module (`import MapLibre 4.0`).

## UI

- **Top bar**: three buttons — Presets, Maps (styles), Settings — plus a **Dark** toggle and (right side) a 2D/3D toggle and zoom +/- buttons.
- **Maps dialog**: lists style URLs (Liberty / Bright / Positron from OpenFreeMap, Open Waters), lets you add/remove style URLs, and switches on click. Switching uses the runtime `setStyle` ([PR #326](../references/upstream-prs.md)).
- **Presets dialog**: named camera presets (add/remove; click to `flyTo`), persisted.
- **Settings dialog**: application scale slider with *Restart to apply*, persisted.

## Gestures

Implemented as QML pointer handlers — see [Gestures](../flows/gestures.md): two-finger pinch-zoom, one-finger/left-mouse pan, right-mouse smooth zoom, wheel stepped zoom.

## Persistence

`QSettings` (Windows: `HKCU\Software\MapLibre\MapLibreEarth`) stores window size/position, map camera, app scale, presets, map styles and dark mode.

## Related

- [`main.cpp`](./mapplibrerearth.md) · [Gestures](../flows/gestures.md) · [Style load & switch](../flows/style-load-and-switch.md)
