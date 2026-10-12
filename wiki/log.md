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
