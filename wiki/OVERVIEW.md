---
title: MapLibreEarth — Overview
description: "Navigation hub for the MapLibreEarth wiki: the standalone map app and the MapLibre Native / MapLibre Native Qt work behind it."
tags: [ wiki, overview ]
---
# Overview

The home and navigation hub for the `MapLibreEarth` wiki. MapLibreEarth is a standalone Qt Quick / QML map application built on [MapLibre Native Qt](https://github.com/maplibre/maplibre-native-qt); it began as that repo's `quick-standalone` example and is now its own project. This wiki also records the work done in MapLibre Native and MapLibre Native Qt that the app depends on.

## What this is

MapLibreEarth is one QML app ([`main.qml`](./entry-points/main-qml.md), `main.cpp`) built against an installed `QMapLibre` package. That package is itself built from a fork of [MapLibre Native Qt](./concepts/maplibre-native-qt.md), which vendors [MapLibre Native](./concepts/maplibre-native.md) as a git submodule. Because the app targets the [Open Waters](./flows/open-waters-rendering.md) nautical style, the project carries a small set of [downstream patches](./references/fork-patches.md) to the vendored core.

## Start here

- **Building / running** → [Runbooks](./runbooks/index.md).
- **New to the project** → [Architecture overview](./architecture/overview.md) → [Concepts](./concepts/index.md) → [Flows](./flows/index.md).
- **The MapLibre work** → [MapLibre Native](./concepts/maplibre-native.md), [MapLibre Native Qt](./concepts/maplibre-native-qt.md), [Style-spec properties](./concepts/style-spec-properties.md).
- **Decisions** → [Decisions index](./decisions/index.md).
- **Upstream** → [Pull requests](./references/upstream-prs.md).
- **Picking up the work** → [Next steps](./next-steps.md).

## Navigation

### Architecture

- [Overview](./architecture/overview.md) — the app and the MapLibre stack it sits on.
- [Technology](./architecture/technology.md) — Qt, MSVC, Vulkan/OpenGL, NDK, build systems.
- [Environment](./architecture/environment.md) — machine paths, SDKs, install prefixes, devices.

### Modules

- [Modules index](./modules/index.md) — [MapLibreEarth app](./modules/mapplibrerearth-app.md), [`QMapLibre::Core`](./modules/qmaplibre-core.md), [`QMapLibre` Quick](./modules/qmaplibre-quick.md), [MapLibre Native core](./modules/maplibre-native-core.md).

### Entry points

- [Entry points index](./entry-points/index.md) — [`main.cpp`](./entry-points/mapplibrerearth.md) and [`main.qml`](./entry-points/main-qml.md).

### Concepts

- [Concepts index](./concepts/index.md) — [MapLibre Native](./concepts/maplibre-native.md), [MapLibre Native Qt](./concepts/maplibre-native-qt.md), [style-spec properties](./concepts/style-spec-properties.md), [the QML map item](./concepts/qml-map-item.md).

### Flows

- [Flows index](./flows/index.md) — [style load & switch](./flows/style-load-and-switch.md), [gestures](./flows/gestures.md), [Open Waters rendering](./flows/open-waters-rendering.md).

### Decisions

- [Decisions index](./decisions/index.md) — D1 standalone app, D2 13.6.1 upgrade, D3 downstream patches, D4 right-drag zoom, D5 Debug vs Release libraries, D6 draft upstream PRs.

### Runbooks

- [Runbooks index](./runbooks/index.md) — [Windows build](./runbooks/build-windows.md), [Android build](./runbooks/build-android.md), [Android deploy](./runbooks/deploy-android.md), [Qt Creator Debug/Release](./runbooks/qt-creator-debug-release.md), [Open Waters](./runbooks/open-waters.md).

### Verification

- [Verification index](./verification/index.md) — [Windows](./verification/windows.md), [Android](./verification/android.md), [Open Waters](./verification/open-waters.md), [Linux tests](./verification/linux-tests.md).

### Reference

- [Handover (JDReadme)](./references/handover-jdreadme.md) — the original build handover, preserved.
- [Downstream patches](./references/fork-patches.md) — the two patches applied to the vendored core.
- [Upstream pull requests](./references/upstream-prs.md) — the five draft PRs.
- [Upstream issues](./references/upstream-issues.md) — the MapLibre Native gaps.
- [Project history](./history.md) — dated milestones.
- [Wiki log](./log.md) — append-only record of changes to this wiki.
- [Next steps](./next-steps.md) — the ordered to-do list.
