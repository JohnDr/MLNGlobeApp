---
type: Status
title: Next steps
description: What to do next on MapLibreEarth and the MapLibre Native / Native Qt work, in order.
tags: [ status, project, handover ]
status: draft
---
## Summary

Ordered to-do list. Update it at the end of each session and record results in [Project history](./history.md) and the [wiki log](./log.md).

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
- [ ] Phase 6 — Vulkan depth-attachment offscreen texture + terrain depth pass / occlusion.
- [ ] Phase 7 — symbol / label elevation.
- [ ] Phase 8 — globe × terrain, fog/sky.
- [ ] App: add a terrain preset (Esri World Imagery + AWS terrarium `raster-dem`) to the Maps list.

## Related

- [History](./history.md) · [Wiki log](./log.md) · [Decisions](./decisions/index.md)
