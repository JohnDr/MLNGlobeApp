---
type: Concept
title: MapLibre Native Qt
description: The Qt bindings around MapLibre Native — the modules, the QMapLibre package and the QML plugin.
tags: [ concept, maplibre-native-qt ]
status: draft
---
## Summary

**MapLibre Native Qt** ([repo](https://github.com/maplibre/maplibre-native-qt)) is the Qt wrapper around [MapLibre Native](./maplibre-native.md). It builds the `QMapLibre` C++ library, a Qt Quick map item and (optionally) widget and location modules. MLNGlobeApp links against it.

## What it produces

| Artifact | Role |
|----------|------|
| `QMapLibre.dll` / `libQMapLibre_<abi>.so` | The `QMapLibre::Core` library (`Map`, `Settings`, `MapRenderer`). |
| `QMapLibreQuickPrivate.dll` | Private support for the Qt Quick item. |
| `qml/MapLibre/declarative_maplibre.dll` | The `MapLibre` QML module (`import MapLibre 4.0`). |

CMake package: `QMapLibreConfig.cmake` (`find_package(QMapLibre COMPONENTS Core Quick)`). Project version 4.0.

## Modules and targets

The build options used here: `MLN_QT_WITH_WIDGETS=OFF`, `MLN_QT_WITH_LOCATION=OFF` (Qt-for-Android has no QtLocation). The vendored Native core is built as the **`mbgl-core`** target.

## This project's fork

The fork `JohnDr/maplibre-native-qt` is used to build a `QMapLibre` that MLNGlobeApp consumes. It carries:

- the [13.6.1 upgrade](../decisions/d2-upgrade-13-6-1.md), and
- two fork-only [patches](../references/fork-patches.md) to the vendored core.

Prepared upstream PRs (currently drafts): [#323–#326](../references/upstream-prs.md).

## Related

- [MapLibre Native](./maplibre-native.md) · [QMapLibre Core module](../modules/qmaplibre-core.md) · [QMapLibre Quick module](../modules/qmaplibre-quick.md)
