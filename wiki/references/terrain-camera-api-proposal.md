---
type: Reference
title: Terrain camera/elevation API — proposal outline
description: Internal outline for the upstream terrain elevation query and GL JS camera helpers needed by the Qt wrapper and terrain gestures.
tags:
  - reference
  - upstream
  - terrain
  - camera
  - proposal
status: draft
---
# Terrain camera/elevation API — proposal outline

> Status: internal draft for review. Not posted to any upstream PR. Needed before the `atElevation` / `raycast` / `setLocationAtPoint` port can be a focused PR.

## Problem

The Qt wrapper and the GL JS-aligned gestures need the camera to know where the terrain is under a screen point, and to move the map so a given surface point stays under a pixel:

- `AtElevation(latLng, elevation)` → screen point
- `Raycast(screenPoint)` → `{latLng, elevation}` (the first terrain hit along the view ray)
- `SetLocationAtPoint(latLng, screenPoint, elevation)` → keeps the surface point under the pixel
- a terrain elevation query (`queryTerrainElevation` / `elevationAt`) to feed the above

GL JS has these as `Transform` camera operations (`screenPointToLocation`, `setLocationAtPoint`, terrain raycast). Our fork implements them in patches 0009/0053/0054; patch 0056 refined the centre clamp but is redundant with #4190's #4711.

## Upstream state (2026-10-23)

- #4190 provides terrain rendering (`RenderTerrain`, `style::Terrain`) and the centre anchor (#4711, `TerrainCamera` tests), but **no elevation query** (`queryTerrainElevation`, `elevationAt`, `terrainElevation` are absent).
- There is no `Map::setLocationAtPoint`, `TransformState::raycastTerrain`, or `atElevation` on the branch.
- Our camera code depends on the fork's `TerrainTileManager`/`TransformState`; it cannot be ported line-for-line.

## Minimal API to propose

1. **Terrain elevation query**
   - A map/renderer-safe call, e.g. `Map::queryTerrainElevation(const LatLng&) -> std::optional<double>`.
   - Back it with the DEM tiles already held by #4190's `RenderTerrain`/terrain cache; expose a read-only query rather than the fork's tile manager.
2. **Camera helpers** (in `Transform`/`TransformState`, following GL JS):
   - `screenPointToLocation(const ScreenCoordinate&) -> std::optional<LatLng>` at the terrain surface.
   - `atElevation(const LatLng&, double elevation) -> ScreenCoordinate`.
   - `setLocationAtPoint(const LatLng&, const ScreenCoordinate&, std::optional<double> elevation)`.
   - A ray-march/bisection helper (`raycastTerrain`) shared by the above.
3. **Tests**: port the useful 0054 cases (`AtElevation*`, `Raycast*`, `SetLocationAtPoint*`) and keep #4190's `TerrainCamera` anchor tests; add a case where terrain is absent (no-op/`nullopt`).

## Why not port 0053/0054 as-is

- No upstream elevation query to call.
- Different terrain/render architecture (`RenderTerrain` vs `TerrainTileManager`).
- #4711 already covers the centre-anchor behaviour; only the query + camera API is new.

## Next

Review this outline, then ask the #4190 author/maintainer whether they want the query + camera API as a follow-up PR against `feature/terrain-3d`, or as a separate proposal. Do not post the outline or open a PR without that go.
