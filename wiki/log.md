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

## 2026-10-11 — Raster uncovered-parts on the globe (phase 12o, Vulkan)

- **Implemented:** globe **phase 12o** (`9fa47e1f`). `GlobeTileMesh` now grids only the parts of a tile its **`TileMask`** keeps — an overlapped parent tile is split into quadrant parts gridded at the finer zoom — and a new `GlobeTileMeshCache` keyed by zoom/pole/mask dedupes the meshes. The raster, hillshade and color-relief render layers build their globe meshes through the cache with the bucket's mask. This stops overlapping raster tiles from blending, which is the cause of the translucent rectangles that flickered while rotating the globe.
- **Patch:** `patches/maplibre-native-0016-globe-raster-uncovered-vulkan.patch`; the sixteen-patch chain (0001-0016) reproduces the tree. Built clean on MSVC/Vulkan.
- **Milestone:** the whole design-proposal phase plan is now ported for Vulkan (plus the clip-mask and raster-coverage polish phases). Remaining is verification and the optional feature-query paths.
- **References:** [Globe projection](./concepts/globe-projection.md) · [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 — Globe high-zoom blank + tile-edge banding (patch 0017)

- **Symptom:** the globe rendered fine at low zoom but went **blank in a band around zoom 8-10** (the "UK fills the window" zoom). Once rendering, it showed a **wide darker band along tile edges** on the globe (e.g. a north-south band through Calbourne on the Isle of Wight, plus a horizontal one at z11) — but **not** on flat Mercator.
- **Root cause 1 — the blank:** the globe cover's **variable-zoom / level-of-detail** path legitimately requests tiles *finer* than the nominal covering zoom (at z8.99 it asks for z9). `TilePyramid` sized its `bounds`-derived `TileRange` guard with `maxZoom = min(tileZoom, zoomRange.max)` (the nominal zoom), so `TileRange::contains` failed the zoom check on every finer tile — 9 of 10 ideal tiles were rejected, the layer got ~1 render tile and the view went blank. Fixed by sizing the guard over the full source zoom range when variable-zoom is active (globe / `TileLodMode::Distance`) — `tile_pyramid.cpp`.
- **Root cause 2 — the band (a translation bug):** the port's `removeTrianglesOutsideTileX` / `removeLinesOutsideTileX` dropped a triangle only when **all** vertices were outside (`&&`); GL JS drops when **any** vertex is outside (`||`). So the subdivider kept triangles straddling the edge and bled up to a subdivision cell into the neighbour. Mirrored GL JS (`||`, z0-only).
- **Root cause 3 — the band (structural):** the fill geometry reaching the subdivider carries Native's tile **buffer**; the subdivision grid then rounds it up to a grid line a full cell past the tile edge (at granularity 2 the cell is `EXTENT/2` — half a tile), so adjacent tiles overlap over a wide strip and both draw it. Fixed by clipping fill polygons to `[0, EXTENT]` on both axes (Sutherland-Hodgman) in `gfx::generateFillAndOutineBuffers` **before** subdivision — the GL-JS-faithful place. (`fill_generator.cpp`.)
- **Patch:** `patches/maplibre-native-0017-globe-tile-edge-fixes.patch` (3 files); the seventeen-patch chain (0001-0017) reproduces the tree. Committed `ce2b55c` on `main` (fork).
- **Ruled out with source evidence (MapLibre GL JS):** subdivision granularity (identical — `fill (128,2)`, `line (512,0)`, `tile (128,32)`, `stencil (128,1)`), the clip-mesh granularity (GL JS stencil `(128,1)` = a quad; ours draws the static quad), and the tile buffer size (both 128). GL JS's guide confirms subdivision must "split the geometry in consistent places" and warns it is "very prone to subtle errors, resulting in single-pixel seams".
- **STILL OPEN — the thin line:** after the fixes a **thin (~1px) line remains at every globe tile edge** (both axes). Diagnosis: the anti-aliasing seam between separately-drawn tiles — each tile is its own primitive clipped at the shared meridian, and the two edges' projected vertices differ by float rounding, so their AA fringes do not coincide (the seam pixel shows ~25% background). **Planned fix:** apply the raster technique to globe **fills** — draw tiles with a small overlap but use the stencil to mark drawn pixels and discard already-marked ones ("draw once"), so there is neither a gap nor a double-blend. The fill layer already enables stencil (`render_fill_layer.cpp:187/196`); the two-pass draw-once pass is what is missing. Resume from [Next steps](./next-steps.md).
- **References:** [Globe projection](./concepts/globe-projection.md) · [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (later) — Globe tile-edge thin line — RESOLVED

- **Fixed the residual ~1px darker line at every globe tile edge** (e.g. the vertical line below the "a" in Calbourne). **Cause:** the patch-0017 clip (Sutherland-Hodgman to `[0, EXTENT]`) creates an **artificial edge** along the tile boundary where it cuts a crossing fill ring; the fill's **antialias outline** traces that edge, and **both** neighbouring tiles stroke the same meridian, so the two strokes blend into a ~3px darker line. **Diagnosed** by disabling `fill-antialias` — the seam column (x=991) dropped from 125 to gone; the geometry itself abuts exactly (dump: tile 507 reaches x=8192, tile 508 reaches x=0, no overlap).
- **Fix:** in `gfx::generateFillAndOutineBuffers`, skip fill-**outline** segments that lie along the tile's vertical boundary (`x == 0` / `x == EXTENT`) — they are clipping artifacts, not real polygon edges. The triangles still use the clipped geometry, so the wide band stays fixed. Folded into patch **0017** (now three files: `tile_pyramid.cpp`, `subdivision.cpp`, `fill_generator.cpp`). Committed `8784f61` on `main` (fork).
- **Verified:** seam gone at Calbourne z10/z11, no distortion. Note GL JS does **no** geometry clipping at all (its tiles are `[0, EXTENT]` from the source, and it only warns if they exceed that), so it never creates the artificial edge — this fix makes the Native appearance match.
- **Ruled out along the way** (with source evidence): subdivision granularity (identical to GL JS), clip-mesh granularity (both quads), buffer size (both 128), MSAA (Native Vulkan uses `e1`), and the per-tile stencil clip (seam persisted with the stencil disabled).
- **References:** [Globe projection](./concepts/globe-projection.md) · [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (later still) — First-run map did not paint until panned/zoomed

- **Symptom:** on a cold start the map showed only the background (no tiles) until the user panned or zoomed, after which it was fine.
- **Diagnosis:** captured the app with `PrintWindow` at t=4s with no input — essentially unpainted (1/40548 water samples); after a single zoom kick it was fully painted (22808/40548). So the tiles were loaded but the map was **not repainted** until an input forced it.
- **Cause:** in the Qt Quick map item (`map_quick_item.cpp`), rendering is driven by Qt scene-graph repaints. It only scheduled a repaint on the scheduler's `needsRendering` signal plus one delayed update on `MapChangeDidFinishLoadingMap` — it did **not** update on `MapChangeDidFinishRenderingFrame`. Tiles arriving after the initial frame were rendered into the target but never shown.
- **Fix:** handle `MapChangeDidFinishRenderingFrame` by scheduling another `QQuickItem::update()`, so the map keeps repainting until it reports a fully rendered frame. Verified: fully rendered by t=6s with no input, and 0 ms CPU over 5 s idle (no busy loop).
- **Committed** `c31de46` on `main` (fork) — a **wrapper** change (not a vendored patch).
- **Unrelated note:** the `"Invalid geometry in line layer"` warning seen when panning to IOW is a pre-existing style/data mismatch (point features fed to a line layer in the OpenFreeMap liberty style), not the globe work — left as is.
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — 3D terrain: phase 1 (style property + API)

- **Started 3D terrain** — aerial imagery draped over terrain, the GL JS **render-to-texture** approach. Chosen approach: build directly on the fork's existing per-tile RTT framework (`RenderTarget`/`OffscreenTexture`, already used by hillshade and heatmap on Vulkan) rather than back-porting upstream's experimental, actively-reverting `feature/terrain-3d` branch. Flat/Mercator first; full drape as the first milestone.
- **Implemented phase 1** (patch **0019**, commit `e3e678b` on `main`/fork): the style's root `terrain` object (`{source, exaggeration}`) modelled on `projection`/`light` — `Terrain` + `TerrainObserver`, its conversion, parser wiring, and `Style`/`Style::Impl` storage; `Map::setTerrain` / `clearTerrain` / `hasTerrain` / `getTerrainSource` / `getTerrainExaggeration` (source validated as `raster-dem`); Qt `Map::setTerrain`/`clearTerrain`; QML `terrainSource` + `terrainExaggeration`, re-applied after each style load. The renderer is unchanged — it still draws flat.
- **Verified:** `mbgl-core`, `MLNQtCore`, `MLNQtQuickPrivate` and `declarative_maplibre` all build (Release, MSVC / Vulkan); patch 0019 applies cleanly to a pristine + `0001`–`0018` tree and reproduces the working tree.
- **Next:** phase 2 — camera elevation in `Transform`/`TransformState` (+ synchronous centre anchoring in render setup). See [Next steps](./next-steps.md) and [Fork patches](./references/fork-patches.md).
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md) · [Project history](./history.md).

## 2026-10-12 (terrain) — 3D terrain: phase 2 (transform elevation)

- **Implemented phase 2** (patch **0020**, commit `8473c72` on `main`/fork): `TransformState`/`Transform` gain `getElevation()` / `setElevation()` — naming the map centre's altitude as the ground elevation under it (GL JS's `transform.elevation`) — and `getCameraAltitude()`.
- **Why it is thin:** the GL JS formulas confirm the mapping. GL JS's `getCameraAltitude() = cos(pitch)·cameraToCenterDistance/pixelsPerMeter + elevation` is exactly what Native's `updateCameraState()` already derives from the centre altitude (`z`), which the style's `centerAltitude` / `setCenterAltitude` already drive. So in this port `setElevation` is the existing centre-altitude path, and the camera is lifted with the terrain for free.
- **Deferred:** GL JS's `recalculateZoomAndCenter` (which keeps the camera fixed and moves the centre/zoom when the terrain under the centre changes) is **not** ported yet — it is only meaningful once something samples terrain, so it will land with the DEM provider / mesh phases where it can be tested.
- **Verified:** `mbgl-core` builds (Release, MSVC / Vulkan); patch 0020 applies cleanly to a pristine + `0001`–`0019` tree and reproduces the working tree.
- **Next:** phase 3 — terrain tile manager + DEM elevation provider (reuse `DEMData` / `RasterDEMTile`). See [Next steps](./next-steps.md) and [Fork patches](./references/fork-patches.md).
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md) · [Project history](./history.md).

