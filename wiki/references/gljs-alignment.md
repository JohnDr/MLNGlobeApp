---
type: Reference
title: MapLibre GL JS alignment audit
description: What the fork's terrain/cover/camera/drape work matches in MapLibre GL JS and where it departs; every departure needs John's agreement.
tags: [ terrain, gl-js, alignment, audit ]
status: current
---
## Rule

GL JS is the reference ([AGENTS.md](../../AGENTS.md), "GL JS alignment rule"). Deviations must be justified and **agreed with John before implementation**. Status values: **aligned**, **departs – proposed** (needs a decision), **departs – agreed** (John agreed; reason recorded), **unverified** (not compared against the GL JS source).
Audit date: 2026-10-17. Nothing below is marked *agreed* yet — John has not reviewed it.

## Aligned (checked against GL JS source: `terrain.ts`, `covering_tiles.ts`, `terrain_tile_manager.ts`, `frustum.ts`, `mercator_covering_tiles_details_provider.ts`)

| Area | GL JS | Fork |
|---|---|---|
| Elevation units | world z in metres; camera matrix scales z by pixels-per-metre | same (`Camera::getWorldToCamera`); mesh, symbols, pan plane, boxes, frustum all metres |
| Tile bounding volumes | per-tile box from `Terrain#getMinMaxElevation` (DEM tile, else loaded ancestor) | `TerrainTileManager::getMinMaxElevation` via `TransformState::setTileElevationRange`; unknown -> `[min(0,e), max(0,e)]`, e = centre elevation |
| Frustum | `unprojectClipSpacePoint`: z stays in metres; `Aabb.intersectsFrustum` 8 corners | `Frustum::fromInvProjMatrix` z in metres; 8-corner `intersects/intersectsPrecise` |
| Variable zoom with terrain | `allowVariableZoom` true with terrain; `createCalculateTileZoomFunction(9.314, 3.0)` | `TileCoverParameters::terrainVariableZoom` + the fork's `calculateTileZoom` (terrain cover and every source cover) |
| Mesh size | 128x128 per terrain tile | 128x128 segments |
| Skirts | frame around each mesh, length tile width / 5 | skirt vertices lowered by tile width / 5 |
| DEM border | `backfillBorder` from neighbours | `DEMData::backfillBorder` from 8 neighbours; meshes rebuilt on change |
| Pan / unprojection | elevation-aware at the centre | unprojects onto the plane at the centre altitude (metres) |
| Terrain LOD centre | `centerCoord = worldFromLngLat(center, elevation)` | `TileCoordinate::fromLatLng` of the map centre (fixed 2026-10-17; was the sea-level screen-centre ray hit) |
| Sky | `sky.ts`, `sky.fragment.glsl`, `draw_sky.ts` (drawn first; horizon line in screen space) | `style::Sky`, `SkyPass`, `SkyShader` (Mercator branch of the same gradient, same `getMercatorHorizon`) |
| Sky properties | all 7 properties: zoom expressions + `-transition` (`sky.ts`, `sky_properties.g.ts`) | `style::Sky` on the `Properties`/`Transitionable` machinery (as `Light`); `RenderSky` evaluates per frame; tests `StyleConversion.Sky*` |
| Globe sky + atmosphere | `sky.fragment.glsl` globe branch, `atmosphere.fragment.glsl`, `getGlobeCenterInViewSpace`, `getAtmosphereAltitudeBlend`, `getSunPos` (light) | same shaders and maths: `SkyShader` (limb blend), `AtmosphereShader`, `SkyPass` computes the globe's view-space centre from the globe view-projection |
| Sky API | `map.setSky(sky?)` / `getSky` | `QMapLibre::Map::setSky(QVariantMap)` / `clearSky`; QML `MapLibre { skyEnabled; sky }` |
| Terrain fog | `terrain.fragment.glsl`: `v_fog_depth` from the fog matrix (near = camera-to-sea-level), `calculateFogBlendOpacity(pitch)` | same maths: depth from the projection's `w` (`f(d-n)/((f-n)d)`), same blend/opacity, gamma 2.2 mix |

## Departs from GL JS

