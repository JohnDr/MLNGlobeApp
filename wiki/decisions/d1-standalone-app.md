---
type: ADR
title: D1 — Standalone MLNGlobeApp app
description: Splitting the heavily-modified quick-standalone example out of the MapLibre Native Qt repo into its own CMake project.
tags: [ adr, project ]
status: accepted
---
## Status

Accepted (2026-10-11).

## Context

The `quick-standalone` example inside the MapLibre Native Qt repo was developed far beyond the upstream example — style picker, presets, settings, dark mode, 3D toggle, custom gestures, Open Waters. The intent is to contribute the [MapLibre Native 13.6.1 upgrade](../decisions/d2-upgrade-13-6-1.md) upstream, but the example must **not** be part of that contribution: upstream expects its own standard example.

## Decision

Extract the modified example into its own standalone CMake project at `C:\hda\dev\Projects\MapLibreEarth` (public repo `JohnDr/MLNGlobeApp`), rename it to **MLNGlobeApp**, and leave the upstream `examples/quick-standalone` untouched in any PR. The project keeps the upstream example's structure (a `find_package(QMapLibre COMPONENTS Core Quick)` CMake project), so it builds against an installed `QMapLibre` rather than from inside the Native Qt tree.

## Consequences

- The app is a first-class project; the example in the fork can be discarded.
- MLNGlobeApp depends on a `QMapLibre` install that has the two [fork patches](../references/fork-patches.md); once the [library-fix PRs](../references/upstream-prs.md) land upstream, it can build against releases.
- The app was renamed throughout (`project()`, the CMake target, the QML module URI `Example` → `MLNGlobeApp`, `qrc:/MLNGlobeApp/main.qml`, `setApplicationName`).

## Related

- [Entry points](../entry-points/index.md) · [D6](./d6-draft-upstream-prs.md) · [MLNGlobeApp module](../modules/mapplibrerearth-app.md)
