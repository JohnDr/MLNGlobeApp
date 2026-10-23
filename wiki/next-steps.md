---
type: Status
title: Next steps
description: What to do next on MapLibreEarth and the MapLibre Native / Native Qt work, in order.
tags: [ status, project, handover ]
status: draft
---
## Summary

Ordered to-do list. Update it at the end of each session, **together with the [upstream contribution tracker](./runbooks/upstream-contribution-progress.md)** (the two must not contradict each other), and record results in [Project history](./history.md) and the [wiki log](./log.md).

## RESUME HERE — authoritative (2026-10-23)

**State:** patches **0001–0058** in `maplibre-native-qt/patches/` (fork branch `maplibreearth-patches` of
`johndr/maplibre-native`, one commit per patch, applied to the vendored core). Terrain, sky and the GL JS
alignment from 2026-10-18 still hold. Since that block was written:

- **0057 — Metal symbol shaders** (2026-10-22): ports the per-tile `ProjectionUBO` to the Metal symbol
  shaders. On macOS Metal, symbols rendered blank/corrupt without it — **104/175 render groups passed
  before, 175/175 after**. Metal-only, but part of the series and applied with the rest.
- **0058 — test-only** (2026-10-22): moves one `TerrainCamera` test pixel off a sea-level crossing.
- **macOS Metal verified**: core render tests **175/175 groups**, server suites **60/60**, app builds and
  runs with the per-config libraries — [macOS verification](./verification/macos.md),
  [build-macos runbook](./runbooks/build-macos.md).
