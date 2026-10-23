---
type: Verification
title: macOS tests (Metal: core, render, expression, Qt, gestures)
description: What the macOS/Metal test suites cover and their results as of 2026-10-23, with the commands, the upstream gaps (incl. the Dawn Tint-tests configure bug and the iOS build gaps) and the known fork failure.
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

## WebGPU PR branches (2026-10-22)

The macOS WebGPU jobs exist only in `.github/workflows/macos-ci.yml` (Metal is not in CI), so the
three upstream PR branches were rebuilt here from worktrees of the vendor clone:

```bash
# both implementations; each has its own build tree and metrics directory
cmake --preset macos-webgpu-wgpu -DCMAKE_OSX_ARCHITECTURES=arm64     # Debug, deployment target 14.3
cmake --preset macos-webgpu-dawn -DCMAKE_OSX_ARCHITECTURES=arm64
# brew: glfw icu4c libuv jpeg-turbo webp libpng; PKG_CONFIG_PATH needs icu4c, libuv, glfw
cmake --build build-macos-webgpu-wgpu --target mbgl-test-runner mbgl-render-test-runner
cmake --build build-macos-webgpu-dawn --target mbgl-test-runner mbgl-render-test-runner
mkdir -p metrics/macos-webgpu-dawn   # metrics/macos-webgpu-wgpu already exists; else "Invalid path inside the manifest file"
```

| PR | Before | After the local fixes |
|----|--------|----------------------|
| #4534 sky | `-f render-tests/sky/` aborts, exit 134: `name 'target' is a reserved keyword` (`wgsl:222`) | sky **3/3**, render suite **1485 pass / 0 fail**, unit **1257 pass / 0 fail** |
| #4190 terrain | `Map.RenderingStatisticsTrackDrawsAcrossFrames` aborts, exit 134: `redefinition of 'GlobalPaintParamsUBO'` (`wgsl:209`); once cleared, **18 unit image-diff failures** (CI reported 14 on Dawn — the wgpu extras are the four pitched-circle variants) | unit **1157 pass / 0 fail**, render suite **1368 pass / 0 fail** |
| #4533 globe | green in CI | Metal `render-tests/projection/globe/` **71 pass + 1 ignored, 0 fail**, including `fill-seams/checkerboard` |

**Dawn (same worktrees, 2026-10-22).** Dawn is `FetchContent`-ed by `vendor/dawn.cmake` at tag
`v20260210.203301` into `vendor/dawn` (≈1.8 GB with `DAWN_FETCH_DEPENDENCIES=ON`) and built as a
subdirectory of the same build tree: the first configure fetched it in ≈80 s, and the build was a
plain Ninja build (≈2.5 min for Dawn and both runners on 12 cores). Contrary to the CI workflow no
`go` was needed by `fetch_dawn_dependencies.py` — brew `python@3.15` alone sufficed (CI installs
`python@3.11 go`). The second worktree reused the fetched Dawn tree and
`CCACHE_NOHASHDIR=1 CCACHE_BASEDIR=~/dev/tmp` let ccache serve its Dawn objects from the first.

| PR | Dawn before (CI) | Dawn after the local fixes |
|----|------------------|----------------------------|
| #4534 sky | Run WebGPU render tests: 1484 passed, 84 ignored, **1 failed** — `render-tests/sky/atmosphere-globe` | sky **3/3** (incl. `sky/atmosphere-globe`), unit **1257 pass / 0 fail**, render **1485 pass / 0 fail** (5 passed-but-ignored, 84 ignored) |
| #4190 terrain | Run unit tests: **14 image-diff failures** (list in [progress](../runbooks/upstream-contribution-progress.md#macos-from-the-pr-ci-logs-2026-10-21)) | all 14 pass; unit **1157 pass / 0 fail**, render **1368 pass / 0 fail** (4 passed-but-ignored, 94 ignored) |

