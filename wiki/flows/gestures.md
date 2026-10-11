---
type: Flow
title: Gestures
description: How pan, pinch-zoom, right-drag zoom and stepped wheel zoom are implemented in main.qml.
tags: [ flow, gestures ]
status: draft
---
## Summary

All gestures are QML pointer handlers declared inside the [`MapLibre` item](../concepts/qml-map-item.md). They call [`QMapLibre::Map`](../modules/qmaplibre-core.md) invokables (`pan`, `scale`).

## The handler set

| Gesture | Handler | Calls |
|---------|---------|-------|
| Pinch-zoom (two fingers) | `PinchHandler` (2 points) | `map.scale(scale, centroid)` |
| Pan (one finger / left mouse) | `PinchHandler` (1 point) | `map.pan(delta)` |
| Smooth zoom (right mouse drag) | `PinchHandler` (1 point, `acceptedButtons: Qt.RightButton`) | `map.scale(2^(-dy/250), centroid)` |
| Stepped zoom | `WheelHandler` | `map.scale(...)` per notch |

## Why `PinchHandler`, not `DragHandler`

Both the pan and the right-drag zoom are **one-point `PinchHandler`s**, deliberately not `DragHandler`s:

- The pan handler began as a `DragHandler` that kept a **stale translation baseline** — when a two-finger pinch ended, it re-grabbed the remaining finger and snapped the map. A one-point `PinchHandler` resets its baseline on re-activation, so the lift-off jump is gone (diagnosed from the device logcat: the jump immediately followed `ACTION_POINTER_UP`).
- The right-drag `DragHandler` activated on the press but never tracked right-button translation; a one-point `PinchHandler` does.

## The right-button library change

No right-drag handler works unless the map item receives right-button events: a `QQuickItem` accepts only `Qt::LeftButton` by default, so the press never reaches the item's handlers. The `MapQuickItem` constructor now sets `setAcceptedMouseButtons(Qt::LeftButton | Qt::RightButton)` ([D4](../decisions/d4-right-drag-zoom.md)).

## Pinch spike guard

The two-finger pinch ignores the one-frame scale spike when a finger is added or removed (`delta > 0.25 && delta < 4.0`).

## Related

- [The QML map item](../concepts/qml-map-item.md) · [D4](../decisions/d4-right-drag-zoom.md) · [`main.qml`](../entry-points/main-qml.md)