## 2026-10-12 (terrain) — 3D terrain: phase 3 slice 1 (DEM elevation sampler)

- **Implemented** (patch **0021**, commit `e24d058` on `main`/fork): `DEMData::getElevation(x, y)` — bilinear interpolation of the metre elevation at a continuous tile coordinate in `[0, dim]`, mirroring GL JS `DEMData#getElevation`, adapted to Native's one-pixel border. Added unit tests in `test/geometry/dem_data.test.cpp` (integer-coordinate and mid-point cases).
- **Verified:** `mbgl-core` and `mbgl-test` both compile with the change; patch 0021 applies cleanly to a pristine + `0001`–`0020` tree and reproduces the working tree. Note: `mbgl-test` in this Qt-only build is a **static library** with no runner executable, so the native gtest could not be executed here — compile only.
- **Still to do for phase 3:** the terrain **tile manager** — fetching DEM tiles over the terrain cover and exposing sampled elevation (reusing `RasterDEMTile`/`RenderRasterDEMSource` and `DEMData`). Open architecture decision: a terrain-owned tile manager (as GL JS has) vs. reusing the source's tile pyramid (which only loads tiles a layer uses, and terrain has no layer).
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — 3D terrain: phase 3 (DEM elevation provider)

- **Implemented the terrain DEM provider** (patches **0021** `e24d058`, **0022** `bb3b9bc`): `DEMData::getElevation` (bilinear sampler, GL JS `DEMData#getElevation` adapted to the one-pixel border) and a **terrain-owned `TerrainTileManager`** (`src/mln/renderer/terrain_tile_manager.{hpp,cpp}`). Decision: a raster-dem source only loads tiles a *layer* uses and terrain has no layer, so terrain manages its own tile set — the manager fetches/decodes raster-dem tiles via the `FileSource`, caches `DEMData`, and exposes `getElevation(latLng, zoom)` (0 until loaded) plus `tileFor`. `getDEMData` is virtual so tests inject data.
- **Verified:** `mbgl-core` and `mbgl-test` compile; both patches apply cleanly to a pristine + prior tree and reproduce the working tree. Unit tests added (`test/geometry/dem_data.test.cpp`, `test/renderer/terrain_tile_manager.test.cpp`) but, as before, **not run** — `mbgl-test` in this Qt-only build is a static library with no runner executable.
- **Not wired:** nothing constructs a `TerrainTileManager` yet; it is consumed by the terrain mesh / camera (phases 4+).
- **Next:** phase 4 — terrain mesh (pinned to the DEM zoom) + Vulkan terrain shader; then the RTT drape split and the Vulkan depth pass. This is the bulk of the feature.
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — 3D terrain: phase 4 (render pass) — in progress

