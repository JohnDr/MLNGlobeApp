---
type: Reference
title: Mouse, wheel and trackpad gestures vs MapLibre GL JS
description: How the app's pointer gestures compare with GL JS, the agreed deviations, and the automated render check used to verify drag-pan.
tags: [ gestures, gl-js, alignment, terrain ]
status: current
---
## Scope

Gestures live in `main.qml` (object `gest`, `MouseArea mouseGestures`, `WheelHandler wheel`); the terrain primitives are in the fork patch **0053** (`Map::setLocationAtPoint`, `latLngForPixelAtElevation`, `terrainPointForPixel`, `setElevationHold`, `isGlobeRendering`) exposed through `MapQuickItem` (`setLocationAtPoint`, `coordinateAtElevation`, `terrainPointAt`, `setElevationHold`, `globeRendering`). GL JS sources read (main, 2026-10-18): `ui/handler_manager.ts`, `handler_inertia.ts`, `handler/{mouse,drag_handler,scroll_zoom,click_zoom,keyboard,box_zoom}.ts`, `handler/shim/*`, `ui/camera.ts` (`holdElevation`, `moveCenterOntoTerrain`, `captureRotationPivot`), `geo/projection/mercator_transform.ts` (`setLocationAtPoint`, `screenPointToLocationAtElevation`, `_raycastTerrain`).

## Comparison

| Gesture | GL JS | App | Status |
|---|---|---|---|
| Left drag | `MousePanHandler`: click tolerance 3 px; per frame `panDelta`, `around` = pointer; `setLocationAtPoint(preZoomAroundLoc, around, aroundElevation)`; anchor elevation = terrain point under the pointer at gesture start (`_terrainGestureElevation`, plane skipped when within 0.9 of the camera height); elevation held for the gesture; pointer not on the terrain: pixel pan about the centre | same: 3 px tolerance, one application per rendered frame (`flushPan`), `setLocationAtPoint` at the anchor elevation, 0.9 guard, hold, centre pixel pan when the start point is off the terrain | aligned, but the anchor pick is a DEM ray march, not a depth read (below) |
| Pan inertia | `HandlerInertia`: 160 ms buffer, 60 ms velocity window, linearity 0.3, maxSpeed 1400 px/s, deceleration 2500, bezier(0,0,0.3,1) | same constants and curve (`gest.startInertia`, `inertiaAnim`) | aligned |
| Wheel / trackpad zoom | `ScrollZoomHandler`: wheel rate 1/450, default 1/100, `maxScalePerFrame` 2, sigmoid, 200 ms smooth-out bezier for a wheel, none for a trackpad, zoom about the pointer, shift divides by 4; wheel vs trackpad by timing heuristic | same maths (`gest.wheelEvent` / `zoomFrame`); wheel vs trackpad from Qt (`pixelDelta` present = trackpad) | **agreed deviation** (device type from Qt) |
| Wheel notch size | browser `deltaY` per notch | `wheelNotchDelta = 242.6`, calibrated on John's GL JS (0.337 zoom levels per click; the first attempt with 100 gave 0.151) | **agreed**: calibration constant |
| Rotate / pitch | right drag or ctrl+left drag: bearing 0.8 deg/px (circular about the centre, `getAngleDelta` beyond 100 px), pitch -0.5 deg/px; bearing snaps to north within 7 deg at the end | same constants (`gest`); pitch clamped to 0..85 | aligned; max pitch 85 is John's earlier choice (GL JS default 60) |
| Double click | `ClickZoomHandler`: zoom +1 (shift: -1) over 300 ms, easing bezier(0.25,0.1,0.25,1), about the pointer | same (`dblZoom`) | aligned |
| Middle drag | none | continuous zoom `2^(-dy/250)` about the cursor, drag up = zoom in | **agreed deviation** (John: keep the smooth zoom of the earlier app, on the middle button) |
| Keyboard, shift-drag box zoom | present | not implemented | open (John: later) |
| Globe | globe controls | globe drawing still uses `map.pan` / `map.scale` (old centre-offset pan) | departs, unchanged; the terrain path applies when `globeRendering()` is false |

## Release of a terrain drag

GL JS `putCenterBackOnTerrain` re-solves the centre so the picture does not change. The fork's camera model differs (centre altitude follows the terrain under the centre; patch 0039 `raiseCameraAboveTerrain`), so during a drag `Map::setElevationHold(true)` stops that update and `updateTerrainCamera`, on release, calls `Transform::putCenterOnTerrainKeepingCamera`: the centre slides along the view ray onto the terrain with camera position and orientation unchanged, zoom re-solved. If the DEM is not available there, the old `setElevation` is used (a visible height step).

## Anchor pick (deviation, to confirm)

GL JS picks the terrain under the pointer from the rendered depth (`screenTerrainPointToMercatorCoordinate` / `_raycastTerrain`, which marches the ray against the DEM coverage index and bisects). The app marches the ray against the DEM through `TerrainTileManager::sampleElevation` (finest loaded tile, stepping down to coarser ones) in `TransformState::raycastTerrain`, 4 m steps, 24 bisections. Reason: no depth read-back in the Vulkan renderer. Replacement if ever wanted: read the terrain depth buffer.

## Bug found by the render check (2026-10-18)

The first terrain pan used the state-level unprojection with the pixel y not flipped (the `Transform` wrappers flip it; the state functions expect y up). Features overshot the cursor more the higher the pitch (flat Amsterdam, pitch 30/60/77.5: 8% / 25% / 83% of the drag). Fixed in `Map::{latLngForPixelAtElevation,terrainPointForPixel,setLocationAtPoint}`. The earlier symptoms (map moving further than the mouse, vertical movement, drift) all came from this.

## How it was verified (reusable)

Temporary in-app self-test (removed): a QML Timer set the camera, `grabToImage` saved before/after images, the same code path as the mouse dragged N pixels, and a Python script (numpy, normalised cross-correlation of a template at the start pixel) measured where the feature went. Pitch 0 flat: exact. After the fix, flat Amsterdam pitch 30/60/77.5 and cliffs/Alps pitch 60: 0-4 px error on 120-600 px drags. Pitch 77.5 cliffs and pitch 70 Mont Blanc matched with low scores (0.6-0.7; strong perspective change of the template) and are not confirmed numerically. A second check, `pixelForCoordinate(coordinateAtElevation(p))`, returned p exactly at pitch 30/60/77.5.
