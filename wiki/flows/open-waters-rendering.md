---
type: Flow
title: Open Waters rendering
description: The Open Waters nautical style — the newer properties it uses, the layers that were dropped, and the patch that fixes them.
tags: [ flow, style, open-waters ]
status: draft
---
## Summary

**Open Waters** (`https://tiles.openwaters.io/seamap/style.json`) is the nautical seamap style the app targets. It has ~390 layers and exercises several newer style-spec features that make it a stress test for [MapLibre Native](../concepts/maplibre-native.md).

## The problem

Native **drops an entire layer** when any property is unknown. Because Open Waters uses properties Native does not implement, ~16 symbol layers (buoys, beacons, lights, topmarks, landmarks, platforms, harbours, obstructions, …) were silently discarded, so **no symbol icons rendered** — only text labels. The log showed:

```
[ParseStyle] layer 'buoys' doesn't support property 'icon-overlap'
```

## The fix

The [style-spec patch](../references/fork-patches.md) ([D3](../decisions/d3-downstream-patches.md)) maps `icon-overlap` / `text-overlap` onto `icon-allow-overlap` / `text-allow-overlap`, allows data-driven `line-dasharray`, and accepts colour-relief `resampling`. Result: buoys / marks / lights and dashed hazard areas render, with **0 style-parse warnings** (was 16 + 2).

## WebP elevation

The style's elevation/terrain source serves **WebP** raster tiles. Qt's `qwebp` imageformats plugin is therefore installed for the Windows host and bundled into the Android APK (see [Android build](../runbooks/build-android.md)); without it the WebP tiles fail to decode.

## Remaining log line

`[General]: Invalid geometry in line layer` — a data issue in the source tiles, harmless.
