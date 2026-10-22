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
| Core `mbgl-test-runner`, `Map.*` | **cannot complete** — hangs in `Map.ContinuousRendering`; root cause found, upstream [#4822](https://github.com/maplibre/maplibre-native/issues/4822) |
| Core `mbgl-test-runner`, server suites (60 tests) | **60 pass, 0 fail** — each suite in its own process, via a local `USE_CPP_TEST_SERVER` test build (upstream does not define it on macOS Metal) |
| Gesture logic `tests/gesture/run.sh` | **35/35** QtQuickTest cases pass |

Baseline: pristine `c7506d6` on the same Metal build passes `icon-size` 11/11; the fork before patch
0057 failed all 11 (blank frames), which pinned the symbol breakage on the fork (fixed by 0057).

## Commands

```bash
# core tests (Metal), from vendor/maplibre-native
~/dev/tmp/build-maplibre-native-core-tests-macos/mbgl-test-runner \
  --gtest_filter='-Map.*:HTTPFileSource.*:OnlineFileSource.*:MainResourceLoader.*:MapSnapshotter.*:LocalGlyphRasterizer.PingFang:LocalGlyphRasterizer.PingFangWithBoldInStyle:LocalGlyphRasterizer.PingFangSemibold'

# server suites (60 tests) need a local test build with USE_CPP_TEST_SERVER, one suite per process
for s in HTTPFileSource MainResourceLoader MapSnapshotter OnlineFileSource; do
  ~/dev/tmp/build-maplibre-native-core-tests-macos/mbgl-test-runner --gtest_filter="$s.*"
done

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

## Server suites (60 tests)

The canonical Metal build cannot run them (known issue 2). To verify the storage/network code on
macOS, add the define to the test main only — `test/CMakeLists.txt`, guarded by `if (APPLE)`:

```cmake
if (APPLE)
    set_source_files_properties(
        ${PROJECT_SOURCE_DIR}/test/src/mln/test/test.cpp
        PROPERTIES COMPILE_DEFINITIONS USE_CPP_TEST_SERVER
    )
endif()
```

Only `test/src/mln/test/test.cpp` recompiles, then `cmake --build <test build dir> --target
mbgl-test-runner`. Run **one suite per process** (the in-process server uses fixed port 3000):

| Suite | Tests | Result |
|-------|-------|--------|
| `HTTPFileSource.*` | 11 | pass |
| `MainResourceLoader.*` | 20 | pass |
| `MapSnapshotter.*` | 6 | pass |
| `OnlineFileSource.*` | 23 | pass |
| **Total** | **60** | **60 pass, 0 fail** |

This edit is a **local experiment, not a fork patch**: after running, restore `test/CMakeLists.txt`
to the patched state and rebuild, so `vendor/maplibre-native` equals patches 0001–0058 again.

Running all four suites in a **single** process reproducibly trips a timing flake in
`OnlineFileSource.TemporaryError`: the first `/temporary-error` response arrives after 1–4 s instead
of < 0.2 s. The in-process server has a 4-thread pool, and the earlier suites (both `HTTPFileSource.*`
and `MainResourceLoader.*` alone are enough to trigger it) leave keep-alive connections occupying
the workers, so the new request queues behind them. The test passes alone and together with
`MapSnapshotter.*`. That is upstream test infrastructure (shared server, no per-test isolation), not
fork code.

## Known issues on macOS

1. **`Map.*` Metal deadlock — root-caused, upstream issue
   [#4822](https://github.com/maplibre/maplibre-native/issues/4822).** `mtl::OffscreenTextureResource::bind()`
   allocates a new `MTLCommandBuffer` on every call, but a frame binds the headless default renderable
   three times (two `UploadPass`es plus the main `RenderPass`) and swaps it once. The two abandoned
   command buffers are never committed and each holds one of the queue's in-flight slots, so after
   ~32 frames (64 slots, 2 leaked per frame) `-[MTLCommandQueue commandBuffer]` blocks forever:
   `OffscreenTextureResource::bind()` → `_MTLCommandBuffer initWithQueue:` → `dispatch_semaphore_wait`,
   with every worker thread idle and the test's 10 s shut-off timer unable to fire inside the render
   callback. Instrumenting `bind()`/`swap()` shows the 3:1 ratio and the block at ~96 binds / ~31
   swaps. Reproduces on pristine `c7506d6`, so it is upstream, not fork-specific; macOS Metal is not in
   CI (`macos-ci.yml` builds only WebGPU, and `ContinuousRendering` is `TEST_DISABLED_ON_CI`). The
   iOS/macOS `MTKView` renderables already guard with `if (!commandBuffer)`; with the same guard
   `Map.ContinuousRendering` passes in 1.35 s and `Map.*` (CI filter) is **55/55 in 7.5 s**. The guard
   is **not shipped** as a fork patch yet — it only affects the headless backend, and the running app
   is unaffected.
2. **Server suites need a local test-build flag on macOS Metal (60 tests).**
   `test/src/mln/test/test.cpp` starts the in-process `HttpServer` only for
   `(TEST_HAS_SERVER && __QT__) || USE_CPP_TEST_SERVER`, and `test/CMakeLists.txt` defines
   `USE_CPP_TEST_SERVER` only for `WIN32`, Linux and WebGPU. The 60 tests are still enabled, so in the
   canonical build `HTTPFileSource`, `OnlineFileSource`, `MainResourceLoader` and `MapSnapshotter`
   fail/hang on connection errors. With the server compiled in, **all 60 pass when each suite runs in
   its own process** (11 + 20 + 6 + 23; see *Server suites* above).
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
3. `Map.*` coverage needs the [#4822](https://github.com/maplibre/maplibre-native/issues/4822) fix
   (headless command-buffer reuse) either upstream or as a fork patch.
4. Universal (`x86_64;arm64`) build not tested; all figures are arm64.

## Related

- [Build (macOS)](../runbooks/build-macos.md) · [Upstream contribution progress](../runbooks/upstream-contribution-progress.md)
- [Linux tests](./linux-tests.md) · [Windows](./windows.md) · [Android](./android.md) · [GL JS alignment](../references/gljs-alignment.md)
