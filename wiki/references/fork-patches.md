---
type: Reference
title: Downstream patches
description: The fork-only patches applied to the vendored MapLibre Native at configure time.
tags: [ reference, patches ]
status: draft
---
## Summary

The fork of MapLibre Native Qt carries twenty-four patches to the vendored [MapLibre Native](../concepts/maplibre-native.md) core, under `maplibre-native-qt/patches/`. They are applied **idempotently at configure time** by `src/core/CMakeLists.txt` (`git apply --reverse --check` then `git apply`), and `.gitattributes` forces `patches/*.patch` to LF.

## Patch 0001 — style-spec properties

`maplibre-native-0001-style-spec-properties.patch` changes three files:

| File | Change |
|------|--------|
| `src/mln/style/layers/symbol_layer.cpp` | Handle `icon-overlap` / `text-overlap` in `setPropertyInternal` → `icon-allow-overlap` / `text-allow-overlap` (`never` → false; `always`/`cooperative` → true). |
| `src/mln/style/layers/line_layer.cpp` | Allow **data expressions** for `line-dasharray` (`convert<...>(value, error, true, false)`). |
| `src/mln/style/layers/color_relief_layer.cpp` | Accept `resampling` (no-op). |

See [Style-spec properties](../concepts/style-spec-properties.md).

## Patch 0002 — relax evaluate asserts

`maplibre-native-0002-relax-evaluate-asserts.patch` removes the two asserts in `include/mln/style/property_expression.hpp::evaluate(float zoom)`:

```cpp
assert(!isZoomConstant());
assert(isFeatureConstant());
```

They reject legitimate callers such as `CrossFadedPropertyEvaluator`, which evaluates a cross-faded property (e.g. `line-dasharray`) at z-1/z/z+1 even for a data expression. Release has asserts compiled out; the patch keeps **Debug** in sync with Release. See [D3](../decisions/d3-downstream-patches.md).

## Patch 0003 — globe projection seam

`maplibre-native-0003-globe-projection-seam.patch` is the ported **globe phase 1** (plus the projection selection API) — see [Globe projection](../concepts/globe-projection.md). It adds `src/mln/map/projection_base.hpp` (`ProjectionBase` + `ProjectionData`), `src/mln/map/mercator_projection.{hpp,cpp}`, routes `TransformState` through the projection, and carries a per-drawable `ProjectionUBO` through every layer tweaker on all four backends. **Mercator only, no behaviour change.**

