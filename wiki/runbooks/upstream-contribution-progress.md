---
type: Runbook
title: Upstream contribution progress
description: "Live tracker for offering the fork's terrain/globe/sky work upstream: branch status, per-platform test results (Windows, Android, Linux, macOS) and pickup steps."
tags:
  - runbook
  - upstream
  - status
  - testing
status: current
---
# Upstream contribution progress

> Live tracker, updated 2026-10-21. Strategy: join the existing upstream feature branches, report test results, and contribute focused gaps (Qt/QMapLibre wrapper first). **Do not** submit the 58-patch fork stack or a competing globe/terrain/sky implementation.

## Strategy (agreed 2026-10-20)

1. **Join the existing branches** — test them on Windows/Android/Linux and report; they explicitly need testers.
2. **Focused PRs** against `feature/terrain-3d` / the globe branch for gaps. The unique, working stack is the **Qt/QMapLibre wrapper + app API** (63 commits in `maplibre-native-qt`), which the core PRs need.
3. **Only if the implementation is materially different/better**: write a comparison/design proposal for the TSC first; no competing PRs.

## Upstream landscape

| Effort | Owner | Branch / base | State | Notes |
|---|---|---|---|---|
| Globe #4533 | johncarmack1984 | `phased/12h` → `main` | open, not draft, `BLOCKED`, CI green (2026-10-20) | Issue #3161; design proposal #4525 closed; 673 files. |
| Sky #4534 | ClayWarren | `codex/sky-style-spec-4414`, stacked on globe | open, not draft, `DIRTY`; CI stuck since 2026-10-21 (`action_required`) | Issue #4414; Metal/Vulkan render pass. Two WebGPU WGSL bugs found + fixed locally 2026-10-22 (wgpu **and** Dawn now green locally, below). Last *executed* head (2026-10-16): only `ios-build` failed, because the new `MLNSkyTest.mm.ejs` imports `<Mapbox.h>` (`ios_test` failed to build) — one-line PR bug, below; Android CI passed. |
| Terrain #4190 | NathanMOlson | `feature/terrain-3d` → `main` | **draft**, `DIRTY` | Maintainer `louwers` coordinating; follow-ups #4558, #4790, #4791, #4801, #4809, #4810 target `feature/terrain-3d`; issue #252. Three WebGPU bugs found + fixed locally 2026-10-22 (wgpu **and** Dawn now green locally, below). Its iOS Dawn CI failure is pre-existing on `main` (below). |
| Overlap #4752 | JohnDr | `mln-icon-text-overlap` → `main` | **draft**, `BLOCKED`, pre-commit green | Our icon/text-overlap implementation; build workflows await approval; refs #251. |
| Qt #323–#326 | JohnDr | fork branches → `maplibre-native-qt` `main` | #323 draft; #324/#325/#326 ready | #323 Metal fix at `91297dd`, CI approval pending; #326 has empty-style fallback + `styleChanged` NOTIFY at `5d1077a`. |

## Gap analysis (summary)