| # | Area | GL JS | Fork | Status |
|---|---|---|---|---|
| 1 | Mesh construction | one shared flat mesh, elevation sampled from the DEM texture in the vertex shader | per-tile mesh with CPU-baked elevation (rebuild when exaggeration changes; the CPU hillshade went in patch 0044) | departs – proposed (target: shared mesh + DEM texture sampling) |
| 2 | Hillshade | separate hillshade layer; terrain draw has no baked shading | baked shade removed by patch 0044 (mesh is xyz, shader draws the drape texture directly) | **fixed** 2026-10-18 |
| 3 | DEM tile zoom | terrain tiles = `coveringTiles` with tileSize = source.tileSize*2, DEM source tile = terrain z - deltaZoom(1), parent fallback, mesh samples a sub-rectangle | same (`TerrainTileManager::terrainZoomFor`, `sourceTileFor`, `getSourceTile`; mesh samples the DEM quadrant) | **fixed** by patch 0045 |
| 4 | Cover centre zoom | `transform.zoom + scaleZoom(transform.tileSize / options.tileSize)` | `zoom + (nominalZ - floor(zoom))`, identical for power-of-two tile sizes since nominalZ = floor of the GL JS value | **aligned** (patch 0045) |
| 5 | Extra DEM requests | none (uses source cache) | requests a z9 ancestor for every visited cover node so a range exists early | departs – proposed |
| 6 | Tile cap | none; the count is bounded by the LOD cover only | 192-tile backstop in the terrain pass kept: measured cover maximum 17 tiles over pitch 0-85, zoom 10-17 (12-15 at pitch 70-85), but boundedness is not proven; each tile now holds a 16.8 MB drape target | departs - proposed (remove once the LOD cover is shown bounded) |
| 7 | Horizon culling margin | `getElevationForTileCulling` adds up to 500 m near the horizon | not implemented | departs – proposed |
| 8 | Drape targets | RTT recycle pool (`painter._rttObjectRecyclePool`), released when a tile leaves the cover or changes, pool cleared at rest (`clearRTTPool`); rttSize = terrain tile size * 2 (2048 px for the 512-px DEM) | same (patches 0045/0046): pool in `RenderOrchestrator`, size as GL JS, pool emptied when the camera is at rest; no shared depth attachment (our drape targets have none) | **aligned** |
| 9 | Unrendered drape | no tint; terrain draws its texture | removed (patch 0045): the terrain shader draws the drape texture as is, like `terrain.fragment.glsl` | **fixed** |
| 10 | Drape refresh | `RTTFingerprint` (source tile ids + revision + zoom + visible layers); `zoom` kept while moving, one stale tile per frame, `needsFollowUpFrame` | same classes none/zoom/sourceTiles/visibleLayers/revision with the same policy (patch 0046); follow-up frame via `observer->onInvalidate()`. A source tile's revision is our `onTileChanged` count, which also fires on layer-property re-evaluation (e.g. a zoom expression on the drape layer re-prepares its tiles), so those refresh as `revision` (immediately) | **aligned** (revision source differs) |
| 11 | Missing DEM tiles | **unverified** (believed: treated as flat) | flat sea-level mesh | unverified |
| 12 | Camera collision | `_raiseCameraByPitchAndZoom` family | `Transform::raiseCameraAboveTerrain` (modelled on it, not diffed) | unverified |
| 13 | Globe terrain | terrain on globe: flat mercator RTT (`applyGlobeMatrix: false`), wrapped tile ids, pole geometry in `_buildSkirts` | same since patches 0050 (flat Mercator drape, wrap-0 matrices) and 0051 (pole caps); the old holes at ~z11 were the drape bug | **fixed** 2026-10-18 |
| 15 | Draped layers other than raster | every draped layer renders per RTT tile with its own matrix | only the raster tweaker keeps per-drape-target UBO blocks; hillshade/fill/line/color-relief reuse one projection for all drape targets (hillshade shows as a repeated picture or is missing) | **fixed** by patch 0043 (hillshade, color-relief, fill, line, background; circle/symbol/heatmap/fill-extrusion tweakers not draped, untouched) - see log 2026-10-18 |
| 14 | Sky / fog / projection planes | fog matrix near = camera-to-sea-level distance, far = `_calculateNearFarZ`; the same far plane (and `nearZ = height / 50`) is the projection's | **aligned** (patches 0047/0048): `getFogDepthRange` ports `_calculateNearFarZ`, and with terrain `getProjMatrix` uses its far plane and `nearZ = height / 50` (the nearClipped matrix keeps its own near). Globe untouched | **fixed** |

## How to use this page

Before changing terrain/cover/camera/drape code: find the GL JS function, link it here, and if the change adds a row to "Departs", ask John first. When a row is resolved, move it to "Aligned" with the GL JS reference. Record decisions in [log](../log.md).


## Agreed deviations from GL JS

| Area | GL JS | Fork | Agreed |
|---|---|---|---|
| LOD edge stitching (patch 0048) | skirts only: tiles of different zoom sample different DEM zooms and a crack is hidden by the skirt | the finer tile's edge vertices take their heights from the coarser neighbour's mesh edge (its DEM sampled at its 129 vertices, linearly interpolated), per side, with corners from the north/south edges; the mesh is rebuilt when a neighbour or its DEM changes. The skirts stay | John, 2026-10-18: "stitch the tile edges from the coarser DEM" and "Keep them [skirts] because GL JS has them" |

## Decided: keep as GL JS (2026-10-18)

- Mipmaps/anisotropy on the drape targets (row 8): kept.
- Hillshade strength depends on the hillshade tile's zoom (`exaggeration` in `hillshade_prepare`), so a step appears where hillshade tile zooms change across a drape tile boundary: kept as GL JS ("keep GL JS's zoom dependence").
- Skirt length now GL JS's: `metersPerWorldUnit(0.5, 0.5) / 2^zoom / 5` at the **map zoom**, equator-based, applied in the vertex shader (`u_ele_delta`); the mesh carries a skirt flag in `w`.
- Tile-zoom function per source (patch 0048): `roundZoom` (GL JS: true for raster and raster-dem sources, false for terrain tiles) now rounds each tile's zoom in the terrain LOD cover, and the centre zoom is `zoom + log2(512 / tileSize)` (`TileCoverParameters::roundZoom`, `centerZoomShift`); with terrain the raster-dem nominal zoom is rounded as well.
- DEM sampling convention (patch 0049): DEM pixel i is at tile fraction (i + 0.5) / dim, as GL JS (`DEM_CELL_CENTER_OFFSET`, `uv * dim + 1.5`): **aligned**. Centre elevation at Glencoe now 739.85 m (GL JS 739.91).

- 2026-10-18: sharpness gap at c81 (about 5-15%, mostly hillshade layer, far band for raster) investigated: not caused by drape mipmaps/anisotropy (measured); no confirmed GL JS divergence found; cause open.
