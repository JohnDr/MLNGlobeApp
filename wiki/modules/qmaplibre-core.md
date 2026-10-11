---
type: Module
title: QMapLibre Core
description: The QMapLibre::Core library — Map, Settings and MapRenderer — and the API the app drives.
tags: [ module, qmaplibre ]
status: draft
---
## Summary

`QMapLibre::Core` is the C++ binding over the [MapLibre Native](../concepts/maplibre-native.md) engine. It lives in `maplibre-native-qt/src/core` and builds to `QMapLibre.dll` (Windows) / `libQMapLibre_<abi>.so` (Android).

## Key classes

| Class | Role |
|-------|------|
| `QMapLibre::Map` | The map: camera, style, sources, rendering. The QML item calls into it. |
| `QMapLibre::Settings` | Cache DB path, tile server options, resource transform. |
| `QMapLibre::MapRenderer` | Drives `Map::render()` into the current graphics context. |

## Invokables the app uses

The [QML map item](../concepts/qml-map-item.md) exposes these to QML: `flyTo`, `scale` (relative zoom about a centre), `pan`, `setStyleUrl`, and camera accessors. `Map::scale` multiplies the current scale via the engine's `scaleBy`.

## Notes

- Built with `MLN_WITH_VULKAN=ON`; `MLN_QT_WITH_WIDGETS=OFF`, `MLN_QT_WITH_LOCATION=OFF`.
- The engine namespace is `mln` (see [D2](../decisions/d2-upgrade-13-6-1.md)).

## Related

- [QMapLibre Quick](./qmaplibre-quick.md) · [MapLibre Native Qt](../concepts/maplibre-native-qt.md)