- Fork work: 58 core patches on 13.6.1 (patch 0057 is the 2026-10-22 macOS/Metal symbol fix, 0058 a test-only terrain-camera pixel fix), all authored by JohnD (audit on 2026-10-20).
- Upstream branches touch 233 of those 258 files; only 25 are untouched by all three (#4533/#4534/#4190).
- Architectures differ: upstream `RenderTerrain` / `style::Terrain` / `TerrainLayerTweaker` / `TerrainLoadMode` / `TerrainSkirtLength`; ours `TerrainTileManager` / `TerrainPass` / `terrain_stitch` / per-tile RTT pool. File overlap is infrastructure, not mergeable code.
- **Likely unique candidates**: Qt/QMapLibre wrapper (terrain/sky/globe API, `liveCoordinate`/`liveZoom`, metrics, gestures), terrain-camera ray-scan centre (verify against #4190's `TerrainCamera` tests and #4711), RTT drape pool/fingerprint, globe-terrain pole caps, flat draped wrapped tiles.
- **Likely already covered**: globe (#4533), sky/atmosphere (#4534), LOD skirts/occlusion, overzoom/backfill (#4809/#4810). Do not re-submit.

## Test results

### Windows 11 (MSVC, Vulkan)

Build setup now works (see [pickup](#pickup-after-restart--os-switch)):

- **#4190 terrain**: unit tests **30/30 pass** (`*Terrain*`). Terrain render tests are **ignored** upstream (native 3D terrain not graded against GL JS yet).
- **#4534 sky**: render tests **3/3 pass** on Windows/Vulkan — `sky/basic`, `sky/atmosphere-globe`, `sky/zoom-expression`.
- **#4533 globe** (tested through #4534's globe snapshot `2a85b5d`, 2026-10-17): 53 groups, **2 unique failures**, both tile-edge seams:
  - `projection/globe/fill-seams/checkerboard`
  - `projection/globe/raster-warped`
  Ignored: `debug-tile-borders`, `fill-planet-pole`, `fill-planet-pole-top`, `fill-planet-tiles`, 2 in `antimeridian-overdraw`. All other groups pass. Re-run the two failures on the newer #4533 head `ff96700` before reporting.
- **Full unit suite**: stops on platform tests, not PR-related — `OnlineFileSource.ConnectionError` (backoff timing) and `LocalFileSource.InvalidUTF8Path`.

### Android (S23, serial `RFCW910087W`)

Built from the PR CI `android-ui-test-vulkan` artifacts (package `org.maplibre.android.testapp`):

- **#4533**: `GlobeActivity` renders correctly. **PASS**.
- **#4190**: `TerrainActivity` renders pitched 3D terrain with draped imagery. **PASS**.
- **#4534**: no Sky activity; `GlobeActivity` shows no atmosphere. Not visually verifiable; CI failures above stand.

### Linux (Ubuntu 26.04, Vulkan/RADV, AMD Radeon 780M) — 2026-10-21

All three branches built as worktrees of the local clone (`~/dev/tmp/mln-pr4533|pr4534|pr4190`), submodules populated from the shared object store (no re-download), Release + `MLN_WITH_VULKAN=ON`/X11 (no GLFW/OpenGL), Ninja, build trees `~/dev/tmp/build-pr45xx-vk`. Core build ≈2.5 min; the existing [Linux tests](../verification/linux-tests.md) path works unchanged for PR branches.

**Unit tests** (`mbgl-test-runner`, Vulkan, RADV; one runner at a time — fixed HTTP test port 3000):

| Branch | Head | Result |
|---|---|---|
| #4533 globe | `ff96700` | **1243 tests / 145 suites — all pass**, 4 disabled |
| #4534 sky | `2a85b5d` | **1245 tests — all pass**, 4 disabled |
| #4190 terrain | `c6b31b7` | **1145 tests — all pass**, 30 tests named `*Terrain*` included |

The Windows-only stops (`OnlineFileSource.ConnectionError`, `LocalFileSource.InvalidUTF8Path`) did **not** reproduce on Linux.

**Render tests** (`mbgl-render-test-runner -p metrics/linux-vulkan.json`, one group per process):

- `projection/globe` (72 tests): 66 passed, 3 ignored, 2 passed-but-ignored, **1 failed** — `projection/globe/fill-seams/checkerboard`. Byte-identical outcome on #4533 `ff96700` and #4534 `2a85b5d` (`actual.png` md5 `127999d3…`), so it is not a stale globe snapshot.
- `raster-warped` **passes** on Linux/RADV: its Windows/Vulkan failure is platform-specific, not a globe defect.
- The checkerboard failure is a **threshold technicality, not a visible seam**. mapbox `pixelmatch` (threshold 0.1285, as in GL JS) counts **10 mismatched pixels of 65536** against `allowed = 0.00015` (9.83 px). All 10 sit on the image border (x=0 column, x=247, y=252 row) where the globe wraps; the other 4180 differing pixels are anti-aliasing-only. The same frame on **lavapipe** (`VK_ICD_FILENAMES=…/lvp_icd.json` — the software ICD GitHub's Ubuntu runners fall back to, which is why Linux CI is green) scores **9 mismatched pixels and passes**. Graded instead against the repo's own Linux expectation for this test (`metrics/expectations/platform-linux-opengl/…/checkerboard/expected.png`) the RADV frame differs by ≤59/255 with one pixel over 25: RADV Vulkan looks like RADV OpenGL, so the test fails on the Metal-rendered expectation, not on the globe's seams.
- `sky/` (3 tests: `basic`, `atmosphere-globe`, `zoom-expression`): **3/3 pass** on Linux/Vulkan — the Metal sky expectations hold here.
- `terrain/` (6 tests): **6/6 ignored** (all-platform ignore, graded against GL JS) — same as Windows.
- Full suite, #4533 (all 184 groups, ≈38 min): only two failing groups — `projection` (the checkerboard test above) and `fill-extrusion-pattern/tile-buffer`, the pre-existing upstream Linux/Vulkan baseline failure also present on pristine `c7506d6`. `text-font` 7/7 pass here (pristine had `burmese`/`khmer`/`devanagari` errors).
- Full suite, #4534 (184 groups): the **same two failures** as #4533 — `projection/globe/fill-seams/checkerboard` and `fill-extrusion-pattern/tile-buffer`.
- Full suite, #4190 (184 groups): **only** `fill-extrusion-pattern/tile-buffer` (the pre-existing baseline failure). This branch is based on `main` and carries no globe (`projection/globe`) or `sky/` fixtures, so those groups do not exist here — its `projection` group is the pre-globe four tests, all passing.

### macOS (from the PR CI logs, 2026-10-21)

A Mac was not available here, but the failing CI jobs were mined for exact signatures. `#4533` (globe) passes **both** `macOS WebGPU (Dawn)` and `(wgpu)`; `#4534` and `#4190` do not:

| PR | Job | Failing step | Signature |
|---|---|---|---|
| #4534 sky | macOS WebGPU (Dawn) | Run WebGPU render tests | 1484 passed, 84 ignored, **1 failed** — `render-tests/sky/atmosphere-globe` |
| #4534 sky | macOS WebGPU (wgpu) | Run WebGPU render tests | **abort** in wgpu-native (`src/lib.rs:422`, uncaptured error) — WGSL parse error: `name 'target' is a reserved keyword` at `wgsl:222` (`let target = atmosphere.inv_view_projection * …`) |
| #4190 terrain | macOS WebGPU (Dawn) | Run unit tests | **14 image-diff failures**: `Annotations.LineAnnotation`, `Annotations.ChangeMaxZoom`, `FeatureTracking.{ApiQuery,NDCBoundSymbol,NDCBoundSymbolOffset,NDCBoundCircle,NDCBoundFill,Overlap}`, `ColorRelief.UploadsDEMTextureOncePerTile`, `LocalGlyphRasterizer.NoLocalWithContentInsetsAndPitch`, `TileLOD.{disabled,pitchThreshold,scale,radius}` |
| #4190 terrain | macOS WebGPU (wgpu) | Run unit tests | **abort** — WGSL parse error: `redefinition of 'GlobalPaintParamsUBO'` (`wgsl:209` vs `wgsl:234`) while running `Map.RenderingStatisticsTrackDrawsAcrossFrames` |

Both aborts are WGSL compile failures inside wgpu-native, and both are already confirmed in these checkouts: `shaders/atmosphere.vertex.glsl:12` declares `vec4 target`, which the generator emits verbatim to WebGPU (`include/mln/shaders/webgpu/sky.hpp:99` — `let target = …`), and several generated WebGPU headers carry repeated `struct GlobalPaintParamsUBO` definitions (`background.hpp` ×3, `fill.hpp` ×6, `circle.hpp` ×2), which collide when two such sources are concatenated into one module. `main`'s (run `39495626975`, 2026-10-20) and #4533's macOS WebGPU jobs are green, so both failures are branch-introduced. Also failing for the same PRs: `#4534` `ios-build` and Android OpenGL instrumentation/render tests; `#4190` `ios-build-webgpu-dawn`, `android-build-webgpu-wgpu` and the Windows tests.

All of the above were **reproduced and fixed locally on 2026-10-22** — see [macOS WebGPU](#macos-webgpu--reproduced-and-fixed-2026-10-22) below: #4534's wgpu abort is a second WGSL error after `target` (duplicate `PI`), and #4190 needed three fixes (the `GlobalPaintParamsUBO` duplicate in `circle.hpp`, stray `drape_tile` fields bloating the WebGPU line shader's drawable/props structs, and missing texture-upload stats in `src/mln/webgpu/texture2d.cpp`). With those, both unit and render suites are green on wgpu **and** on Dawn: the Dawn jobs were then built and re-run locally on the same worktrees, where the 14 unit tests and `sky/atmosphere-globe` pass and the suite totals equal the wgpu ones.

### CI state re-checked with `gh` (2026-10-22)

Re-read straight from GitHub with `gh` on 2026-10-22 (`gh` is authenticated as `JohnDr`), which
shifts two of the claims above:

- **`main` is itself red on `ios-build-webgpu-dawn`.** `main`'s newest `ios-ci` run
  [`39637551740`](https://github.com/maplibre/maplibre-native/actions/runs/39637551740)
  (2026-10-21, `fix(core): Fix dynamic texture cleanup race condition (#4817)`) fails **only** that
  job — `ios-build`, `ios-build-cmake`, `ios-build-webgpu-wgpu` and `ios-ci-result` all pass. It dies
  in *configure*, not in a build:

  ```text
  CMake Error at vendor/dawn/third_party/CMakeLists.txt:91 (add_subdirectory):
    /Users/runner/…/vendor/dawn/third_party/googletest does not contain a CMakeLists.txt file.
  ```

  Line 91 is `if ((DAWN_BUILD_TESTS OR TINT_BUILD_TESTS) AND NOT TARGET gmock) →
  add_subdirectory(${DAWN_GOOGLETEST_DIR})`. `vendor/dawn.cmake` forces `DAWN_BUILD_TESTS=OFF` but
  leaves Dawn's `TINT_BUILD_TESTS` default **ON** (confirmed locally: the macOS Dawn configure prints
  `-- Tint build tests: ON`), which is what pulls googletest in; on this Mac it works only because the
  dependency fetch happened to populate `third_party/googletest` (it is there, with a
  `CMakeLists.txt`), while the CI runner's tree did not have it at configure time. So `#4190`'s red
  `ios-build-webgpu-dawn` is **pre-existing on `main`, not branch-introduced**. The one-line fix
  `set(TINT_BUILD_TESTS OFF … FORCE)` in `vendor/dawn.cmake` was **verified locally on 2026-10-23**
  (see next-actions 3 and [macOS verification](../verification/macos.md#dawns-tint_build_tests--mains-red-ios-dawn-job-2026-10-23)).
- **`#4534`'s CI has not executed anything since 2026-10-16.** Its last executed `ios-ci`
  ([`38968591824`](https://github.com/maplibre/maplibre-native/actions/runs/38968591824)) and
  `macos-ci` ([`38968591814`](https://github.com/maplibre/maplibre-native/actions/runs/38968591814))
  runs are from 2026-10-16T21:19, both failing; every run from the 2026-10-21T16:48 push (ios, macOS,
  Linux, Android, qt, node, rust, ohos) is `action_required` — the workflow runs need **maintainer
  approval** before they execute. Consequences: every “#4534 CI …” statement in this file describes
  the **2026-10-16** runs (the mined job logs `117211053553`/`117211053314` are from that macOS run),
  and the wgpu/Dawn fixes cannot show up green in CI until the runs are approved *and* the fixes are
  pushed to the branch — neither of which is ours to do.
- **`#4534`'s Android CI passed on 2026-10-16**, so the “CI fails Android OpenGL
  instrumentation/render” line above is stale or from the 2026-09-17 run, not the current head
  (`android-ci` run `38968592220`, conclusion *success*). On the last executed head the only iOS/CI
  failures were `ios-build` (below) and the two macOS WebGPU jobs (the WGSL ones fixed locally).
- **`#4534`'s `ios-build` failure is a one-line PR bug, not sky rendering.** The failing step is
  *Running iOS tests*: `//platform/ios/test:ios_test` **FAILED TO BUILD**, with
  `bazel-out/ios_sim_arm64-fastbuild…/bin/platform/darwin/test/MLNSkyTest.mm:5:9: fatal error:
  'Mapbox.h' file not found`. The template `platform/darwin/test/MLNSkyTest.mm.ejs:6` (new in this PR)
  says `#import <Mapbox.h>` while its sibling `MLNLightTest.mm.ejs:8` — and the generated
  `MLNMapViewCompassViewTests.mm` — say `#import <MapLibre.h>`, which is this SDK's umbrella header.
  Fix is `Mapbox.h` → `MapLibre.h` in the template; worth passing to the author.
- **`#4190`'s executed run (2026-10-19)** for the record: fails `ios-build-webgpu-dawn` (above),
  `android-build-webgpu-wgpu`, `macOS WebGPU (Dawn)` (job `118198908406`) and `(wgpu)`
  (job `118198908267`), and both Windows `test` jobs; passes `ios-build`, `ios-build-cmake`,
  `ios-build-webgpu-wgpu`, `MacOS Metal CI Tests`, `OpenGL`, `Vulkan`, all Linux jobs and
  codecov. The two macOS WebGPU failures are the ones fixed locally (above) and are **not pushed**,
  so CI will stay red until the branch carries the fixes.

### macOS fork build (native Metal) — 2026-10-22

First validation of the fork's 57 patches on macOS/Metal (macOS 27.0.1, Xcode 27.1, Qt 6.12.0, arm64;
build/run path in [Build (macOS)](./build-macos.md)).

| Check | Result |
|---|---|
| Library build + `ctest` | 3/3 pass (`test_mln_quick`, `test_mln_location`, `test_mln_widgets`) |
| App | starts on Metal (`Graphics API: 6`), QML root loads |
| Core render tests, all 175 groups | **175/175 pass** (`metrics/macos-xcode11-release-style.json`, one process per group) |
| Expression tests | **332 pass, 18 ignored, 0 fail** |
| Core unit tests, `-Map.*` and the 4 server suites | **991 pass, 0 fail** (991 tests / 130 suites; patch 0058 fixed the last test) |
| `Map.*` | **hangs** — headless command buffers are allocated per pass and never committed, so the Metal queue's in-flight slots run out after ~32 frames and `-[MTLCommandQueue commandBuffer]` blocks. Root-caused and filed as [#4822](https://github.com/maplibre/maplibre-native/issues/4822); the local `if (!commandBuffer)` guard makes `Map.*` 55/55, not shipped as a fork patch |
| Server suites (60 tests: `HTTPFileSource`, `OnlineFileSource`, `MainResourceLoader`, `MapSnapshotter`) | **60 pass, 0 fail** — suite-per-process with a local `USE_CPP_TEST_SERVER` build (upstream defines it only for Windows/Linux/WebGPU); not a fork patch. A single combined process trips `OnlineFileSource.TemporaryError` (keep-alive/4-thread server pool) |

**Fork regression found and fixed — patch 0057** (`maplibre-native-0057-globe-symbols-metal.patch`).
Patches 0003/0004/0014 give every backend a per-tile `ProjectionUBO` (globe + terrain elevation) but
never ported the Metal symbol shaders, which still projected through the pre-globe `drawable.matrix`.
On Metal every `icon-*`/`text-*`/`symbol-*` render test drew a blank frame: **104/175 groups before,
175/175 after**. The port mirrors `vulkan/symbol.hpp` (anchor through `projectTileWithElevation()`,
along-line/variable-anchor and `pitch_with_map` label-plane handling, the Vulkan `z`/clip logic), and
`SymbolDrawableUBO` in `mtl/symbol.hpp` grows to `18 * 16` to match the shared layout. Pristine
`c7506d6` passes `icon-size` on Metal, so this was a fork regression, not upstream. A temporary
globe-projection symbol render test also rendered correctly.

**Fork test fix — patch 0058:** `TerrainCamera.RaycastSlopeHitLiesOnTerrainAndOnTheRay`
(`test/map/terrain_camera.test.cpp:204`) asserted `hit->elevation > 0.0` with its pixel exactly on the
slope's sea-level crossing, which is `-3.31e-07` on macOS (`y=350 → +122.9 m`, `y=400 → +261.7 m`);
the test now uses `{400, 350}`. Test-only, no render/projection change.

## Pickup after restart / OS switch

### Windows

- PR clone: `C:\hda\dev\tmp\maplibre-native-pr`; branches `pr4533`, `pr4534`, `pr4190`; currently on **pr4534** (`2a85b5d`); build tree `build-windows-vulkan`.
- **vcpkg is a copy** at `platform/windows/vendor/vcpkg` (not a junction). 34 MSYS package pins were updated to current mirror versions + SHA512; `msys2-runtime` is 3.6.9-2. Do not replace it with the Qt vendor's vcpkg.
- **ICU**: configure overrides `ICU_I18N_LIBRARY_RELEASE` / `ICU_UC_LIBRARY_RELEASE` to the vcpkg ICU 74 libs; otherwise the Windows SDK ICU is mixed with vcpkg headers and the link fails.
- Scripts (temp): `%LOCALAPPDATA%\Temp\opencode\configure-mln-pr3.bat`, `build-mln-test.bat`, `build-mln-render.bat`. Recreate from this doc if the temp dir is cleaned.
- Submodule dirs are **junctions** to `maplibre-native-qt/vendor/maplibre-native`. Before any `git switch`/`status`, remove all reparse points under `vendor`, `platform`, `docs` (their `.git` files point into the Qt repo); switch, then recreate. Keep the vcpkg copy.
- Targets: `mbgl-test-runner`, `mbgl-render-test-runner`.
- Render tests: `mbgl-render-test-runner -p metrics/windows-vulkan.json -f render-tests/<group>/` from the repo root; **one group per process**. Delete generated `actual.png`/`diff.png` afterwards.

### Android

- Download artifacts: `gh run download <run-id> --repo maplibre/maplibre-native -n android-ui-test-vulkan -D <dir>`.
- Runs: globe `39488232473`, sky `38968592220`, terrain `39293102159`.
- Install `InstrumentationTestAppVulkan.apk` (or `...MultiBackend.apk`); uninstall the package first when switching artifacts (different debug signatures).
- Activities: `org.maplibre.android.testapp/org.maplibre.android.testapp.activity.style.GlobeActivity` and `...style.TerrainActivity`.

### Linux (works — 2026-10-21)

- Source trees: `git worktree add ~/dev/tmp/mln-pr<NNNN> pr<NNNN>` inside the existing clone `~/dev/projects/maplibre-native` (PR refs fetched with `git fetch https://github.com/maplibre/maplibre-native refs/pull/<n>/head:refs/heads/pr<n>`; submodule pointers are unchanged by all three, so no re-download). Populate submodules by hard-linking the clone's checkouts and pointing each `.git` file at the shared `…/.git/modules/<name>` (helper `/tmp/opencode/link-submodules.sh`).
- Configure: `cmake -B ~/dev/tmp/build-pr<NNNN>-vk -S . -G Ninja -DCMAKE_BUILD_TYPE=Release -DMLN_WITH_VULKAN=ON -DMLN_WITH_X11=ON -DMLN_WITH_GLFW=OFF -DMLN_WITH_OPENGL=OFF -DMLN_WITH_PMTILES=ON` — GLFW defaults ON and then demands `glfw3`.
- Build (`PATH=$HOME/Qt/Tools/Ninja:$PATH`): `ninja -C ~/dev/tmp/build-pr<NNNN>-vk mbgl-test-runner mbgl-render-test-runner mbgl-expression-test` (≈2.5 min, 16 cores).
- Run: unit tests from the source dir, one runner at a time (port 3000); render tests `-p metrics/linux-vulkan.json -f render-tests/<group>/`; all 184 groups via `/tmp/opencode/render-suite.sh <src> <bin> metrics/linux-vulkan.json <outdir>`.
- Force software Vulkan (what CI uses) for AA comparisons: `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json`.
- Qt tests: N/A — none of the three branches touches the Qt wrapper.

### macOS WebGPU — reproduced and fixed (2026-10-22)

Done on the Mac mini (macOS 27.0.1, Xcode 27.1, arm64). All four WebGPU/CI failures above were
reproduced from PR worktrees of the vendor clone — `~/dev/tmp/mln-pr4533` (`ff96700`),
`mln-pr4534` (`38dac5b`), `mln-pr4190` (`c6b31b7`), submodules initialised from the shared object
store, wgpu-native built by cargo at configure time — and **fixed locally**. How it was run,
mirroring `.github/workflows/macos-ci.yml`:

- Presets: `cmake --preset macos-webgpu-dawn` / `macos-webgpu-wgpu` (also available: `macos-metal`, `macos-vulkan`, `ios-metal`, `ios-webgpu-{dawn,wgpu}`). Build targets `mbgl-test-runner mbgl-render-test-runner mbgl-expression-test`.
- Unit tests: `build-macos-webgpu-<impl>/mbgl-test-runner --gtest_filter=-Map.StyleNetworkErrorRetry:LocalGlyphRasterizer.PingFang:LocalGlyphRasterizer.PingFangWithBoldInStyle:LocalGlyphRasterizer.PingFangSemibold:Map.Offline`.
- WebGPU render tests: `build-macos-webgpu-<impl>/mbgl-render-test-runner --manifestPath metrics/macos-webgpu-<impl>.json`.
- Metal baseline for the Linux checkerboard question: `cmake --preset macos-metal`, then `-f render-tests/projection/globe/` and compare against the RADV frame (`~/dev/tmp/…/fill-seams/checkerboard/actual.png` here, or `/tmp/opencode/checkerboard-radv-actual.png`).
- Hypotheses to test, in order: (a) the terrain shader concatenation emits `GlobalPaintParamsUBO` twice (`wgsl:209`/`234`) — the wgpu abort; (b) the sky vertex shader's `target` identifier is a reserved WGSL keyword — rename and re-run; (c) whether Dawn's `sky/atmosphere-globe` failure and the 14 terrain unit-test diffs are real rendering differences (read `actual.png`/`diff.png`, the unit tests print `getImageDiff … <= imageThreshold`).
- CI logs already mined: `/tmp/opencode/ci-logs/api-{117211053553,117211053314,118198908406,118198908267}.log` (Dawn+wgpu for #4534 and #4190); those temp copies have since been cleaned — re-mine with `gh run view <run-id> --log-failed --repo maplibre/maplibre-native`.
- Local build notes: `-DCMAKE_OSX_ARCHITECTURES=arm64` (preset defaults are Debug, deployment target 14.3); brew deps `glfw icu4c libuv jpeg-turbo webp libpng`, `PKG_CONFIG_PATH` must include icu4c, libuv and glfw. Dawn **was** rebuilt locally too (see the Dawn subsection below) — `cmake --preset macos-webgpu-dawn`; its CI job (118198908406) fails at the same *Run unit tests* step with the same 14 tests that the wgpu run reproduces (plus 4 pitch-circle variants that only fail on wgpu), and both jobs are green after the fixes.

#### #4534 (sky) — two WGSL errors, abort fixed

- Before: `-f render-tests/sky/` aborts, exit 134, `name 'target' is a reserved keyword` at `wgsl:222:9` (`let target = atmosphere.inv_view_projection * …`) — matches the CI signature (`src/lib.rs:422` panic from wgpu-native).
- Bug 1: `include/mln/shaders/webgpu/sky.hpp` uses `target` as a local; renamed to `view_pos`.
- Bug 2 (surfaced next): `redefinition of 'PI'` — the sky fragment redeclares a constant the shared prelude already defines (common `wgsl:3` vs fragment `wgsl:214`); removed the duplicate.
- After: `render-tests/sky/` **3/3 pass**; full wgpu render suite **1485 passed, 0 failed, exit 0** (`--manifestPath metrics/macos-webgpu-wgpu.json`); unit suite with the CI filter **1257 passed, 0 failed**.

#### #4190 (terrain) — three bugs, all fixed

1. **Abort: `GlobalPaintParamsUBO` redefinition.** `circle.hpp` keeps a per-shader `prelude` whose copy of the struct still had the pre-terrain 48-byte layout (no `drape_tile`), while the shader's `vertex` declared the 64-byte layout again — the group concatenation redefines both the struct *and* the `paintParams` binding → `wgsl:209`/`wgsl:234`, exit 134 in `Map.RenderingStatisticsTrackDrawsAcrossFrames`. Fix: add `drape_tile: vec4<f32>` to the prelude copy (64 B, matching `layer_ubo.hpp`) and delete the duplicate struct/binding from the vertex. The test now passes in 247 ms.
2. **Line drawables read shifted data — 17 of the 18 image diffs.** `line.hpp` had grown `drape_tile: vec4<f32>` in the WGSL `LineDrawableUBO` (→ 112 B) and `LineEvaluatedPropsUBO` (→ 64 B), but the C++ structs are 96 B and 48 B and the CPU uploads `LineDrawableUnionUBO` (128 B stride). `LineDrawableEntry` therefore became 144 B, so every line drawable's matrix/props were read at the wrong offset: tile-border debug lines became giant red quads (`TileLOD.*`, `FeatureTracking.NDCBound*`, `Annotations.LineAnnotation`) and pitched circles were mis-placed. Fix: remove the five stray `drape_tile` fields — the shader already applies the *global* `paintParams.drape_tile`. `line-color/` and `line-width/` groups go from 3 and 2 failures to **0**, and 17 of the 18 failing tests pass.
3. **Telemetry: texture-upload stats.** `src/mln/webgpu/texture2d.cpp` never bumped `RenderingStats::numTextureUpdates`/`textureUpdateBytes` (GL, Vulkan and Metal all do), so `ColorRelief.UploadsDEMTextureOncePerTile` tripped its "the test proves nothing" guard even though the DEM texture is uploaded. Fix: increment both stats in `upload()` and `uploadSubRegion()`; the test passes in 38 ms.

After all three: wgpu unit suite with the CI filter **1157 passed, 0 failed**, and the full wgpu render suite **1368 passed, 0 failed, exit 0** (smaller total than #4534 — this branch has no globe/sky fixtures and adds terrain ones).

#### #4533 (globe) — Metal re-measure

`cmake --preset macos-metal` in `~/dev/tmp/mln-pr4533`, then
`build-macos-metal/mbgl-render-test-runner -p metrics/macos-xcode11-release-style.json -f render-tests/projection/globe/`:
**71 passed + 1 ignored, 0 failed**, including `projection/globe/fill-seams/checkerboard` — the
repo's expectation for that test is satisfied on Metal. This matches the earlier Linux finding that
the RADV failure was a tolerance/threshold issue (10 mismatched pixels vs 9.83 allowed), not a
visible seam.

#### Dawn — both PRs re-run locally (2026-10-22)

The Dawn jobs were only mined from CI before; they are now built and run here. `vendor/dawn.cmake`
`FetchContent`s Dawn `v20260210.203301` into `vendor/dawn` (≈1.8 GB, `DAWN_FETCH_DEPENDENCIES=ON`)
and adds it to the same tree, so:

- `cmake --preset macos-webgpu-dawn -DCMAKE_OSX_ARCHITECTURES=arm64` — first configure fetched Dawn
  in ≈80 s; later worktrees reuse the fetched tree (and ccache, `CCACHE_NOHASHDIR=1`
  `CCACHE_BASEDIR=~/dev/tmp`) so configure is ≈10 s and the Dawn build ≈3 min.
- No `go` was needed, unlike the CI workflow (which installs `python@3.11 go`): brew `python@3.15`
  ran `fetch_dawn_dependencies.py` unaided.
- Render tests need the metrics directory to exist: `mkdir -p metrics/macos-webgpu-dawn` before
  `mbgl-render-test-runner --manifestPath metrics/macos-webgpu-dawn.json`.

| PR | Dawn before (CI) | Dawn after the local fixes |
|---|---|---|
| #4534 sky | Run WebGPU render tests: 1484 passed, 84 ignored, **1 failed** — `render-tests/sky/atmosphere-globe` | `-f render-tests/sky/` **3/3** (incl. `atmosphere-globe`); unit **1257 pass / 0 fail**; render **1485 pass / 0 fail** (5 passed-but-ignored, 84 ignored) |
| #4190 terrain | Run unit tests: the **14 image-diff failures** listed above | the same 14-test filter **14/14 pass**; unit **1157 pass / 0 fail**; render **1368 pass / 0 fail** (4 passed-but-ignored, 94 ignored) |

No abort, panic or failure line in any of the four logs, and the totals match the wgpu runs exactly —
so the bugs were backend-agnostic WGSL/generated-header mistakes, not Dawn/wgpu divergence, and
`sky/atmosphere-globe` is fixed by the same two `sky.hpp` edits. Evidence:
`/tmp/pr4190-{unit,render}-dawn-full.log`, `/tmp/pr4534-{unit,render}-dawn-full.log`, render HTML in
`metrics/macos-webgpu-dawn.html`.

**Local only**: the three worktrees are experiments; the fixes are uncommitted and nothing was pushed. The diffs are saved as `~/dev/tmp/webgpu-pr-fixes/pr4534-webgpu-wgsl.patch` and `~/dev/tmp/webgpu-pr-fixes/pr4190-webgpu.patch` (`git diff` in `~/dev/tmp/mln-pr4534` / `~/dev/tmp/mln-pr4190`). As of 2026-10-23 `~/dev/tmp/mln-pr4190` also carries the uncommitted `vendor/dawn.cmake` one-liner (`TINT_BUILD_TESTS OFF`, next-actions 3) and the `platform/ios/src/MLNMapView+WebGPU.mm` include (next-actions 11a).

### iOS / Xcode (works — 2026-10-23, simulator only)

Machine changes on the Mac mini (one-off; repeat if this Mac is reimaged):
`xcodebuild -runFirstLaunch` — it had been returning **69**, Xcode's components were never installed, so
`CoreSimulator.framework` was missing and every iOS CMake preset died in compiler detection — then
`xcodebuild -downloadPlatform iOS` (iOS 27.0 + 27.1 simulator runtimes, ~16 min, disk 88 → 71 GB); and
`brew install bazelisk`, because two iOS phase scripts shell out to `bazel` (the repo's `.bazelversion`
pins 8.6.0, fetched on first use). Verify: `xcodebuild -checkFirstLaunchStatus` → 0,
`xcrun simctl list runtimes` → 27.0/27.1, `cmake --preset ios-webgpu-dawn` configures in ~78 s.

- Build from worktree `~/dev/tmp/mln-pr4190` (presets default to the **simulator**):
  `cmake --preset ios-metal` / `ios-webgpu-dawn`, then
  `cmake --build build-ios-webgpu-dawn --target mbgl-core ios-sdk-static app`. `ios-metal` builds clean
  (`libmbgl-core.a` + fat `ios-sdk-static.framework` + ObjC demo `app`); `ios-webgpu-dawn` needs the
  local uncommitted one-line `#import <mln/gfx/context.hpp>` in `platform/ios/src/MLNMapView+WebGPU.mm`
  (next-actions 11a). Uncommitted in that worktree now: the three WebGPU shader/stat fixes, this include,
  and the shared `vendor/dawn.cmake` `TINT_BUILD_TESTS OFF` one-liner (next-actions 3).
- Blocked: this Xcode 27.1 install has **no `Simulator.app`**, so simulator screenshots stay blank
  (needs an Xcode repair) — a text-only simulator test is unaffected
  (`bazel test //platform/ios/test:ios_test --//:renderer=metal`, heavy, builds its own SDK). Device runs
  need Apple ID signing, not set up. Detail: [macOS verification → iOS on this Mac](../verification/macos.md#ios-on-this-mac-toolchain-fixed-2026-10-23).

## Next actions (ordered)

1. ~~**Linux**: build/test #4533/#4534/#4190; run `fill-seams` and `raster-warped`~~ **Done 2026-10-21**: all three build, unit tests all pass; `raster-warped` is Windows-only; `fill-seams/checkerboard` fails on both Windows and Linux/RADV but by one pixel (10 mismatched vs 9.83 allowed) against the Metal expectation, and passes on lavapipe. Diffs saved. Full render suites also finished: #4534 matches #4533's two failures; #4190 has only the pre-existing `fill-extrusion-pattern/tile-buffer`.
2. ~~**macOS WebGPU**~~ **Done 2026-10-22**: rebuilt all three PR branches locally (wgpu **and** Dawn). Five bugs fixed in the PR worktrees — #4534: `target` reserved keyword + duplicate `PI` (abort → full render suite 1485/0); #4190: duplicate `GlobalPaintParamsUBO` in `circle.hpp` (abort), stray `drape_tile` fields bloating the WebGPU `line.hpp` drawable/props structs (17 of 18 image diffs), and missing texture-upload stats in `src/mln/webgpu/texture2d.cpp` (last unit failure) → unit 1157/0, render 1368/0. Both also built against Dawn (`macos-webgpu-dawn`): CI's 14 unit failures and `sky/atmosphere-globe` pass, totals identical to wgpu. #4533 on Metal: globe group 71 passed + 1 ignored, `fill-seams/checkerboard` passes. Uncommitted, nothing pushed; see [macOS WebGPU](#macos-webgpu--reproduced-and-fixed-2026-10-22).
3. **Unblock `main`'s red `ios-build-webgpu-dawn`** (found 2026-10-22, **verified locally 2026-10-23**):
   add `set(TINT_BUILD_TESTS OFF CACHE BOOL "Disable Tint tests" FORCE)` to `vendor/dawn.cmake` beside the
   existing `DAWN_BUILD_TESTS OFF`. Dawn defaults `TINT_BUILD_TESTS` to **ON**
   (`vendor/dawn/CMakeLists.txt:249`; only Emscripten forces it off), so the fork already-disabled
   `DAWN_BUILD_TESTS` does not stop `vendor/dawn/third_party/CMakeLists.txt:90`
   (`if ((DAWN_BUILD_TESTS OR TINT_BUILD_TESTS) AND NOT TARGET gmock)`) from pulling in googletest at
   line 91. Verified by pointing `DAWN_GOOGLETEST_DIR` at an **empty** directory, which reproduces `main`'s
   failure verbatim — `CMake Error at vendor/dawn/third_party/CMakeLists.txt:91 … does not contain a
   CMakeLists.txt file` with `-- Tint build tests: ON` — and, with the one-line fix, the same configure
   returns 0 and prints `-- Tint build tests: OFF`. The canonical `build-ios-webgpu-dawn` (whose cache held
   `TINT_BUILD_TESTS=ON`) reconfigures and rebuilds `mbgl-core` + `ios-sdk-static` to
   `** BUILD SUCCEEDED **`; `build-macos-webgpu-dawn` reconfigures with `TINT_BUILD_TESTS:BOOL=OFF` and
   ninja reports **no work to do**, i.e. the Dawn libraries we link are bit-for-bit unaffected — nothing we
   build consumes Tint's tests (the one relevant target, `tint_lang_msl_validate`, is guarded by
   `if(TARGET …)` at `vendor/dawn.cmake:120`). The fix removes the requirement whatever the reason CI's
   googletest was empty. Applied **locally, uncommitted** in `~/dev/tmp/mln-pr4190`. **Raise it
   separately**, since it affects `main` and every WebGPU-Dawn job, not just our PRs; details in
   [macOS verification](../verification/macos.md#dawns-tint_build_tests--mains-red-ios-dawn-job-2026-10-23).
4. **Hand `#4534`'s iOS fix to the author**: `platform/darwin/test/MLNSkyTest.mm.ejs:6` imports
   `<Mapbox.h>`; it must be `<MapLibre.h>` like `MLNLightTest.mm.ejs:8`, otherwise
   `//platform/ios/test:ios_test` fails to build. Also worth asking a maintainer to approve that PR's
   pending runs (all `action_required` since 2026-10-21).
5. **Post one consolidated test report**: #4533 (seams + platform), #4534 (Windows Vulkan render pass; the two WGSL bugs; the `Mapbox.h` iOS build failure), #4190 (Windows terrain tests pass; CI Windows job failures are platform tests; iOS Dawn failure is pre-existing on `main`).
6. **Qt wrapper**: adapt the 63-commit QMapLibre API to the upstream core, split into focused `maplibre-native-qt` PRs, coordinate with maintainers.
7. **Unique core pieces**: verify the terrain-camera ray scan against #4190's `TerrainCamera`/#4711; then RTT pool/pole caps if still gaps. Target `feature/terrain-3d`.
8. **Existing PRs**: #4752 review/CI, #323 CI approval, #326.
9. **Design proposal only** if `TerrainPass`/`terrain_stitch` is materially better than `RenderTerrain`; write a comparison for the TSC first.
10. **iPhone (deferred; iOS toolchain fixed 2026-10-23)**: QMapLibre *does* have upstream iOS support (`cmake/presets/iOS.json`, Qt6 toolchain, `MLN_WITH_METAL=ON`, deployment target 17.0) and the Mac has Qt's `ios_device` kit, so MapLibreEarth-on-device (real device Metal for the fork) and upstream's bazel-built `RenderTest`/`CppUnitTests` iOS schemes are both plausible. The Xcode gap is **fixed** (`xcodebuild -runFirstLaunch` + `-downloadPlatform iOS` → iOS 27.0/27.1 simulator runtimes, `ios-*` presets configure in ~78 s) and **bazel is now installed** (`brew install bazelisk`, 2026-10-23; the repo pins bazel 8.6.0), so the CMake iOS build runs: `ios-metal` builds core + SDK + demo app, `ios-webgpu-dawn` builds once the missing include in item 11(a) is applied. Still missing for a *device* run: Apple ID signing (not set up as of 2026-10-23 — a free personal team would do). For a *simulator* run there is no visual capture on this Mac yet (no `Simulator.app`, item 11). Details: [macOS verification](../verification/macos.md#ios-on-this-mac-toolchain-fixed-2026-10-23).
11. **iOS gaps found while building locally 2026-10-23** (all pre-existing on `main`, each hidden by another blocker; details in [macOS verification](../verification/macos.md#what-the-ios-build-revealed-2026-10-23)): (a) `platform/ios/src/MLNMapView+WebGPU.mm` never includes `mln/gfx/context.hpp`, so `context.reset()` on `unique_ptr<mln::gfx::Context>` cannot compile — one-line fix, applied **locally, uncommitted** in the `#4190` worktree; worth upstreaming together with the Dawn configure fix (item 3), since that configure failure is the only reason CI has not seen it; (b) `platform/ios/app` cannot build with `MLN_WITH_WEBGPU` — it needs the `platform/darwin/app` include directory that only `custom-layer-examples` provides, and `darwin.cmake` skips that target for WebGPU; (c) the CMake ObjC demo `app` crashes on launch against the iOS 27.1 SDK (legacy lifecycle, `_UIApplicationRuntimeIssueForNoSceneLifecycleAdoption`) — upstream's current iOS app is the Swift `app-swift` built by bazel. Also: this Xcode 27.1 install has **no `Simulator.app`**, so simulator screenshots are all-black; repairing Xcode is separate work.

## Guardrails

- No competing full implementation; no 58-patch dump.
- Keep MapLibreEarth on 13.6.1 until upstream features land.
- GL JS is the reference; disclose AI use; each PR needs tests and a platform statement.

## Open questions

- ~~Are the two Windows/Vulkan seam failures platform-specific or a stale globe snapshot?~~ **Answered 2026-10-21**: `raster-warped` is Windows-only (passes on Linux/RADV); `fill-seams/checkerboard` reproduces on Windows **and** Linux/RADV but is a one-pixel threshold miss (10 mismatched vs 9.83 allowed) against the Metal-rendered expectation, and passes under lavapipe — an expectation-coverage gap, not a stale snapshot.
- Does #4190 already cover the terrain-camera ray scan (it has `TerrainCamera` tests and #4711)?
- ~~Is the sky shader's `target` identifier the cause of #4534's wgpu abort, and is `GlobalPaintParamsUBO` really emitted twice in #4190's terrain WGSL (or is it Dawn/wgpu divergence)?~~ **Answered 2026-10-22**: yes to both, and it is not Dawn/wgpu divergence — the same fixes make the Dawn builds green with totals identical to wgpu (Dawn subsection above).
- Which Qt API shape should the upstream core expose?
- ~~Which Linux build/deps path is fastest for the PR branches?~~ **Answered 2026-10-21**: worktrees of the existing clone + hard-linked submodules (no download, no junctions), Release Vulkan Ninja build ≈2.5 min per branch — see Linux pickup above.

## Related

- [Contribution plan](upstream-contribution-plan.md) · [Upstream PRs](../references/upstream-prs.md) · [Upstream issues](../references/upstream-issues.md) · [D6](../decisions/d6-draft-upstream-prs.md)
- [Linux tests](../verification/linux-tests.md) · [macOS tests](../verification/macos.md) · [Windows](../verification/windows.md) · [Android](../verification/android.md)
