---
title: Wiki Log
description: Append-only audit trail of wiki generation and refresh runs.
---
# Wiki Log

Append-only. One dated entry per generation or refresh run.

## 2026-10-11 — Initial wiki generated

- **Added:** the full MapLibreEarth wiki — [OVERVIEW](./OVERVIEW.md) and the [architecture](./architecture/index.md), [concepts](./concepts/index.md), [decisions](./decisions/index.md), [modules](./modules/index.md), [entry-points](./entry-points/index.md), [flows](./flows/index.md), [runbooks](./runbooks/index.md), [references](./references/index.md) and [verification](./verification/index.md) sections.
- **Project:** `C:\hda\dev\Projects\MapLibreEarth`, content dir `wiki/`, initialised as an OpenKnowledge project (`.ok/config.yml`).
- **Sources:** the project session, the git history of `maplibre-native-qt` (commits `6db61e9`, `1177540`, `6e06e49`), the draft upstream PRs, and the [JDReadme handover](./references/handover-jdreadme.md).
- **Coverage:** MapLibreEarth the app; the MapLibre Native 13.6.1 upgrade; the MapLibre Native Qt bindings; the two downstream patches; the draft upstream PRs; Windows + Android build and deploy.

## 2026-10-11 — Globe projection: research, roadmap, phase 1

- **Added:** [Globe projection](./concepts/globe-projection.md) — the phased roadmap for porting globe into the vendored MapLibre Native, and the [GL JS globe guide](./external-sources/maplibre-gl-js-globe-guide.md) ingested as a source.
- **Implemented:** the projection API seam (`MapOptions` / `TransformState` / `Map` / `QMapLibre::Map` / QML `MapLibre`) and **globe phase 1** (the `ProjectionBase`/`ProjectionData` seam with a per-drawable `ProjectionUBO`), ported from `maplibre-native` PR #4533 commit `955e04af`. Mercator-only, no behaviour change.
- **Patch:** added `patches/maplibre-native-0003-globe-projection-seam.patch`; all three patches verified to apply to a pristine `android-v13.6.1` checkout.
- **Verified:** every changed production TU passes an MSVC `/Zs` syntax check against the `qt6-Windows-Vulkan` build tree.
- **References:** [Fork patches](./references/fork-patches.md), [Project history](./history.md).

## 2026-10-11 — Globe projection: phases 1 and 2 ported

- **Implemented:** globe **phase 2** — `ProjectionUBO` + `projectTile()` added to the shared vertex prelude and the whole fill family (GL/Metal/Vulkan/WebGPU) switched to project through it; ported verbatim from `maplibre-native` PR #4533 commit `642c2973`. Mercator-only, pixel-identical.
- **Patch:** added `patches/maplibre-native-0004-globe-phase-2-projecttile.patch`. The full four-patch chain (0001–0004) was verified to apply cleanly to a pristine `android-v13.6.1` checkout, reproducing the working tree exactly.
- **Verified:** the Vulkan shader TUs (`src/mln/shaders/vulkan/fill.cpp`, `src/mln/vulkan/renderer_backend.cpp`) pass an MSVC `/Zs` syntax check against the `qt6-Windows-Vulkan` build tree.
- **References:** [Globe projection](./concepts/globe-projection.md) · [Fork patches](./references/fork-patches.md) · [Project history](./history.md).

## 2026-10-11 — Globe projection: phase 3 (projection style property)

- **Implemented:** globe **phase 3** — the style-root `projection` property (parser + `ProjectionDefinition` expression type + `Style`/`Style::Impl` API + transition scalar to the transform), ported from `maplibre-native` PR #4533 commit `69376bbd`. Mercator-only, rendering unchanged.
- **Reconciled by hand:** 7 files where our `android-v13.6.1` tree predates upstream (`style.hpp`, `style_impl.hpp`, `parser.{hpp,cpp}`, `expression/interpolate.cpp`, `test/style/style.test.cpp`, `transform_state.hpp`).
- **Patch:** added `patches/maplibre-native-0005-globe-phase-3-projection-property.patch`; the full five-patch chain (0001–0005) was verified to apply to a pristine checkout and reproduce the working tree exactly.
- **Verified:** every changed/new TU (`parser.cpp`, `style_impl.cpp`, `style.cpp`, `expression/interpolate.cpp`, `expression/value.cpp`, `transform_state.cpp`, `transform.cpp`, `map_impl.cpp`, and the three new `projection*` translation units) passes an MSVC `/Zs` syntax check.
- **References:** [Globe projection](./concepts/globe-projection.md) · [Fork patches](./references/fork-patches.md).

