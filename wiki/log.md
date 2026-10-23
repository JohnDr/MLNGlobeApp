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

## 2026-10-12 (terrain) — phase 4 bug chase: the attribute binding is fine

- **Disproved the attribute-binding theory.** With `fprintf` diagnostics (since removed) I confirmed the full draw path executes for the terrain drawables: the pass builds **100** drawables (`total=100`), `TileLayerGroup::render` runs them (`render call count=100`), the `TerrainTweaker` executes on real z12 tiles (so `hasRenderPass`/`draw()` are reached), and `Drawable::bindAttributes` **never** returns false (unconditionally instrumented — no `no-vbuf`, no `setVertices` type mismatch). So the raw `Float4` vertex attribute binds, the vertex buffer is bound, and `drawIndexed` runs.
- **Yet nothing renders.** Even after replacing the vertex shader with a **direct-NDC** mapping (`gl_Position = vec4(in_position.xy/4096-1, 0, 1)`) and the fragment with a **solid magenta**, the map still shows only the style background. Depth on/off makes no difference; the scissor rect is the full viewport.
- **Conclusion:** the fault is past the data/binding — it is in the **`TerrainShader` pipeline** (SPIR-V compile / pipeline layout / vertex-input state), not in the mesh, projection matrix, attribute binding, or the pass wiring. The terrain drawables are submitted and their draw is issued, but produce no fragments.
- **Next:** verify the `TerrainShader` compiles and its pipeline is valid — e.g. capture the Vulkan validation messages, or bisect by rendering the terrain mesh with an existing known-good shader (matching its attribute type). The SwiftShader/validation layer would make this visible.
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — phase 4 bug chase 2: colour mask + projection timing

- **Enabled Vulkan validation.** The app uses Qt Quick's Vulkan instance (the `VulkanRendererBackend` Qt-device path), which bypasses maplibre's own instance where the validation layer/messenger are wired. Forcing maplibre's own instance made the map render white (it breaks Qt's zero-copy texture sharing), so validation was captured by forcing the *loader* to add the layer (`VK_INSTANCE_LAYERS=VK_LAYER_KHRONOS_validation`) on the Qt instance. **Result: zero validation errors / no VUIDs** — the terrain draws were valid Vulkan all along.
- **Fixed bug 1 — colour write mask.** `DrawableBuilder`'s default `ColorMode::disabled()` sets the colour write mask to **all false**. The background sets a real colour mode; the terrain didn't, so it wrote no colour. Fixed with `ColorMode::unblended()`.
- **Fixed bug 2 — projection UBO timing.** Set from a **drawable** tweaker (runs in the render pass, after upload) the projection uniform buffer was stale at draw time. Moved to `TerrainPass::update`, which runs **before** the upload pass. Both fixes are patch **0025** (`edfd72a`).
- **Diagnosis status:** with the colour mask fixed, a **direct-NDC** vertex shader renders the terrain (full-screen colour), proving pipeline + attribute + draw all work; but `projectTileFor3D`/`projectTile` places the terrain **off-screen**, so the remaining bug is the **projection matrix used for the terrain tiles** in `TerrainPass::update` (`state.getProjectionData` via `PaintParameters::projectDataForTile`), not the shader/binding/draw path.
- **Next:** dump and verify the projection UBO matrix for a camera-covering DEM tile (the composed `projMatrix * tileMatrix` should map tile coords `0..EXTENT` to NDC near `[-1,1]`); fix how the per-tile matrix is obtained.
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — phase 4 bug chase 3: the projection matrix

- **Confirmed the projection is the last bug.** With the colour-write fix in place, a direct-NDC vertex shader renders the terrain (full-screen), but the real projection places it off-screen.
- **Matrix dump** for a camera-covering DEM tile (z12, 2160/1444): `m0=355254.7 m5=250329.1 m12=0 m13=0 m15=124043.9` — i.e. scaling tile coords `0..EXTENT` to clip produces values around `10^9` and `w≈-4·10^8`, so every tile lands at NDC ≈ `(-3.4, -2.0)`, off-screen. Both `PaintParameters::projectionDataForTile` and the normal-layer `LayerTweaker::getProjectionData` give the **same** (wrong-looking) matrix, so the terrain uses the same construction as fills — the discrepancy is not the call site. Using UBO index `0` vs `constant.ubo_index` changes nothing.
- **Next:** determine why this per-tile matrix is ~`10^10` too large for the terrain tiles — check the `ProjectionUBO` C++/GLSL field-layout match, and compare the identical matrix dumped from a *working* fill/background drawable for the same tile. That comparison will show whether the matrix values are actually abnormal or whether the shader reads the UBO with a mismatched layout.
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — phase 4 bug chase 4: the matrix really is inconsistent

- **`mat4` is `double`-backed**, so the earlier `reinterpret_cast<const float*>` dumps were garbage. Re-dumped as `double`.
- For a camera-covering tile the pieces are individually sane:
  - `transformParams.projMatrix` ≈ `[2.95 ... | -3 ... | ... -0.0191 ... | -1892 1921.5 1921.5 1921.5]`; `state.matrixFor(tile)` = uniform `0.015625` scale + a world translation (`276480, 184832`).
  - `projMatrix · matrixFor(tile)` (computed explicitly with `matrix::multiply`) gives `m0≈0.046, m15≈1921.5` — a plausible tile→clip matrix.
- **But the matrix actually uploaded/fed to the shader (`toProjectionUBO(projectionDataForTile(tile)).matrix`) is different** — e.g. `m0=355255, m5=250329, m15=124044` (z12) / `m0=602.2, m5=611.6, m15=2125.4` (z3) — it does **not** equal `projMatrix · matrixFor(tile)`.
- **C++/GLSL `ProjectionUBO` layouts match** (matrix, fallback_matrix, tile_mercator_coords, clipping_plane, …), so it is not a struct-layout mismatch. The discrepancy is inside the projection-data construction (`TransformState::getProjectionData` → `matrix::multiply(mercatorMatrix, projMatrix, mercatorMatrix)`) — confirm the multiply argument/order convention and which `projMatrix`/`tileMatrix` it actually composes.
- **Next:** read `matrix::multiply`'s implementation (order of `a`,`b`) and `MercatorProjection::tileMatrix` vs `TransformState::matrixFor`; the terrain's `toProjectionUBO` result should then either match a fill drawable's or reveal the wrong operand.
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — 3D terrain phase 4: it renders

- **The terrain now draws as a shaded elevated surface** (patches **0023**–**0026**; rendered on-device with the Alps/DEM test style). Root cause turned out to be **two** things:
  1. **UBO consolidation** (`MLN_UBO_CONSOLIDATION` is on for Vulkan): the shader reads the **layer group's** shared projection buffer, indexed by each drawable's `uboIndex`. Terrain never populated it (so the shader read garbage) and every drawable's `uboIndex` stayed 0. Fixed by filling the layer group's projection buffer in `TerrainPass::update` exactly as the layer tweakers' `uploadProjectionUBOs` does, and assigning `drawable.setUBOIndex(i++)`.
  2. **Wrong tile matrix**: `PaintParameters::projectionDataForTile` returned a matrix that sent tiles off-screen; the correct tile→clip matrix is `projMatrix · state.matrixFor(tileID)` (what `LayerTweaker::getProjectionData` composes for fills, via `multiplyWithProjectionMatrix`).
- **How it was confirmed:** with the UBO populated, a probe shader output `projection_ubo[...].matrix[0][0]` as colour → `≈357000`, proving the UBO was now read; switching to the `projMatrix · matrixFor(tile)` matrix made the DEM surface appear with hillshading.
- Earlier fixes along the way: the colour-write mask (`ColorMode::unblended()`, the default `disabled()` writes no colour) and repaint-on-tile-load (patch 0024). Vulkan validation reported no errors throughout — it was never a validation bug.
- **Next:** phase 5 — drape the map layers (raster/fill/line, then symbols) onto the terrain via per-tile render targets, replacing the current flat-layer-under-terrain look. Then phase 6 (depth pass/occlusion), phase 7 (symbol elevation), phase 8 (globe × terrain).
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — phase 5: screen-space drape (first cut)

