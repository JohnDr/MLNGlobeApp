---
type: Concept
title: 3D terrain
status: draft
description: How the fork renders aerial imagery draped over 3D terrain — architecture, patches, and current state.
tags: [ terrain, rendering, vulkan, drape, fork ]
---

## What it is

The map renders a **3D terrain surface** and **drapes the map layers onto it**, so imagery/vector content follows the relief. This is the GL JS render-to-texture model, built on the fork's existing per-tile RTT framework rather than a back-port of upstream's experimental `feature/terrain-3d` branch.

A style enables it with a root property:

```json
{ "sources": { "dem": { "type": "raster-dem", "tiles": ["..."], "encoding": "terrarium" } },
  "terrain": { "source": "dem", "exaggeration": 1.5 } }
```

## Architecture (patches)

All downstream patches are in `maplibre-native-qt/patches/` (see [Fork patches](../references/fork-patches.md)). The terrain span is **0019–0033**:

| Patches | What |
|---|---|
| **0019** | style root `terrain {source, exaggeration}` + `Style`/`Map` API + Qt/QML (`terrainSource`, `terrainExaggeration`). |
| **0020** | `Transform` elevation (the centre altitude is the ground elevation under it; GL JS `transform.elevation`) + `getCameraAltitude`. |
| **0021–0022** | `DEMData::getElevation` bilinear sampler; a **terrain-owned** `TerrainTileManager` that fetches/decodes `raster-dem` tiles and exposes `getElevation(latLng, zoom)`. |
| **0023–0026** | The Vulkan **`TerrainShader`** + **`TerrainPass`**: a grid mesh per DEM tile with CPU-baked elevation + hillshade, drawn with depth. Key fixes: colour write mode, **UBO consolidation** (the shader reads the layer group's shared projection buffer, indexed by `uboIndex`), and the tile→clip matrix `projMatrix·matrixFor(tile)`. |
| **0027–0029** | **Drape**: per-tile `RenderTarget`s, each rendered with a **per-tile orthographic projection** (`PaintParameters::projMatrixOverride`) and sampled at a tile-local UV. **0029** keeps symbols screen-space (only `background/fill/line/raster/hillshade/color-relief` are draped — GL JS `LAYERS_TO_TEXTURES`) and adds a per-tile texture **cache** (fingerprint + `drapeGeneration`). |
| **0030** | **Symbol elevation**: `terrainElevationFn` → `SymbolDrawableUBO.elevation` → `updateCameraFromElevation…`. |
| **0031** | **Globe variant**: pick the shader projection variant from `state.isGlobeRendering()`; use the globe matrix. Renders on the globe but the mesh is still flat (petals). |
| **0032** | Hypsometric **fallback tint** where the drape is black. |
| **0033** | 512→**256 px** per-tile drape targets (fixes `Vulkan texture allocation failed`). |

Key code: `src/mln/renderer/terrain_pass.{hpp,cpp}`, `terrain_tile_manager.{hpp,cpp}`, `include/mln/shaders/vulkan/terrain.hpp`, and the orchestration in `render_orchestrator.cpp` (`updateLayers`, `renderTerrainDrapeTargets`) + `renderer_impl.cpp`.

## Current state (2026-10-12)

- ✅ Terrain renders as a **shaded elevated surface** (flat/Mercator), with a **per-tile RTT drape**.
- ✅ Symbols stay screen-space; per-tile texture cache in place.
- ✅ App: a **"3D Terrain (satellite draped)"** map in the Maps list (`terrain-style.json`, Esri World Imagery + AWS terrarium).
- ⚠️ **OPEN — raster drape regression:** the **satellite raster is not captured into the drape targets** (drape is black; the fallback tint shows). It *was* draped around patch **0029**; broke between **0030–0033**. See [Next steps](../next-steps.md).
- 🔶 Globe terrain renders but the mesh needs the globe curvature / pole-capped tessellation. Fog/sky not started.

## Gotchas learned

- **UBO consolidation is on** for Vulkan — a custom shader's projection UBO must be uploaded to the **layer group's** shared buffer and each drawable's `uboIndex` set.
- `file://` style URLs need **two** slashes before the Windows drive (`file://C:/...`), not three.
- The app's empty `terrainSource` (`terrainEnabled` false) calls `clearTerrain()`, which **wipes a style's own `terrain`** — so terrain must be turned on for a terrain style.
- `mat4` is **double**-backed; cast to `float` for the UBO.