## 2026-10-11 — Globe renders on Vulkan (phase 4 fast-path)

- **Implemented:** the globe now **renders on Vulkan**. Ported globe **phase 4**'s projection math (`VerticalPerspectiveProjection`, `gfx::ProjectionVariant`, per-drawable `depth_offset`) but wired it to **Vulkan** instead of Metal: a globe `projectTile` prelude in `vulkan/common.hpp`, the Vulkan fill and background shaders projecting through it, `PROJECTION_GLOBE` plumbed through the Vulkan `ShaderGroup`/`Context`, and the renderer requesting the globe variant. `mln::Map::setProjectionType` sets the style projection, so the QML `projectionType` and the root style `projection` both drive it.
- **Scope:** no subdivision yet (phase 5), so the sphere is faceted; the zoom morph (9e) is not in. Metal/GL/WebGPU globe is out of scope.
- **Patch:** added `patches/maplibre-native-0006-globe-phase-4-vulkan.patch`; the full six-patch chain (0001–0006) applies to a pristine checkout.
- **Verified:** the changed/new TUs pass MSVC `/Zs` (`vertical_perspective_projection.cpp` — new, `transform_state.cpp`, `mercator_projection.cpp`, `layer_tweaker.cpp`, `render_fill_layer.cpp`, `render_background_layer.cpp`, `paint_parameters.cpp`, `vulkan/context.cpp`, `vulkan` shader TUs, `map.cpp`). GLSL is validated at runtime, not by `/Zs`.
- **References:** [Globe projection](./concepts/globe-projection.md) · [Fork patches](./references/fork-patches.md).

## 2026-10-11 — Globe subdivision (phase 5) — smooth sphere on Vulkan

- **Implemented:** globe **phase 5**. Fill/line geometry is subdivided at the generators, the background tiles are meshes with **pole caps** (`rawGlobeTileMesh`), and `SubdivisionGranularitySetting` is plumbed `BucketParameters -> GeometryTileWorker -> TilePyramid -> fill/line buckets`. Ported from `maplibre-native` PR #4533 commit `aef0619`; the **Vulkan** shaders gained the pole-aware `projectTile(pos, rawPos)` variant (hand-written, since upstream's phase 5 is Metal-only). The sphere is now **curved** instead of faceted.
- **Not included:** upstream phase 5 also bundles globe gestures and the raster/hillshade/fill-extrusion families; those are out of scope here.
- **Patch:** added `patches/maplibre-native-0007-globe-phase-5-subdivision.patch`; regenerated 0006 to fix non-ASCII bytes. The seven-patch chain (0001-0007) reproduces the tree.
- **Built & run:** maplibre-native-qt compiled clean on MSVC/Vulkan; MapLibreEarth rebuilt and launched.
- **References:** [Globe projection](./concepts/globe-projection.md) · [Fork patches](./references/fork-patches.md).

## 2026-10-11 — Globe tile cover (phase 7) — fixes limb gaps

