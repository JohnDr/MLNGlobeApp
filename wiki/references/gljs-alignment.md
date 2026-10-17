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
| Terrain fog | `terrain.fragment.glsl`: `v_fog_depth` from the fog matrix (near = camera-to-sea-level), `calculateFogBlendOpacity(pitch)` | same maths: depth from the projection's `w` (`f(d-n)/((f-n)d)`), same blend/opacity, gamma 2.2 mix |

## Departs from GL JS

| # | Area | GL JS | Fork | Status |
|---|---|---|---|---|
| 1 | Mesh construction | one shared flat mesh, elevation sampled from the DEM texture in the vertex shader | per-tile mesh with CPU-baked elevation and CPU hillshade (rebuild when exaggeration changes) | departs – proposed (target: shared mesh + DEM texture sampling) |
| 2 | Hillshade | separate hillshade layer; terrain draw has no baked shading | baked shade in vertex `w`, applied in the terrain shader | departs – proposed |
| 3 | DEM tile zoom | source zoom derived from tile size / deltaZoom / source min,max; loaded-parent fallback | `clamp(floor(zoom)+2, 0, 14)`, no parent fallback for the mesh | departs – proposed |
| 4 | Cover centre zoom | `transform.zoom + scaleZoom(transform.tileSize / options.tileSize)` | `zoom + (demZoom - floor(zoom))` | unverified / departs – proposed |
| 5 | Extra DEM requests | none (uses source cache) | requests a z9 ancestor for every visited cover node so a range exists early | departs – proposed |
| 6 | Tile cap | none | 192-tile backstop in the terrain pass | departs – proposed (remove once LOD cover is proven bounded) |
| 7 | Horizon culling margin | `getElevationForTileCulling` adds up to 500 m near the horizon | not implemented | departs – proposed |
| 8 | Drape targets | RTT pool/cache, 1024 px for 256-px sources | one 512 px target per terrain tile, no pool | departs – proposed |
| 9 | Unrendered drape | no tint; terrain draws its texture | beige hypsometric tint where the drape alpha is 0 (fork feature, patch 0032) | departs – proposed (remove or agree) |
| 10 | Stale drape while reloading | previous RTT kept until the new one renders | cleared/re-rendered; navy/beige tiles for seconds after big zoom jumps | departs – proposed |
| 11 | Missing DEM tiles | **unverified** (believed: treated as flat) | flat sea-level mesh | unverified |
| 12 | Camera collision | `_raiseCameraByPitchAndZoom` family | `Transform::raiseCameraAboveTerrain` (modelled on it, not diffed) | unverified |
| 13 | Globe terrain | terrain on globe is supported | mesh/drape in globe incomplete; holes seen at ~z11 | departs – proposed |
| 14 | Sky / fog | zoom-interpolated expressions + transitions on all 7 sky properties; globe atmosphere (`atmosphere.fragment.glsl`) | constants only, no transitions; no globe sky/atmosphere (sky not drawn on the globe); fog only on the terrain surface, as in GL JS; far plane from the native `getProjMatrix` (GL JS uses its own `_calculateNearFarZ`) | departs – needs a decision (target: expression/transition support, atmosphere) |

## How to use this page

Before changing terrain/cover/camera/drape code: find the GL JS function, link it here, and if the change adds a row to "Departs", ask John first. When a row is resolved, move it to "Aligned" with the GL JS reference. Record decisions in [log](../log.md).
