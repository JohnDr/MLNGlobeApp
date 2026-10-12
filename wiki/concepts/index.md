---
type: Concept
title: Concepts
description: Index of the core concepts behind MapLibreEarth — the MapLibre stack, the style spec and the QML map item.
tags: [ wiki, concept ]
status: draft
---
# Concepts

The pieces the project is built from.

- [MapLibre Native](./maplibre-native.md) — the C++ rendering engine (namespace `mln`).
- [MapLibre Native Qt](./maplibre-native-qt.md) — the Qt bindings and the `QMapLibre` package.
- [Style-spec properties](./style-spec-properties.md) — the newer style-spec properties Native does not implement.
- [The QML map item](./qml-map-item.md) — the `MapLibre` item, its gestures and its runtime `setStyle`.
- [Globe projection](./globe-projection.md) — rendering on a sphere and the phased plan to port it into Native.
- [3D terrain](./terrain.md) — aerial imagery draped over 3D terrain (per-tile render-to-texture), its patch span and current state.

## Related

- [Architecture](../architecture/index.md) · [Modules](../modules/index.md) · [Flows](../flows/index.md)
