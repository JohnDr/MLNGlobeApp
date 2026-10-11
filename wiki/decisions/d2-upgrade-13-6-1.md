---
type: ADR
title: D2 — Upgrade to MapLibre Native 13.6.1
description: Bumping the vendored MapLibre Native submodule to android-v13.6.1 and porting the mbgl to mln API rename.
tags: [ adr, maplibre-native ]
status: accepted
---
## Status

Accepted (2026-10-10; commit `6db61e9`).

## Context

The vendored core was pinned to `android-v13.4.0` (`702ebc61`). `13.6.1` brought the newer style-spec support and fixes the [Open Waters](../flows/open-waters-rendering.md) style needs. In this range MapLibre Native renamed its public API: `include/mbgl` → `include/mln` and namespace `mbgl` → `mln`.

## Decision

Bump `vendor/maplibre-native` to `android-v13.6.1` (`c7506d6a`) and port the bindings:

- `include/mbgl` → `include/mln` (including quoted `"mbgl/..."` includes, not only `<mbgl/...>`).
- namespace `mbgl` → `mln` (including forward declarations such as `namespace mbgl { class TileServerOptions; }`).
- install `include/mln` instead of `include/mbgl`.

~30 files under `src/core` and `src/quick`. CMake target names (`mbgl-core`, `mbgl-compiler-options`, `Mapbox::Map`) are unchanged. Also adapt the OpenGL backend: `Renderable::size` is now private, so use `getSize()` / `setRenderableSize()`.

## Consequences

- Prepared as upstream PR **#323** (draft).
- The OpenGL `Renderable::size` fix was folded into the upgrade (found while building the PR with the OpenGL renderer).
- Vulkan on Windows with recent SDKs additionally needs the vendored-headers include fix (PR **#324**).

## Related

- [MapLibre Native](../concepts/maplibre-native.md) · [Upstream PRs](../references/upstream-prs.md) · [Windows runbook](../runbooks/build-windows.md)