- **Symptom:** at whole-globe view, the globe's limb had empty areas that appeared and moved as the globe rotated — the tile cover was still Mercator-shaped, so the visible hemisphere was not fully covered.
- **Implemented:** globe **phase 7** (`4e83526f`, PR #4533): `util/bounding_volumes` (frustum volume/plane intersection) and `util/mat3`, plus a globe branch in `util/tile_cover` that tests tiles against the camera frustum in unit-sphere space and the horizon plane, loading only the visible hemisphere. `TileCoverParameters::transformState` became a reference.
- **Patch:** added `patches/maplibre-native-0008-globe-phase-7-tile-cover.patch`; the eight-patch chain (0001-0008) reproduces the tree.
- **Built & run:** compiled clean on MSVC/Vulkan; MapLibreEarth rebuilt and launched.
- **References:** [Globe projection](./concepts/globe-projection.md) · [Fork patches](./references/fork-patches.md).

## 2026-10-11 — Globe phase 6 + globe→Mercator hand-off (fixes zoom-to-solid-colour)

- **Bug (reported):** zooming with the wheel, some steps showed a single flat colour filling the window. Diagnosed with an instrumented build: the globe radius (`worldSize/2π/cos(lat)`) grows without bound while `cameraToCenterDistance` stays fixed (~1321 px), so past a few zoom levels the camera sits on the sphere's surface → one colour.
- **Fix:** ported the **globe→Mercator hand-off** into `style::Projection::Impl::evaluate` — `globe` is a sphere above zoom 11, ordinary Mercator below 12, blended in between (GL JS's behaviour). This also gives the **globe→flat morph**. Also ported **phase 6** (`2f7bcd9e`): globe unproject, anchored zoom, constrain and camera-state caching.
- **Qt fix:** decoupled `QMapLibre::Map::ProjectionType` (QML-facing, kept Mercator=0/Globe=1) from the native enum (which gained VerticalPerspective) after a value change briefly caused the app to load Mercator.
- **Patch:** added `patches/maplibre-native-0009-globe-phase-6-transform.patch`; the nine-patch chain (0001-0009) reproduces the tree's source.
- **Verified:** rebuilt and drove wheel zoom programmatically; high zoom now shows ~2800 distinct colours (map detail) instead of one. See [Globe projection](./concepts/globe-projection.md) · [Fork patches](./references/fork-patches.md).

## 2026-10-11 — Lines on the globe (fixes the single-colour smear)

- **Bug (reported):** zooming, many levels filled the whole window with a single colour. Found by capturing the window with `PrintWindow` (screen sampling was fooled by an overlapping window): the colour was **#E9AC77**, the style's road-casing line colour.
- **Cause:** the Vulkan **line** vertex shaders (`line`, `line-gradient`, `line-pattern`, `line-sdf`) still projected with `drawable.matrix` (Mercator); on the globe the road casings smeared across the window, reading as a solid fill. Line layers had simply never been made globe-aware (part of upstream phase 9a).
- **Fix:** bind the projection UBO and project the line position through `projectTile` (extrude via `fallback_matrix`), like the fill family. Carried as `patches/maplibre-native-0010-globe-lines-vulkan.patch`.
- **Verified:** captured the fixed globe (a clean sphere) where it was previously solid orange. The ten-patch chain (0001-0010) reproduces the tree's source.
- **Method note:** the app persists zoom/state and this session overlapped the whole window with the editor, so earlier capture-based measurements were unreliable; screenshotting via `PrintWindow`, then reading the image, was the decisive tool.
- **References:** [Globe projection](./concepts/globe-projection.md) · [Fork patches](./references/fork-patches.md).

## 2026-10-11 — Session wrap: globe renders on Vulkan (fills, background, lines)

**State when powered down:** the globe works on Vulkan — curved, horizon-covered, morphs to flat past zoom ~11, and draws fills, background and lines. Ten downstream patches (`patches/maplibre-native-0001`–`0010`) reproduce the vendored tree. `maplibre-native-qt` last commits: `3b1a201` (phase 6 + hand-off), `9e82f2d` (Qt enum), `69b359a` (lines). The MapLibreEarth wiki is committed with this entry.

**Outstanding:** the remaining layer families are not globe-aware and show artifacts — most visibly the `natural_earth` **raster** (a flat grey block on the globe). See [Next steps](./next-steps.md) for the ordered plan (rasters → fill-extrusion → symbols → circle/heatmap).

**Debugging notes for next time:**
- The app persists its state in `HKCU\\Software\\MapLibre\\MapLibreEarth` (zoom/center/style). Automated wheel-zoom testing drifts the center; delete the `map` values to reset to the QML defaults.
- This machine's editor window can overlap the app, so **screen pixel-sampling of the map is unreliable** — capture the app window with Win32 `PrintWindow(hwnd, hdc, 2)` and read the PNG instead.
- Add temporary diagnostics behind an env var writing to a file to a fixed temp path (`fprintf` to `env-or-fallback`), since GUI-app stderr is not visible.

## 2026-10-11 — Rasters on the globe (Vulkan)

- **Implemented:** globe **phase 9c** (`5d5a1ca9`, PR #4533) for Vulkan. The raster, hillshade and color-relief vertex shaders bind the projection UBO and project through `projectTile`; their render layers build the subdivided pole-capped `GlobeTileMesh` instead of the flat quad when `projectionVariant == Globe`. The `natural_earth` shaded relief now wraps onto the sphere (confirmed with a `PrintWindow` screenshot showing continents on the globe) instead of appearing as a flat grey block.
- **Patch:** added `patches/maplibre-native-0011-globe-raster-vulkan.patch`; the eleven-patch chain (0001-0011) reproduces the tree.
- **Gotcha:** after rebuilding the library, the app window's `QMapLibre.dll` is only refreshed when the MapLibreEarth target relinks — copy `install/maplibre-native-qt/bin/QMapLibre.dll` next to the app if a change doesn't appear.
- **References:** [Globe projection](./concepts/globe-projection.md) · [Fork patches](./references/fork-patches.md).

## 2026-10-11 — Circles/heatmaps (9b) and fill-extrusions (9d) on the globe

- **Phase 9b** (`3f24993a` → patch 0012): circle and heatmap vertex shaders project extruded corners on the sphere, via `projectToSphere` + a new `globeRotateVector` prelude helper + `interpolateProjection`, driven by a new `globe_extrude_scale` drawable field. Adds `LayerTweaker::globeExtrudeScale`.
- **Phase 9d** (`29d6dcd8` → patch 0013): fill-extrusion vertices project through `projectTileFor3D`; a new **`GlobeDepthPass`** writes the planet into the depth buffer before the translucent pass (so 3D geometry behind the horizon is hidden); fill-extrusion buckets subdivide walls/roofs on the globe. Adds `RenderLayer::projectionVariant` + `updateProjectionVariant`, the `GlobeDepthShader` (Vulkan) + registration in `vulkan/renderer_backend.cpp` and `cmake/vulkan.cmake`, and 3D prelude helpers. Upstream's TileProjector feature-query path was skipped (rendering does not need it).
- **Both build clean** on MSVC/Vulkan; the thirteen-patch chain (0001-0013) reproduces the tree. Committed `75c1318` (9b) and (9d).
- **Remaining:** phase 8 — symbols/labels on the globe (placement/collision, ~40 files); not started.
- **References:** [Globe projection](./concepts/globe-projection.md) · [Fork patches](./references/fork-patches.md).

## 2026-10-11 — Symbols/labels on the globe (phase 8) — all layer families done

- **Implemented:** globe **phase 8** (`3a217519`, PR #4533) for Vulkan. The symbol projection (`layout/symbol_projection`), collision index (`text/collision_index`) and placement (`text/placement`) now work on the sphere; the symbol vertex shaders project through a new `projectTileWithElevation` prelude helper; the symbol render layer switches projection variant. Added `src/mln/map/tile_projector.hpp` and the `mercator_projection`/`vertical_perspective_projection` symbol methods. Skipped the feature-query-only parts (TileProjector capture and the label-plane capture).
- **Patch:** added `patches/maplibre-native-0014-globe-symbols-vulkan.patch`; the fourteen-patch chain (0001-0014) reproduces the tree.
- **Built clean** on MSVC/Vulkan.
- **Milestone:** every layer family in the design proposal's phase plan is now globe-aware on Vulkan — fills, background, lines, rasters/hillshade/color-relief, circles/heatmaps, fill-extrusions and symbols. Remaining work is verification and polish, not porting. See [Next steps](./next-steps.md).
- **References:** [Globe projection](./concepts/globe-projection.md) · [Fork patches](./references/fork-patches.md).

## 2026-10-11 — Globe clip masks (phase 9f, Vulkan)

- **Context:** investigating a flicker (large translucent rectangles) while rotating the globe. Ruled out the globe depth pass (flicker persisted with it disabled) and projection-variant flapping (logged: one Mercator→Globe switch per layer at startup). The symptom points at raster-tile overlap/blend during the rotation load burst.
- **Implemented:** the **Vulkan half of phase 9f** (clip masks). `Context::renderGlobeTileClippingMasks` writes each tile's pole-capped mesh to the stencil, driven by a new `shaders::GlobeClipMask` block, so layers outside their tile are clipped on the sphere. Adds the globe branch to the Vulkan `clipping_mask` shader, a `granularity` parameter to `rawGlobeTileMesh`, and the shared `paint_parameters` globe branch (the earlier 'globe draws unclipped' early-return is removed).
- **Patch:** `patches/maplibre-native-0015-globe-clip-masks-vulkan.patch`; the fifteen-patch chain (0001-0015) reproduces the tree. Built clean on MSVC/Vulkan.
- **Remaining:** **phase 12o** (draw only the uncovered parts of raster tiles) — the direct fix for the raster-overlap flicker — needs the globe mesh **cache** refactor and a per-tile **mask** on the raster/hillshade buckets, which our tree lacks; it is a multi-file port, not yet started.
- **References:** [Globe projection](./concepts/globe-projection.md) · [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).
