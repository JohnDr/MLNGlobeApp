---
type: Concept
title: MapLibre Native
description: The C++ rendering engine vendored by the Qt bindings — its namespace, renderers and strict style parser.
tags: [ concept, maplibre-native ]
status: draft
---
## Summary

**MapLibre Native** is the cross-platform rendering engine — the library that actually parses styles, loads and processes tiles, and draws. It is written in C++ and lives in the [MapLibre Native repo](https://github.com/maplibre/maplibre-native).

## How it is vendored

In this project it is a **git submodule** at `vendor/maplibre-native`, pinned to a release tag (`android-v13.6.1`, commit `c7506d6a`). The CMake target built from it is still named **`mbgl-core`** (with `Mapbox::Map` as an alias) — the target names were not renamed when the API changed.

## The `mbgl` → `mln` rename

Up to `android-v13.4.0` the public API used the `mbgl` namespace and `include/mbgl`. From `android-v13.6.1` these are **`mln`** and **`include/mln`**. The Qt bindings therefore had to rename all includes, forward declarations and namespace uses. See [D2](../decisions/d2-upgrade-13-6-1.md).

## Renderers

Native draws through a GPU abstraction with backends for **Vulkan**, **OpenGL**, **Metal** and **WebGPU**. This project uses Vulkan on Windows and Android (`MLN_WITH_VULKAN=ON`); OpenGL is available for CI-parity builds.

## The style parser is strict

The single most important behaviour for this project: when the style parser converts a layer, **any unknown layout or paint property makes it drop the entire layer** — `conversion/layer.cpp` returns `nullopt` on the first bad property. The [Open Waters](../flows/open-waters-rendering.md) style uses several newer style-spec properties Native does not implement, so ~16 layers (buoys, beacons, lights, topmarks, landmarks, …) would be silently discarded. The [style-spec patch](../references/fork-patches.md) works around this. See [Style-spec properties](./style-spec-properties.md).

## Related

- [MapLibre Native Qt](./maplibre-native-qt.md) · [Style-spec properties](./style-spec-properties.md) · [MapLibre Native core module](../modules/maplibre-native-core.md)
