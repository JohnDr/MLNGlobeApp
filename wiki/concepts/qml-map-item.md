---
type: Concept
title: The QML map item
description: The MapLibre Qt Quick item — its C++ type, invokables, gestures and runtime setStyle.
tags: [ concept, qml ]
status: draft
---
## Summary

The `MapLibre` QML type the app uses is the C++ **`MapQuickItem`** (`QML_NAMED_ELEMENT(MapLibre)`) in `src/quick/plugins/map_quick_item.cpp`. It owns a `QMapLibre::Map`, hands it a style URL and renders it through a Qt Quick texture node (Vulkan or OpenGL). See the [Quick module](../modules/qmaplibre-quick.md).

## Invokables the app uses

`flyTo`, `scale`, `pan`, and camera accessors (`center`, `zoom`, `bearing`, `pitch`). The app's style switching calls `setStyleUrl` via the `style` property.

## Input and gestures

- A `QQuickItem` accepts only `Qt::LeftButton` by default, so a **right-button press is never delivered** to the item and never reaches pointer handlers declared on it. The `MapQuickItem` constructor now calls `setAcceptedMouseButtons(Qt::LeftButton \| Qt::RightButton)` — the required library change for right-drag zoom ([D4](../decisions/d4-right-drag-zoom.md)).
- All gestures are implemented in QML as pointer handlers (see [Gestures](../flows/gestures.md)): a one-point `PinchHandler` for pan, a two-point `PinchHandler` for pinch-zoom, a one-point **right-button** `PinchHandler` for smooth zoom, and a `WheelHandler` for stepped zoom.

## Runtime `setStyle`

Setting the `style` property used to only store the value — the map is initialised from `m_style`, so changing it while the map was running had no effect until the next launch. The fix applies the new URL to the live map immediately and resets the style-loaded state. See PR [#326](../references/upstream-prs.md).

## Related

- [QMapLibre Quick module](../modules/qmaplibre-quick.md) · [Style-spec properties](./style-spec-properties.md) · [Gestures](../flows/gestures.md)
