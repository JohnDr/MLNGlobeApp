---
type: Module
title: QMapLibre Quick
description: The Qt Quick map item, its texture nodes and the MapLibre QML plugin.
tags: [ module, qmaplibre ]
status: draft
---
## Summary

The Qt Quick integration lives in `maplibre-native-qt/src/quick`. It builds the private support library and the **`MapLibre` QML module** the app imports.

## Parts

| Part | File | Role |
|------|------|------|
| Map item | `plugins/map_quick_item.cpp` | The [`MapLibre` QML type](../concepts/qml-map-item.md) (C++ `MapQuickItem`). |
| Texture node (base) | `texture_node_base.cpp` | Shared render-node logic. |
| Texture node (Vulkan) | `texture_node_vulkan.cpp` | Renders the engine into a Vulkan texture. |
| Texture node (OpenGL) | `texture_node_opengl.cpp` | The OpenGL variant. |
| QML plugin | `plugins/MapLibre/declarative_maplibre.dll` | `import MapLibre 4.0`. |

## Behaviours this project relies on

- **Right-button events** — the constructor sets `setAcceptedMouseButtons(Qt::LeftButton | Qt::RightButton)` ([D4](../decisions/d4-right-drag-zoom.md)).
- **Runtime `setStyle`** — the style property applies to the live map immediately (PR [#326](../references/upstream-prs.md)).

## Related

- [QMapLibre Core](./qmaplibre-core.md) · [The QML map item](../concepts/qml-map-item.md) · [Gestures](../flows/gestures.md)
