---
type: Verification
title: Linux tests (core, render, expression, Qt, gestures)
description: What the Linux test suites cover and their results as of 2026-10-18, with the commands and the known failures.
tags: [ verification, linux, tests, vulkan ]
status: current
---
## Summary

Linux (Ubuntu 26.04, Vulkan) is the only platform where the test suites have been run so far. All figures are from 2026-10-18/19 on the patched vendored core (upstream `c7506d6` + patches 0001-0056; re-run after 0056 on 2026-10-19 with identical results).

| Suite | Result |
|-------|--------|
| Core `mbgl-test-runner` (Vulkan) | 1110 tests, **all pass** after patch 0055 (before it: `StyleConversion.Projection`, `CustomDrawableLayer.Line/Fill` failed - these were regressions of the fork, not upstream failures; pristine Vulkan passes 1025/1025) |
| Core `mbgl-test-runner` (OpenGL) | 1145 tests, all pass after patch 0055 |
| Render tests, Vulkan (per group) | after 0055: the same 4 as pristine Vulkan (`fill-extrusion-pattern/tile-buffer` fails; `text-font/{burmese,khmer,devanagari}` error) |
| Expression tests `mbgl-expression-test` | 332 pass, 17 ignored, 0 fail |
| Qt `ctest` (`test_mln_quick`, Release, Vulkan, rebuilt with patch 0055) | pass, needs `QT_QPA_PLATFORM=xcb`; `offscreen` aborts |
| Gesture logic `tests/gesture/run.sh` | 35 QtQuickTest cases pass |

Baselines: pristine upstream `c7506d6` was built for OpenGL and Vulkan (reverse-applied patches in `~/dev/tmp/maplibre-native-pristine`). Pristine Vulkan: 1025 unit tests pass, 0 fail. Run the suites **one at a time**: the unit tests use a fixed HTTP test server port (3000), so two runners at once hang.

## Tests added for the fork (patch 0054, tests only)

- `test/map/terrain_camera.test.cpp` (26): `screenCoordinateToLatLngAtElevation` (round trips, y-up pixel convention, horizon), `raycastTerrain` (flat, slope, cliff, miss, camera inside, unknown), `Map::setLocationAtPoint` (grab stays, antimeridian), `putCenterOnTerrainKeepingCamera`, and globe fallbacks.
- `test/util/tile_cover.test.cpp` (`TerrainTileCover.*`, 9): terrain LOD, per-tile elevation range, round zoom.
- `test/util/bounding_volumes.test.cpp` (4): frustum with boxes spanning an elevation range.
- `tests/gesture/tst_gesture.qml`: runs the real `gest` object cut from `main.qml` against a mock map (easing, anchor-elevation guard, drag pan, scroll zoom incl. 0.337 levels per notch, inertia).

Measured tolerances: `setLocationAtPoint` leaves a 0.1-0.3 m residue above 0 m elevation (single pass, as GL JS); `putCenterOnTerrainKeepingCamera` drifts the camera up to ~6 m at pitch 75. Note: Transform's default max pitch is 60 degrees; tests need `setMaxPitch(85)`.

## Run

```bash
export PATH=$HOME/Qt/Tools/Ninja:$PATH
ninja -C ~/dev/tmp/build-maplibre-native-core-tests mbgl-test-runner mbgl-expression-test mbgl-render-test-runner
cd vendor/maplibre-native && ~/dev/tmp/build-maplibre-native-core-tests/mbgl-test-runner     # run from the source dir
tests/gesture/run.sh                                                                          # in the app repo
```

Render tests per group (a single process aborts on thread-local keys): `mbgl-render-test-runner -p metrics/linux-vulkan.json -f render-tests/<group>/`.

## Linux OpenGL (2026-10-18)

Same flags as the Vulkan tree but `MLN_WITH_OPENGL=ON` (tree `~/dev/tmp/build-maplibre-native-core-tests-opengl`; needs `libgles-dev`); GPU AMD Radeon 780M (radeonsi), real display, `metrics/linux-opengl.json`.

| | Pristine `c7506d6` | Fork before 0055 | Fork with 0055 |
|---|---|---|---|
| Unit tests | 1060 pass | 15 fail | 1145 pass |
| Render tests failing/erroring | 5 (`text-font/{burmese,khmer,devanagari}`, `fill-extrusion-pattern/tile-buffer`, `icon-text-fit/textFit-grid-long`) | 497 | the same 5 |
| Expression tests | - | 332 pass, 0 fail | - |

**What was wrong (fixed by patch 0055):**
1. Patches 0014/0030 changed the shared symbol GLSL (`shaders/symbol_*.vertex.glsl`, `SymbolDrawableUBO`, `projectTileWithElevation`) for Vulkan, but the checked-in OpenGL shader headers `include/mln/shaders/gl/*.hpp` (generated from `shaders/` by `shaders/generate_shader_code.mjs`) were not regenerated, and the OpenGL symbol shader infos did not map `ProjectionUBO`. Every symbol/text/icon test drew nothing.
2. The custom drawable layer's fill and line tweakers did not upload the `ProjectionUBO` the shaders project through (fails on Vulkan and, for fill, OpenGL).
3. `StyleConversion.Projection` expected the pre-hand-off `globe` evaluation.

**Pitfall:** running `node shaders/generate_shader_code.mjs` rewrites `include/mln/shaders/shader_source.hpp`, `src/mln/shaders/shader_source.cpp` and `shader_manifest.hpp`, dropping the hand-added Sky/Atmosphere/Terrain entries (it also ignores `-o` and writes into the tree). After generating, restore those three files and keep only the changed GL headers. Rule going forward: any change to shared `shaders/*.glsl` or a shared UBO struct must regenerate the GL headers and be run on OpenGL (and Vulkan) before the patch is accepted.

Raw lists: session notes folder (`opengl-*.txt`).

## Coverage gaps

1. `TerrainTileManager::getMinMaxElevation`, `sampleElevation` fallbacks, `isMissing`: the `tiles` map is private; needs a test seam.
2. `Map::terrainPointForPixel` and the elevation-hold flow: need a loaded raster-dem source.
3. No GL JS golden tile lists for the terrain LOD cover.
4. No render-test fixtures for terrain, sky or globe (render tests only cover the existing styles).
5. QML wiring outside `gest` (rotate/pitch, bearing snap, middle-drag, double click) and `setLocationAtPoint` on a globe.
6. Pitch above 85.5 guard; centre-zoom clamping.

## Upstream contribution readiness

See [Preparing to contribute upstream](../runbooks/upstream-contribution-plan.md) for the requirements and the plan. Short answer: Linux is now green on both renderers (Vulkan and OpenGL unit tests pass; OpenGL render tests match pristine). Still open: Windows, Android, Qt `ctest` on OpenGL, location/widgets tests.

## Related

- [Windows](./windows.md) · [Android](./android.md) · [Upstream PRs](../references/upstream-prs.md) · [GL JS alignment](../references/gljs-alignment.md)