- **Implemented the terrain render pass** (patches **0023** `c5fcf5e`, **0024** `a0c9048`): a Vulkan `TerrainShader` (single `float4` vertex attribute — tile xy, world-pixel elevation, hillshade), a `TerrainPass` that builds a 16×16 grid mesh per DEM tile with CPU-baked elevation + hillshade and draws it with depth after the flat layers, `UpdateParameters.terrainTileset`/`terrainExaggeration` resolved from the style's terrain source in `Map::Impl`, and the pass wired into `RenderOrchestrator` + `RendererImpl`. 0024 makes the tile manager report loads so the map repaints (terrain is not a style source, so the map stopped after the first few frames otherwise).
- **How it was tested:** a local style (`MapLibreEarth/terrain-style.json`) with an inline AWS terrarium `raster-dem` source + `terrain`, loaded via `file://C:/...` (note: `file://` + Windows path needs two slashes, not three), and `terrainSource: "dem"` from QML.
- **Confirmed working (with temporary `fprintf` diagnostics, since removed):** the style's terrain resolves (`getTerrain` → source `dem`, `isTileset=1`), the shader is found, DEM tiles fetch + decode (`RES ... err=0 bytes≈137k`), and the pass builds **100** drawables with a valid mesh (elevation 1554–2800 m; first vertex (0,0,44.63,0.82)) and a valid projection matrix.
- **STILL NOT VISIBLE:** the surface does not appear — the map shows only the style background. Depth on/off makes no difference. The bug is in the raw-vertex (Float4) attribute binding or the terrain shader/`projectTileFor3D` usage, not in the data. Resume there.
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).
