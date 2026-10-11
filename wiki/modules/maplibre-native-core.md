---
type: Module
title: MapLibre Native core
description: The vendored MapLibre Native engine built as the mbgl-core target, with the project's patches applied.
tags: [ module, maplibre-native ]
status: draft
---
## Summary

The engine itself is vendored at `maplibre-native-qt/vendor/maplibre-native` and built as the CMake target **`mbgl-core`** (alias `Mapbox::Map`). Its namespace is `mln`.

## Facts

- Pinned to the submodule tag `android-v13.6.1` (`c7506d6a`).
- ~9 MB of C++ across style parsing, tiles, geometry, shaders and GPU backends.
- Renderers: Vulkan / OpenGL / Metal / WebGPU; this project uses Vulkan (and OpenGL for parity checks).
- The style parser **drops an entire layer** on any unknown layout/paint property ([details](../concepts/maplibre-native.md)).

## The project's patches

At configure time `src/core/CMakeLists.txt` applies the two [downstream patches](../references/fork-patches.md) to this tree:

- `icon-overlap` / `text-overlap`, data-driven `line-dasharray`, colour-relief `resampling` ([style-spec](../concepts/style-spec-properties.md)).
- a `PropertyExpression::evaluate` assert relaxation ([D3](../decisions/d3-downstream-patches.md)).

After configure, the submodule working tree is patched (` m vendor/maplibre-native`); the committed gitlink stays clean.

## Related

- [MapLibre Native](../concepts/maplibre-native.md) · [Downstream patches](../references/fork-patches.md)
