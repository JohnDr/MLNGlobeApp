---
type: Verification
title: macOS tests (Metal: core, render, expression, Qt, gestures)
description: What the macOS/Metal test suites cover and their results as of 2026-10-22, with the commands, the upstream gaps and the known fork failure.
tags: [ verification, macos, metal, tests ]
status: current
---
## Summary

macOS 27.0.1, Xcode 27.1, Qt 6.12.0, arm64 (`-DCMAKE_OSX_ARCHITECTURES=arm64`), **Metal** backend and
the patched vendored core (upstream `c7506d6` + patches 0001–0058). Build paths are in
[Build (macOS)](../runbooks/build-macos.md).

| Suite | Result |
|-------|--------|
| Library + `ctest` (Quick, Location, Widgets) | **3/3 pass** |
| Core render tests (Metal, per group) | **175/175 groups pass** (`metrics/macos-xcode11-release-style.json`) |
| Expression tests `mbgl-expression-test` | **332 pass, 18 ignored, 0 fail** |
| Core `mbgl-test-runner`, everything except `Map.*` and the server suites | **991 pass, 0 fail** (991 tests / 130 suites; patch 0058 fixed the last test) |
| Core `mbgl-test-runner`, `Map.*` | **cannot complete** — 34 pass, then an upstream Metal deadlock (see below) |
| Core `mbgl-test-runner`, server suites (60 tests) | **cannot run** — upstream does not build the test HTTP server on macOS Metal |
| Gesture logic `tests/gesture/run.sh` | **35/35** QtQuickTest cases pass |

Baseline: pristine `c7506d6` on the same Metal build passes `icon-size` 11/11; the fork before patch
0057 failed all 11 (blank frames), which pinned the symbol breakage on the fork (fixed by 0057).

## Commands

```bash
# core tests (Metal), from vendor/maplibre-native
~/dev/tmp/build-maplibre-native-core-tests-macos/mbgl-test-runner \
  --gtest_filter='-Map.*:HTTPFileSource.*:OnlineFileSource.*:MainResourceLoader.*:MapSnapshotter.*:LocalGlyphRasterizer.PingFang:LocalGlyphRasterizer.PingFangWithBoldInStyle:LocalGlyphRasterizer.PingFangSemibold'

# render tests: one process per group (all groups via ~/dev/tmp/render-suite-macos.sh)
~/dev/tmp/build-maplibre-native-core-tests-macos/mbgl-render-test-runner \
  -p metrics/macos-xcode11-release-style.json -f render-tests/<group>/

# expressions
~/dev/tmp/build-maplibre-native-core-tests-macos/mbgl-expression-test

# Qt + gestures
ctest --test-dir ~/dev/tmp/build-maplibre-native-qt-macos --output-on-failure
tests/gesture/run.sh
```

Run one unit runner at a time: the tests use a fixed in-process HTTP port (3000), and two concurrent
runners corrupt each other's results.

## Patch 0057 — Metal symbol shaders

Patches 0003/0004/0014 moved fill/line/raster/background (and the Vulkan symbols) to the per-tile
`ProjectionUBO`, but never touched `include/mln/shaders/mtl/symbol.hpp`: the Metal symbol vertex
shaders still projected through the pre-globe `drawable.matrix`, so every `icon-*`, `text-*` and
`symbol-*` render test produced a blank frame (**104/175 groups before, 175/175 after**). Patch 0057
mirrors `vulkan/symbol.hpp` — `SymbolDrawableUBO` grows to `18 * 16`, all three vertex shaders bind
`idProjectionUBO` and use `projectTileWithElevation()`, with the Vulkan along-line/variable-anchor,
`pitch_with_map`, `z` and clip-space logic. A temporary globe-projection symbol render test rendered
correctly as well. The patch is recorded in
[upstream contribution progress](../runbooks/upstream-contribution-progress.md).

## Known issues on macOS

1. **`Map.*` upstream Metal deadlock.** The backend deadlocks in
   `OffscreenTextureResource::bind()` → `-[AGXG18GFamilyCommandQueue commandBuffer]` →
   `_MTLCommandBuffer initWithQueue:` → `dispatch_semaphore_wait`. Observed stops:
   `Map.ContinuousRendering` (after `-Map.StyleNetworkErrorRetry:Map.Offline`, 34 tests in) and
   `Map.Issue15342`. Reproduces on pristine `c7506d6`, so it is upstream, not fork-specific.
2. **Server suites are not built on macOS Metal (60 tests).** `test/src/mln/test/test.cpp` starts the
   in-process `HttpServer` only for `(TEST_HAS_SERVER && __QT__) || USE_CPP_TEST_SERVER`, and
   `test/CMakeLists.txt` defines `USE_CPP_TEST_SERVER` only for `WIN32`, Linux and WebGPU. The tests
   are still enabled, so `HTTPFileSource`, `OnlineFileSource`, `MainResourceLoader` and
   `MapSnapshotter` fail/hang on connection errors. A local build with `-DUSE_CPP_TEST_SERVER` (or
   `CI_BUILD=1`, which disables them) would be needed to run them.
3. ~~`TerrainCamera.RaycastSlopeHitLiesOnTerrainAndOnTheRay`~~ **fixed by patch 0058** (test-only):
   pixel `{400, 300}` was exactly the slope's sea-level crossing and gave `-3.31e-07` instead of
   `> 0`; nearby pixels give `+122.9 m` (y=350) and `+261.7 m` (y=400). The test now uses `{400, 350}`
   and all 22 `TerrainCamera` tests pass.

## Coverage gaps

1. No visual check of the running app's globe/terrain labels: `screencapture` fails from the agent
   shell ("could not create image from display", no Screen Recording permission). The Metal symbol
   shaders are covered by the render tests, including a temporary globe-projection test.
2. No render-test fixtures for terrain or globe (`metrics/integration/render-tests` is Mercator only);
   sky/terrain/globe shading is only exercised by the app and upstream PR branches.
3. `Map.*` coverage depends on the upstream deadlock being fixed first.
4. Universal (`x86_64;arm64`) build not tested; all figures are arm64.

## Related

- [Build (macOS)](../runbooks/build-macos.md) · [Upstream contribution progress](../runbooks/upstream-contribution-progress.md)
- [Linux tests](./linux-tests.md) · [Windows](./windows.md) · [Android](./android.md) · [GL JS alignment](../references/gljs-alignment.md)