- **Implemented a first-cut drape** (patch **0027**): the orchestrator owns a full-viewport offscreen `RenderTarget` (registered via `addRenderTarget`, populated with the live layer groups); `TerrainPass` binds its texture to the terrain drawables; the terrain shader samples it at each fragment's screen position (`v_uv` from `gl_Position`) and multiplies by the hillshade. The map content now sits on the relief.
- **Confirmed on-device:** the grey map background appears draped over the terrain with hillshading.
- **Known issues (to refine):** it is **screen-space**, so imagery has parallax error under tilt (a per-tile RTT split is the proper GL JS approach); and **uncovered regions of the render target show as blue artifacts** (the RTT's clear/gap handling needs work). The layer groups are also rendered twice (into the RTT and to the screen), which is wasteful.
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — phase 5 polish (a): gap artifacts not solved yet

- **Tried the obvious fixes:** (1) skip rendering the layer groups to the screen when the drape is active (no double render) and (2) disable terrain depth. Neither removed the **tile-grid blue gaps** in the drape.
- **Ruled out:** the gaps are **not** a missing mesh — the terrain builds and draws all `drawables=100` / `cover=100` every frame. Depth on/off makes no difference. A solid-colour terrain fragment still shows the gaps, so they are the pixels *behind* the terrain in a tile-grid pattern (the offscreen RTT's uncovered/untouched regions), not the drape sampling.
- **Conclusion:** the screen-space drape's offscreen `RenderTarget` render leaves tile-shaped untouched regions (blue). The per-tile approach (**b**) sidesteps this: each terrain tile renders its own layers into a self-contained tile-sized target. Extra changes reverted; the vendored tree matches patch **0027**.
- **Next:** implement the **per-tile RTT** drape (GL JS-style): terrain tiles render drape-eligible layers into per-tile render targets and the terrain mesh samples its own tile's texture.
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — phase 5: per-tile RTT drape (works)

- **Confirmed against GL JS source** (`src/webgl/render_to_texture.ts`): current GL JS renders RTT-eligible layers (`background`, `fill`, `line`, `raster`, `hillshade`, `color-relief`; **not** symbols) into **per-tile cached textures** and drapes them onto the terrain mesh — so per-tile RTT is the faithful approach (the old "one shared screen-space texture" design is outdated).
- **Implemented per-tile RTT** (patch **0028**): each terrain tile gets its own tile-sized `RenderTarget` holding the draped layers, rendered with a **per-tile orthographic projection** (added `PaintParameters::projMatrixOverride`, honored by `projectionDataForTile` and `multiplyWithProjectionMatrix`). The terrain mesh samples its own tile's texture at a tile-local UV (`in_position.xy / EXTENT`). **Renders seamlessly on-device** — no parallax and the blue screen-space gap artifacts are gone.
- Remaining refinements (not blockers): the per-tile targets re-render every frame (GL JS caches with per-tile fingerprints + a per-frame budget), and non-draped symbol layers are currently draped too (GL JS keeps them screen-space).
- **Next:** phase 6 — Vulkan depth-attachment offscreen texture + terrain depth pass/occlusion; phase 7 symbol elevation; phase 8 globe × terrain.
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — phase 5 refinements: screen-space symbols + texture cache

- **Symbols stay screen-space** (confirmed against GL JS `LAYERS_TO_TEXTURES` — only background/fill/line/raster/hillshade/color-relief are draped; symbols are "live"): implemented in patch **0029** by classifying style layers by `getTypeInfo()->type`, restricting the per-tile targets to the drape-eligible layers, and drawing the rest on top (the translucent pass now renders the terrain first, then the non-draped groups).
- **Per-tile texture cache** (patch **0029**): each drape tile stores a fingerprint (layer/source/image identity, DEM zoom, group/layer counts, plus a `drapeGeneration` bumped in `onTileChanged`); a tile re-renders only when new or when its fingerprint changes. Idle frames no longer re-render every tile. First-cut bug (the first render cached an empty layer set as black) was fixed by folding the group/layer counts into the fingerprint.
- **Verified on-device** with the background+drape style (steady #8899aa×hillshade). Note: a quick OSM-raster test style showed black at zoom 12 (OSM tiles did not load in the sandbox) — unrelated to the drape code.
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — phase 7: symbol elevation (compile-verified)

- **Implemented symbol elevation** (patch **0030**): `PaintParameters::terrainElevationFn` samples the DEM elevation (world pixels) at a tile centre; the symbol tweaker writes it into a new `SymbolDrawableUBO` field (repurposed `pad1`); the symbol shaders pass `drawable.elevation` into the existing `projectTileWithElevation` calls (were `0.0`). So symbols sit on the draped surface. Uses a per-tile-centre approximation (≈ a few px error at typical zooms). `field` symbols (along-line / variable anchors) aren't yet elevated.
- **Note:** phase 6 (a separate depth-attachment texture) turned out unnecessary — the terrain already writes depth to the main buffer and symbols draw after it; real occlusion comes from elevation + depth, which this patch moves toward.
- **Verification:** compiles (mbgl-core). **Not visually confirmed** — the sandbox can't load the glyphs (`demotiles.maplibre.org/font`) needed to render symbol text, so no labels appeared even with terrain off. The elevation path only runs when symbol drawables exist.
- **Next:** phase 8 — globe × terrain, fog/sky (large; no upstream reference for globe terrain).
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — phase 8: globe × terrain (renders, mesh rough)

- **The terrain now renders draped on the globe** (patch **0031**): the `TerrainShader` projection variant is chosen from the transform (`state.isGlobeRendering()` → Globe, else Mercator), drawables rebuild on variant change, and the globe uses `projectionDataForTile`'s globe matrix (not the Mercator `projMatrix·matrixFor` composition). Confirmed on-device — a draped sphere.
- **Known roughness:** the mesh is still the flat 16×16 tile grid, so on the sphere tiles appear as overlapping "petals" with gaps — the globe needs the curvature / pole-capped tessellation the globe background layer uses (its own follow-up).
- **Fog/sky and true pole handling** are not started.
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — app: a draped-terrain map in the Maps list

- **Added a "3D Terrain (satellite draped)" entry to the Maps list** (app commit `733a374`). Its style (`terrain-style.json`) has an **Esri World Imagery** raster source plus an **AWS terrarium** `raster-dem` source and a `terrain` root property, so the satellite imagery is draped over the relief by the fork's per-tile RTT drape. Verified on-device: **satellite imagery over the 3D relief** (Matterhorn, pitched ~67°) and a draped globe.
- The QML computes the local `file://` style URL from `window.terrainStyleUrl` (maplibre's file source needs `file://` + the drive path, no third slash); adjust the path per machine.
- **References:** [Next steps](./next-steps.md) · [Fork patches](./references/fork-patches.md).

## 2026-10-12 (terrain) — the draped-terrain map was hidden by the stored list

- **Symptom:** the new "3D Terrain (satellite draped)" entry didn't appear for the user — a stored `maps/list` (QSettings) from an earlier version replaced `defaultMapStyles` wholesale, so newly-added built-in maps never showed.
- **Fix (app commit `7c2f281`):** `loadMapStyles` now appends any `defaultMapStyles` entry whose URL isn't already in the stored list. Confirmed the stored list now contains the terrain entry.
- **Confirmed draping works** with that style on-device: satellite imagery conforming to the 3D relief at ~66° pitch. Known artifact: some far/horizon tiles show un-draped (dark) patches.
- **References:** [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — "no draping": the map was in globe mode

- **Symptom:** selecting "3D Terrain (satellite draped)" showed satellite imagery but no drape. **Cause:** the app defaults to **globe mode**, and the drape is unreliable there (the globe terrain mesh is still rough); a flat map at pitch 0 also *looks* undraped even though the drape is present.
- **Fix (app commit `236b0e1`):** `selectMap` switches the terrain style to **flat (Mercator)** and sets a **50° tilt** (applied once the style loads, via the existing style-loaded camera apply), so the drape over the relief is immediately visible. Rebuild the app, select the map, and the relief shows without needing to tilt by hand.
- **References:** [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — "no draping" root cause: empty terrainSource cleared the style's terrain

- **The real cause** (confirmed with a diagnostic: `terrainTileset=0`): `terrainEnabled: false` makes the app's `terrainSource` empty, and the QML item's `setTerrainSource("")` calls `clearTerrain()` — which **wipes the style's own `terrain` root property**. So the draped-terrain style's terrain was deleted, and the raster drew flat.
- **Fix (app commit `58c5faf`):** when the terrain style loads (Maps list **or** preset), `onStyleUrlChanged` turns terrain on (`terrainSource="dem"`), switches to flat projection and tilts — so the drape shows. Diagnostic confirmed `terrainTileset=1` afterwards.
- **Pipeline verified:** a background-only terrain style drapes correctly (grey `#8899aa` over the relief).
- **Remaining:** the satellite **raster layer isn't being captured into the drape render targets** in the current build (black → the new hypsometric fallback tint, patch `cad250e`), though it draped at patch 0029. Needs investigation. The fallback (`maplibre-native-0032`) now keeps the relief visible regardless.
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12 (terrain) — raster still not captured into the drape targets

- **Fixed from the logs:**
  - `Vulkan texture allocation failed` — the 512px per-tile drape targets (100+) exhausted GPU memory; reduced to **256px** (patch **0033**, `945a8cf`). The terrain **relief now renders** (visible ridges/valleys) instead of a black frame.
  - `Terrain source 'dem' not found in style` — the terrain toggle persisted across styles; now it is only on for the draped-terrain style (app `c535d31`).
- **Still open:** the **satellite raster layer is not captured into the per-tile drape targets** — the drape is black, so the new hypsometric fallback (patch 0032) shows the tint instead of imagery. The raster uses `RasterLayerTweaker`'s `getProjectionData` (which honors `projMatrixOverride`) and "raster" is in the drape set, so the cause is elsewhere (likely the raster layer group not rendering in `RenderTarget::render`, or its tiles/textures under memory pressure).
- **Also seen:** `Invalid geometry in line layer` — a style geometry warning, unrelated to the drape.
- **References:** [Fork patches](./references/fork-patches.md) · [Next steps](./next-steps.md).

## 2026-10-12/13 — session handoff: terrain drape, and a raster regression

**Goal:** get aerial imagery visibly draped over the terrain. See [3D terrain](./concepts/terrain.md).

### Where it stands
- The terrain **renders** as a shaded elevated surface (flat/Mercator): relief is visible on-device.
- The **satellite raster is not captured into the per-tile drape targets** — this is the blocker. The drape is black, so the fallback tint (patch 0032) shows instead of imagery.

### ⚠️ It is a REGRESSION (agreed)
Satellite imagery **was draped over the Matterhorn around patch 0029** (`9971e08`, style commit `733a374`). It broke between **0030** (symbol elevation) and **0033**. Bisect range for tomorrow: rebuild at `0029` vs `0031` and check the raster. See the diagnostics list in [Next steps](./next-steps.md).

### Fixed today
- **`Vulkan texture allocation failed`** (`texture2d.cpp`) — 512px per-tile drape targets (100+) exhausted GPU memory → **256px** (patch **0033**, `945a8cf`). The relief now renders.
- **`Terrain source 'dem' not found in style`** — the terrain toggle persisted across styles; now it's on only for the draped-terrain style (app `c535d31`).
- **The raster drew flat / no drape** — the app's empty `terrainSource` (`terrainEnabled` false) called `clearTerrain()`, which **wipes a style's own `terrain`**. Fixed: `onStyleUrlChanged` turns terrain on (+ flat + tilt) for the terrain style (app `58c5faf`). Confirmed via diagnostic (`terrainTileset=1`).

### App
- "3D Terrain (satellite draped)" is in the Maps list (`terrain-style.json` = Esri World Imagery + AWS terrarium `raster-dem` + `terrain`); selecting it switches to flat + tilts; built-in maps are merged into a stored list (`733a374`, `7c2f281`).
- The style URL is machine-specific: `window.terrainStyleUrl` in `main.qml` = `file://C:/hda/dev/Projects/MapLibreEarth/terrain-style.json`.

### Commits today
- fork `main`: `d6f6756` (globe variant), `cad250e` (fallback tint), `945a8cf` (256px targets).
- app `main`: `733a374`, `7c2f281`, `58c5faf`, `c535d31`.
- Also seen (unrelated): `Invalid geometry in line layer`.

### Verified pipeline
A **background-only** terrain style drapes correctly (grey over the relief) — so the drape pipeline works; only the raster content is missing.
- **References:** [Next steps](./next-steps.md) · [Fork patches](./references/fork-patches.md) · [3D terrain](./concepts/terrain.md).

## 2026-10-13 — raster regression: narrowed (still open)

Instrumented the drape path (temporary `fprintf`s, since removed) and found:

- `TerrainPass::update` runs: `shader=1 demZoom=14 cover=72`.
- `RenderOrchestrator::renderTerrainDrapeTargets` runs and renders the targets: `toRender=72 targets=72`.
- The drape target **contains the raster**: `groups=1: 1(d=72)` — the raster layer group is present with 72 drawables.
- The `drapeLayerIndices` are `{0 1}` (style indices) while `layerGroupsByLayerIndex` is keyed `{1, 2}` — a **key-space mismatch** worth checking, but the raster (group `1`) *is* selected.
- Yet a **raw drape sample is black** (fragment changed to `texture(drapeSampler, …)` with no shade/tint) — so the raster's drawables produce **no visible content inside the target**, even though the group is present and the target is rendered.

Also fixed: **patch 0034** (`7514f65`) — the per-tile ortho was **y-flipped** (`matrix::ortho` maps its `top` arg to clip +1, but Mercator world-y grows downward); now passes `(ty+s, ty)`. This corrected the drape orientation but did **not** recover the raster.

**Where to look next:** why the raster's drawables draw nothing inside `RenderTarget::render` — the per-tile `projMatrixOverride` reaches `multiplyWithProjectionMatrix`, but the raster's tile drawables may end up off-screen / clipped, or their tile textures aren't ready at target-render time. Bisect `0029` (worked) → `0031`.
- **References:** [Next steps](./next-steps.md) · [3D terrain](./concepts/terrain.md).

## 2026-10-13 — Terrain raster drape: localised (per-target projection UBO not applied)

Continued the raster-drape investigation on-device (Windows/Vulkan, flat/Mercator at the Matterhorn, zoom 13). All instrumentation was reverted; the vendored tree again matches patches 0001–0034 exactly.

**Reproduced:** terrain relief + hypsometric fallback tint (patch **0032**), no satellite imagery.

**Controls run** (each a rebuild + on-device screen capture):
- A flat (no-terrain) style with the same Esri source renders the Matterhorn perfectly → the raster source/tiles are fine.
- Drawing the drape targets with the main `projMatrix` in place of the per-tile ortho → imagery appears in every tile.
- Raster fragment forced to solid magenta → **no** magenta in the drape; setting the offscreen clear colour to red turns the whole drape red. So the terrain samples the target, but the raster writes **nothing**.
- Magenta + `gl_Position` bypassed (tile coords written straight to clip) → magenta appears. So the raster drawable, the offscreen render pass, and the texture binding all work.

**Conclusion:** the per-tile ortho is numerically correct (a coincident z14 raster tile composes to `clip (-1,1)…(1,-1)`), the raster group is added to each target and `drawables=5 submitted=5` in the translucent pass — but the projection matrix the raster shader reads is **not** the per-target ortho. Leading cause: the consolidated projection SSBO is re-uploaded per tile in the **render phase**, and Vulkan's per-frame buffer windowing (`BufferResource::update`/`updateVulkanBuffer`) drops per-tile updates within one frame; only a frame-stable matrix (the main `projMatrix`) takes effect. This is **not** the assumed 0029→0031 regression: the capture code is byte-identical to patch 0029 apart from the tile size (0033) and the ortho y-flip (0034).

**Next:** confirm with a projection-buffer readback, then fix by giving each drape target its own projection data (per-target UBO/index) or uploading the per-tile matrices in the update phase before the upload pass. See [Next steps](./next-steps.md) and [3D terrain](./concepts/terrain.md).

## 2026-10-13 — Terrain raster drape: readback + per-target projection fix

Follow-up to the localisation above.

**Readback:** dumping the raster layer group's `ProjectionUBO` during the render phase revealed that the group is **transient** in `layerGroupsByLayerIndex` — it is added to each render target in `updateLayers` and then removed from the map by `processChanges`, so at draw time the map looks nearly empty even though the target still holds the group. Code review then confirmed the mechanism: `maxFrames = 1` is forced by the Qt offscreen backend (`vulkan_renderer_backend.cpp`, `initSwapchain()`), so each layer has a single buffer window; `renderTerrainDrapeTargets` re-runs each drape layer's tweaker once per terrain tile within one command buffer, so the per-tile projection uploads collapse to the last write and every target is drawn with the wrong matrix.

**Fix (implemented): per-target projection block.**
- `PaintParameters::drapeTargetOrdinal` (−1 off-drape); set per tile in `renderTerrainDrapeTargets`.
- `gfx::UniformBuffer` gains an offset-aware `update(data, size, offset)` (default falls back to a whole-buffer update) plus `contents()`; the Vulkan `UniformBuffer` implements both. `LayerTweaker::uploadProjectionUBOs` takes a `baseElement`.
- `RasterLayerTweaker` sizes the projection and drawable buffers to `base + drawableCount` and offsets `setUBOIndex`, so each drape target's matrices live in their own block and are selected per draw.

**Verified:** the tweaker path runs on-device (`ordinal=0,1,2…`, `base = ordinal × drawableCount`, distinct per-tile matrices). **Not verified:** the final imagery — in that session the Esri raster tiles (and even a flat raster style) failed to load, so the terrain still showed relief + fallback tint. Re-test with a warm cache.

**Next:** extend the same per-target block layout to the `background`/`fill`/`line`/`color-relief`/`hillshade` tweakers (they share the single-window buffer), then verify the drape end-to-end. See [Next steps](./next-steps.md) and [3D terrain](./concepts/terrain.md).

## 2026-10-13 (later) — Terrain raster drape: shader-side diagnostics

Ran verified shader diagnostics (earlier attempts were invalid — the deployed `QMapLibre.dll` was stale, and a concurrent build left a corrupt `.obj`; both fixed).

**Confirmed:**
- The raster drawable **does** render into the drape target — bypassing the vertex geometry (`gl_Position = in_position/4096 - 1`) fills the drape with solid magenta. So capture, pipeline, target and bindings are fine.
- The **per-target projection matrices are delivered** to the shader — colour-coding `projection_ubo[ubo_index].matrix[3].xy` shows a distinct value per tile. The per-target block fix works at the UBO level.
- With the real matrix the raster is off-target (black); the user observed the imagery **flicker in, then turn green** — i.e. the drape populates then goes empty; the green is the fallback tint (0032) over a black drape, not terrain drawn on top of the map.

**Revised hypothesis:** the drape target is created/rendered (and then **cached black** by the fingerprint) at a moment when the raster layer group is absent from `layerGroupsByLayerIndex` (the transience where `processChanges` removes groups the drape selection depends on). This is a drape-selection/caching bug, probably independent of the projection math.

**State:** both installs rebuilt clean and current (`LIB_REFRESH_OK`); app runtime refreshed; no diagnostics left in the tree.

**Next:** make the drape selection independent of the transient `layerGroupsByLayerIndex` (use the render layers' groups directly), or force a re-render of a drape target when its draped layer groups appear; then re-verify. See [Next steps](./next-steps.md) and [3D terrain](./concepts/terrain.md).

### Corner-placement probe (same day)

Further shader probe: with the raster geometry bypassed (so the drape is visible) the fragment colour encodes `matrix * vec4(8192,8192,0,1)` — the clip-space position of the raster tile's far corner. Result: the drape is mostly **yellow (clip ≈ +1,+1)** with a red strip (clip ≈ +1,−1) at the top. A tile exactly coincident with its drape target should put that corner at **(+1,−1)**. So the per-tile ortho is not placing the raster tile where the target expects — consistent with the real-geometry render landing off-target (black). The normal (non-terrain) raster path is unaffected (user confirmed Esri renders during style switches).

Diagnostics reverted; both installs rebuilt clean and current. Next candidate: re-derive the per-tile ortho against `matrixFor`'s actual y convention (and the raster quad's vertex layout), rather than the current `ortho(tx, tx+s, ty+s, ty)`.

### Shader probes (same day) — what the raster vertex shader sees

With the raster geometry bypassed (so the drape is visible), probing the projection UBO in the vertex shader:
- `matrix[3].xy` (translation) → a smooth per-tile gradient (per-target blocks are distinct).
- `matrix[0][0]` (m0, x-scale) → **< 0.1 everywhere** (grey), i.e. a small ortho-like (or zero) value, **not** the camera scale (~1.5).
- With the **real** `gl_Position` (matrix × pos) the raster is **clipped** (solid-colour fragment shows no drape); with the bypass it fills.

Also confirmed: `mercatorTileMatrix` uses a positive y scale, `matrix::multiply` is column-major `out=a·b`, and `LayerTweaker::multiplyWithProjectionMatrix` **does** honour `projMatrixOverride` — so the derived per-tile ortho is correct on paper, and the tweaker uploads it. Yet the shader's real projection clips the tile.

**Conclusion / next:** the per-target projection block the shader reads is small/ortho-like (possibly empty) yet produces off-range clip coords — needs a GPU capture (RenderDoc; `ENABLE_RENDERDOC_FRAME_CAPTURE` exists) of a drape target pass to see the actual projection buffer contents and the raster draw's push-constant `ubo_index` vs the buffer it indexes. This is beyond what shader-colour probes can resolve.

All diagnostics reverted; both installs rebuilt clean and current; app runtime refreshed.

### Attempted fix + probes (same day) — unresolved

Tried per-target projection blocks: reserve block 0..N−1 for the main pass, and size each layer's projection/drawable buffers **once per frame** to `(drapeTargetCount+1)×drawableCount` (no mid-frame grow). Added `PaintParameters::{drapeTargetOrdinal,drapeTargetCount}`, an offset-aware `gfx::UniformBuffer::update(data,size,offset)` + `contents()`, and `LayerTweaker::uploadProjectionUBOs(baseElement,totalElements)`.

Shader probes (geometry bypassed so the drape is visible):
- push-constant `ubo_index` is **large** (≥64) → the per-target offset *is* applied to the index.
- `projection_ubo[ubo_index].matrix[0][0]` (m0) is **< 0.1 everywhere** (grey) — i.e. ~0, not the ~2/s the tweaker computes.
- the per-vertex clip position from that matrix is **uniformly off-target** (clamped) → with the real `gl_Position` the raster is fully clipped (matches the black drape).

So the tweaker computes a correct ortho, but the block the shader reads comes back ~zero-scale — the disconnect is between the written buffer/block and what the draw actually reads (descriptor range / binding), not the ortho math. A shader-colour probe cannot resolve this; it needs a GPU capture.

**State:** changes left in the tree (sound but insufficient); both installs + app runtime current (`LIB_REFRESH_OK`). Next: RenderDoc **capture of one terrain-drape pass** to inspect the raster draw's projection SSBO contents, descriptors and push constants.

### RenderDoc analysis of a drape frame (2026-10-14)

Captured a full drape frame (`MapLibre.rdc`, 20932 draws, 253 render passes) and analysed it with RenderDoc's embedded Python (`qrenderdoc --python`, reading `GetConstantBlock` / `GetReadWriteResources` / `GetBufferData`).

Findings:
- **The per-target projection fix works.** Each raster draw's push-constant `ubo_index` = 83, 84, 85, … and the block it indexes holds a valid ortho (`m0=0.000244141`, per-tile `m12/m13`). Blocks 0–8 are zero (reserved for the non-drape pass, not read).
- **The raster vertex data is correct**: a 4-vertex quad, positions `(0,0)…(8192,8192)`, indices `0,1,2,1,2,3`.
- **Raster tiles are overzoomed parents.** Logging the drape target key vs the raster drawable's tile: drape tiles are `z14`, raster tiles are `z10` (`drape=14/8536/5823 ← raster=10/533/363`). For the covering tile the composed matrix is **on-target** (`m0=0.00390625`, `m12=-17`, `m13=31` → spans clip x[-17,15], y[-1,31], covering [-1,1]).

So: vertices 0..8192, a covering on-target matrix, and valid blocks — yet the drape target ends up black (terrain paints the fallback tint). The remaining contradiction (quad covers the target but nothing lands in it) could not be resolved from the capture alone; it needs RenderDoc's **Vertex Shader debugger** on a covering draw (e.g. target `14/8536/5823` ← raster `10/533/363`) to read the actual `gl_Position` and whether fragments are generated. Diagnostics reverted; both installs rebuilt clean.

### RenderDoc vertex output — root cause found (2026-10-14)

Inspected `Colour Pass #1` (the first drape target, a 256×256 offscreen colour attachment) in `MapLibre.rdc`:
- The target is **black**.
- Viewport = `(0,0,256,256)`, scissor = `(0,0,256,256)` — correct.
- The raster draw's mesh output: VS input `in_position` = `(0,0)…(8192,8192)`; VS output **`gl_Position` = `(7,7)…(9,9)`** (w=1).

So the raster quad is projected to clip `(7..9, 7..9)` — **entirely off-target** (needs `[-1,1]`) → clipped → black. The offset is exactly **+8 clip = +4 tiles** in both x and y at the same zoom. That is why every drape target is black and the terrain shows the fallback tint.

**Root cause:** the per-tile ortho (built from the drape target's tile) and the raster drawable's `matrixFor(tileID)` disagree by ~4 tiles — they don't share the same tile reference. Next: log the drape target key alongside the raster drawable's `tileID` canonical for the same pass to see the exact offset, then reconcile (cover tile coords / wrap / overscale).

### Paired tile log + text (follow-up)

RenderDoc mesh output (confirmed): `gl_Position` = `(7,7)…(9,9)` → the raster quad is +4 tiles off its drape target in that frame → clipped → target black. Push constant `length=4`, viewport/scissor `256×256` (correct).

Paired CPU log (drape target key vs raster drawable `tileID`) at a low-zoom state (drape `z3`, raster `z0`/`z2`): the raster group does contain a covering drawable (`canon=0/0/0 wrap=0 → m0=0.00195 m12=-1 m13=1`, i.e. on-target), plus wrapped copies (`wrap=-1/+1 → m12=-17/+15`) and a `z2` tile. So placement *can* be correct — yet the drape is still the flat tint, and the raster is loaded only at `z0`/`z2` (whole-world/coarse) while the drape is `z3`. So two things stack: (1) an intermittent per-tile offset (the capture's +4), and (2) the raster being barely loaded / its covering texture not contributing.

Diagnostics reverted; both installs rebuilt clean and current (`LIB_REFRESH_OK`).

### PRIMARY BUG FOUND — raster layer registers no group at the draping zoom (2026-10-14)

Drove the app to the failing state (wheel-zoom to zoom 13, flat, Matterhorn) and logged the layer-group inventory during the drape selection:

```
GROUPS n=1 drapeIdx=0,1, | 2:org.maplibre.annotations.points(d=0)
```

So during draping at zoom 13, `layerGroupsByLayerIndex` contains **only the annotation group (index 2)**. The **satellite raster group (index 1) is not present at all**, while `drapeLayerIndices = {0, 1}`. (Background index 0 is legitimately absent on flat Mercator — `backgroundLayerAsColor` → clear color.)

Consequence: the drape selection adds no raster group to any target → every drape target is empty/black → the terrain shows the fallback tint. This is why the raster tweaker never ran in the drape (only TARGET lines appeared in the log).

So the dominant fault is **not** the projection/ortho: the raster layer produces **no render layer group** at this zoom (its `RenderRasterLayer::update` creates the group only when `renderTiles` is non-empty — so the source has no render tiles here, or the group isn't registered). Earlier, at zoom 1.3 (globe), the raster *was* present (z0/z2 tiles) — so this is zoom/coverage dependent.

**Next:** find why the satellite source yields no render tiles at the flat detail zoom (source coverage/zoom vs the draped style), and ensure the raster group is registered and thus draped. The intermittent +4-tile projection offset is secondary (it can only matter once the raster is actually draped).

### Source side is fine — raster is loaded, registered, selected (2026-10-14)

Instrumented `RenderRasterLayer::update` and the drape selection at zoom 13 (flat, Matterhorn):
- `update id=satellite zoom=13.00 globe=0 renderTiles=79 imageData=0 layerGroup=1` → the satellite source **is loaded** (79 render tiles) and its layer group exists.
- `GROUPS n=2 drapeIdx=0,1, | 1:satellite(d=79) 2:org.maplibre.annotations.points(d=0)` → the satellite group **is registered** and **is selected** for the drape.
- Raster drawables at zoom 13 are `z14` (same zoom as the drape `z14`); for the matching tile the composed matrix is on-target (`m12=-1`).

So the earlier "raster group absent" was a **logging-cap artifact** (the log ran before the tiles had loaded). The source, registration, selection and tile alignment are all correct — **yet the drape is still the flat tint.**

That leaves only the raster **draw** itself (the RenderDoc capture caught one frame where `gl_Position` was `(7..9)` off-target — an intermittent projection offset) or the raster texture/binding in the offscreen pass. Diagnostics reverted; both installs rebuilt clean and current (`LIB_REFRESH_OK`).

### RenderDoc Python works — all drape draws are off-target by +4 tiles (2026-10-14)

Confirmed the RenderDoc Python route: RenderDoc 1.46 embeds Python 3.8 (`python38.dll`) and my scripts run via `qrenderdoc --python <script> <capture>` (no external Python / `renderdoc.pyd` needed). Read the **post-vertex-shader `gl_Position`** for the first 200 drape draws in `MapLibre.rdc` (`GetPostVSData(0,0,VSOut)` → mesh format → `GetBufferData`):

```
draw 681 gl_Pos=(7.000, 7.000, -0.001, 1.000)  off
draw 690 gl_Pos=(7.000, 9.000, ...)              off
draw 699 gl_Pos=(7.000, 11.000, ...)             off
...
SUMMARY on-target=0 off-target=200
```

**Every drape raster draw is off-target** (none within `[-1,1]`); the tiles project to a grid starting at `(7,7)` stepping by 2. So the whole raster cover is shifted **+8 clip = +4 tiles** in x *and* y relative to the terrain cover — no raster tile covers any drape target, so every target is clipped black and the terrain paints the fallback tint.

Combined with the earlier verifications (source loaded, group registered/selected, per-target projection blocks correct), the single remaining fault is this **systematic +4-tile offset between the raster cover and the terrain cover** (both `z14` at zoom 13). Next: log the terrain-cover tile (`terrainPass.getCover()`, what the ortho is built from) side-by-side with the raster drawable's `tileID` for the same drape target and find the origin of the +4.

### Root cause: satellite raster is stuck at z2 (detail tiles not loading) (2026-10-14)

Logged the terrain-cover tile vs the raster drawable's `tileID` for the first four drape targets across zoom levels (drove the app's zoom button to get to detail zoom):

```
zoom 12  drape=12/2041/2037…  raster=2/1/2 osZ=2  m0=0.25  m12=-2035
zoom 13  drape=13/4089/4085…  raster=2/1/2 osZ=2  m0=0.5   m12=-4083
zoom 14  drape=14/8185/8181…  raster=2/1/2 osZ=2  m0=1     m12=-8179
```

At map zoom 14 the drape tiles are `z14`, but the raster drawables are **`z2`** (world-size) — the satellite source is falling back to a very coarse ancestor, **not loading detail tiles**. `m0=1` confirms the 12-zoom gap.

And that coarse tile is **offset**: the drape tile `14/8185/8181` sits at world y `0.499` (inside z2 tile col/row `1/1`), but the rendered raster is `z2` tile `1/2` (its y-range `[0.5,0.75]` doesn’t contain `0.499`) — i.e. one z2 tile (= 4 z14 tiles) south. That is the +4-tile offset, and why the drape is coarse/black.

**So the dominant fault is: the satellite source does not load tiles at the draped detail zoom (stuck at `z0`/`z2`), and the coarse ancestor it does use is offset from the terrain cover.** Next: find why the satellite `z~13/14` tiles aren't requested/loaded in the draped-terrain style (whereas the flat satellite style did render imagery). Diagnostics reverted; both installs rebuilt clean and current.

### Instrumented the raster source (2026-10-14)

Added a probe in `RenderRasterSource::updateInternal` (after `updateTileMasks`) logging the tile pyramid's rendered tiles and `tileset.zoomRange`:

```
rendered=0 zrange=[0,18]   (every frame, at all zooms)
```

The zoom range is correct (`[0,18]`), but the source reports **0 rendered tiles** — i.e. no loaded raster tiles — while the raster *layer* earlier reported 79 render tiles. So the satellite source isn't producing loaded tiles in the draped-terrain style. (Caveat: `tilePyramid.getRenderedTiles()` may not be the same set as the layer's `getRenderTiles()`; it read 0 consistently, which is worth re-checking with the exact accessor the layer uses.) Diagnostics reverted; both installs rebuilt clean and current (`LIB_REFRESH_OK`).

**Next:** confirm via the layer's own `getRenderTiles()` whether tiles are present-but-unloaded vs absent, and why the satellite source isn't fetching/keeping detail tiles while draped (tile budget/priority consumed by DEM+terrain, or the source's tiles failing).

### Raster source: 0 loaded tiles at the correct zoom (2026-10-14)

Logged `RenderRasterSource::updateInternal` at map zoom 13:

```
tileSize=256 zoom=13.00 zoomRange=[0,18] rendered=0
```

Everything is correct — tile size 256, map zoom 13, zoom range `[0,18]` — but the source has **zero rendered/loaded tiles**. So the satellite tiles are *requested* (the raster layer previously reported 79 render tiles) but **not loading** in the draped-terrain style.

Combined with everything else (projection, per-target blocks, group registration, selection all verified correct), the whole bug reduces to: **the satellite raster never loads its tiles while the terrain is draped**, so the drape gets a coarse/empty ancestor → black → tint. The `+4`-tile offset seen earlier is just the coarse `z2` ancestor being misaligned with the terrain cover.

**This is a tile-loading problem, not a rendering-math problem.** Next: find why the satellite source doesn't load tiles while draped — check whether the tile requests are issued and fail (network/HTTP), or are starved/evicted by the DEM+terrain tile budget. Diagnostics reverted; both installs rebuilt clean and current.

### BREAKTHROUGH: the drape works — the fault is the Esri satellite source (2026-10-14)

Acted on John's idea to test draping with a **known-good** map:

1. **Liberty (vector) + DEM + terrain** — built `liberty-terrain.json` (Liberty style + the AWS terrarium `dem` source + `terrain`). Result: **renders perfectly draped** — roads, labels, lakes and shading all conform to the 3D relief at pitch 81°.
2. **OSM raster + DEM + terrain** — `osm-terrain.json` (terrain-style with the satellite URL swapped to `tile.openstreetmap.org`). Result: **renders perfectly draped** (Matterhorn/glaciers draped over the relief).

So the drape mechanism, the per-tile RTT, the terrain, the projection/ortho, the per-target projection blocks, and the layer-group registration/selection are **all correct**. The **only** component that fails is the **Esri World Imagery raster source**, whose tiles never load in the app (`rendered=0`), so the drape samples an empty/coarse ancestor → black → tint.

**Conclusion:** this is not a terrain-drape bug at all — it is the Esri satellite source failing to load tiles in this environment. Test styles `liberty-terrain.json` and `osm-terrain.json` live in the app repo. Next: why the Esri source's tiles don't load (network/host reachability from the app, user-agent/rate-limit, or response decode), and decide whether to keep Esri or switch the demo's draped-terrain imagery to a working raster.

### Phase 1 result + correction (2026-10-14)

Logged the terrain cover, the raster render-tile cover, and both transform states in one frame at zoom 13:

```
COVER  z=14 x=[8536..8544] y=[5823..5833] n=79 | uS z=13.000 c=45.97630,7.65860 | rS z=13.000 c=45.97630,7.65860
RASTER n=79 osZ=14 canonZ=14 x=[8536..8544] y=[5823..5833] stateZoom=13.000
```

- The **terrain cover and the raster cover are identical** (same zoom, same x/y range), and **both transform states are equal** (same zoom/centre). So there is **no cover mismatch** and no stale-state bug — the earlier hypotheses (H1–H4) are dead.
- **Correction:** the RenderDoc "all draws off-target" finding was a **misinterpretation** — my script compared *vertex* `gl_Position` to `[-1,1]`, but a coarse/covering tile legitimately has vertices outside that box while its triangle still covers the target. So the `+4` was not proof of a bug; the zoom-22 run (drape z14 vs raster z18) also naturally produces vertices far outside.

Per-draw log for drape target `14/8536/5823` shows the raster group contains **z10 parents** (`533/363 → m12=-17`, which does cover) for the target's un-loaded `z14` tile, plus `z14` tiles at `8539..8541` (`m12=5..9`, offset ~+3 from the target). So the raster's **detail tiles aren't loaded for the target's tile** (a `z10` parent stands in), and the covering parent draw still lands black.

Net: covers align; the raster detail tiles are missing (z10 fallback); and a covering draw still doesn't reach the target. Diagnostics reverted; both installs rebuilt clean and current.

### ROOT CAUSE FOUND + FIXED — the drape works (2026-10-14)

The per-tile drape ortho mapped `z = 0` to the **near plane** (`matrix::ortho(ortho, tx, tx+s, ty+s, ty, -1.0, 1.0)` → `z_clip = 0`). Every raster/fill/line drawable has `enableDepth = true` (default), so `LayerTweaker::multiplyWithProjectionMatrix` applies a per-drawable depth offset: `projMatrix[14] -= K`. That pushes `z_clip = -K < 0` — and **Vulkan clips `z < 0`**, so *every* drape draw was discarded (leaving the clear colour → the patch-0032 fallback tint). This is exactly why the controls behaved as they did: bypassing `gl_Position` (writing `z = 0` directly) drew, and the main (perspective) projection — whose z is not at the near plane — worked.

**Fix:** map the tile's `z = 0` into the middle of the clip range so the depth offset keeps `z ∈ [0,1]`: `matrix::ortho(ortho, tx, tx + s, ty + s, ty, -1.5, 0.5)` (→ `z_clip = 0.5`).

**Result:** the terrain now renders with the draped layers — verified on-device at zoom 13 with `osm-terrain-style.json` (roads, lakes, labels, shading all conform to the relief) and at low zoom (world draped).

**Residual (separate, smaller):** the draped content is **rotated 180°** (labels read mirrored). Flipping the ortho's x/y did not change it, so the 180° is in the terrain sampling path (`v_uv` / `1 - v_uv.y`), not the ortho. Next: fix the drape orientation.

Both installs rebuilt clean and current. The earlier confusion (cover mismatch, "+4 off-target") was a red herring — covers align at zoom 13; the RenderDoc "off-target" compared vertex positions, not coverage.

### Terrain drape orientation FIXED (2026-10-14)

With the z-clip fix in place the drape rendered but rotated 180° (labels mirrored). Flipping the ortho's x/y did nothing, because the rotation is in the terrain's **texture sampling**, not the projection. The drape render target stores north at `v = 0` (clip `y = +1` → image row 0), exactly what the terrain mesh's `v_uv` already encodes — so the extra `1.0 - v_uv.y` in `terrain.hpp` was a spurious vertical flip that, with the tile image, showed as a 180° rotation.

**Fix:** `texture(drapeSampler, v_uv)` (dropped the `1.0 - v_uv.y`). Verified on-device: the world view is not mirrored, the Alps imagery at zoom 13 is upright, and a tilted CARTO basemap's "API KEY REQUIRED" watermark reads correctly on the draped relief.

Captured as patch **0037** (`maplibre-native-0037-terrain-drape-uv-orientation.patch`), pushed to fork (`4955ba4`).

**Remaining (smaller, cosmetic):** a visible **tile seam** where adjacent drape tiles meet (one tile's imagery offset from its neighbour) — a per-tile raster/DEM cover alignment issue, separate from orientation.

### Raster/DEM drape cover-alignment investigated (2026-10-14)

The Seam" I chased earlier is **not** a cover bug: with a clean labelled raster (OSM topo) the drape is perfectly aligned at zoom 12 and 14 — roads, rivers and labels run continuous across tile boundaries. The offset "rectangle" seen with **Esri World Imagery** is that imagery's own mosaic/parallax (satellite captures from different angles over mountains), not a code defect.

But the investigation did surface a **real bug**: at **zoom >= 15 the whole drape goes black** (terrain falls back to the hypsometric tint, no imagery). Instrumenting `renderTerrainDrapeTargets` shows:

- zoom 14: `cover=21 targets=21 groups=2 [raster z15=72]` -> correct (raster cover = mapZoom+1, drapes fine).
- zoom 15: `cover=76 targets=76 groups=2 [raster z2=22]` -> the **raster layer's drawables are stuck at z2** while the DEM cover is z14, so the drape targets render the wrong (empty) content -> black.

So the raster layer's tile cover/drawables are not being rebuilt for zoom 15 (stale z2 from the app's startup zoom). `coveringZoomLevel(15, Raster, 256)` = 16, so the expected zoom is fine — the layer's tiles just aren't updated. This is the "raster/DEM cover misalignment" at high zoom. Next: find why the raster layer's cover doesn't refresh on the final zoom step (the same path works at zoom 14).

### Zoom>=15 drape bug — root cause (2026-10-14)

Digging the raster layer's cover path gave the answer. Instrumenting `RenderRasterSource::updateInternal` shows its `parameters.transformState.getZoom()` is **1.323** at map zoom 15 (constant, every frame):

```
RASTSRC needsRendering=1 zoom=1.323 maxZoom=18
```

`coveringZoomLevel(1.323, Raster, 256)` = 2, so the raster layer builds only **z2** drawables, while the DEM/terrain cover is z14 -> the drape targets render z2 tiles (unloaded) -> black, and the terrain falls back to the tint.

The stale zoom comes from the **app**: `main.qml`'s `applyCamera()` does `map.easeTo({ pitch: window.mapTilt, bearing: window.mapBearing })` **without a zoom**, and it runs on every style load (the `onStyleLoadedChanged` handler, line ~487). The style load resets the camera, and the re-apply leaves the map's transform at ~1.3 while the QML `map.zoomLevel` still reads 15 — so the QMapLibre/MapLibre transform is at 1.3 for the raster source's cover.

**Fix direction:** make `applyCamera()` (and the terrain-preset camera apply) include the current zoom in `easeTo` — e.g. `map.easeTo({ center: map.coordinate, zoom: map.zoomLevel, pitch, bearing })` — so the camera re-apply keeps the zoom and the raster source's cover matches the DEM cover.

Diagnostics reverted; both installs rebuilt clean.

### Zoom>=15 drape — part 2: the source-zoom fix is necessary but not sufficient (2026-10-14)

Applied the `applyCamera` fix (center+zoom in `easeTo`), rebuilt the **app** via Qt Creator (the QML is compiled in via `qt_add_qml_module`, so an app rebuild is required), and re-instrumented:

```
RASTSRC zoom=15.000     (was 1.323)
DRAPE cover=11 targets=11 [raster z16=72]   (was z2)
```

So the camera fix **works** — the raster source's transform is now the map zoom, and the raster layer builds **z16** drawables (correct for zoom 15). **But the drape is still empty** at zoom 15, so there is a *second* issue: the raster cover (z16) exceeds the DEM cover (DEM zoom is hard-capped at `clamp(floor(zoom)+2, 0, 14)` = 14). At zoom 14 the raster cover was z15 vs DEM z14 (2x) and draped fine; at zoom 15 it's z16 vs z14 (4x) and the drape renders empty.

So two fixes are needed: (1) the app camera fix (done, `e367b01`), and (2) the drape must handle a draped-layer cover zoom that is *coarser/finer* than the per-tile DEM cover — the raster tiles at z16 drawn into a z14 DEM drape target need their projection/UV to account for the 4x tile-zoom difference.

Both library diagnostics reverted; both installs rebuilt clean.

### Zoom>=15 drape — cap experiment + status (2026-10-14)

Checked the projection path: `TransformState::getProjectionData(tileID, projMatrix)` = `projMatrix * tileMatrix(tileID, scale)`, i.e. tile-local -> world -> clip, which is correct for any `tileID` zoom, so the raster z16 quads are placed correctly in the z14 drape target. So the empty drape is not a projection composition bug.

Tried raising the DEM zoom cap (`clamp(floor(zoom)+2, 0, 14)` -> `15`): at zoom 15 this made it **worse** — the terrain rendered only a **corner sliver** (the DEM z15 cover is largely empty/off for this source), so the cap is reverted to 14.

**Status:**
- (1) App camera fix (`applyCamera` keeps center+zoom): **done, verified** (`e367b01`) — raster source zoom is now 15.000, raster cover z16.
- (2) Zoom>=15 drape still empty. Known-good: zoom<=14 (raster cover = DEM cover + 1). Broken: zoom>=15 (raster cover = DEM cover + 2). DEM cap 14 is needed (15 breaks the terrain).

Next hypotheses for (2): the drape target is a fixed **256px** texture per DEM tile, so at zoom 15 a z14 DEM tile is 1024 screen px; the z16 raster cover must be squeezed into that 256px target. Worth checking (a) the raster cover trimming/`buffer_scale` used when drawing into a foreign-zoom target, (b) whether the drape target size should scale with the cover ratio, (c) whether the draped layers should be forced to a cover zoom matching the DEM.

### Zoom>=15 drape — RenderTarget instrumentation (2026-10-14)

Instrumented `RenderTarget::render` (per-target layer groups + drawable counts), plus the drape loop (DEM tiles, raster drawables' tiles, and the two transform states):

- The drape target at zoom 15 is **256x256, 1 layer group (idx=1, raster, n=72)** and renders **fully black** — not even a background group is attached, and the raster group draws nothing.
- The two transform states **agree** (`parameters.transformParams.state` == `parameters.state`, zoom 15, scale 32768, worldSize 16777216), so the ortho and the tile matrices share a scale.
- The covers **do overlap**: DEM `14/8544/5827` => z16 x[34176..34179] y[23308..23311], inside the raster cover's z16 range `16/34174..34182 x 23303..23312`.

So the overlapping z16 raster tiles are **present and correctly selected but not drawn** into the z14 target. That localises the fault to the raster drawable's *render inside the drape target* at a 4x cover ratio (2x, at zoom<=14, works) — e.g. its clip position, `origin` translate, or the translucent pass / depth handling in the offscreen target — not to cover selection or the projection composition.

All diagnostics reverted; both installs rebuilt clean.

### Session summary — 3D terrain drape (2026-10-14)

Fixed three real bugs, then localised a fourth. **Resume point is the "RESUME HERE" section of [Next steps](./next-steps.md).**

**Fixed + verified:**
1. Drape drew nothing (per-tile ortho `z` at the near plane → Vulkan clipped every draw) — patch **0036**.
2. Drape rotated 180° (spurious `1.0 - v_uv.y` in the terrain sampler) — patch **0037**.
3. App camera reset on style load (`applyCamera` eased pitch/bearing without zoom → map transform stuck at ~1.3 → raster cover collapsed to z2) — app `e367b01`.

**Open:** drape empty at zoom >= 15. The z16 raster cover overlaps the z14 DEM targets (verified), the transform states agree, but the offscreen target renders black — the overlapping tiles are present but not drawn. Next: log the raster drawable's clip range inside one target, or read back the target pixels. See [Next steps](./next-steps.md).

All library diagnostics reverted; both installs rebuilt clean. Fork patches pushed: `maplibre-native-0036-terrain-drape-ortho-z.patch`, `maplibre-native-0037-terrain-drape-uv-orientation.patch`.

### Session checkpoint — z15 drape/terrain still empty (2026-10-15)

Goal was to find why the draping works at zoom <= 14 but the map is empty (background only) at zoom >= 15. Earlier this session: fixed patch **0036** (per-tile ortho `z` at the near plane -> Vulkan clip) and **0037** (drape UV orientation), plus the app camera reset (`e367b01`). This session could not close z15.

**Ruled out (each with evidence):**
- **Cover ratio** — at z14, forcing the draped cover to `DEM+2` (the same ratio as z15) via a temporary `MLN_DRAPE_LOD_SHIFT` knob drapes **perfectly**. So the ratio is not the cause.
- **Staleness / cached-black** — instrumented: the raster layer loads its tiles and the drape targets **re-render with the full group** (`DRTARGET ... n=60`) and still come out empty. The target is not merely stale.
- **Transform states** agree; **covers overlap**; **projection composition** (`ortho * matrixFor(tileID)`) is correct for any tile zoom.
- **Terrain projection is NOT anomalous** — the `projMatrix` is byte-identical at z14/z15 (`m0=2.266718, m5=-1.928363`) and the composed terrain matrix scales uniformly 2x (`m0` 0.1417->0.2833, `m5` -0.1205->-0.2410). An earlier claim in this session that `m5` scaled 2.62x was a **measurement error** (derived from a RenderDoc `VTX0->VTX1` delta that is not `m5*512`) and is retracted.

**RenderDoc captures (kept):**
- `C:\hda\dev\tmp\z14_settled.rdc` (frame 78) — drape fills; complete map.
- `C:\hda\dev\tmp\z15_settled.rdc` (frame 353) — settled for the raster (app kept repainting via a temporary QML Timer).
- **Both captures have the same draw histogram** except the terrain count (22 vs 6) — so the raster draws are issued at z15 too.

**z15 findings:** terrain draw (EID 19) `gl_Position = (-3877.75, -6132.93, 1689.42, 1690.05)` -> NDC `(-2.295, -3.629)` (off-screen); pipeline = **cull None, depth Disabled, depth-clip on, render area `(0,0,1951,1474)`**; the main colour attachment shows an **undefined (checkerboard) region** below a background band.

**Unresolved contradiction:** the CPU cover log shows z15 cover tiles that *do* project on-screen (e.g. one spanning NDC x[-0.85,0.74] y[-1.06,0.48]), and nothing in the pipeline culls/rejects (depth disabled, no culling) — yet the app shows only the background. The pieces do not reconcile yet.

**Capture tooling (for next time):** capture needs the app launched under RenderDoc (`renderdoccmd capture`) **and** the in-app API (`-DENABLE_RENDERDOC_FRAME_CAPTURE` + a trigger); the app renders on demand so a **forced-repaint** (QML Timer nudging `map.pan`) is needed to reach a settled frame. `qrenderdoc --python` runs the script before the capture loads and `pyrenderdoc.LoadCapture(...)` blocks — analyse in the GUI instead. Diagnostics must go to files (MapLibre's `Log::` sink is dropped).

**Cleanup done:** library worktree `reset --hard` + `clean -fd` + re-applied patches 0001..0037 (diagnostics removed); app `main.qml` reverted (repaint Timer removed; `applyCamera` fix kept); both installs + the app rebuilt clean. The `terrainDrapeZoom` one-liner was lost in the revert (re-add next time).

**Next step:** on CPU, log per terrain-cover tile the composed NDC of its **centre** and whether it passes `[-w,w]x[0,w]`, side-by-side z14 vs z15 — prove which tiles *should* rasterise — before any more GPU work.

### GL JS reference model (P0) + P1 drape RTT size — 2026-10-15

Adopting MapLibre GL JS as the reference (as John directed). Reference facts, from source:

- **Terrain tile set** (`src/tile/terrain_tile_manager.ts`): `deltaZoom = 1`; terrain `tileSize = source.tileSize * 2**deltaZoom`; terrain tiles come from `coveringTiles(transform, {tileSize: terrainTileSize, maxzoom: 22, reparseOverscaled: false})`; the DEM source zoom is `min(terrainTileZoom - 1, source.maxzoom)` with **fallback to loaded parents** (`getSourceTile` while-loop). No hard cap.
- **RTT size** (`src/webgl/render_to_texture.ts`): `rttSize = terrain.tileManager.tileSize * terrain.qualityFactor` (`qualityFactor = 2`) — e.g. 1024 for a 512 source; `setFrameUniformWorldSize(frameUniformBuffer, rttSize, rttSize)` for the pass.
- **Drape matrix is pure tile space** (`terrain_tile_manager.ts`): the RTT tile's own matrix is `mat4.ortho(terrainRttPosMatrix32f, 0, EXTENT, EXTENT, 0, 0, 1)`; a source tile is placed into it by `dz/dx/dy` deltas in EXTENT units (child: `ortho(0,size,size,0,0,1)` + translate; parent: `ortho(0,EXTENT,EXTENT,0,0,1)` + translate + scale `1/2**dz`). No `worldSize`/camera scale.
- **Terrain mesh** (`src/render/terrain.ts`): `meshSize = 128`; one regular grid over `[0,EXTENT]x[0,EXTENT]`, z=0, **reused for every tile**; elevation is fetched in-shader from the DEM (`u_terrain_matrix`, `u_terrain_dim`, `u_terrain_unpack`) and multiplied by `u_terrain_exaggeration` (metres x exaggeration). `_getDEMTileMatrix` derives the tile->DEM mapping from the DEM tile **actually used** (its own zoom `dz`), not the source's declared maxzoom.
- **Invalidation**: per (source, rtt-tile-key) `RTTFingerprint {sourceTileIds, sourceRevision, zoom, visibleLayerIds}`; textures kept while moving and re-rendered one-per-frame after; `needsFollowUpFrame` for the rest.
- **The drape groups are the terrain tiles**: a layer's tiles are grouped under terrain tiles via `getTerrainCoords` (same/parent/child).

**P1 result — equivalence check.** Our per-tile ortho `matrix::ortho(ortho, tx, tx+s, ty+s, ty, -1.5, 0.5)` **already equals** GL JS's `ortho(0,EXTENT,EXTENT,0,0,1)` expressed in world coords (the tile-local->world mapping is `matrixFor(tileID)`); the only deliberate difference is the z mapping (`0,1` -> Vulkan `-1.5,0.5`) so the per-drawable depth offset in `multiplyWithProjectionMatrix` does not clip on Vulkan. So the drape **xy/placement is not the z15 divergence**.

**P1 change made:** the drape render-target size is now `source.tileSize x 2` (GL JS's `qualityFactor = 2`), i.e. **512** for our 256-px raster sources — was a hardcoded 256. Verified z15 after: **still empty** (so the size was not the cause either).

The remaining divergences are therefore **P2 (terrain/DEM tile-zoom rules: `floor(zoom)+2` cap 14 vs `coveringTiles` + `min(terrainZoom-1, source.maxzoom)` + parent fallback)** and **P3 (the mesh/elevation model)** — that is where the zoom-dependence lives.

### P2 result + P3 pre-check — none of the planned divergences is the cause (2026-10-15)

Following P1 (drape RTT size 512, GL JS-aligned; the ortho was shown algebraically equal to GL JS's tile-space matrix — z15 still empty, z14 fine), I tested the remaining reference divergences directly:

- **P2 (terrain tile zoom):** set the terrain/DEM tiles to the camera's tile zoom (`newDemZoom = clamp(floor(zoom), 0, 15)` in `terrain_pass.cpp`, which leaves z14 unchanged). **z15 still empty.** Reverted.
- **P3 pre-check (elevation):** set the style's `terrain.exaggeration` to **0.0** (a flat mesh). **z15 still empty** — so the elevation term is not the cause. Reverted.

So a **flat terrain mesh at the camera's own tile zoom is still invisible at z15**, ruling out: the drape matrix/size (P1), the terrain/DEM tile zoom (P2), and the elevation (P3). The fault is therefore in the **composed terrain matrix `projMatrix * matrixFor(tileID)` at camera zoom 15** (the transform / tile-matrix path in `TransformState`), or in the **camera state the app leaves at z15** — note the earlier anomaly that the render transform reports **pitch 0.9** while the app UI shows `p50`.

**Tree state:** P1 kept (`drapeTileSize = 512`, documented as GL JS's `terrainTileSize x qualityFactor`); the P2 test reverted to `clamp(floor(zoom)+2, 0, 14)`; the style's exaggeration restored to 1.5; both installs + the app rebuilt clean.

**Next:** instrument `TransformState::matrixFor(tileID)` / the composed matrix in `TerrainPass::update` for **the camera's own tile**, at camera z14 vs z15 (same camera centre), and log the camera the app applies (pitch/elevation/zoom) — to find why the camera's own tile lands off-screen at z15.

### Algorithm/maths audit vs MapLibre GL JS (2026-10-15)

Per John's directive — every algorithm/maths we implement must be checked against the working reference. Reference files read: `render/terrain.ts`, `tile/terrain_tile_manager.ts`, `render/render_to_texture.ts`, `render/frame_render_context.ts`, `render/painter.ts`, `geo/projection/covering_tiles.ts`, `geo/projection/projection_data.ts`, `geo/projection/mercator_projection.ts`, `geo/transform_helper.ts`, `shaders/glsl/_prelude.vertex.glsl`, `webgl/render_to_texture.ts`.

| Our algorithm | GL JS reference | Status |
|---|---|---|
| Terrain tile zoom `clamp(floor(zoom)+2, 0, 14)` | `coveringZoomLevel(transform, {tileSize: source.tileSize*2})` = `floor(zoom + scaleZoom(512/(2*srcTileSize)))` = **floor(zoom)** | **DIVERGENT** (+2 and a cap of 14). Tested `floor(zoom)` — z15 still empty |
| Raster source tile zoom (native `coveringZoomLevel`) | `floor(zoom + scaleZoom(512/256))` = floor(zoom)+1 | equivalent |
| **Terrain cover** `util::tileCover(state, zoom, Range(zoom,zoom))` | `coveringTiles(transform, {tileSize, minzoom:0, maxzoom:22, reparseOverscaled:false, terrain})` — **camera-frustum DFS** with per-tile bounding volumes, **terrain elevation culling**, horizon-plane tests and variable zoom (`createCalculateTileZoomFunction`) | **DIVERGENT (major, un-checked until now)** |
| Drape matrix | tile-space `ortho(0,EXTENT,EXTENT,0,0,1)` + `dz/dx/dy` | equivalent (proved P1) |
| Drape RTT size | `terrainTileSize * qualityFactor` = 1024 (256 src) | ours 512 (memory-bounded) |
| DEM source zoom + fallback | `min(terrainZoom-1, source.maxzoom)` + fallback to loaded parents | **DIVERGENT** (ours is `demZoom` itself; no −1, no fallback) |
| Elevation scale | metres x exaggeration, applied via `_getDEMTileMatrix` in-shader; `_pixelPerMeter = worldZFromAltitude(1,center)*worldSize` | **DIVERGENT** (ours bakes `e*exag*pixelsPerMeter(cameraZoom)` into the mesh) — flat test says not the z15 cause |
| Terrain mesh | one 128x128 grid over `[0,EXTENT]^2`, z=0, reused; DEM sampled in-shader | **DIVERGENT** (ours 17x17 per tile, elevation baked) |
| Per-tile projection | `mainMatrix` (tile-local->clip; normalised mercator coords `getMercatorTileCoordinates`) | equivalent (projMatrix ∘ matrixFor, world px) |
| Hillshade / light | GL JS hillshade | **DIVERGENT** (ours light `LightX/Y/Z`) — cosmetic |
| Drape texture UV | (their RTT sampling) | checked (patch 0037) |

**Conclusion:** most maths are equivalent; the two genuinely un-verified **algorithms** are (1) the **terrain cover** (`coveringTiles` frustum DFS vs our `tileCover`) and (2) the **DEM tile zoom + parent fallback** (`min(terrainZoom−1, source.maxzoom)`). The cover is the strongest remaining candidate because the z15 mesh is invisible even flat at the camera's own tile zoom, which a wrong cover would explain (no mesh where the camera looks).

**Plan:** port `coveringTiles` (or at least its terrain call: `tileSize = source.tileSize*2`, `maxzoom 22`, `reparseOverscaled:false`, terrain-elevation culling) and the DEM `min(terrainZoom−1, source.maxzoom)` + parent-fallback rule into `terrain_pass.cpp`/`terrain_tile_manager`, then re-test z15.

### DECISIVE: the z15 cover/mesh are correct — it is the terrain DRAW (2026-10-15)

Added a per-frame cover diagnostic in `terrain_pass.cpp` (every cover tile's centre NDC, DEM-loaded state, and drawable count). z15 (OSM terrain, Zermatt, pitch 0.87, elev 0):

```
COVER zoom=15 demZoom=14 n=6 lat=46.0207 pitch=0.87 elev=0.0 |
  14/8544/5827[data=1 n=1 ndc=-0.28,-0.08]  14/8545/5827[data=1 n=1 ndc=1.35,-0.08]
  14/8544/5826[data=1 n=1 ndc=-0.18,0.84]   14/8543/5827[data=1 n=1 ndc=-1.90,-0.08]
  14/8545/5826[data=1 n=1 ndc=0.87,0.84]    14/8543/5826[data=1 n=1 ndc=-1.23,0.84]
```

So at z15 the terrain **cover is correct** (tiles' centres on-screen — one dead-centre), every cover tile has **DEM data and a terrain drawable (n=1)**, and it builds meshes. Therefore:

- **The cover is NOT the fault** — the planned `coveringTiles` port is unnecessary for z15.
- **The tile placement / matrix is NOT the fault** — centres project on-screen.
- The fault is **the terrain DRAW**: valid, on-screen geometry with drawables produces **no pixels** — and it does so even when the terrain is **flat** (exaggeration 0), so it is not the elevation.

Next: instrument the terrain **projection UBO** — log the `pd.mainMatrix` actually written for a terrain drawable (and the drawable's `uboIndex` / depth) and compare with the CPU-composed matrix, to see whether the shader reads a different/wrong matrix at z15 (the projection-UBO consolidation path). The earlier RenderDoc mesh output showed the shader's `gl_Position` off-screen with elevation; the flat case removes elevation, so the UBO content is the remaining candidate.

**Tree:** the cover diagnostic is in `terrain_pass.cpp` (temporary); P1 (`drapeTileSize` 512) kept; both installs + the app built.


## 2026-10-16 — z>=15 terrain/drape bug SOLVED (patch 0040)

**The "terrain draw renders no pixels at z15" conclusion was wrong.** With the fragment shader forced to the hillshade tint the terrain drew fine at z15–16; the blue was the *drape texture* (background only) plus, later, missing/over-scaled terrain. Four separate faults, all fixed in `maplibre-native-0040-terrain-elevation-aware-cover.patch`:

1. **Elevation scaled by pixels-per-metre twice.** `Camera::getWorldToCamera` already multiplies the z column by `pixelsPerMeter` (GL JS convention: z in **metres**). The terrain mesh (and the symbol elevation function) baked z in world *pixels* (`e * exaggeration / metersPerPixel`), so the surface was flattened below ~z16 and exaggerated above it until it rose through the camera (all blue by z16.5 at pitch 0). Fix: mesh z and `elevationFunction` are metres. Hillshade now uses each tile's own ground width (it used the current-zoom `metersPerPixel`).
2. **Tile covers ignored terrain height** (the sea-level footprint of the frustum is not where raised terrain is visible): raster tiles for the drape and DEM tiles at the bottom of a pitched view were culled → empty drape (z>=15) and blue strips at the bottom. Fix = GL JS `coveringTiles` + `Terrain#getMinMaxElevation`: each DFS node's bounding box spans its DEM tile's min/max elevation (`DEMData::minElevation/maxElevation`; loaded tile at the node's zoom, else nearest loaded ancestor, else sea level..centre elevation; a coarse z9 ancestor is requested so a range exists). Provided to every source's cover through `TransformState::setTileElevationRange` (set by the orchestrator from `TerrainPass::elevationRangeFunction`).
3. **`Frustum` z units.** GL JS keeps the unprojected frustum z in metres (box z in metres too); the port scaled z like x/y. `fromInvProjMatrix` now keeps z in metres (globe unaffected).
4. **`Frustum::intersects/intersectsPrecise` ignored box elevation** (only 4 corners at z=0, z-edge separating axes missing). Now 8 corners + the `[0,0,1] x edge` axes.

Verified (Qt Creator, Release and Debug, scripted sweep with screenshots): imagery drapes at z14, 15, 16, 16.5, 17, 18 at pitch 0 and 50, no blue. A brief beige hillshade tint appears for a few seconds after a large zoom jump while raster tiles load (expected fallback, more visible in Debug).

**Method note:** a temporary QML Timer in `main.qml` (zoom/pitch sweep + `contentItem.grabToImage` to /tmp/shots, then `Qt.quit()`) lets Claude run the whole test through `run_project` without hands on the window. Keep it out of commits.

**Also fixed (maplibre-native-qt, not in the patch):** Debug `BackendScope::exists()` assertion on window resize and on backend teardown — `MapRenderer::updateRenderer` and `~VulkanRendererBackend` now take an Implicit `BackendScope` (it also made Debug `test_mln_quick` pass). **Tests:** vendored core tests now build in `~/dev/tmp/build-maplibre-native-core-tests` (see maplibre-native-qt AGENTS.md): 1056 pass; 3 fail identically without 0040 (`StyleConversion.Projection`, `CustomDrawableLayer.Line/Fill`). **Open / not done:**  (c) Terrain mesh is still 17x17 baked; no DEM-at-`floor(zoom)` rule yet (GL JS divergence, not needed for this bug). (d) Pre-existing warning `map_impl.cpp:153 missing initializer terrainTileset`.

## 2026-10-17 — GPU memory runaway at steep pitch (machine hang) FIXED

**Symptom:** with pitch >~65 and zoom ~12–13 the app hung and, once, took the whole PC down (reboot). Kernel log (`journalctl -k -b -1`): `MapLibreEarth` looping in `amdgpu_gem_create_ioctl` under memory pressure -> TTM swap-out list corruption (~8M warnings). Cause: **unbounded terrain tile cover.** The terrain pass used one DEM zoom (14) all the way to the horizon; at pitch 71 / zoom 12.75 it requested **16,679 terrain tiles** (1,652–4,635 drape render targets of 512x512, a mesh and a DEM request each).
**Fix** (in patch 0040, `terrain_pass.cpp`): the terrain cover is capped to the nearest **128** tiles (cover is sorted centre-first). Measured at pitch 71–80: cover 128, drape targets <=128, GPU memory ~150 MB. A per-distance LOD cover (`TileLodMode::Distance`, zoom range 8..14) was tried and **rejected**: it coarsened the near field (blurry/blue frames); also fixed the Distance-mode box z units in `tile_cover.cpp` (box z is metres, camera is tile units).
**Superseded** by the GL JS-style LOD cover (see the entry below).
**Safety net:** `~/dev/tmp/memguard.sh` (persistent log `~/dev/tmp/memguard.log`) kills MapLibreEarth and dumps stacks when its RSS > 8 GB, system MemAvailable < 5 GB or amdgpu GTT > 9 GB. Run it before any pitch/zoom stress test. Build-filter lesson: grep compile output for `error:` (not ` error `) or failed builds look like successes.


## 2026-10-17 (later) — terrain cover now uses GL JS `calculateTileZoom` (supersedes the 128-tile cap)

The fixed-zoom cover + 128-tile cap above was a stop-gap and not GL JS behaviour. GL JS (`covering_tiles.ts`) always allows variable zoom when terrain is present (`allowVariableZoom` returns true for `options.terrain`) and picks each tile's zoom with `createCalculateTileZoomFunction(9.314, 3.0)`. The fork already had that function for the globe path; it is now used by the **flat** `util::tileCover` when `TileCoverParameters::terrainVariableZoom` is set and the transform carries a tile elevation range (i.e. terrain on):
- `TerrainPass` covers `Range(0, demZoom)` with `terrainVariableZoom`; `tile_pyramid.cpp` (every source's cover) sets it too, like GL JS passing `terrain` to each source's `coveringTiles`. The 192-tile cap remains only as a backstop.
- Measured (Ben Nevis view, Debug, memguard on): pitch 71 / zoom 12.75 -> **77 terrain tiles** (z7..z14, 31 at z14; was 16,679), pitch 80 / z13 -> 50, pitch 50 / z15 -> 6; GPU memory ~150 MB. Near field at DEM zoom, far field coarse; imagery drapes to the horizon.
- Distance-mode box z units fixed (box z metres vs camera tile units) in the same patch. Patch 0040 now touches 16 files.
- Not done: the vendored render tests were not rerun after this last change (it only triggers when terrain is on); core 1056/1059 (same 3 known failures), Qt `ctest` passes in both configs.

## 2026-10-17 (later) — far terrain no longer flattened: mesh 17x17 -> 129x129
GL JS draws every terrain tile with a 128x128 mesh; ours was 17x17 per tile at any zoom, so a coarse far-field tile (z7–z9, tens of km wide) got a handful of height samples and the distant relief looked smoothed away. `TerrainGridSegments` is now 128 (129^2 vertices still fit uint16 indices) and the mesh is no longer rebuilt on every 0.25 zoom (heights are metres, hillshade uses the tile's own width, so nothing in it depends on the current zoom any more; only demZoom/exaggeration/tileset changes rebuild). Verified with screenshots at pitch 66–80 (ridgelines to the horizon). Remaining GL JS differences: no skirts/seam handling between LOD levels, one 512 px drape target per tile (GL JS 1024 for 256-px sources).

## 2026-10-17 — save/restore of heading and pitch on exit
`saveState()` persisted only coordinate, zoom, globe flag and style; `window.mapTilt`/`mapBearing` were never saved. Now `map/tilt` and `map/bearing` are saved on close and restored in `restoreState()` after the style is set (a draped-terrain style otherwise forces tilt 50 when the tilt is ~0), then `applyCamera(false)`; the style's load re-applies them. Verified with a scripted close (tilt 61, heading 33) and a fresh launch (HUD showed Heading 33°, Pitch 61°, Zoom 13.7; `~/.config/MapLibre/MapLibreEarth.conf` holds `tilt=`/`bearing=`).

## 2026-10-17 (evening) — tile-edge gaps (flat and globe)
Causes found by reading GL JS (`terrain.ts` `_buildSkirts`, DEM `backfillBorder`) and testing flat + globe with scripted screenshots at a z14 tile corner (56.65623, -5.031738) and top-down views:
1. **Edge vertices of same-zoom neighbours disagreed** (each tile's edge row read only its own border pixel, a copy of its last pixel). `TerrainTileManager` now backfills the 1-px DEM border from all 8 loaded neighbours (`DEMData::backfillBorder`) and tells `TerrainPass` (`takeUpdatedTiles`) to rebuild meshes whose border changed. Unit test `DEMData.SharedEdgeIsContinuousAfterBackfill`.
2. **T-junctions between LOD levels** (new variable-zoom cover): each mesh has a **skirt** (GL JS: tile width / 5) hanging below its edges. Skirts show as curtains only where a neighbour is absent (cover edge, DEM-less tiles).
3. **Hillshade seam**: normals at a tile edge were one-sided; slopes now come straight from the DEM +-1 px (using the backfilled border) so shading matches across tiles. `DEMData::getElevation` may read the border (coordinates down to -1).
4. **Missing DEM tiles** (sea lochs with no source tile) left holes: `isMissing()` tiles now get a flat sea-level mesh (GL JS treats missing DEM as flat); a tile first built flat is rebuilt when its data arrives.
5. **Dark water drawn beige**: the shader replaced near-black drape pixels with the tint. Drape targets now clear to **transparent** (`RenderTarget::setClearColor`) and the shader tints only where `alpha < 0.5` (unrendered), so black imagery stays black.
Verified: flat and globe agree at zoom 11.5-12.5 with no hairline cracks at the tile corner, any pitch/bearing tried. Frames captured mid-load (navy background / beige squares until the raster tiles arrive) are the drape loading, not geometry gaps — still worth improving (keep the previous texture until the new one is ready). Patch 0040 now touches 19 files; core tests 1057 pass (+1) with the same 3 known failures.
Open: globe at low zoom (~z11) showed purple holes bordered by skirt curtains in one view although every covered tile had a mesh — not understood; re-check with the globe path (`globe::tileCover`, elevation boxes) and drape RTT in globe.

## 2026-10-17 (late) — Glencoe N/S seam investigation + copyable camera readout
- **HUD:** the bottom-left camera panel is now selectable text (Ctrl+C) and has a **Copy** button that puts a full-precision block on the clipboard (centre lat/lon to 6 dp, zoom 4 dp, pitch, bearing, camera altitude, ground, exaggeration, projection, terrain flag, style URL, window size/scale, plus a JSON line usable with `map.easeTo`). Paste it into the bug report to reproduce the exact view.
- **Seam through the Three Sisters (lon ~ -5.00977, a tile boundary at every zoom 12-15):** measured with TEMP logging: same-zoom neighbours (z14 7963|7964) now have **0.00 m** edge-height mismatch after the border backfill; per-vertex edge heights identical (1141.5 m both sides). Skirts, a mesh overlap of 8 units and skirt-off experiments each changed the look but a thin wavy dark line along that boundary remained at pitch 0 (also where the drape is not rendered) and it is NOT a height crack. Remaining suspects (not yet resolved): (a) drape RTT edge columns / raster-tile edge handling at that boundary (z12 raster tile edge), (b) per-tile hillshade/shade discontinuity at the edge (tiles 0.60 vs 0.54), (c) LOD (z13|z14) neighbours in the rows to the south. Experiments (outward overlap, skirt-off) were reverted per the GL JS alignment rule.
- Next: user to paste the exact camera block for the view where the gap is most visible.
- **RESOLVED (diagnosis) — the line is a DEM data seam, not a renderer bug.** John's camera (lat 56.6455 lon -5.0149 z13.32 pitch 81 bearing 189) reproduced via scripted automation. Per-tile colour debug showed the tile boundary is clean and the dark wavy line lies ~200 m east of it, at lon -5.000. Probing `terrain->getElevation` across lon -5.0012..-4.9988 shows a narrow ~100 m trench exactly at -5.0001 over lat 56.640-56.655 (e.g. lat 56.645: 699 -> 589 -> 703 m; 56.650: 442 -> 372 -> 442). It is in the AWS terrarium source (a 5 W source-tile seam), so GL JS with the same DEM would show it. Earlier suspects (a)-(c) above are ruled out. All TEMP diagnostics removed; clean sources restored (terrain_pass.cpp, terrain.hpp, main.qml); both library configs rebuilt/installed. Options for John under the GL JS rule: leave as data artefact, or choose a different DEM source.

## 2026-10-17 (night) — GL JS comparison harness, Mapterhorn style, terrain LOD centre fix
- **Qt WebP plugin** built from qtimageformats v6.11.2 (system libwebp) into `~/dev/tmp/qtimageformats` and installed into `~/Qt/6.11.2/gcc_64/plugins/imageformats/libqwebp.so` (needed for Mapterhorn DEM tiles). Without it: `Unsupported image type`.
- **TileJSON DEM sources:** `Map::Impl` only used a raster-dem source's tileset when it was inline in the style, so `url`-based sources (Mapterhorn) left terrain off (flat, hillshade only). Now uses the resolved TileJSON (`resolvedTerrainTileset`, patch 0040 / `map_impl.cpp`).
- **New style** `gljs-terrain-style.json` = the GL JS "3D Terrain" example (menu entry "3D Terrain (GL JS example)").
- **Harness** `tools/gljs-harness/` (maplibre-gl 6.14.0, `serve.py`, `?save=NAME` posts a PNG to /tmp/shots). **Match the app's window:** logical size and DPR (system 2.0 x app scale = 2.4): `w=1476&h=929&dpr=2.4` for a 3542x2230 app shot; using device pixels at dpr 1 shows ~2.4x too much ground. Background browser tabs throttle rendering - nudge with a screenshot before waiting for `__savedOk`.
- **Terrain LOD bug (mine):** the tile-cover centre was the screen-centre ray hit on sea level, kilometres from the real centre at high pitch over elevated terrain, so camera-to-centre distance was doubled and tiles were one level too deep (OSM cover 115 tiles to z17; GL JS 39 to z16). Now the lat/lng centre (GL JS `worldFromLngLat(center, elevation)`): 47 tiles to z15 on the same view. In patch 0040 (`tile_cover.cpp`).
- **HUD** bottom-left now has the same five lines/format as the harness HUD (+ Copy button).
- Still open vs GL JS (side-by-side `/tmp/shots/sbs_*.png`): no sky, drape RTT 512 vs GL JS 1024 (softer foreground), washed-out look, far-field low-zoom tiles (z3-6) that GL JS culls, keep-old-texture drape lag. Core tests: 1057 pass, same 3 pre-existing failures.

## 2026-10-17 (late night) — Sky + terrain fog (patch 0041)
- **Sky** ported from GL JS (`sky.ts`, `sky.fragment.glsl`, `draw_sky.ts`): `style::Sky` (root `sky` object, spec defaults, `Style::getSky/setSky`), `SkyPass` draws a screen quad first with `SkyShader` (distance above the horizon line, `getMercatorHorizon`). `sky: {}` gives the default blue sky; no `sky` key = no sky. The GL JS example style (`gljs-terrain-style.json`) now has `"sky": {}`.
- **Fog**: terrain shader blends the surface towards fog/horizon colour (`v_fog_depth`, `calculateFogBlendOpacity`: off below pitch 60, full at 70) via a layer UBO (`idTerrainFogUBO`). Verified at Glencoe pitch 81: distant ridges haze into the horizon like GL JS.
- Not done (row 14 in `references/gljs-alignment.md`): expressions/transitions, globe atmosphere/sky, `Map::setSky` Qt/QML API, Debug build of the app (MCP cannot switch config). New tests `StyleConversion.Sky*`; core tests: same 3 pre-existing failures. Patch `0041-sky-and-terrain-fog` (30 files, 8 new) is **not yet on the fork branch**; uncommitted.

## 2026-10-17 (night, later) — sky expressions/transitions, globe atmosphere, QML API (patch 0042)
- `style::Sky` now uses the property/transition machinery (like `Light`): all seven sky properties accept constants or zoom expressions and have `-transition` options; `RenderSky` evaluates per frame (`hasTransition` keeps frames coming). Tests: `StyleConversion.Sky{Defaults,Constants,ExpressionsAndTransitions,Errors}`.
- **Globe**: `SkyShader` has the globe branch (sky fades through the atmosphere; limb is the horizon); new `AtmosphereShader` (Rayleigh/Mie, sun from the style `light`, `getSunPos`) drawn over the scene. `SkyPass` computes the globe centre in view space from the globe view-projection. Verified: blue limb halo at zoom 1.5-5.5, pitch 0-85.
- **API**: `QMapLibre::Map::setSky(QVariantMap)` / `clearSky()`; QML `MapLibre { skyEnabled: true; sky: {"sky-color": "#199EF3", ...} }` (values constant, JSON string or expression list; a style (re)load replaces the sky, the item re-applies it). `skyEnabled: false` removes a sky the item added and leaves the style's own sky alone.
- Debug note: `test_mln_quick` asserts (thread identity in `MapRenderer::updateRenderer`) under the default threaded render loop; with `QSG_RENDER_LOOP=basic` (the app's loop, see the runbook) it passes. Pre-existing, not from sky.
- Patch `0042-sky-expressions-globe-atmosphere` (28 files, 6 new) on top of 0041; the Qt wrapper changes are in maplibre-native-qt itself (`src/core/map.*`, `src/quick/plugins/map_quick_item*`).
- App: toolbar **Sky** switch (persisted `map/skyEnabled`, default on) drives `MapLibre.skyEnabled`; a style's own `sky` is kept when no `sky` properties are given (`Map::hasSky`).
- **Sky off** (switch, `skyEnabled: false` explicitly set): no sky at all, even for a style that defines one; the area above the flat map's horizon then shows the app's space backdrop colour (`backgroundColor`, #333366) via the sky quad drawn in that colour; terrain fog is off. (`SkyPass::update(..., spaceColor)`, patch 0042.)

## 2026-10-17 (late night) — investigation: "relief detail washed out / smoother vs GL JS"
Matched views (991x1051 logical, DPR 2, exaggeration 1, Glencoe 56.645543,-5.014887), app vs `tools/gljs-harness`, plus experiments (all reverted; nothing changed in the code):
1. **The style's `hillshade` layer is effectively not rendering in the terrain drape.** With the baked shade switched off (TEMP `shade = 1.0` in `terrain.hpp`) the pitched view loses almost all relief: the drape holds only the OSM raster. The relief you see in the app comes from the *baked per-vertex shade* (CPU hillshade of the 128x128 mesh - GL JS has none), which is why it is low-frequency/"smoother" and heavier in broad dark blotches, while GL JS's crisp relief is the DEM-resolution hillshade layer.
2. **Cause (confirmed with a hillshade-only style):** at pitch 0 / zoom 13.3 the hillshade shows the *same picture repeated in every drape tile* (3x3 tiling), at pitch 60 / zoom 14.5 it is absent. Only `RasterLayerTweaker` writes per-drape-target UBO blocks (`drapeTargetOrdinal` / `drapeTargetCount`, `raster_layer_tweaker.cpp:80-90`); the other draped layer types (hillshade, color-relief, fill, line, background) go through their tweakers once per frame with a single projection, so every drape target (each with its own ortho matrix) reuses the same one. Raster drapes correctly, everything else is wrong in all but one tile. Hillshade drawables do exist (10 per tile cover in the log), so it is not a missing-tile or stale-drape problem (forcing re-render every 1.5 s changed nothing).
3. **Tile seams:** at pitch 0 the app shows brightness steps along drape tile boundaries (cross-shaped); GL JS has none. Partly #2, partly the baked shade; the hillshade DEM border (`backfillBorder`) is not shared across drape tiles either.
4. **Drape sharpness:** OSM labels/paths are noticeably softer in the app at z14.5 (RTT 512 px vs GL JS 1024 for 256-px sources; alignment row 8).
5. **Not a defect:** at pitch 60 the app is darker/more contrasted than GL JS (GL JS hazier). At pitch 81 the two cameras do not frame the same scene (GL JS's terrain camera collision moves its camera), so detail comparisons there are not like for like.
**Recommended fix (needs a decision):** generalise the per-drape-target UBO window from the raster tweaker to the other draped layer types (hillshade first), then re-evaluate whether the baked shade should go (GL JS has none; alignment rows 1-2), then the seams and RTT size.

## 2026-10-18 - patch 0043: per-drape-target UBO blocks for every draped layer type
- `LayerTweaker::drapeUBOWindow` / `updateWindowedBuffer` (layer_tweaker.hpp/.cpp) generalise the raster tweaker's block layout (block 0 = main pass, block `ordinal+1` = drape target) and are now used by the hillshade, color-relief, fill, line and background tweakers (drawable, tile-props and projection UBOs, `uboIndex` offset). Raster tweaker left as is. Patch `maplibre-native-0043-drape-per-target-ubo-all-layers.patch` (committed on the local fork branch `maplibreearth-patches`, not pushed).
- Verified Release app (Qt Creator MCP) vs `tools/gljs-harness`, hillshade-only style (osm dropped), 991x1051 dpr 2, Glencoe: z14.5/p0, z13.3/p0 and z13.3/p60 now show the hillshade draped correctly, unique per tile (no 3x3 repeat, present at pitch 60); relief features line up with GL JS. Full GL JS style at z13.3/p60 shows crisp DEM-resolution relief again. Libraries refreshed for Release and Debug; the Debug *app* was not rebuilt (the MCP cannot be switched to Debug here). Core tests: 1061 pass, only the 3 known failures.
- Still different from GL JS: the app is darker/greener (baked per-vertex shade multiplies the drape, broad dark blotches on lit slopes), a straight drape-tile edge is visible in dark hillshade areas at z13.3/p60. Both left for John's decision (baked shade removal; hillshade DEM border sharing; alignment rows 1-2).

## 2026-10-18 (part 2) - patch 0044: missing near hillshade, baked shade removed
- **Why the nearest drape tiles had no hillshade:** `TilePyramid::update` rejected tiles outside `tileRange` whose max zoom was `min(tileZoom, source max)` unless the globe / distance-LOD was on. The terrain cover (patch 0040) asks every source for finer tiles in the near field (z14 at zoom 13.3 pitch 60), so those ideal tiles were never created ("none"), the hillshade (and the OSM raster) fell back to z13 or nothing for the nearest ground. `variableZoom` now also holds when `terrainVariableZoom` is set. Diagnosed with temporary logging of ideal / rendered tiles and the hillshade drawables per drape (removed).
- **Baked shade removed (alignment rows 1-2):** the terrain mesh is now xyz (`Float3`, no CPU hillshade, no light constants, no slope sampling); the terrain shader draws the drape texture directly. Where the drape alpha is 0 a constant beige tint remains (row 9, John to decide whether to keep). Fog and sky unchanged.
- **Row 3 (DEM tile zoom) not changed - needs John:** GL JS terrain tiles are `coveringTiles` with tileSize = source.tileSize * 2 (1024 for the 512 px Mapterhorn source): nominal z = floor(zoom - 1), DEM source tile z - 1 (deltaZoom), RTT sized from that. The fork uses `floor(zoom)+2` (max 14) for the mesh, DEM and drape tile together, with a 512 px drape per tile. Aligning needs the terrain tile manager to sample a sub-rectangle of a coarser DEM tile and the drape RTT size to follow (row 8), otherwise the drape gets 4x coarser. That is a design change, not a constant.
- **Measured** (Release, hillshade + OSM style, z13.3 pitch 60, 991x1051 dpr 2, luminance mean/std): GL JS top 181/28, mid 145/34, bottom 125/34; app before 0043 140/38, 162/46, 178/31; app now 181/27, 143/34, 124/34.

## 2026-10-18 (part 3) - patch 0045: GL JS terrain tile zoom + DEM tiles + RTT size, drape fingerprint, no tint
- **Terrain tile zoom / DEM tiles (alignment rows 3, 4):** terrain tiles are `coveringTiles` at tile size `source.tileSize * 2` (`TerrainTileManager::terrainZoomFor` = `floor(zoom + log2(512 / (tileSize*2)))`, max 22, passed to the same variable-zoom cover as before). Each samples the DEM tile one zoom coarser (`sourceTileFor`, deltaZoom 1, capped at the source max), with the nearest loaded ancestor while that loads (`getSourceTile`); the mesh samples the terrain tile's quadrant of the DEM tile (offset/size in DEM pixels). Meshes are rebuilt when the DEM tile they sample arrives. UpdateParameters gets `terrainTileSize`; the camera elevation samples the same DEM zoom (`Map::Impl::terrainElevationAt`). Tests: `TerrainTileManager.TerrainZoomFollowsGLJS`, `SourceTileIsOneZoomCoarserAndCapped`.
- **Drape size (row 8):** `rttSize = source.tileSize * 2 * 2` = 2048 px for Mapterhorn (was 512). Same drape density as before per world pixel (512 px per z14 tile = 2048 px per z12 tile) with about 15x fewer targets: 12-15 at pitch 70-85, 4 at z16, 26-39 before.
- **Re-render storm (task 3):** `drapeGeneration` was bumped by every source tile change and was part of every drape tile's fingerprint, so any OSM/DEM tile load anywhere re-rendered all drape targets (26-39 per frame, 61 render frames, 1350 target renders over a 3-view run). The fingerprint is now GL JS's `RTTFingerprint` idea: style identity + the source tiles (id and per-tile data revision, bumped in `onTileChanged`) of the drape layers that overlap the drape tile. Same 3-view run: 31 render frames, 133 target renders (about 10x fewer); tiles still re-render when their source tiles finish loading.
- **Tint removed (row 9):** `terrain.hpp` draws the drape texture only. A hillshade-only style now shows the window background where the hillshade is transparent (white, like GL JS's page), nothing relied on the tint.
- **Measured** (Release, z13.3 pitch 60, 991x1051 dpr 2, luminance mean/std top/mid/bottom): GL JS 181/28, 145/34, 125/34; app now 181/28, 145/34, 125/34. Near hilltop and the three views were compared visually; the pitch-81 GL JS reference could not be captured at the app's size (the harness never idled in the browser pane, and GL JS's terrain camera differs at that pitch), so p81 is judged by eye only. A faint tile edge in the nearest slope at pitch 81 remains (hillshade LOD change between source tiles).
- **Memory** (amdgpu GTT, `~/dev/tmp/memsample.sh`, same 3-view sweep): peak +840 MB before, +1240 MB after (about +400 MB; the drape targets are 2048 px RGBA, 16.8 MB each, 12-15 of them, plus transient old targets when the cover changes); VRAM carve-out unchanged (~3.8 GB used). No RTT pool yet (row 8), so targets are destroyed and recreated as the cover changes.
- **Not done / for John:** the 192-tile cap in `terrain_pass.cpp` (row 6) now allows far more memory per tile (192 x 16.8 MB); the cover is 12-15 tiles in practice but the cap should become a memory budget or be removed together with the RTT pool. Zoom-dependent style properties in the drape are still not tracked (row 10).

## 2026-10-18 (part 4) - patch 0046: drape RTT recycle pool, GL JS fingerprint classes, follow-up frames
- **How GL JS bounds drape memory** (render_to_texture.ts, painter.ts, tile.ts): no byte budget and no tile-count cap. Only renderable terrain tiles hold an RTT; a tile that leaves the cover or whose texture changes releases it to `painter._rttObjectRecyclePool`, `acquireRTT` pops from the pool before allocating, and `clearRTTPool` frees the pool at rest. The count is bounded by the LOD cover.
- **Pool (A):** `RenderOrchestrator` keeps `terrainDrapePool`; targets of tiles leaving the cover go to the pool, new tiles take from it before `createRenderTarget`, the pool is emptied when the camera is at rest (`!zoomChanged && !isChanging()`), and cleared on a size change. One shared depth attachment is not applicable (drape targets have colour only).
- **Fingerprint (B):** `DrapeFingerprint` = style identity, visible-layers hash (layer visibility and minzoom/maxzoom at the current zoom), the sorted (layer, source tile) keys under the drape tile with their data revisions, and the zoom rendered at. `differenceOf` returns none/zoom/sourceTiles/visibleLayers/revision; policy as `RenderToTexture::prepareForRender`: zoom while moving or visibleLayers with a zoom change keep the old texture and request a follow-up frame, zoom/sourceTiles re-render one tile per frame (nearest first, the cover order), others immediately. Tiles entering or leaving the set are `sourceTiles`; only a changed revision of a tile in both is `revision` (first version hashed the set and classified every zoom change as revision - fixed).
- **Measured** (Release, `gljs-terrain-style.json`, 991x1051 dpr 2): GTT peak above the app's start: old per-frame scheme +840 MB (3 views), patch 0045 without pool +1240 MB (3 views), now +640 MB over a 10-view sweep (z13.3 p60/p81, z14.5 p0, zoom sweep 12-17). Max cover 17 tiles (initial load), 12-15 at pitch 70-85, 4 at z16; pool reuse seen (`pool` drops to 0 as new tiles take it). Render-target renders: 1350 (old, 3 views) -> 133 (0045) -> 93 render frames / about 350 renders for the 7-view sweep; one tile per frame after a zoom jump (follow-up frames), e.g. 13.0 -> 13.9: 1+1+1+1 renders in 4 frames instead of 4 at once.
- **Zoom-dependent style (C):** hillshade-exaggeration zoom interpolate: luminance std 26.7 at z13.0, 40.7 at z13.9, and exactly 26.7 again back at z13.0 (drape refreshes after zoom changes in both directions); raster-opacity zoom interpolate on the OSM layer: 36.6 -> 39.0 -> 36.6. Tile loads still update the drape (sourceTiles class).
- **Not done:** the 192-tile cap stays (alignment row 6): the maximum seen is 17 but boundedness of the LOD cover is not proven; each tile is now 16.8 MB, so John should decide between removing it and a proof/limit. Test style names must contain `terrain-style.json` for the app to enable terrain (main.qml checks the URL).

## 2026-10-18 — performance-metrics panel
Top-left, under the control cluster, as the GL JS "Display performance metrics" example: **Load** (ms from the style (re)load to the map `load`), **Idle** (ms to the map's first fully-rendered state) and **FPS** (map frames rendered in the last second). Qt plugin: `MapQuickItem::renderedFrames()` (counts `MapChangeDidFinishRenderingFrame` partial + fully rendered frames) and the `mapLoaded` / `mapIdle` signals (`MapChangeDidFinishLoadingMap` / `...RenderingMapFullyRendered`). Measured: idle 0 FPS, animated zoom 60 FPS. The 192-tile drape cap is kept (John's decision 2026-10-18).
- Metrics panel: added **Frame** (average CPU time per rendered frame, encoding + rendering, from the core's `RenderingStats`; not GPU time). Qt: `Map::frameRendered(encodingMs, renderingMs)` and `MapQuickItem::averageFrameTimeMs()` (average since the previous call). Measured 1.4 ms/frame at 60 FPS (Glencoe pitch 81 zoom animation, Release). Load and Idle are equal in this app: the core's "map loaded" event fires at the first fully rendered frame.

## 2026-10-18 — pitch-81 comparison, app vs GL JS (matched 991x1051 @ DPR 2, Glencoe, zoom 13.3176, pitch 81.12, bearing 189.375, exaggeration 1, Release, patches 0043-0046)
Same scene, ridgelines and lake coincide (terrain geometry/DEM zoom aligned). Remaining differences, with causes:
1. **Mid-field detail softer, streaky** (forest face): GL JS drape textures use `LINEAR_MIPMAP_LINEAR` + max anisotropy (`painter.acquireRTT`); our drape target sampler is plain linear, no mips, anisotropy 1 (`offscreen_texture.cpp:26`; `SamplerState{mipmapped=false,maxAnisotropy=1}`).
2. **Near-field tile edge**: a vertical brightness/height step and a doubled ridge line on the nearest slope at a terrain tile boundary (LOD change); GL JS is smooth.
3. **Far haze**: GL JS fades distant terrain gradually into the horizon; the app keeps more colour/contrast far away and has a harder horizon band. Fog far plane differs (alignment row 14: native `farZ` vs GL JS `_calculateNearFarZ`).
4. **Brightness**: app 8-15 levels darker (mid 116 vs 124, near 134 vs 148, far 150 vs 160), likely the missing mipmap averaging and the fog/far-plane difference; not yet isolated.

## 2026-10-18 (part 5) - patch 0047: drape mipmaps + anisotropy, DEM backfill redraw, GL JS fog far plane
- **1. Drape mipmaps (GL JS `acquireRTT` + `generateMipmap`):** the drape render-target texture is created mipmapped with `Linear` + anisotropy 16 (clamped to the device). Vulkan: the framebuffer uses a level-0-only view (`Texture2D::createLevel0View`), mips 1.. are blitted from level 0 after the render pass ends (`RenderableResource::finishRender` called from `CommandEncoder::present` -> `Texture2D::generateAttachmentMips`, with barriers from the shader-read level 0 / undefined lower levels), usage gains TransferDst. Measured at the pitch-81 view (991x1051 dpr 2, luminance bands far/mid/mid2/near): before 161/119/108/143, after 161/119/108/144, GL JS 176/128/119/155; Laplacian std (sharpness) in the mid crop 8.5 both before and after vs GL JS 12.2. So mips/anisotropy did not change the mid-field softness or the 8-15 level darkness (those have another cause, not texture filtering; see below). GPU memory (amdgpu GTT, 10-view sweep): peak +890 MB vs +640 MB before mips (about +33% on 2048 px targets as expected).
- **2. Near-field tile-edge step (investigation + one fix):** the DEM edge heights agree across same-zoom terrain tiles (logged), so there is no mesh crack there. Fix found: when a DEM tile is backfilled from a neighbour, the *neighbour's* hillshade is prepared again, but nothing told the drape, so its drape tile kept the old edge shading; `RenderRasterDEMSource::onTileChanged` now notifies the observers for the backfilled neighbour (`RenderTileSource::onTileChanged(borderTile)`), so its drape tiles re-render. The remaining step and the pale band are inherent LOD effects, same mechanism as GL JS (see the alignment audit, "Open: near-field LOD seams"): not changed, needs John.
- **3. Fog far plane:** `TransformState::getFogDepthRange` now ports GL JS `_calculateNearFarZ` (min elevation = min(centre elevation, DEM minimum of the centre tile, camera altitude - 100 m); `lowestPlane`; law-of-sines distances to the screen top and the horizon; `farZ = (cos(pi/2 - limitedPitch) * topHalfMinDistance + lowestPlane) * 1.01`). GL JS also uses this far plane for its projection; ours still uses `getProjMatrix`'s, unchanged (needs John's agreement). Pitch-81 bands (horizon/far): before 217/161, after 239/174, GL JS 237/176.
- All 3 steps rebuilt in both library installs and the Release app; core tests: only the 3 known failures.

## 2026-10-18 (part 6) - patch 0048: GL JS skirts + projection planes, LOD edge stitching (agreed deviation), roundZoom mid-field fix
John's decisions (via the main session): keep mipmaps; stitch tile edges from the coarser DEM; keep GL JS's hillshade zoom dependence; change the projection's far plane to GL JS's; lengthen the skirts to GL JS's; investigate the mid-field. Measured at the c81 view (lat 56.645543, lon -5.014887, zoom 13.3176, pitch 81.12, bearing 189.375, 991x1051 dpr 2): bands horizon/far/far2/mid/mid2/near luminance, Laplacian std for mid/mid2.
- **5. Skirts:** `u_ele_delta` as GL JS: skirt vertices carry `w = 1`, the vertex shader lowers them by `40075016.7 / 2^max(zoom,0) / 5` m (map zoom, equator); the length is in the terrain UBO (`depth_range.z`). Visual check: unchanged except the band along cracks.
- **4. Projection near/far (Mercator + terrain only):** `getProjMatrix` uses `getFogDepthRange`'s far plane (GL JS `_calculateNearFarZ`) and `nearZ = height/50` when the transform carries a tile elevation range (terrain); the nearClipped matrix keeps its near plane; globe and non-terrain maps untouched. Checked: pitch 85 z13.3, pitch 70 z15, pitch 80 z11 - no clipping of far terrain or of the near slope, horizon fade as before (bands horizon/far 236/174 vs GL JS 237/176). The cached inverse projection (tile cover frustum) uses the same function, so the cover and the draw agree.
- **2. LOD edge stitching:** `terrain_stitch.hpp` (`coarserNeighbour`, `coarseEdgeParameter`, `interpolateEdge`, unit-tested) and `TerrainPass`: for each side whose neighbour in the cover is coarser, the edge heights come from that neighbour's facing mesh edge (129 DEM samples, linear in between); corners from north/south; skirts kept. A per-tile signature (coarser neighbours + the DEM tile each currently uses) rebuilds the mesh when a neighbour's LOD or DEM changes, and DEM updates of the neighbours' source tiles remove the dependent drawables. At the c81 view the pale skirt band along the near ridge turns into a thin line (the ridge is continuous across the z14/z13 boundary).
- **6. Mid-field (finding and fix):** per-band tile zooms, GL JS vs ours at the p60 and c81 views (screen band = tenth of the viewport height of the tile centre, 9 = bottom). At p60 terrain and hillshade matched already; **OSM raster differed**: GL JS z15 over bands 7-9 and z12-13 at the top, ours z14 at 7-8 and z11-12 at the top. Cause: GL JS rounds each tile's LOD zoom for raster sources (`roundZoom = true`, also for raster-dem) while our terrain LOD used `floor`, and the centre zoom handed to the tile-zoom function used the cover's zoom instead of `zoom + log2(512/tileSize)` (wrong by a level for 256-px sources when frac(zoom) >= .5). Fixed (`roundZoom`, `centerZoomShift`); ours now matches GL JS per band (OSM z15 near, z12-13 top; hillshade z14 near, z13 mid, z11-12 top; terrain z13/12/11/10). Result at c81: mid 120 -> 127 (GL JS 128), mid2 108 -> 119 (119), far2 132 -> 134 (136), near 144 -> 147 (155); Laplacian std mid 8.0 -> 10.3 (12.2), mid2 6.6 -> 10.2 (11.0). The earlier mid-field softness and darkness were this LOD difference, not hillshade or drape sizing (drape RTT size matches: 2048 px, same terrain zoom per band). Remaining near-band gap (147 vs 155) and sharpness gap are not explained yet.
- main.qml was only edited by temporary screenshot scripts and is restored (verified with `git diff`). Core tests: only the 3 known failures; both library installs refreshed; Release app rebuilt via the MCP (Debug app not).

## 2026-10-18 (part 7) - follow-up checks after 0048 (no code change, no patch 0049)
- **Remaining gaps at c81:** the "near 147 vs 155" gap was an artifact of the app's HUD/compass overlay in the measured band (the app screenshot includes its camera panel at the bottom left; GL JS's is smaller). Measured on columns 800-1700 only (clear of the overlays), bands far/far2/mid/mid2/near/near2 luminance: ours 169/131/127/111/134/150, GL JS 170/133/128/111/133/149. Laplacian std: ours 17.0/10.0/14.1/10.6/2.1/1.4, GL JS 19.0/10.7/15.5/11.8/2.9/1.4 (about 8-10 % less in the far/mid field, not explained; the per-band tile zooms of terrain, OSM and hillshade match GL JS, the drape rttSize is 2048 in both, cameras agree: centre elevation 730.8 m vs 739.9 m, camera altitude 1756.7 vs 1764.6 m, far plane 18188 vs 18280). Candidate left: GL JS samples the DEM at texel centres in the shader (`coord = pos * dim + 1.5` on a border-padded texture) while the fork samples the DEM grid at integer pixel coordinates (a half-DEM-pixel offset that could explain the 9 m centre-elevation difference); not changed, needs a decision as it moves all terrain by half a DEM pixel.
- **Z-fighting with the new near/far planes:** checked with a test style (gljs terrain style + OpenFreeMap vector tiles: fill-extrusion buildings, labels, roads) at Fort William (z17 pitch 75, z15 pitch 80, z13.3 pitch 70) and Ben Nevis summit (z15 pitch 75, z17 pitch 80, z11 pitch 70); camera elevations 8-1340 m, far planes up to 170 000 px: no flicker, striping or clipping seen; building bases sit cleanly on the terrain and labels are not cut. Not exercised: location indicator, custom drawable layers.
- **Render tests** (linux-vulkan, per group, 176 groups): 1200 passed, identical to the 2026-10-16/17 baseline; the only non-passing tests are the known `fill-extrusion-pattern/tile-buffer` (failed) and `text-font/{burmese,devanagari,khmer}` (errored). Benchmarks (`TileCover*`, after only; the non-terrain cover path is unchanged by 0043-0048): PitchedViewport 3078 ns, Globe/3 10207 ns, Globe/8 36344 ns, Bounds 185 ns, Polygon 1148 ns.

## 2026-10-18 — investigation: half-DEM-pixel sampling offset vs GL JS (no code change yet)
GL JS places DEM pixel `i` at tile coordinate `(i + 0.5) / dim` (texel centres): CPU `DEM_CELL_CENTER_OFFSET = -0.5` in `terrain_coverage.ts` (`getSampler`), GPU `get_elevation`: `uv * u_terrain_dim + 1.5` with a 2-texel border (`_prelude.vertex.glsl`). Ours samples `getElevation(u * dim, v * dim)` with no offset (`terrain_pass.cpp:61`, `terrain_tile_manager.cpp:71, 88`), so the DEM is read half a DEM pixel off (terrain displaced toward the south-east relative to the hillshade/drape, which are cell-centred).
**Verified with the real Mapterhorn tiles** at the Glencoe centre (56.645543, -5.014887), bilinear: DEM z11 (the zoom the mesh samples, 21 m/px): no offset = **730.8 m** (the app's HUD value), with the GL JS -0.5 offset = **739.9 m** (GL JS's HUD value). Both reproduced to 0.1 m, so this fully explains the 9 m centre-elevation difference. Error scales with DEM pixel size and slope: z10 -18.8 m, z11 -9.0 m, z12 -4.6 m, z13 -2.3 m, z14 -1.1 m; horizontal displacement is 0.5 DEM px (10.5 m at z11).
Fix (recommended, not a departure): apply the -0.5 cell-centre offset once, in the sampling path used by the mesh, `TerrainTileManager::getElevation` and `getMinMaxElevation` consumers; the 1-px DEM border is enough (x in [-0.5, dim-0.5]). Update the DEM unit tests; mesh edge stitching/backfill are unaffected.

## 2026-10-18 (part 8) - patch 0049: DEM pixel-centre sampling (GL JS `DEM_CELL_CENTER_OFFSET`)
- GL JS places DEM pixel i at tile coordinate (i + 0.5) / dim (CPU: `DEM_CELL_CENTER_OFFSET = -0.5`; GPU: `uv * dim + 1.5` on a border-padded texture). The fork sampled `getElevation(u * dim, v * dim)`, half a DEM pixel off. New `DEMData::getElevationAtPoint(x, y)` (pixel-edge coordinates, subtracts 0.5) is used for the terrain mesh (`TileDem::elevation`, which the 0048 edge stitching also uses), `TerrainTileManager::getElevation` and `sampleElevation` (map centre / camera elevation, symbol elevation). `getElevation` stays the raw pixel-grid sampler (hillshade/slope code does not use it). The 1-pixel border covers the range [-0.5, dim - 0.5]; two tiles still give the same height at a shared edge (average of the two edge pixels), tested.
- Tests: `DEMData.ElevationAtPointUsesPixelCentres`, `ElevationAtPointSharedEdgeAgrees`, `TerrainTileManager.GetElevationUsesDemPixelCentres`; core suite: only the 3 known failures.
- Measured at the c81 view: centre elevation 730.8 -> 739.85 m (GL JS 739.91), camera altitude 1756.7 -> 1765.7 m (GL JS 1764.6), far plane 18188 -> 18281 (GL JS 18280). Bands over columns 800-1700 (ours/GL JS): far 171/170, far2 132/133, mid 128/128, mid2 111/111, near 133/133, near2 149/149; Laplacian std far 16.0/19.0, far2 9.9/10.7, mid 15.0/15.5, mid2 10.9/11.9, near 2.4/2.9, near2 1.4/1.4 (before: 17.0/10.0/14.1/10.6/2.1/1.4): mid and mid2 slightly sharper, far slightly softer, the overall gap to GL JS is unchanged (about 5-15 %). The z14.5 pitch 60 view shows roads, streams and hillshade registered on the terrain as before.

## 2026-10-18 (part 9) - HUD "Ground NaN" fix and sharpness-gap decomposition (no core change, no patch 0050)
- **HUD "Ground NaN m" (app bug, not terrain sampling):** `cameraReadout` bound `groundMeters`/`cameraMeters` to expressions of the form `tick >= 0 ? map.terrainElevation(...) : NaN`. QML evaluated them once at start-up, before the map had terrain, and the dependency on `tick` did not re-trigger them, so the panel stayed at NaN / 0. Fix (main.qml, deliberate, uncommitted): `groundMeters`/`cameraMeters` are plain properties refreshed by an imperative `refresh()` called from the 400 ms Timer. Verified at the c81 view with the Mapterhorn style: ground 739.85 m, camera 1765.7 m (HUD, `map.terrainElevation` and the camera altitude all use `Map::Impl::terrainElevationAt`, same path).
- **Sharpness gap at c81 (Laplacian std, ours vs GL JS, bands far/far2/mid/mid2/near):** both layers 16.0/9.9/14.6/10.8/2.4 vs 19.0/10.7/15.5/11.9/2.9; OSM only 8.4/7.0/6.8/2.2/0 vs 11.9/6.9/5.9/2.4/0; hillshade only 16.5/12.8/16.6/12.3/3.2 vs 21.7/20.7/17.7/11.0/7.4. The OSM raster drape matches GL JS except in the far band (z10-12 tiles). The hillshade layer carries the remaining deficit (contrast-normalised far2/mid/mid2), but the hillshade-only luminance differs from GL JS (GL JS composites over the page background, ours over white), so the comparison is only indicative.
- **Experiment:** drape textures without mipmaps and without anisotropy (temporary): hillshade-only Laplacian std changed by less than 0.4 in every band, so mip/aniso filtering is not the cause. Temporary change removed. No clear defect against GL JS was found, so no fix; the residual gap (about 5-15%) is not attributed to a specific cause.

## 2026-10-18 — decisions and housekeeping
- John: **accept the hillshade sharpness gap vs GL JS** (decomposed: OSM raster matches except the far band; hillshade carries the rest; mipmaps/anisotropy ruled out); no further chasing. Keep the 192-tile cap.
- HUD "Ground NaN" fixed in `main.qml`: the ground/camera values were bindings that depended on a timer tick and were evaluated once at start-up; now plain properties refreshed from the 400 ms timer.
- Wiki brought up to date (next-steps resume section, fork-patches 0041-0049, history).

## 2026-10-18 (part 10) - globe + terrain: flat drape, wrapped tiles, pole caps (patches 0050, 0051)
- **Symptoms reproduced** (Release app, scripted sweeps via a temporary `main.qml` Timer + `grabToImage`, 991x1051 @ DPR 2, globe on, both terrain styles; Glencoe, Alps, flat Netherlands, poles, antimeridian; zoom 1.5-14, pitch 0/45/70): on the globe the terrain geometry was spherical but **every tile showed the wrong imagery** (Europe/Greenland repeated, tiles cut by arcs), large white areas (tiles whose drape was empty), partly missing hillshade. Plain Liberty on the globe was fine.
- **Cause 1 (drape in the globe projection):** the per-tile drape targets are rendered with the globe variants of the layer shaders (their drawables are built for the globe), and `LayerTweaker::getProjectionData` / `PaintParameters::projectionDataForTile` returned the *globe* matrix and transition 1 even with the drape ortho override, so each drape tile was a globe-view picture, not the tile's flat imagery. GL JS renders render-to-texture tiles with `applyGlobeMatrix: false` (Mercator). **Fix (0050):** with `projMatrixOverride` set the main matrix is the fallback (Mercator) matrix and `projectionTransition = 0`, so the globe shader variants draw the flat tile.
- **Cause 2 (tiles across the antimeridian):** a drape target is keyed by canonical tile but rendered for world x of wrap 0, while source tiles of the other world copy (wrap +/-1, e.g. at lon 179 on the far side) carry wrapped matrices: their drape stayed empty (white half disc; Mercator terrain had the same latent problem). **Fix (0050):** the drape pass uses the wrap-0 tile matrix (GL JS renders the wrapped tile id).
- **Cause 3 (poles):** the 129x129 mesh stops at lat 85.05 deg, and its skirt hung down into the planet, a dark curtain/fan around the poles. GL JS `_buildSkirts(..., northPole, southPole)` puts the outer skirt row of the polar tiles at the pole sentinel Y, not lowered, so the tile is capped to the pole. **Fix (0051):** same in `buildTerrainMesh` (globe only, `NORTH_POLE_Y`/`SOUTH_POLE_Y`, `w = 0`); `projectTileFor3D`'s globe branch now maps pole vertices to the pole and hides them while the projection flattens (as `projectTile` does).
- **Not defects / unchanged:** near/far imagery colour break at z11 pitch 45-70 is the Esri mosaic changing with zoom (same in Mercator); terrain fog stays Mercator-only (as GL JS on the globe); no holes at z11 pitch 55 any more, drape after zoom jumps is there within 0.7 s (z3 -> z11 and z11 -> z1.5), Mercator<->globe toggling with terrain fine. GPU memory peak over all sweeps 554 MB GTT, 591 MB RSS (memguard).
- **GL JS comparison** (harness now has `globe=1`): GL JS example style (Mapterhorn DEM + OSM + hillshade) at z3/z8/z11, pitch 0/45/70: terrain, hillshade, curvature and drape match; one visible difference, the sky above the horizon at z11 pitch 70 is pale/white in the app and blue in GL JS (globe sky branch in the globe-to-Mercator transition, see next-steps).
- **main.qml interplay:** `selectMap`/`onStyleUrlChanged` used to switch the globe OFF for URLs containing `terrain-style.json` ("globe mesh still rough"); no longer true, so John agreed and the auto-switch was removed from `main.qml`.
- Files: `layer_tweaker.cpp`, `paint_parameters.cpp` (0050); `terrain_pass.cpp`, `shaders/vulkan/common.hpp` (0051).
- **Verification (Release libs, Debug libs rebuilt/installed; the Debug APP was not run: the Qt Creator MCP cannot switch to Debug):** core tests 1068 pass, only `StyleConversion.Projection`, `CustomDrawableLayer.Line/Fill` fail (known); render tests (176 groups, linux-vulkan) only `fill-extrusion-pattern/tile-buffer` fails and `text-font/{burmese,khmer,devanagari}` error (known baseline). Before/after sheets, GL JS comparisons and sequences: `~/dev/tmp/globe-terrain-0050/` (`sheet_sat_before0050.png` vs `sheet_sat.png`). Patches are on the local fork branch `maplibreearth-patches` (0050, 0051; not pushed) and in `maplibre-native-qt/patches/` (not committed).

## 2026-10-18 (part 10) - patch 0052: globe background wrong after Liberty <-> Positron toggles
- **Symptom:** on the globe, toggling Liberty and Positron left wrong colours (Positron land transparent, sea grey) until a pan/zoom. Reproduced with a temporary harness (globe, London z2, style toggled every 5 s, window grabbed every 500 ms): every Positron visit after the first was wrong; Liberty also differed (mean RGB 132.5 vs 164.8 once fixed).
- **Cause:** a style switch that keeps the layer id calls `RenderLayer::layerChanged`, which resets the layer tweaker. `RenderBackgroundLayer::update` created a new tweaker but kept the existing tile drawables, which still pointed at the old tweaker (only their own tweaker updates them; the fill layer already discards such drawables). A pan/zoom changed the tile cover, which rebuilt the drawables.
- **Fix:** `render_background_layer.cpp` now removes drawables whose tweaker is not the current one, so they are rebuilt with the new tweaker (patch `maplibre-native-0052-background-layer-tweaker-rebuild.patch`). Not a deviation from GL JS.
- **Verified:** with the harness, every Positron visit now has identical frames (mean RGB 185.2/188.0/197.2, same as the first visit) and every Liberty visit 164.8/177.7/207.4; one transient frame at each switch while tiles load.

## 2026-10-18 (part 11) - pointer gestures aligned with GL JS (patch 0053, main.qml)
- **Decisions (John):** GL JS button mapping (left pan, right / ctrl+left rotate + pitch, no right-drag zoom); gestures in QML/JS on thin C++ primitives; wheel vs trackpad from Qt's device data; max pitch stays 85; double-click zoom now, keyboard and box zoom later; **middle-drag keeps the smooth zoom** (drag up = zoom in); wheel notch calibrated to GL JS (242.6, 0.337 zoom levels per click).
- **Implemented:** pan with GL JS inertia constants, scroll zoom (rates, sigmoid, 200 ms easing), rotate/pitch (0.8 / -0.5 deg per px, north snap 7 deg), double-click zoom, once-per-frame pan application, terrain anchoring (`setLocationAtPoint` at the picked elevation, 0.9 camera guard), elevation hold during the drag and GL JS-style release (centre slides along the view ray). Details and the GL JS comparison: [gesture page](references/gesture-gljs-alignment.md).
- **Bug found by an automated render check:** the unprojections used a y that was not flipped, so features overshot the cursor more with pitch (flat Amsterdam pitch 30/60/77.5: 8% / 25% / 83%). Fixed; flat and terrain drags now stay within 0-4 px of the cursor (pitch 77.5 cliffs and pitch 70 Mont Blanc inconclusive: low match scores). The in-app self-test (grabToImage + Python correlation) is described on the gesture page; the code was temporary and is removed.
- **Not done:** keyboard and shift-drag box zoom; globe drawing still uses the old centre-offset pan/scale; pitch 77.5+ drags not numerically confirmed; wheel zoom, rotate/pitch and double-click not covered by the render check; Debug app built but John verified only Release so far.
- Files: `main.qml`; `maplibre-native-qt` `src/core/map.*`, `src/quick/plugins/map_quick_item.*`; patch `maplibre-native-0053-gljs-terrain-pointer-anchor.patch`.


## 2026-10-18 — Linux test coverage for terrain/camera/gesture core

- **Added:** patch `maplibre-native-0054-terrain-camera-tests.patch` (tests only): `test/map/terrain_camera.test.cpp` (22 tests for patch 0053 primitives), `TerrainTileCover.*` (9) and elevated-box `BoundingVolumes.*` (4).
- **Verified:** core suite 1106 tests, only the 3 known failures; render tests identical to the known list. Tolerances measured: `setLocationAtPoint` residue ~0.3 m at elevation; `putCenterOnTerrainKeepingCamera` camera drift up to ~6 m at pitch 75.
- **Gaps:** `getMinMaxElevation`, `terrainPointForPixel`/elevation-hold flow, globe paths, GL JS golden tile lists — see the session notes `linux-test-coverage-2026-10-18.md`.

### 2026-10-18 (later) — globe and gesture-logic tests

- **Added:** 4 `TerrainCameraGlobe.*` tests (patch 0054 regenerated) and `tests/gesture/` (`tst_gesture.qml`, `run.sh`): 35 QtQuickTest cases running the real `gest` object extracted from `main.qml` against a mock map (bezier, anchor-elevation guard, drag pan fallbacks, scroll zoom incl. 0.337 levels per notch, inertia). Run `tests/gesture/run.sh`.
- **Not covered:** the MouseArea/WheelHandler wiring outside `gest` (rotate/pitch, bearing snap, middle-drag, double click).

### 2026-10-18 (later) — upstream contribution readiness

- **Added:** [Linux tests](./verification/linux-tests.md) (suite results, fork tests, coverage gaps) and [Preparing to contribute upstream](./runbooks/upstream-contribution-plan.md) (maplibre-native / maplibre-native-qt rules and CI gates, what we meet, the plan). Linked from the verification and runbooks indexes and the overview.
- **Finding:** testing requirements are only partly met: Linux/Vulkan only; no OpenGL, Windows or Android runs; no pristine-upstream baseline.

### 2026-10-18 (later) — Linux OpenGL run

- **Result:** with OpenGL the fork fails 15 unit and 497 render tests where pristine upstream `c7506d6` passes all unit tests and fails 5 render tests. Likely cause: patches 0014/0030 changed shared symbol GLSL/UBO for Vulkan only. Recorded in [Linux tests](./verification/linux-tests.md) and the [contribution plan](./runbooks/upstream-contribution-plan.md); the earlier "known failures" list is corrected (two of them are ours).

### 2026-10-18 (later) - OpenGL regression fixed (patch 0055)

- **Fixed:** stale OpenGL symbol shader headers + missing `ProjectionUBO` binding for symbols, custom drawable fill/line tweakers without `ProjectionUBO`, stale `StyleConversion.Projection` expectation. Vulkan 1110/1110 and OpenGL 1145/1145 unit tests pass; OpenGL render failures equal pristine (5). Pristine Vulkan baseline: 1025/1025.
- **Corrected:** the earlier "known failures" (`StyleConversion.Projection`, `CustomDrawableLayer.Line/Fill`) were fork regressions, not upstream failures. See [Linux tests](./verification/linux-tests.md).

### 2026-10-18 (later) - post-0055 verification

- Qt library tree rebuilt, `test_mln_quick` passes. Render suites: Vulkan fork = pristine Vulkan (4 failing/erroring), OpenGL fork = pristine OpenGL (5). Core unit: Vulkan 1110, OpenGL 1145 all pass.

## 2026-10-19 - gesture follow-ups after the preset bug reports (patch 0056, main.qml, map_quick_item)
- **Right-drag / compass jumped back after a preset:** `map.coordinate` / `map.zoomLevel` hold what was last set through the item; `flyTo` stores the start of the flight and nothing refreshes them, so `applyCamera` re-sent a stale centre. Rotate/pitch and the compass now use `applyOrientation` (pitch and bearing only). `applyCamera` stays for the style-load restore (the style load resets the core camera, so it must use the stored values). New `MapQuickItem::liveCoordinate()` / `liveZoom()` return the map's own camera; used for saving state, presets, wheel zoom and the HUD (HUD bindings depend on the 400 ms tick). The properties themselves stay stored values (live getters broke the restore of the last position on restart: the style load had reset the core to 0,0).
- **Pan inertia** now capped at 0.75 of the pixels to the horizon (`handlePanInertia` in `mercator_camera_helper.ts`); at pitch 81-85 an uncapped inertia coasted kilometres.
- **Jump on release (patch 0056):** `Transform::putCenterOnTerrainKeepingCamera` used a fixed-point iteration that oscillates across ridges, leaving centre and zoom inconsistent so the picture moved (image difference 23 at the Glencoe preset). It now scans down the view ray from the camera for the first point whose ground is at its own height and bisects; the picture difference is 1.3 (noise). Unit tests `TerrainCamera.*` (26) pass.
- **Method:** unattended in-app runs (a temporary QML Timer drives the same code path as the mouse, `grabToImage` before/after, a numpy difference); reusable, see the [gesture page](references/gesture-gljs-alignment.md). All temporary code removed. John verified at the Glencoe and IOW presets.


### 2026-10-19 - full re-run with patch 0056

- Rebuilt the Vulkan and OpenGL test trees and the Qt library with 0056: unit tests Vulkan 1110/1110, OpenGL 1145/1145 (incl. the 26 `TerrainCamera.*`); Qt `test_mln_quick` passes; render failures Vulkan 4 and OpenGL 5, both identical to the pristine lists. No change from the post-0055 results.

## 2026-10-22/23 — macOS Metal verified, iOS builds, upstream WebGPU PRs reproduced

- **Metal (macOS):** the app and the vendored core build and run here. **Patch 0057** ports the per-tile `ProjectionUBO` to the Metal symbol shaders — symbols were blank/corrupt without it (**104/175 → 175/175** render groups); **0058** is test-only. Core render tests 175/175 groups, server suites 60/60. The `Map.*` hang is an upstream Metal deadlock, not the fork.
- **iOS:** Xcode's components had never been installed (`xcodebuild -runFirstLaunch` → 69), so `CoreSimulator.framework` was missing and every iOS CMake preset died in compiler detection; after the repair the `ios-*` presets build. QMapLibre builds for simulator and device (static libs + `MapLibre` QML module, `minos 17.0`); MapLibreEarth builds for both (device `minos 18.0`, **unsigned**) and **runs on the simulator** (Metal shaders compile, `import MapLibre` resolves). A device run is blocked three ways: no signing identity, no iPhone ever enumerated on USB (`xcrun xcdevice list` lists only the Mac, `ioreg` only dock infrastructure; note `system_profiler SPUSBDataType` returns empty output with rc 0 on this Mac, so it cannot be trusted), and an **iOS 18 floor** — an iPhone 6 (iOS 12.5.7) cannot run it.
- **Upstream PRs:** #4534's two WGSL bugs and #4190's three reproduced and fixed on macOS with both wgpu **and** Dawn; #4533 passes. `main`'s red `ios-build-webgpu-dawn` is Dawn's `TINT_BUILD_TESTS` defaulting ON — one-line fix, verified, and it does not change the Dawn libraries we link. #4534's iOS `<Mapbox.h>` import reproduced with bazel 8.6.0 and, once fixed, `//platform/ios/test:ios_test` passes **302 tests / 0 failures**. Portable patches: [local fix set](./references/local-fixes.md).

## 2026-10-23 — Linux re-verification after patches 0057/0058

- Pulled `maplibre-native-qt` to `df1d9f0` (patches 0057 Metal symbol `ProjectionUBO`, 0058 terrain-camera test pixel; Metal renderer backend change) and applied 0057/0058 to `vendor/maplibre-native` in order. Rebuilt `build-maplibre-native-qt-{Release,Debug}` + both installs, and the Vulkan/OpenGL core test trees.
- Re-ran everything: Vulkan unit **1110/1110**, OpenGL unit **1145/1145**, Vulkan and OpenGL expression **332 pass / 17 ignored / 0 fail**, Qt `ctest` pass in both configs, Vulkan render 175 groups (fail: `fill-extrusion-pattern/tile-buffer`; error: `text-font/{burmese,khmer,devanagari}`), OpenGL render 175 groups (the documented five). Identical to 2026-10-18/19 — Linux unaffected. See [Linux tests](./verification/linux-tests.md).
- Rebuilt the **Debug app** from the command line against the Debug install (`build/Desktop_Qt_6_11_2_Debug`) and ran it for 60 s: no QML/GL errors or assertions, `gljs-3d-terrain-example` style loads. `LD_LIBRARY_PATH=<Qt>/lib:<debug install>/lib`, `QML_IMPORT_PATH=<debug install>/qml`, `QT_QPA_PLATFORM=xcb`.

## 2026-10-23 — Linux WebGPU backends on the PR branches

- Built and tested #4534 `38dac5b8` and #4190 `c6b31b7` with **Dawn** and **wgpu** (local fix set applied, uncommitted). Unit: **1260/1260** and **1160/1160** on both backends — wgpu only in per-suite processes (single-process run aborts ~test 90, `radv/amdgpu: Not enough memory for command submission`). Render (184 groups): #4534 Dawn **1336/26/3/56**, #4534 wgpu **1334/28/3/56**, #4190 Dawn **1244/27/3/66**, #4190 wgpu **1243/28/3/66** (its `combinations` group aborted in one process and was re-run per test).
- Findings: `metrics/ignores/platform-linux-webgpu.json` is **missing upstream**, so both Linux WebGPU profiles exit 5 as committed (ran with an empty local file); `TINT_BUILD_TESTS` fix reproduced on Linux (`-- Tint build tests: ON` without it); 12-13 residual image diffs specific to Linux WebGPU (translucent composites, `fill-extrusion-base`, `within`), which pass on Vulkan here and on macOS WebGPU.
- Toolchain: Dawn from a googlesource archive over HTTP/1.1 (the GitHub `FetchContent` clone failed repeatedly), `-DMLN_WITH_GLFW=OFF -DDAWN_USE_GLFW=OFF -DDAWN_USE_X11=OFF`; wgpu-native with Rust 1.91.1 (pinned) and `BINDGEN_EXTRA_CLANG_ARGS` for bindgen.
- **#4533 control** (no WebGPU changes): unit **1258/1258** on both backends; render **1334/25/3/56** (Dawn) and **1331/28/3/56** (wgpu, after re-running the `combinations` and `projection` groups that aborted in-process). Its failure set is a strict subset of #4534's and the 14 residual diffs are identical, so they are **baseline Linux-WebGPU behaviour**, not caused by #4534/#4190. The `feature-state`/`global-state` extras are flaky (3 reruns each: e.g. #4534 `symbol-paint` 3,0,0; #4190 `composite-expression` 3,3,0). `checkerboard` **passes** on WebGPU where RADV Vulkan fails it.
- Evidence: `~/dev/tmp/upstream-report-evidence/webgpu/` (summaries + failing lists).