It is by far the largest patch (~560 lines, 58 files). Unlike 0001/0002, it is a direct port of upstream work (`maplibre-native` PR #4533, commit `955e04af`) rather than a fork-only workaround, so the intent is to **drop it** once a release carrying globe is the vendored submodule.

## Patch 0004 — globe phase 2 (`projectTile`)

`maplibre-native-0004-globe-phase-2-projecttile.patch` is the verbatim upstream **globe phase 2** (PR #4533, commit `642c2973`). It adds `ProjectionUBO` + `projectTile()` to the shared vertex prelude and switches the whole **fill family** (GL, Metal, Vulkan, WebGPU) to project through it instead of `drawable.matrix` — still pixel-identical. It applies **after** 0003 (it edits the same shader headers).

## Patch 0005 — globe phase 3 (the `projection` style property)

`maplibre-native-0005-globe-phase-3-projection-property.patch` is **globe phase 3** (PR #4533, commit `69376bbd`), ported with manual reconciliation. It adds `style::Projection` / `ProjectionDefinition`, parses the style-root `projection` property, gives it an expression type and a `Style`/`Style::Impl` API, and plumbs its transition scalar to the transform (still Mercator). It applies **after** 0004.

Unlike 0003/0004 this was **not** a clean apply: our `android-v13.6.1` style subsystem predates upstream (e.g. no `colorSpace` on `InterpolateImpl`, no `global-state` expression), so 7 files were reconciled by hand (`style.hpp`, `style_impl.hpp`, `parser.{hpp,cpp}`, `expression/interpolate.cpp`, `test/style/style.test.cpp`, and the phase-1 `transform_state.hpp`). **This is the pattern for phases 4+: each will need reconciliation against the drifted tree.**

## Patch 0006 — globe on Vulkan (phase 4 fast-path)

`maplibre-native-0006-globe-phase-4-vulkan.patch` makes the globe **render** — see [Globe projection](../concepts/globe-projection.md). It takes globe **phase 4**'s projection math (`VerticalPerspectiveProjection`, `gfx::ProjectionVariant`, the per-drawable `depth_offset`) and delivers the globe **on Vulkan** rather than Metal:

- A globe `projectTile` prelude in `include/mln/shaders/vulkan/common.hpp` (translated from phase 4's Metal prelude), the Vulkan **fill** and **background** shaders projecting through it, and the `PROJECTION_GLOBE` define plumbed through the Vulkan `ShaderGroup`/`Context`.
- The renderer (`RenderFillLayer`, `RenderBackgroundLayer`) requests the globe variant when `TransformState::isGlobeRendering()`.
- `mln::Map::setProjectionType` sets the style's projection, so both the QML `MapLibre.projectionType` and the root style `projection` property drive it.

It is **not** an upstream phase as-is: it folds phase 4 with the Vulkan half of phase 10b and skips Metal/GL/WebGPU. Upstream's metrics, changelog and render-test fixtures are deliberately excluded (source only). Applies **after** 0005.

## Patch 0007 — globe subdivision (phase 5)

`maplibre-native-0007-globe-phase-5-subdivision.patch` is globe **phase 5** (`aef0619`, PR #4533): subdivide fill/line geometry and cap the tile meshes at the poles, so the sphere curves instead of faceting. It adds `util/subdivision`, `util/tile_mesh`, `renderer/globe_tile_mesh.hpp`, and threads `SubdivisionGranularitySetting` through `BucketParameters` → `GeometryTileWorker` → the fill/line buckets; the Vulkan shaders gain the pole-aware `projectTile(pos, rawPos)` variant.

Upstream ships phase 5 as a single commit bundling subdivision, globe gestures, and the raster/hillshade/fill-extrusion layer families. This patch carries the **subdivision and pole-cap** parts (plus the Vulkan shader half, which upstream had not done yet); the gesture and extra-layer-family work is not included. Applies **after** 0006.

## Patch 0008 — globe tile cover (phase 7)

`maplibre-native-0008-globe-phase-7-tile-cover.patch` is globe **phase 7** (`4e83526f`, PR #4533): the globe tile cover. It adds `util/bounding_volumes` (frustum volume/plane intersection) and `util/mat3`, and a globe branch in `util/tile_cover` that tests each tile against the camera frustum in unit-sphere space plus the horizon plane, so only the visible hemisphere is loaded (`TileCoverParameters::transformState` becomes a reference). This removes the limb gaps that moved with rotation. Applies **after** 0007.

## Patch 0009 — globe transform (phase 6) and the globe→Mercator hand-off

`maplibre-native-0009-globe-phase-6-transform.patch` is globe **phase 6** (`2f7bcd9e`, PR #4533) — globe unproject, anchored zoom, constrain, camera-state caching and the projection-type rename — plus the **zoom 11–12 globe→Mercator hand-off** from `style::Projection::Impl::evaluate` (the core of phase 9e).

The hand-off was not optional: without it the globe radius grows without bound while `cameraToCenterDistance` stays fixed, so the camera ends up on the sphere's surface and zooming in renders a single flat colour. It also merges the native `ProjectionType` from `ProjectionDefinition` and drops the ad-hoc `mln::map/projection_type.hpp`. Applies **after** 0008.

## Patch 0010 — lines on the globe (Vulkan)

`maplibre-native-0010-globe-lines-vulkan.patch` switches the four Vulkan line vertex shaders (`line`, `line-gradient`, `line-pattern`, `line-sdf`) from `drawable.matrix` to the globe `projectTile` and binds the projection UBO — the line half of upstream's "render lines on the globe" (phase 9a). Without it, the road-casing lines smeared across the whole window in their colour on the globe, which read as a single-colour fill. This is a hand-written Vulkan change (upstream did it for Metal). Applies **after** 0009.

## Patch 0011 — rasters on the globe (Vulkan)

`maplibre-native-0011-globe-raster-vulkan.patch` is globe **phase 9c** (`5d5a1ca9`, PR #4533) for Vulkan: the raster, hillshade and color-relief vertex shaders bind the projection UBO and project through `projectTile`, and their render layers build the subdivided pole-capped `GlobeTileMesh` (instead of the flat quad) when the globe is active. The `natural_earth` shaded relief then wraps onto the sphere instead of showing as a flat block. Adds the `projectionVariant` plumbing to those render layers. Applies **after** 0010.

## Patch 0012 — circles & heatmaps on the globe (Vulkan)

`maplibre-native-0012-globe-circle-heatmap-vulkan.patch` is globe **phase 9b** (`3f24993a`, PR #4533) for Vulkan: the circle and heatmap vertex shaders project extruded corners onto the sphere (`projectToSphere` + `globeRotateVector` + `interpolateProjection`), driven by a new `globe_extrude_scale` drawable field. Adds `LayerTweaker::globeExtrudeScale` and the `globeRotateVector` prelude helper. Applies **after** 0011.

## Patch 0013 — fill-extrusions on the globe (Vulkan)

`maplibre-native-0013-globe-fill-extrusion-vulkan.patch` is globe **phase 9d** (`29d6dcd8`, PR #4533) for Vulkan: fill-extrusion vertices project through `projectTileFor3D`; a new **`GlobeDepthPass`** draws the planet into the depth buffer before the translucent pass so 3D geometry behind the horizon is hidden; fill-extrusion buckets subdivide walls/roofs on the globe. Adds `RenderLayer::projectionVariant` + `updateProjectionVariant`, the `GlobeDepthShader` (Vulkan) and registration, and 3D prelude helpers. Upstream's TileProjector feature-query path is not ported here (rendering does not need it). Applies **after** 0012.

## Patch 0014 — symbols/labels on the globe (Vulkan)

`maplibre-native-0014-globe-symbols-vulkan.patch` is globe **phase 8** (`3a217519`, PR #4533) for Vulkan: the symbol projection (`layout/symbol_projection`), collision index (`text/collision_index`) and placement (`text/placement`) work on the sphere; the symbol vertex shaders project through `projectTileWithElevation` (new prelude helper); the symbol render layer switches projection variant. Adds `src/mln/map/tile_projector.hpp` and the `mercator_projection`/`vertical_perspective_projection` symbol methods. Applies **after** 0013.

## Patch 0015 — globe clip masks (Vulkan)

`maplibre-native-0015-globe-clip-masks-vulkan.patch` is the Vulkan half of globe **phase 9f** (`ea76633b`): a globe clip-mask pass (`Context::renderGlobeTileClippingMasks`) writes each tile's pole-capped mesh to the stencil, driven by the `shaders::GlobeClipMask` block (projection + stencil ref + tile), so layers outside their tile are clipped on the sphere. Adds the globe branch to the Vulkan `clipping_mask` shader, a `granularity` parameter to `rawGlobeTileMesh`, and the shared `paint_parameters` globe branch. Applies **after** 0014.

## Patch 0016 — raster uncovered-parts on the globe (Vulkan)

`maplibre-native-0016-globe-raster-uncovered-vulkan.patch` is globe **phase 12o** (`9fa47e1f`): `GlobeTileMesh` now grids only the parts of a tile its **`TileMask`** keeps (splitting an overlapped parent tile into quadrant parts), and a `GlobeTileMeshCache` keyed by zoom/pole/mask dedupes them. The raster/hillshade/color-relief render layers build their globe meshes through the cache with the bucket's mask, so overlapping raster tiles stop blending. Applies **after** 0015.

## Patch 0017 — globe tile-edge fixes

`maplibre-native-0017-globe-tile-edge-fixes.patch` fixes the globe **blank band at z8-10** and the **wide darker band along globe tile edges**. Three files: `renderer/tile_pyramid.cpp` (size the `bounds` `TileRange` guard over the full source zoom range when the cover is in variable-zoom mode, so the globe cover's finer tiles are not rejected — otherwise the layer gets ~1 tile and the view is blank); `util/subdivision.cpp` (mirror GL JS `removeTrianglesOutsideTileX` / `removeLinesOutsideTileX` — drop a triangle when **any** vertex is outside, not only when all are, which is a port translation bug; z0-only); and `gfx/fill_generator.cpp` (clip fill polygons to `[0, EXTENT]` on both axes before subdivision so the grid cannot place vertices past the tile edge, and skip fill-**outline** segments lying along the tile's vertical boundary — clipping artifacts that both tiles would otherwise stroke into a darker line along every globe tile edge). Applies **after** 0016.

## Patch 0018 — globe backdrop colour

`maplibre-native-0018-globe-background-color.patch` adds `Map::setBackgroundColor(Color)` and threads an optional `backgroundColor` through `UpdateParameters` → `RenderTreeParameters` to the renderer's clear pass, so the space behind the globe is a chosen colour instead of black. The clear is applied **globe-only** (`TransformState::isGlobeRendering()` guards the background block in `render_orchestrator.cpp`), and `renderer_impl.cpp` clears the backdrop even with a shared context when the globe is active and the colour is opaque. The Qt `Map` and the QML `MapLibre` element expose it as `backgroundColor`. Applies **after** 0017.

## Patch 0019 — terrain style property

`maplibre-native-0019-terrain-style-property.patch` adds the style's root `terrain` object — a `raster-dem` source plus an `exaggeration` — modelled on the existing `projection`/`light` root objects (which 0005 introduced). New files: `include/mln/style/terrain.hpp`, `include/mln/style/conversion/terrain.hpp`, `src/mln/style/terrain.cpp`, `terrain_impl.hpp`, `terrain_observer.hpp`, `src/mln/style/conversion/terrain.cpp`. It wires the parser (`terrain` member + `parseTerrain`) and `Style`/`Style::Impl` (`setTerrain`/`getTerrain` + `TerrainObserver`), and adds `Map::setTerrain` / `clearTerrain` / `hasTerrain` / `getTerrainSource` / `getTerrainExaggeration`. Sources are validated as `raster-dem`. The Qt `Map` gains `setTerrain`/`clearTerrain`; the QML `MapLibre` element exposes `terrainSource` + `terrainExaggeration`, re-applied after each style load (like `projectionType`). Rendering is unchanged — the renderer still draws flat; this is the first slice of [3D terrain](../next-steps.md). Applies **after** 0018.

## Patch 0020 — terrain transform elevation

`maplibre-native-0020-terrain-transform-elevation.patch` gives `TransformState`/`Transform` the elevation surface the terrain renderer needs: `getElevation()` / `setElevation()` name the map **centre's altitude as the ground elevation under it** (GL JS's `transform.elevation`), and `getCameraAltitude()` reports the camera's height above sea level. The formulas match GL JS exactly — GL JS's `getCameraAltitude() = cos(pitch)·cameraToCenterDistance/pixelsPerMeter + elevation` is precisely what the existing `updateCameraState()` already derives from the centre altitude, so here an elevation setter is the existing centre-altitude path. Inert until something samples terrain. Applies **after** 0019.

## Patch 0021 — terrain DEM elevation sampler

`maplibre-native-0021-terrain-dem-elevation-sampler.patch` adds `DEMData::getElevation(x, y)`, which bilinearly interpolates the metre elevation at a continuous tile coordinate in `[0, dim]` — mirroring GL JS `DEMData#getElevation`, adapted to Native's one-pixel border. Unit tests cover the integer-coordinate and mid-point cases. This is the sampling primitive the terrain elevation provider builds on; nothing calls it yet. Applies **after** 0020.

## Patch 0022 — terrain tile manager

`maplibre-native-0022-terrain-tile-manager.patch` adds `renderer/terrain_tile_manager.{hpp,cpp}`: a **terrain-owned** DEM tile manager (GL JS's `TerrainTileManager` model). A `raster-dem` source only loads tiles a *layer* uses, and terrain has no layer, so it fetches and caches tiles itself via the `FileSource`, decodes them into `DEMData`, and exposes `getElevation(latLng, zoom)` by sampling the covering tile (0 until it loads), plus `tileFor`. `getDEMData` is virtual so tests inject data; `test/renderer/terrain_tile_manager.test.cpp` covers `tileFor` and uniform sampling. Still unwired — nothing constructs one yet. Applies **after** 0021.

## Patch 0023 — terrain render pass

`maplibre-native-0023-terrain-render-pass.patch` adds a Vulkan `TerrainShader` (one `float4` vertex attribute: tile xy, world-pixel elevation, hillshade) and a `TerrainPass` that, per DEM tile in the cover, builds a 16×16 grid mesh with CPU-baked elevation + hillshade and draws it with depth, after the flat layers. `UpdateParameters` carries the terrain tileset + exaggeration (resolved from the style's terrain source in `Map::Impl`), and the render orchestrator owns the pass. It **builds and runs** — the style's terrain resolves, the shader is found, DEM tiles fetch/decode, and 100 terrain drawables are built with valid vertices and a valid projection matrix — but the surface **does not appear on screen yet**; the bug is in the raw-vertex attribute binding / terrain shader. See the [log](../log.md). Applies **after** 0022.

## Patch 0024 — terrain repaint on tile load

`maplibre-native-0024-terrain-repaint-on-tile-load.patch` makes `TerrainTileManager` report DEM tile loads via a callback; the orchestrator turns that into `RendererObserver::onInvalidate` so the map renders again and rebuilds the terrain. Without it (terrain is not a style source) the map stopped after the first few frames and never picked up loaded tiles. Applies **after** 0023.

## Regenerating a patch

Edit the files in `vendor/maplibre-native`, then dump the diff with a UTF-8 writer (PowerShell's `>` writes UTF-16, which `git apply` rejects):

```
git -C vendor/maplibre-native diff --no-color -- src > patches\....patch
```

After configure the submodule shows ` m vendor/maplibre-native`; the committed gitlink stays clean and the patches re-apply on a fresh checkout.

## Related

- [Style-spec properties](../concepts/style-spec-properties.md) · [D3](../decisions/d3-downstream-patches.md) · [MapLibre Native core](../modules/maplibre-native-core.md)
