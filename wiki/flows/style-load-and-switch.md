---
type: Flow
title: Style load and switch
description: How a style URL reaches the engine, and how switching a style at runtime behaves.
tags: [ flow, style ]
status: draft
---
## Summary

The app sets the map's `style` property to a URL (or JSON). That flows: QML `style` → [`MapQuickItem::setStyle`](../modules/qmaplibre-quick.md) → [`QMapLibre::Map::setStyleUrl`](../modules/qmaplibre-core.md) → the [MapLibre Native](../concepts/maplibre-native.md) style parser.

## Load

On first load the style is fetched and parsed; the parser walks its layers and converts each one. **If any layout or paint property is unknown, the entire layer is dropped** — see [MapLibre Native](../concepts/maplibre-native.md) and [Style-spec properties](../concepts/style-spec-properties.md). Every dropped layer logs a `[ParseStyle]` warning.

## Switch at runtime

Originally `setStyle` only stored the value — the map is initialised from `m_style`, so changing the style while the map was running had no effect until the next launch. The fix (PR [#326](../references/upstream-prs.md)) applies the new URL to the live map immediately and resets the style-loaded state, so the Maps dialog switches instantly.

## The Maps dialog

`main.qml` offers Liberty / Bright / Positron (OpenFreeMap) and [Open Waters](./open-waters-rendering.md), plus user-added URLs. Clicking a row sets `map.style`, which triggers the runtime switch above.

## Related

- [Open Waters rendering](./open-waters-rendering.md) · [The QML map item](../concepts/qml-map-item.md)