The Dawn totals are identical to the wgpu ones for both PRs, no run aborted or panicked, and the
render HTML reports land in `metrics/macos-webgpu-dawn.html`. That confirms the bugs were
backend-agnostic WGSL/generated-header mistakes (`target`, duplicate `PI`, `GlobalPaintParamsUBO`,
`drape_tile` struct offsets) rather than Dawn/wgpu divergence.

Five bugs across four files, all uncommitted experiments in the PR worktrees (nothing pushed; diffs
saved as `~/dev/tmp/webgpu-pr-fixes/*.patch`):

1. `include/mln/shaders/webgpu/sky.hpp` (#4534) — `target` → `view_pos` (reserved keyword), and the
   fragment redeclared `const PI`, which the shared prelude already defines.
2. `include/mln/shaders/webgpu/circle.hpp` (#4190) — the per-shader prelude's `GlobalPaintParamsUBO`
   still had the pre-terrain 48-byte layout while the vertex redeclared the 64-byte one, so the
   concatenated module redefined the struct *and* the `paintParams` binding.
3. `include/mln/shaders/webgpu/line.hpp` (#4190) — `drape_tile` had been added to the WGSL
   `LineDrawableUBO` (112 B vs the C++ 96 B) and `LineEvaluatedPropsUBO` (64 B vs 48 B). The CPU
   uploads `LineDrawableUnionUBO` (128 B stride), so `LineDrawableEntry` became 144 B and every line
   drawable was read at the wrong offset: tile-border debug lines turned into giant red quads,
   annotation lines collapsed and pitched circles were misplaced — 17 of the 18 unit failures.
4. `src/mln/webgpu/texture2d.cpp` (#4190) — the WebGPU backend never incremented
   `RenderingStats::numTextureUpdates`/`textureUpdateBytes` (GL, Vulkan and Metal all do), so
   `ColorRelief.UploadsDEMTextureOncePerTile` tripped its "the test proves nothing" guard.

Details and commands:
[upstream contribution progress](../runbooks/upstream-contribution-progress.md#macos-webgpu--reproduced-and-fixed-2026-10-22).

## iOS on this Mac (toolchain fixed 2026-10-23)

Xcode 27.1 (`/Applications/Xcode.app`, 27A9275, iPhoneOS SDK 27.1) was installed all along, but
**Xcode's additional components had never been installed**, so
`/Library/Developer/PrivateFrameworks/CoreSimulator.framework` was missing: `xcrun simctl` and
`xcrun devicectl` failed, and every CMake iOS preset died in compiler detection because CMake's probe
calls `xcodebuild`, whose `IDESimulatorFoundation` plug-in could not load.

```text
$ xcodebuild -checkFirstLaunchStatus   # → rc 69 (components pending)
$ cmake --preset ios-webgpu-dawn       # in ~/dev/tmp/mln-pr4190
CMake Error at CMakeLists.txt:48 (enable_language):
  No CMAKE_CXX_COMPILER could be found.
```

**Fixed 2026-10-23 — neither command needed `sudo`:**

```bash
xcodebuild -runFirstLaunch        # installed the components; -checkFirstLaunchStatus now returns 0
xcodebuild -downloadPlatform iOS  # iOS 27.1 (24A94425, 7.85 GB) + iOS 27.0 (24A434, 8.05 GB), ~16 min
```

`/Library/Developer` now holds `CoreSimulator`, `CoreDevice`, `DeviceKit`, `DeveloperDiskImages` and
`PrivateFrameworks`; both simulator runtimes install as cryptexes and are `isAvailable: True`;
`xcrun simctl list runtimes` lists **iOS 27.0 and 27.1**, `simctl list devices available` lists 12
iPhone/iPad simulators, and `xcrun devicectl list devices` now answers "No devices found" instead of
hanging. Disk went 88 GB → 71 GB free.

**What works now:** `cmake --preset ios-webgpu-dawn` configures here in **77.7 s** (Swift compiler
detected, Dawn configured). The `-- Tint build tests: ON` line that configure used to print was the same
Dawn misconfiguration that reds `main`'s `ios-build-webgpu-dawn` job — fixed and verified 2026-10-23, see
[Dawn's TINT_BUILD_TESTS](#dawns-tint_build_tests--mains-red-ios-dawn-job-2026-10-23). The iOS presets
default to the **simulator** (Xcode generator, `Debug-iphonesimulator`, arm64 + x86_64 with
`ONLY_ACTIVE_ARCH` warnings), matching CI's `ios_sim_arm64` bazel path.

**Remaining local prerequisite: `bazel`.** `cmake --build build-ios-webgpu-dawn --target mbgl-core
ios-sdk-static` now compiles Dawn/Tint/absl and ~1000 objects, then stops at the
`mbgl-ios-umbrella-header` phase script:

```text
Script-0BECA5A2AD596AB922139ABA.sh: line 5: bazel: command not found
** BUILD FAILED **
```

That script runs `bazel build //platform/ios:umbrella_hdr //platform/ios:mln_defines` to generate
`MapLibre.h`/`MLNDefines.h`. Bazel is **not installed** on this Mac (`brew info bazelisk` → 1.30.0,
bottled); CI's `ios-build` job installs it via `bazel-contrib/setup-bazel`, and `ios-build-cmake`
relies on the runner image already having it. The two `Libtool … libabsl_hash.a` failures in the same
run are collateral from the aborted build — that libtool command re-run by hand exits 0.

Related, for the record: QMapLibre **does** support iOS upstream (`maplibre-native-qt`'s
`cmake/presets/iOS.json` — Qt6 toolchain, `MLN_WITH_METAL=ON`, deployment target 17.0) and Qt 6.12.0's
`ios_device` and `ios_simulator_arm64` kits are installed under `~/Qt`. iPhone device testing is
**not set up yet** (no Apple ID signing as of 2026-10-23); see next-actions item 10 in the
[contribution runbook](../runbooks/upstream-contribution-progress.md#next-actions-ordered).

### What the iOS build revealed (2026-10-23)

With bazel in place, the CI target set builds locally for the simulator
(`cmake --build … --target mbgl-core ios-sdk-static app`, worktree `mln-pr4190`):

| Config | Result |
|---|---|
| `ios-metal` | **builds** — `libmbgl-core.a` + `ios-sdk-static.framework` (fat: x86_64 + arm64) + the ObjC demo `app` |
| `ios-webgpu-dawn` | builds **after one upstream fix** (below) |

Bazel is needed by two phase scripts (`mbgl-ios-umbrella-header` → `bazel build //platform/ios:umbrella_hdr
//platform/ios:mln_defines`, `mbgl-darwin-style-code` → `bazel build //platform/darwin:generated_code`);
installed 2026-10-23 as `brew install bazelisk` (bazelisk 1.30.0; the repo's `.bazelversion` pins bazel
**8.6.0**, which bazelisk fetched on first use).

Three upstream gaps, all **pre-existing on `main`** and each hidden by a different blocker:

1. **`platform/ios/src/MLNMapView+WebGPU.mm` cannot compile** (any WebGPU config). Its destructor calls
   `context.reset()` on the `std::unique_ptr<mln::gfx::Context>` member of `gfx::RendererBackend`
   (`include/mln/gfx/renderer_backend.hpp:75`), but `Context` is only forward-declared there — the file
   never includes `mln/gfx/context.hpp`. The Metal and OpenGL siblings never call `context.reset()`, so
   only WebGPU hits it. One-line fix (`#import <mln/gfx/context.hpp>`), applied **locally, uncommitted**
   in the `#4190` worktree; with it the whole `ios-webgpu-dawn` set builds. CI cannot see it because
   `ios-build-webgpu-dawn` dies earlier, in configure (next-actions 3).
2. **The iOS `app` target cannot build with `MLN_WITH_WEBGPU`**: `platform/ios/app/CMakeLists.txt`
   includes `"CustomStyleLayerExample.h"` from the shared `platform/darwin/app` directory and only gets
   that include directory by linking `custom-layer-examples` — which `platform/darwin/darwin.cmake`
   creates inside `if(NOT MLN_WITH_WEBGPU)` ("Custom layer examples use OpenGL ES / Metal APIs directly
   and are not available for WebGPU builds"). Result: `MBXViewController.mm:19: fatal error:
   'CustomStyleLayerExample.h' file not found`.
3. **The ObjC demo app no longer launches on the current SDK**: built against the iPhoneSimulator 27.1
   SDK it dies at scene creation with `EXC_BREAKPOINT`/`SIGTRAP` in
   `_UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption` — *"Application failed to launch:
   UIScene life cycle is required for apps built with this SDK"*. The app is legacy
   (`application:didFinishLaunchingWithOptions:`, no `UIApplicationSceneManifest`, no scene delegate);
   injecting a minimal manifest into the built bundle alone does not satisfy the check. Upstream's current
   iOS app is Swift, built with bazel (`//platform/ios/app-swift:MapLibreApp`); this CMake `app` target is
   what `ios-build-cmake` still builds but nobody launches.

**No visual simulator capture on this Mac yet**: this Xcode 27.1 install has **no `Simulator.app`** —
`/Applications/Xcode.app/Contents/Developer/Applications` does not exist at all, and
`Contents/Applications` holds only Accessibility Inspector, Create ML, DeviceHub (`com.apple.dt.Devices`,
the devices hub), FileMerge, Icon Composer and Instruments. The simulator boots via `simctl` and
SpringBoard runs, but with no UI host the framebuffer stays blank: the home-screen and app screenshots
are byte-identical 106 KB all-black PNGs. `Simulator.app` belongs to the Xcode bundle, not to
`xcodebuild -downloadPlatform iOS`, so inspectable simulator runs need a repaired/reinstalled Xcode. A
test-only simulator run (textual output) is unaffected.

### QMapLibre (Qt wrapper) for iOS simulator — 2026-10-23

The wrapper's iOS path had never been built on this Mac; it builds. With the `ios_simulator_arm64` Qt
kit, `cmake --preset iOS-ccache -DCMAKE_OSX_ARCHITECTURES=arm64` configures in 6.1 s and
`cmake --build … --config Release` finishes **551 steps with 0 warnings and 0 errors**, producing
**static** libraries — `libQMapLibre.a`, `libQMapLibreQuickPrivate.a`, `libQMapLibreLocation.a`,
`libQMapLibreWidgets.a` — plus the QML module `src/quick/plugins/MapLibre/`
(`libdeclarative_maplibre.a`, `qmldir`, `declarative_maplibre.qmltypes`) and the location plugin. Objects
are `platform IOSSIMULATOR, minos 17.0, sdk 27.1`, arm64, and the wrapper's Metal backend
(`metal_renderer_backend.mm`, `texture_node_metal.mm`) compiles in.

Two caveats found: the preset's default `CMAKE_OSX_ARCHITECTURES=arm64;x86_64` is **not buildable
against the Qt-installer iOS kits**, which are single-arch (only the macOS host kit is fat) — configure
accepts it, then the link fails (`ld: warning: ignoring file …/QtCore …: found architecture 'arm64',
required architecture 'x86_64'` → `Undefined symbols … _qt_main_wrapper`), so override to the kit's arch;
and `MLN_WITH_GLFW` stays **ON** (harmless — nothing references it and no test target is built).
Upstream's `iOS CI` is green with the preset defaults, but it gets Qt from `aqtinstall`, so check that
packaging difference before calling either an upstream bug.

Canonical tree and commands: [Build (macOS) → iOS simulator library tree](../runbooks/build-macos.md#ios-simulator-library-tree--2026-10-23).

### Dawn's TINT_BUILD_TESTS — main's red iOS Dawn job (2026-10-23)

`main`'s `ios-build-webgpu-dawn` job fails in **configure**, before any compilation:

```text
CMake Error at vendor/dawn/third_party/CMakeLists.txt:91 (add_subdirectory):
  /Users/runner/…/vendor/dawn/third_party/googletest does not contain a CMakeLists.txt file.
```

Reason: Dawn defaults `TINT_BUILD_TESTS` to **ON** (`vendor/dawn/CMakeLists.txt:249`; only Emscripten
turns it off), and `vendor/dawn/third_party/CMakeLists.txt:90` reads
`if ((DAWN_BUILD_TESTS OR TINT_BUILD_TESTS) AND NOT TARGET gmock)`, so line 91 adds googletest even
though the fork's `vendor/dawn.cmake` already sets `DAWN_BUILD_TESTS OFF`. On this Mac the dependency
fetch happens to populate `third_party/googletest`, so the same configure succeeds and prints
`-- Tint build tests: ON`; the CI runner's directory was empty at configure time, which is the only
reason the job is red.

Fix, one line in `vendor/dawn.cmake` beside the existing Dawn test switch:

```cmake
set(DAWN_BUILD_TESTS OFF CACHE BOOL "Disable Dawn tests" FORCE)
set(TINT_BUILD_TESTS OFF CACHE BOOL "Disable Tint tests" FORCE)
```

Verified 2026-10-23 in `~/dev/tmp/mln-pr4190` by emulating the runner's state with
`-DDAWN_GOOGLETEST_DIR=<empty dir>`:

| Configure | Result |
|---|---|
| `ios-webgpu-dawn`, unpatched | fails — `CMake Error at vendor/dawn/third_party/CMakeLists.txt:91 … does not contain a CMakeLists.txt file` (CI reproduced verbatim) |
| `ios-webgpu-dawn`, patched | **rc 0**, `-- Tint build tests: OFF` |
| `build-ios-webgpu-dawn` (cache held `TINT_BUILD_TESTS=ON`), patched | reconfigures; `cmake --build … --target mbgl-core ios-sdk-static` → `** BUILD SUCCEEDED **` |
| `build-macos-webgpu-dawn`, patched | reconfigures with `TINT_BUILD_TESTS:BOOL=OFF`; ninja reports **no work to do** |

That last row is the useful one: the Dawn libraries we link are unchanged, because `DAWN_BUILD_TESTS` was
already off and the only target we touch in that area, `tint_lang_msl_validate`, is guarded by
`if(TARGET …)` (`vendor/dawn.cmake:120`). The fix also makes the job immune to whatever left CI's
googletest empty. Applied **locally, uncommitted**; worth raising on its own, since it reds `main` and
every WebGPU-Dawn job, not just our PRs (next-actions 3 in the
[contribution runbook](../runbooks/upstream-contribution-progress.md#next-actions-ordered)).

Evidence logs (ephemeral, under `$TMPDIR/opencode/`): `tintcheck-baseline2.log` (CI failure reproduced),
`tintcheck-fixed.log`, `tintcheck-canonical-build.log`, `tintcheck-macos-dawn.log`.

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
4. Universal (`x86_64;arm64`) build: the library install and the app are universal as of 2026-10-22
   (`lipo -archs` → `x86_64 arm64`, `ctest` 3/3, app on Metal). The x86_64 slice is link-checked only —
   this Mac has no Rosetta — so all test figures on this page are the arm64 slice.

## Related

- [Build (macOS)](../runbooks/build-macos.md) · [Upstream contribution progress](../runbooks/upstream-contribution-progress.md)
- [Linux tests](./linux-tests.md) · [Windows](./windows.md) · [Android](./android.md) · [GL JS alignment](../references/gljs-alignment.md)