- **iOS**: QMapLibre and MapLibreEarth build for simulator and device (arm64, `minos 18.0`; the device build
  is **unsigned**); simulator run verified, device run blocked (no signing identity, no iPhone on USB). Not a
  Linux concern — see [macOS verification](./verification/macos.md#ios-device-build--2026-10-23).
- **Upstream contribution testing** (#4533/#4534/#4190) is a *separate* effort with its own tracker
  ([progress](./runbooks/upstream-contribution-progress.md)) and a portable
  [local fix set](./references/local-fixes.md). Do not mix those patches with the fork series.

**On the Linux PC — done 2026-10-23:** the series is applied through **0058**, both library configs and
installs are rebuilt, and the suites were re-run: Vulkan **1110/1110**, OpenGL **1145/1145**, expression
**332/0**, Qt `ctest` pass in both configs, render failure lists identical to pristine (Vulkan 4,
OpenGL 5). Linux is unchanged, as expected — [Linux tests](./verification/linux-tests.md). Procedure
for next time: [Linux runbook](./runbooks/linux-terrain-test-and-debug.md).

**Decisions taken (do not re-litigate):** keep the 192-tile drape cap (no byte memory budget); keep drape
mipmaps; keep GL JS hillshade zoom dependence; accept the remaining ~5-15 % hillshade sharpness gap vs GL JS
(John, 2026-10-18); edge stitching from the coarser DEM is an agreed departure.

**First thing after a reboot:** open Qt Creator (`~/Qt/Tools/QtCreator/bin/qtcreator -client ~/dev/projects/maplibreearth/CMakeLists.txt`),
reconnect the MCP, check `git status` in the three repos, `/tmp` is wiped (use `~/dev/tmp`), restart the
harness server (`python3 tools/gljs-harness/serve.py`, port 8765) and `tools/memguard.sh` before stress
tests. Build/run policy: the **Qt Creator MCP requirement is Windows-only**; on Linux build/run the app from
the command line (Qt Creator itself is optional), libraries from the command line for **both** configs and
installs.

**Open / next**
1. **Debug app build** has not been rebuilt or run since the sky/drape work (build it from the command line on
   Linux); the Debug libraries are rebuilt and `test_mln_quick` passes only with `QSG_RENDER_LOOP=basic`
   (pre-existing threaded-loop assertion in `MapRenderer::updateRenderer`).
2. **Pointer gestures** (patch 0053 + `main.qml`, see [gesture page](./references/gesture-gljs-alignment.md)):
   open are keyboard handlers and shift-drag box zoom; globe-drawing pan/zoom still uses the old
   centre-offset code; wheel zoom, rotate/pitch and double-click are not yet numerically checked on terrain
   (the gesture page's render-check method can be reused).
3. **Globe terrain** (patches 0050/0051): open is the sky colour above the horizon at z11 pitch 70 on the
   globe (pale vs GL JS blue).
4. **Zoom 14.5 / pitch 81 comparisons** are by eye or against older captures; re-capture when touching
   terrain again.
5. Not exercised: location indicator and custom drawable layers with the new near/far planes; benchmarks have
   no pre-change baseline.
6. **Tests:** Linux Vulkan and OpenGL are green and equal to pristine upstream (2026-10-18). Still open:
   Windows 11 and Android runs, Qt location/widgets tests, WebGPU consumers of the changed shared shaders
   (tracked separately), render-test fixtures for terrain/sky/globe, the `getMinMaxElevation` test seam. Rule:
   shared-shader/UBO changes must pass OpenGL as well as Vulkan.
7. **Upstreaming:** the fork's own series stays on hold ([D6](./decisions/d6-draft-upstream-prs.md)); the
   #4533/#4534/#4190 testing work is tracked in [progress](./runbooks/upstream-contribution-progress.md).

## Earlier "RESUME HERE" (2026-10-18) — historical

**State:** terrain, sky and the GL JS comparison tooling are in place and aligned with GL JS (the reference; deviations need John's agreement, see [alignment audit](./references/gljs-alignment.md) and the standing rule in both `AGENTS.md`). Core patches **0001–0056** (0054 tests, 0055 OpenGL/custom-layer fix, 0056 centre-back-on-terrain ray scan; fork branch `maplibreearth-patches` of `johndr/maplibre-native`, one commit per patch; files in `maplibre-native-qt/patches/`). What exists now:
- 3D terrain with GL JS tile covers/DEM zoom (0040, 0045), per-target drape UBOs for all draped layer types (0043), hillshade coverage and no baked mesh shade (0044), RTT pool + GL JS fingerprint/one-stale-tile-per-frame/follow-up frames (0046), drape mipmaps/anisotropy, fog far plane, DEM backfill redraw (0047), LOD edge stitching (agreed departure), GL JS near/far planes, skirts, `roundZoom` for raster tiles (0048), DEM cell-centre (-0.5 px) sampling (0049).
- Sky (`sky` style object with expressions/transitions, globe atmosphere, terrain fog; 0041–0042), Qt/QML API `skyEnabled` + `sky`, toolbar Sky switch. With sky off the area above the horizon is the app's space colour.
- App: GL JS-format camera panel (bottom left, Copy button), performance panel (Load/Idle/FPS/Frame, top left), "3D Terrain (GL JS example)" style (`gljs-terrain-style.json`, Mapterhorn DEM, needs the Qt WebP plugin: `~/Qt/6.11.2/gcc_64/plugins/imageformats/libqwebp.so`, built from qtimageformats v6.11.2 in `~/dev/tmp/qtimageformats`), terrain exaggeration 1.0.
- **Reference harness:** `tools/gljs-harness/` (GL JS 6.14.0, same style, camera from the URL; match the app with `w`/`h` = logical size and `dpr` = system scale x app scale; see its README). Capture/compare method and numbers: [log 2026-10-18](./log.md).

**Decisions taken (do not re-litigate):** keep the 192-tile drape cap (no byte memory budget); keep drape mipmaps; keep GL JS hillshade zoom dependence; accept the remaining ~5-15 % hillshade sharpness gap vs GL JS (John, 2026-10-18); edge stitching from the coarser DEM is an agreed departure.

**First thing after a reboot:** open Qt Creator (`~/Qt/Tools/QtCreator/bin/qtcreator -client ~/dev/projects/maplibreearth/CMakeLists.txt`), reconnect the MCP, check `git status` in the three repos, `/tmp` is wiped (use `~/dev/tmp`), restart the harness server (`python3 tools/gljs-harness/serve.py`, port 8765) and `tools/memguard.sh` before stress tests. Build/run policy: the **Qt Creator MCP requirement is Windows-only**; on Linux build/run the app from the command line (Qt Creator itself is optional), libraries from the command line for **both** configs and installs.

**Open / next**
1. **Debug app build** has not been rebuilt or run since the sky/drape work (build it from the command line on Linux); the Debug libraries are rebuilt and `test_mln_quick` passes only with `QSG_RENDER_LOOP=basic` (pre-existing threaded-loop assertion in `MapRenderer::updateRenderer`).
2. **Pointer gestures** aligned with GL JS 2026-10-18 (patch 0053 + `main.qml`, see [gesture page](./references/gesture-gljs-alignment.md), log part 11). Open: keyboard handlers and shift-drag box zoom; globe-drawing pan/zoom still the old centre-offset code; wheel zoom, rotate/pitch and double-click not yet numerically checked on terrain (the render-check method on the gesture page can be reused); Debug app built but only Release verified by John.
2. **Globe terrain** fixed 2026-10-18 (patches 0050/0051, see log part 10). Open: sky colour above the horizon at z11 pitch 70 on the globe (pale vs GL JS blue); the `main.qml` auto-switch of the globe off for terrain styles was removed (John, 2026-10-18); Debug app not run.
3. **Zoom 14.5 / pitch 81 comparisons** are by eye or against older captures; re-capture when touching terrain again.
4. Not exercised: location indicator and custom drawable layers with the new near/far planes; benchmarks have no pre-change baseline.
5. **Tests (2026-10-18):** Linux Vulkan and OpenGL are green and equal to pristine upstream (unit 1110 / 1145; render lists identical; Qt `test_mln_quick` passes), gesture logic has `tests/gesture/run.sh`; results, tolerances and coverage gaps: [Linux tests](./verification/linux-tests.md). Still open: Windows 11 and Android runs, Qt location/widgets tests, Metal/WebGPU consumers of changed shared shaders, render-test fixtures for terrain/sky/globe, `getMinMaxElevation` test seam. Rule: shared-shader/UBO changes must pass OpenGL as well as Vulkan.
6. Upstreaming stays on hold ([D6](./decisions/d6-draft-upstream-prs.md)); the plan for when it starts (rules, CI gates, split into small PRs, test matrix) is [Preparing to contribute upstream](./runbooks/upstream-contribution-plan.md).

## Earlier "RESUME HERE" (2026-10-17, end of session) — historical

**State:** 3D terrain works on Linux/Vulkan at zoom 14–18, pitch 0–80, Release and Debug: imagery drapes to the horizon, panning at high pitch is correct, no GPU-memory runaway. Everything is in patch **0040** + Qt-wrapper commits (see [fork patches](./references/fork-patches.md), [log 2026-10-16/17](./log.md), [Linux runbook](./runbooks/linux-terrain-test-and-debug.md)). Older "RESUME HERE" sections below are **historical** (their "z15 draw fault" theory was wrong: the blue was the empty drape + double-scaled elevation + cover culling).

**First thing after a reboot:** open Qt Creator (`~/Qt/Tools/QtCreator/bin/qtcreator -client ~/dev/projects/maplibreearth/CMakeLists.txt`), reconnect the MCP, start `~/dev/projects/maplibreearth/tools/memguard.sh` in a terminal before any stress test, check `git status` in the three repos (`maplibreearth`, `maplibre-native-qt`, `maplibre-native`).

**Open / next, in priority order**
0. **Globe terrain:** low-zoom globe (~z11, pitch 55) showed purple holes with skirt curtains although all covered tiles had meshes (log 2026-10-17 evening); investigate, then re-run the flat/globe edge sweeps. Drape lag after big zoom jumps (navy/beige tiles for >15 s) — keep the old texture until the new one is ready.
1. **Compare far terrain with GL JS side by side** (user: far terrain flattened earlier than GL JS). Mesh is now 129x129 per tile (was 17x17); if still flatter, check vertical exaggeration, DEM zoom per LOD level (`demZoom = clamp(floor(zoom)+2, 0, 14)` vs GL JS `source zoom = terrain zoom - deltaZoom` with loaded-parent fallback) and hillshade.
2. **Drape quality:** RTT is 512 px per tile (GL JS 1024 for 256-px sources) -> near imagery soft at zoom 16–18; add an RTT pool/LRU before raising it. Beige tint for a few seconds after big zoom jumps = drape/raster loading (consider keeping the old texture until the new one is ready).
3. **LOD seams:** GL JS has no cracks between LOD levels; ours has no skirts — inspect tile boundaries at steep pitch.
4. **Remaining differences from GL JS:** per-tile RTT cache/pool, DEM neighbour border backfill for hillshade, `maxContentElevation`/horizon plane for covers, globe terrain (mesh still flat).
5. **Tests:** vendored `tile_cover`/`dem_data` tests pass but there are no tests for the elevation-aware cover, `Frustum` with elevated boxes, the terrain LOD cover or `TerrainTileManager::getMinMaxElevation` — add them (`vendor/maplibre-native/test/...` is part of the patch workflow). Three core tests fail for unrelated reasons (`StyleConversion.Projection`, `CustomDrawableLayer.Line/Fill`); render tests: `fill-extrusion-pattern/tile-buffer` fails, `text-font/{burmese,khmer,devanagari}` error — all pre-existing.
6. **Upstreaming** stays on hold ([D6](./decisions/d6-draft-upstream-prs.md)).

**Key facts to remember**
- World z is **metres** (camera matrix scales z by pixels-per-metre); `TransformState::z` is pixels; use `getCenterAltitude()` for metres.
- Terrain tile cover: DFS with per-node DEM min/max boxes, variable zoom via `calculateTileZoom`; a flat sea-level cover or one fixed zoom to the horizon is wrong (culling / 16,679 tiles -> kernel hang).
- The PC crash of 2026-10-17 was the app (amdgpu GEM allocation storm); always run stress tests under `memguard.sh`. `/tmp` is wiped on reboot.
- Build/run policy (Linux): the Qt Creator MCP requirement is Windows-only, so build/run the app from the command line here; library by command line, **both configs + both installs**; filter compile output by `error:`.

## Where things stand (2026-10-11)

- MapLibreEarth builds and runs on Windows (Release **and** Debug) and Android arm64-v8a; deployed to a Galaxy S23 (serial `RFCW910087W`).
- [`QMapLibre`](./concepts/maplibre-native-qt.md) is built from a fork of MapLibre Native Qt, with the MapLibre Native submodule at `android-v13.6.1` plus two [downstream patches](./references/fork-patches.md).
- Five upstream PRs are open as **Drafts** ([references/upstream-prs.md](./references/upstream-prs.md)); **hold** further upstream work until the project stabilises ([D6](./decisions/d6-draft-upstream-prs.md)).

## Open items

## Globe tile-edge seam — DONE (2026-10-12)

Resolved in patch **0017** (`8784f61`): the ~1px line at globe tile edges was the fill **antialias outline** tracing the artificial edge created where the `[0, EXTENT]` clip cut a crossing fill ring (both tiles stroked the shared meridian). Fixed by skipping outline segments that lie along the tile's vertical boundary. See the [globe log](./log.md) entry dated 2026-10-12 (later).

## Globe port — resume here

The globe **renders on Vulkan**: curved, covers the visible hemisphere, morphs back to flat past zoom ~11, and draws **fills, background, lines and rasters/hillshade/color-relief** (see [Globe projection](./concepts/globe-projection.md)). It is driven by **seventeen** downstream patches in `maplibre-native-qt/patches/` (`maplibre-native-0001`…`0017`), which reproduce the vendored tree (`0017` is the tile-edge/blank fix — see the [log](./log.md), 2026-10-12). **The whole design-proposal phase plan is now ported for Vulkan** — every layer family (fills, background, lines, rasters/hillshade/color-relief, circles/heatmaps, fill-extrusions, symbols), clip masks, subdivision, tile cover, gestures, the globe→Mercator morph, and the raster uncovered-parts fix.

**Remaining is verification, not porting:**

- [ ] Eyeball the globe at low zoom with a style exercising each family; confirm the rotating flicker is gone.
- [ ] Optional: upstream's feature-query paths (the TileProjector capture and the symbol label-plane capture) were skipped; they affect querying, not rendering.

See [Fork patches](./references/fork-patches.md) and the [globe log](./log.md).
- [ ] Decide whether to keep the `line-dasharray` data-expression part of the [style-spec patch](./references/fork-patches.md). It is non-conformant (the spec marks `line-dasharray` cross-faded / zoom-only) and is what forced the [assert-relaxation patch](./decisions/d3-downstream-patches.md).
- [ ] Take the draft PRs out of Draft and merge when stable; rebase #324–#326 after #323.
- [ ] Optional: raise the style-spec gaps upstream — [`icon-overlap`/`text-overlap`](./references/upstream-issues.md) (issue #251), data-driven `line-dasharray`, and the Open Waters `resampling` misuse.
- [ ] Optional: add a Qt Creator **Android** kit / CMake preset with `QMapLibre_DIR` so MapLibreEarth builds for Android from the IDE (currently command-line only — see [Android build](./runbooks/build-android.md)).
- [ ] Optional: provide a fork branch/tag that produces the exact `QMapLibre` install MapLibreEarth consumes (the fork `personal` branch does this today).

## 3D terrain — in progress (2026-10-12)

Aerial imagery draped over terrain (the GL JS render-to-texture approach), built on the fork's existing per-tile RTT framework (`RenderTarget`/`OffscreenTexture`, already used by hillshade/heatmap on Vulkan) rather than back-porting upstream's experimental `feature/terrain-3d` branch. Flat/Mercator first; full drape as the first milestone. See [Fork patches](./references/fork-patches.md).

- [x] **Phase 1 — style property + API** (patch **0019**, commit `e3e678b`): style-root `terrain {source, exaggeration}`, `Style`/`Map` API, Qt/QML `terrainSource` / `terrainExaggeration`. The renderer still draws flat.
- [x] **Phase 2 — camera elevation** (patch **0020**, commit `8473c72`): `TransformState`/`Transform` `getElevation`/`setElevation` (the centre altitude as the ground elevation under it, GL JS's `transform.elevation`) + `getCameraAltitude`. Inert until terrain drives it.
- [x] **Phase 3 — terrain tile manager + elevation provider** (patches **0021** `e24d058`, **0022** `bb3b9bc`): `DEMData::getElevation` bilinear sampler, and a **terrain-owned** `TerrainTileManager` (`renderer/terrain_tile_manager`) that fetches/decodes raster-dem tiles via the `FileSource`, caches `DEMData`, and exposes `getElevation(latLng, zoom)`. Unit tests for both. Not yet wired into the map.
- [x] **Phase 4 — terrain mesh + Vulkan terrain shader** (patches **0023**–**0026**): the terrain now renders as a shaded elevated surface. Fixes that got it visible: colour-write mode (0025), consolidated projection UBO + per-drawable `uboIndex` (0026), and the tile→clip matrix `projMatrix · matrixFor(tile)` (0026). shader, `TerrainPass`, wiring into `UpdateParameters`/`RenderOrchestrator`/`RendererImpl`, and the repaint-on-tile-load fix.
- [x] **Phase 5 — drape** (patches **0027**–**0028**): the map is draped onto the terrain as **per-tile render targets** (the current GL JS model — each terrain tile renders the draped layers into its own tile-sized texture via a per-tile orthographic projection), sampled at a tile-local UV. Renders seamlessly. Refinements left: cache/fingerprint the per-tile textures and skip non-draped (symbol) layers from the RTT.
- [x] **Phase 6 — occlusion**: folded into Phase 7 — no separate depth texture is needed (the terrain writes depth to the main buffer and symbols draw after it).
- [x] **Phase 7 — symbol elevation** (patch **0030**): `PaintParameters::terrainElevationFn` → `SymbolDrawableUBO.elevation` → `projectTileWithElevation` (was `0.0`). **Compile-verified only** (the sandbox can't load glyphs).
- [~] **Phase 8 — globe × terrain** (patch **0031**, `d6f6756`): the terrain renders draped on the globe, but the mesh is still the flat grid, so tiles show as overlapping petals with gaps. Needs the globe curvature / pole-capped tessellation. Fog/sky not started.
- [x] **App**: a "3D Terrain (satellite draped)" map is in the Maps list (`terrain-style.json` = Esri World Imagery + AWS terrarium `raster-dem` + a `terrain` root property). Selecting it switches to flat projection + tilts (app `58c5faf`); the toggle applies only to that style (`c535d31`); built-in maps are merged into a stored list (`7c2f281`); the entry shows (`733a374`).

### ⚠️ RESUME HERE — raster drape: the per-target projection matrix never reaches the raster draw (2026-10-13)

**Status:** reproduced and localised. The terrain relief renders; the satellite raster is absent, so the hypsometric fallback tint (patch **0032**) shows instead of imagery. **The drape math and the raster content are not the problem** — the per-target projection matrix never reaches the raster draw.

Evidence (all on-device, Vulkan, flat/Mercator at the Matterhorn, zoom 13):
- The raster source and tiles are fine: a flat (no-terrain) style with the same Esri source renders the Matterhorn perfectly.
- The offscreen path and the raster drawable are fine: forcing the raster fragment to a solid colour and bypassing its projection (writing `gl_Position` directly from tile coords) makes the drape show that colour — so the drawable is submitted, the target is rendered, and `applyDrapeTextures` binds it.
- The per-tile ortho is numerically **correct**: a z14 raster tile coincident with a z14 drape tile composes to `clip (-1,1)…(1,-1)` (it fills the target).
- The raster group **is** added to each target and its drawables pass `hasRenderPass(Translucent)` (`drawables=5 submitted=5`).
- Setting the offscreen clear colour to red turns the whole drape red — the terrain samples the target, but the raster writes **nothing** over it.
- With `projectTile(…projection UBO…)` → no raster; bypassing the matrix → raster. So **the matrix the shader reads is not the per-target ortho.**

**Leading cause:** the shared raster layer group is rendered once per terrain tile inside `renderTerrainDrapeTargets`, and its consolidated projection UBO is re-uploaded per tile **in the render phase**. On Vulkan the buffer update is windowed/versioned per frame (`BufferResource::update` / `updateVulkanBuffer`), so the per-tile updates do not take effect within one frame — every target is drawn with a stale/first matrix. A frame-stable override (the main `projMatrix`) *does* work, which is why the "main projection" control showed imagery. This also means the earlier "background-only drape works (grey)" may have been the target's clear colour, not a real draw.

**Not the assumed regression:** the drape capture code is byte-identical between patch **0029** and HEAD except the tile size (0033) and the ortho y-flip (0034), so a 0029→0031 bisect is unlikely to isolate it. Layer selection (`drapeLayerIndices`) also checks out — the raster group is included either way.

**Readback (2026-10-13):** dumping the projection UBO during the render phase showed the layer group is **transient** in `layerGroupsByLayerIndex` (added to each render target in `updateLayers`, then removed from the map by `processChanges`), so a naive map read-back is misleading for the draw phase — but the mechanism is otherwise confirmed: one command buffer + one single-window buffer per layer, with per-tile re-uploads collapsing to the last write.

**Fix (implemented 2026-10-13, `raster_layer_tweaker`):** each drape target now writes its projection (and drawable UBO) into its **own block** of the shared buffer, selected per draw via `uboIndex`.
- `PaintParameters::drapeTargetOrdinal` (set per tile in `renderTerrainDrapeTargets`, reset to `-1`); tweaker computes `base = ordinal × drawableCount`.
- New offset-aware `gfx::UniformBuffer::update(data, size, offset)` (+ `contents()`) with a Vulkan implementation; `LayerTweaker::uploadProjectionUBOs` takes a `baseElement`.
- `RasterLayerTweaker` sizes the projection/drawable buffers to `base + drawableCount` and offsets `setUBOIndex`.
- The tweaker path was verified on-device (`ordinal=0,1,2…`, `base=ordinal×count`, distinct per-tile matrices).

**Verification inconclusive:** in that session the Esri raster tiles — and even a flat raster style — failed to load, so the terrain still showed relief + fallback tint. Re-test with a warm tile cache / stable network.

**Revision (2026-10-13, later):** verified shader-side, the raster **does** render into the drape target (solid magenta with geometry bypassed) and the **per-target matrices are delivered** (colour-coded matrix differs per tile). With the real matrix the raster is off-target/black, and the user saw imagery **flicker in then turn green** — the drape populates then goes empty (green = fallback tint over a black drape). **Leading hypothesis now:** the drape target is created/rendered (and cached black by the fingerprint) while the raster layer group is absent from the transient `layerGroupsByLayerIndex` — a drape-selection/caching bug, likely independent of the projection math. Next: make the drape selection read the render layers' groups directly, or force a re-render when a draped group appears.

**Also:** apply the per-target block layout to the other draped tweakers (`background`/`fill`/`line`/`color-relief`/`hillshade`) once the selection bug is fixed — only `raster` is converted so far.
- [ ] Fog/sky at the terrain horizon (after the raster is fixed).

## RESUME HERE — 3D terrain drape (2026-10-14)

The section above (2026-10-13 "per-target projection matrix never reaches the raster draw") is **superseded** — that was a red herring (the raster does render into the target). Current state follows.

### Done and verified this session

1. **The original "no imagery" root cause (fixed, patch 0036 / fork `6037bd2`).** The per-tile drape ortho mapped the tile's `z = 0` to the **near plane**; `LayerTweaker::multiplyWithProjectionMatrix` then applies a per-drawable depth offset (`projMatrix[14] -= K`), pushing `z_clip < 0`, and **Vulkan clips `z < 0`** — so *every* drape draw was discarded (leaving the patch-0032 fallback tint). Fix: `matrix::ortho(ortho, tx, tx+s, ty+s, ty, -1.5, 0.5)` (tile `z` → `0.5`). Imagery now drapes over the relief — verified zoom 12/14.
2. **Orientation (fixed, patch 0037 / fork `4955ba4`).** The drape target stores north at `v = 0`, exactly what the terrain mesh's `v_uv` encodes, so the extra `1.0 - v_uv.y` in `terrain.hpp` was a spurious flip (rendered as a 180° rotation). Fix: `texture(drapeSampler, v_uv)`. Verified (world not mirrored, Alps upright, tilted CARTO watermark text reads correctly).
3. **App camera reset (fixed, MapLibreEarth `e367b01`).** `main.qml`'s `applyCamera()` ran `map.easeTo({pitch, bearing})` **without a zoom** on every style load; a style load resets the camera, so the map's transform was left at ~1.323 while the QML `map.zoomLevel` read 15 — and the raster source's tile cover collapsed to **z2**. Fix: include `center` + `zoom` in the `easeTo`. Verified: raster source zoom now `15.000`, raster cover **z16**. **The app QML is compiled in (`qt_add_qml_module`), so an app rebuild via Qt Creator is required for QML changes to take effect.**

### Open — drape empty at zoom >= 15

- Works at zoom <= 14; **empty (fallback tint) at zoom >= 15**.
- Raster cover is `DEM zoom + 2` at zoom 15 (raster z16 vs DEM z14); DEM zoom is hard-capped at `clamp(floor(zoom)+2, 0, 14)` (raising the cap to 15 made terrain *worse* — a corner sliver — so the cap stays 14).
- Instrumentation (`RenderTarget::render`, drape loop): each drape target is **256x256, 1 layer group (idx=1, raster, n=72), renders fully black**; the two transform states **agree** (zoom 15, scale 32768); the **covers overlap correctly** (DEM `14/8544/5827` => z16 x[34176..34179] y[23308..23311], inside the raster cover range 34174..34182 x 23303..23312).
- **Conclusion:** the overlapping z16 raster tiles are present and correctly selected but **not drawn** into the z14 target — the fault is in the raster drawable's *render inside the offscreen drape target at a 4x cover ratio* (2x works), not cover selection or projection composition.

### Next step (2026-10-15) - supersedes the block below

See the log entry "Session checkpoint - z15 drape/terrain still empty (2026-10-15)" for the full state. Ruled out this session: cover ratio (z14 with the draped cover forced to DEM+2 drapes fine), staleness (drape targets re-render with n=60 and stay empty), and any terrain-projection anomaly (the projMatrix is identical at z14/z15; the composed terrain matrix scales uniformly 2x).

Open contradiction: at z15 the CPU cover log shows terrain tiles that project on-screen, the pipeline culls nothing (cull None, depth Disabled, depth-clip on, render area full), yet the app shows only the background - and the main colour attachment has an undefined (checkerboard) region.

Next step (CPU first): in TerrainPass::update, log per terrain-cover tile the composed NDC of its centre and whether it passes the clip volume (-w <= x,y <= w, 0 <= z <= w), side-by-side z14 vs z15, to prove which tiles should rasterise before any further GPU work. Settled RenderDoc captures: C:/hda/dev/tmp/z14_settled.rdc and z15_settled.rdc.

Also: re-add the terrainDrapeZoom one-liner (lost in this session's revert).

### Next step (tomorrow) [superseded - kept for history]

Instrument the raster drawable's render inside one drape target at zoom 15:
1. Log the raster drawable's computed projection matrix / clip range for one target (is the quad off-clip?). Suspect: the `origin` translate in `LayerTweaker::getTileMatrix`, or `translateVtxMatrix` world-wrap handling when the raster tile z differs from the DEM tile z.
2. Or read back a target's pixels (e.g. via a debug blit) to confirm black vs imagery.
3. Check the **translucent pass + depth** handling in the offscreen target (raster is `DepthMaskType::ReadOnly`; the target may have no depth buffer) — compare with the working zoom<=14 path.
4. Check the attached layer-group set (only idx 1 was attached — no background group; is that expected?).

### Environment reminders

- Library builds: `%LOCALAPPDATA%\Temp\opencode\build-libs-both.bat` (prints `LIB_REFRESH_OK`); Release install `C:\hda\dev\tmp\install\maplibre-native-qt`, Debug `…\install-maplibre-native-qt-debug`. App build/run via the **Qt Creator MCP** (project must be open).
- App registry (camera/style): `HKCU:\Software\MapLibre\MapLibreEarth\map` (`styleUrl`, `coordinate` multi-sz, `zoomLevel`, `terrainEnabled`, `globe3D`). A style enables terrain only if `styleUrl` contains `terrain-style.json`.
- Test styles in the repo root: `terrain-style.json` (Esri), `osm-terrain-style.json` (OSM raster — **reliable, labelful**), `liberty-terrain.json`.
- Diagnostics must be written to a file (e.g. `C:\hda\dev\tmp\*.log`) — MapLibre's `Log::` sink is not connected in this app, so `Log::Warning`/`Error` output is dropped.

## Related

- [History](./history.md) · [Wiki log](./log.md) · [Decisions](./decisions/index.md)

## RenderDoc vertex-debugger — exact steps (next session)

Capture to use: `C:\Users\JohnD\OneDrive\Pictures\MapLibre.rdc` (a full drape frame, 20932 draws, 253 passes).

**Where we are:** the per-target projection fix is proven working — each raster draw pushes `ubo_index` 83, 84, … and the block it indexes holds a valid ortho (`m0=0.000244`, per-tile `m12/m13`); the raster quad is a real 4-vertex quad `(0,0)…(8192,8192)`; for the covering tile (drape `14/8536/5823` ← raster parent `10/533/363`) the composed matrix spans clip x[-17,15], y[-1,31] — it contains [-1,1]. Yet the drape target ends black. One GPU step left.

1. Open the capture in qrenderdoc.
2. **Fastest check** — Texture Viewer on the **first** render pass (a 256×256 drape target): is it **black** or imagery?
   - black → the raster draw isn't writing → step 3
   - imagery → the raster wrote; the fault is the terrain sampling the wrong texture → step 5
3. Select that pass's draw → **Pipeline State**:
   - **Viewport/Scissors**: viewport must be 256×256 and the **scissor** must cover it (a 0×0 / main-window scissor culls everything).
   - **Rasterizer**: cull mode (expect *No culling*).
   - **Depth/Stencil**: enabled? compare op?
   - **Mesh Output → VS Output**: read the 4 `gl_Position` values (expect ≈ `(-17,31)`, `(15,31)`, `(-17,-1)`, `(15,-1)`, `w=1`).
4. If `gl_Position` looks right but the target is black: right-click the draw → **Debug → Vertex Shader**, pick vertex 0, step to the end of `main()`, read `gl_Position`.
5. If step 2 said **imagery**: open the **main pass** (last render pass, to the swapchain), select the **terrain draw** → **Pipeline State → Read-only Resources** → the bound 256×256 `Texture2D` — does it match the drape target from step 2? If it's a different/black texture, `applyDrapeTextures` is binding the wrong tile.

**Report back:** step 2 (black/imagery); and from step 3 the 4 `gl_Position`, the viewport/scissor and the cull mode.

## RESUME HERE — 3D terrain drape (2026-10-15 checkpoint)

**Goal:** the terrain drape must work at every zoom. It works at zoom <= 14; at zoom >= 15 the map is empty (background only).

**Fixed and verified earlier:** patch **0036** (per-tile ortho `z` at the near plane -> Vulkan clip), **0037** (drape UV orientation), app camera reset (`e367b01`), and (this session) patch **0038** (drape RTT size = GL JS's `terrainTileSize x qualityFactor` family; ours 512, documented).

**RULED OUT (each with direct evidence):**
- **Drape matrix** — our per-tile ortho is algebraically identical to GL JS's tile-space `ortho(0,EXTENT,EXTENT,0,0,1)` expressed in world coords (P1); only z differs, deliberately, for Vulkan.
- **Drape RTT size** — 256 -> 512, no change (P1).
- **Terrain/DEM tile zoom** — `clamp(floor(zoom)+2,0,14)` vs GL JS `floor(zoom)`; tested `floor(zoom)`, no change (P2).
- **Elevation** — flat terrain (`exaggeration 0`) is still invisible at z15 (P3 pre-check).
- **Cover / placement** — a per-frame cover diagnostic at z15 shows the cover is **correct**: 6 tiles, all with DEM data and a terrain drawable (n=1), tile centres **on-screen** (one dead-centre NDC (-0.28,-0.08)). So the planned `coveringTiles` port is unnecessary for this bug.

**DECISIVE FINDING:** at z15 the cover, tile placement, and meshes are all correct — the fault is entirely in the **terrain DRAW**: valid, on-screen geometry with drawables renders **no pixels**, and it does so even when flat. The shader is therefore **not reading the matrix the CPU composes** (RenderDoc mesh output showed the shader's `gl_Position` off-screen while the same CPU-composed matrix is on-screen).

**NEXT STEP:** instrument the **terrain projection UBO**. In `TerrainPass::update`'s UBO loop log the `pd.mainMatrix` actually pushed **and** the drawable's `uboIndex` (and its depth mode), for a terrain drawable at z14 vs z15, and diff against the CPU-composed `projMatrix * matrixFor(tileID)`. If the pushed/read matrix differs (or the UBO array / `uboIndex` is stale or not consolidated), that is the bug — the projection-UBO consolidation path (patch 0026 territory).

**GL JS reference (checked this session, per John's directive):** the reference model and the full algorithm/maths audit are in [the log](./log.md) under "GL JS reference model (P0)" and "Algorithm/maths audit vs MapLibre GL JS". Verified-equivalent: drape matrix, per-tile projection (`projMatrix ∘ matrixFor` ~ GL JS `mainMatrix`), raster tile zoom, drape UV. Still divergent but *not* the z15 cause: terrain tile zoom, elevation scale, mesh structure (17^2 baked vs 128^2 `[0,EXTENT]` z=0), drape RTT size, hillshade.

**Tooling:** RenderDoc capture needs the app launched under RenderDoc (`renderdoccmd capture`) **and** the in-app API (`-DENABLE_RENDERDOC_FRAME_CAPTURE` + a trigger); the app renders on demand, so a forced-repaint (a temporary QML Timer nudging `map.pan`) is needed for a settled frame. `qrenderdoc --python` runs the script before the capture loads and `pyrenderdoc.LoadCapture(...)` blocks — analyse in the GUI. Diagnostics must go to files (MapLibre's `Log::` sink is dropped). Kept captures: `C:\hda\dev\tmp\z14_settled.rdc`, `z15_settled.rdc`.

**Environment:** library builds via `%LOCALAPPDATA%\Temp\opencode\build-libs-both.bat` (prints `LIB_REFRESH_OK`); Release install `C:\hda\dev\tmp\install\maplibre-native-qt`, Debug `...\install-maplibre-native-qt-debug`; app build/run via the **Qt Creator MCP** (project must be open; `qt-creator_debug` launches non-blocking, `qt-creator_stop_debug` stops). Registry `HKCU:\Software\MapLibre\MapLibreEarth\map`. Test styles: `osm-terrain-style.json` (OSM, labelful — the reliable one), `terrain-style.json` (Esri).

**Tree state:** library worktree = patches 0001..0038 (all diagnostics removed); app `main.qml` at the committed state (no Timer); both installs + the app rebuilt clean.


## RESUME HERE — 3D terrain (2026-10-16): z>=15 drape/terrain FIXED

Patch **0040** fixes the z>=15 blue/empty-drape bug (see [log](./log.md) 2026-10-16): mesh z in metres (was double-scaled by pixels-per-metre), elevation-aware tile covers (per-tile DEM min/max, GL JS `coveringTiles`), frustum z in metres, elevation-aware `Frustum::intersects`. Verified z14–18 at pitch 0/50 in Release and Debug. Remaining: Debug-only assertion at app exit (`VulkanRendererBackend` teardown), run/refresh the vendored tile_cover/dem_data unit tests, then the DEM-zoom (`floor(zoom)`) + mesh-structure divergences if wanted.
