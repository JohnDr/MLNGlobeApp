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

> Live tracker, **updated 2026-10-23**. Strategy: join the existing upstream feature branches, report test results, and contribute focused gaps (Qt/QMapLibre wrapper first). **Do not** submit the 58-patch fork stack or a competing globe/terrain/sky implementation.

**Maintenance rule — keep this current.** This file and [Next steps](../next-steps.md) are the two live
hand-off documents; update **both** at the end of every session, before switching machines or ending a
session, even when the session only verified something. In this file: the branch/CI table, the per-platform
result sections, [Next actions](#next-actions-ordered) (tick off, renumber, or replace rather than leaving a
done item looking pending) and [Open questions](#open-questions). In [Next steps](../next-steps.md): its
"RESUME HERE — authoritative" block. Then record the session in [Project history](../history.md) and the
[wiki log](../log.md). A fact that is only in a chat does not exist for the next session.

## Strategy (agreed 2026-10-20)

1. **Join the existing branches** — test them on Windows/Android/Linux and report; they explicitly need testers.
2. **Focused PRs** against `feature/terrain-3d` / the globe branch for gaps. The unique, working stack is the **Qt/QMapLibre wrapper + app API** (63 commits in `maplibre-native-qt`), which the core PRs need.
3. **Only if the implementation is materially different/better**: write a comparison/design proposal for the TSC first; no competing PRs.

## Upstream landscape

| Effort | Owner | Branch / base | State | Notes |
|---|---|---|---|---|
| Globe #4533 | johncarmack1984 | `phased/12h` → `main` | open, not draft, `MERGEABLE`/`BLOCKED` (review required); CI green — 53 pass, 0 fail (`gh` read 2026-10-23) | Issue #3161; design proposal #4525 closed; 673 files. |
| Sky #4534 | ClayWarren | `codex/sky-style-spec-4414`, stacked on globe | open, not draft, `MERGEABLE`/`BLOCKED` (**no longer `DIRTY`**); CI stuck since 2026-10-21 — all 10 workflows `action_required`, nothing has run on this head (`gh` read 2026-10-23) | Issue #4414; Metal/Vulkan render pass. Two WebGPU WGSL bugs found + fixed locally 2026-10-22 (wgpu **and** Dawn now green locally, below). Linux/Vulkan executed at the **current head `38dac5b8`** (2026-10-23): unit 1245/1245, render 1337 passed / 2 failed over 184 groups — unchanged from `2a85b5d`. Last *CI*-executed head (2026-10-16): only `ios-build` failed, because the new `MLNSkyTest.mm.ejs` imports `<Mapbox.h>` (`ios_test` failed to build) — one-line PR bug, below; Android CI passed. Stacked on an **older globe head** — `phased/12h...codex/sky-style-spec-4414` is `diverged` (5 globe commits behind). |
| Terrain #4190 | NathanMOlson | `feature/terrain-3d` → `main` | **draft**, `CONFLICTING`/`DIRTY` (`gh` read 2026-10-23: unchanged) | Maintainer `louwers` coordinating; follow-ups #4558, #4790, #4791, #4801, #4809, #4810 target `feature/terrain-3d`; issue #252. Three WebGPU bugs found + fixed locally 2026-10-22 (wgpu **and** Dawn now green locally, below). Its iOS Dawn CI failure is pre-existing on `main` (below). |
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
- Windows host: Intel Iris Xe, driver `32.0.101.7088`, Windows 11 `26300`.
- **#4534 sky** (re-ran at `38dac5b8`, 2026-10-23): render tests **3/3 pass** on Windows/Vulkan — `sky/basic`, `sky/atmosphere-globe`, `sky/zoom-expression`.
- **#4533 globe** (full 53-group sweep through #4534 `38dac5b8`, 2026-10-23; #4533 itself is `ff96700`): **2 unique failures** at the new head, the head merge added none:
  - `projection/globe/fill-seams/checkerboard`
  - `projection/globe/raster-warped`
    Ignored: `debug-tile-borders`, `fill-planet-pole`, `fill-planet-pole-top`, `fill-planet-tiles`, 2 in `antimeridian-overdraw`. All other groups pass.
- **Windows `raster-warped` quantified**: 284 mismatched pixels of 262144 (`allowed` 39.32, 7.2×); passes on Linux/RADV. The diff is horizontal edge lines — a Windows/Vulkan (Intel Iris Xe) rasterization difference, not AA-only.
- **Windows `checkerboard` quantified**: independent mapbox pixelmatch (JS 5.3.0, threshold 0.1285) counts 8–9 of 65536 against `allowed` 9.83; the runner's C++ pixelmatch crosses the threshold (Linux JS counted 10), so this is a one-pixel threshold miss, not a visible seam. Diffs saved in `%LOCALAPPDATA%\Temp\opencode\consolidated-report\windows`.
- **Server suites** (`USE_CPP_TEST_SERVER` is defined on WIN32): HTTPFileSource **11/11**, MainResourceLoader **20/20**, MapSnapshotter **6/6**, OnlineFileSource **21/23** — `ConnectionError` and `NetworkStatusChangePreempt` fail with `Reason::Temporary` instead of `Connection` and then hang; **58/60 pass**, a Windows/libcurl mapping issue, not a PR regression. The full suite also stops on `LocalFileSource.InvalidUTF8Path` (platform).

### Android (S23, serial `RFCW910087W`)

Built from the PR CI `android-ui-test-vulkan` artifacts (package `org.maplibre.android.testapp`):

- **#4533**: `GlobeActivity` renders correctly. **PASS**.
- **#4190**: `TerrainActivity` renders pitched 3D terrain with draped imagery. **PASS**.
- **#4534**: no Sky activity; `GlobeActivity` shows no atmosphere. Not visually verifiable; CI failures above stand.

### Linux (Ubuntu 26.04, Vulkan/RADV, AMD Radeon 780M) — 2026-10-21, re-run at the #4534 head 2026-10-23

All three branches built as worktrees of the local clone (`~/dev/tmp/mln-pr4533|pr4534|pr4190`), submodules populated from the shared object store (no re-download), Release + `MLN_WITH_VULKAN=ON`/X11 (no GLFW/OpenGL), Ninja, build trees `~/dev/tmp/build-pr45xx-vk`. Core build ≈2.5 min; the existing [Linux tests](../verification/linux-tests.md) path works unchanged for PR branches.

**Environment (for the report's reproducibility note):** RADV `AMD Radeon 780M (RADV PHOENIX)`, Mesa **26.0.8-1ubuntu0.3**, Vulkan **1.4.335**, LLVM 21.1.8; lavapipe = `llvmpipe` in the same Mesa package, selected with `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json`; Ubuntu 26.04, 16 cores.

**Unit tests** (`mbgl-test-runner`, Vulkan, RADV; one runner at a time — fixed HTTP test port 3000):

| Branch | Head | Result |
|---|---|---|
| #4533 globe | `ff96700` | **1243 tests / 145 suites — all pass**, 4 disabled |
| #4534 sky | `2a85b5d` → **`38dac5b8`** (2026-10-23) | **1245 tests — all pass**, 4 disabled (same count at the new head; the merge from `main` added no tests in this configuration) |
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
- **#4534 re-run at the current head `38dac5b8` (2026-10-23)**: unit **1245/1245**, full suite **1337 passed / 2 failed / 62 ignored** over 184 groups — still only `fill-extrusion-pattern/tile-buffer` (pre-existing) and `checkerboard`. `actual.png` md5 is again `127999d3…`, i.e. the merge from `main` did not change the rendered frame; `sky/` stays **3/3**. Build tree `~/dev/tmp/build-pr4534-vk`, per-group logs `~/dev/tmp/pr4534-head-render/summary.txt`.
- Full suite, #4190 (184 groups): **only** `fill-extrusion-pattern/tile-buffer` (the pre-existing baseline failure). This branch is based on `main` and carries no globe (`projection/globe`) or `sky/` fixtures, so those groups do not exist here — its `projection` group is the pre-globe four tests, all passing.
- **Linux WebGPU (Dawn + wgpu) done 2026-10-23** for all three branches, including the #4533 control: unit
  **1258/1258** (#4533), **1260/1260** (#4534), **1160/1160** (#4190) on both backends; the render residuals are
  identical on #4533, i.e. baseline. See [§ Linux WebGPU](#linux-webgpu-dawn--wgpu--2026-10-23).
- The Linux WebGPU metric profiles reference a **missing** `metrics/ignores/platform-linux-webgpu.json`, so
  they exit 5 as committed (still 404 on upstream `main`); raise it separately.

### Linux WebGPU (Dawn + wgpu) — 2026-10-23

Linux CI has **no** WebGPU jobs (`linux-ci.yml` matrix is Vulkan, OpenGL, OpenGL+rust), so these were the
first Linux runs of the WebGPU backends for all three PR branches. They were built with the
[local fix set](../references/local-fixes.md) applied (uncommitted), on the same machine as the Vulkan runs.

**Build notes (Linux-specific):**

- Dawn: the fork fetches `vendor/dawn` through `FetchContent` from GitHub; the clone aborted three times
  (`early EOF` / `invalid index-pack`) and codeload tarballs truncated at \~22 MB. A **googlesource archive**
  of the same tag (`v20260210.203301`, commit `c20ab4b…`) over HTTP/1.1 worked; one checkout is symlinked
  into both worktrees.
- Configure needs `-DMLN_WITH_GLFW=OFF -DDAWN_USE_GLFW=OFF -DDAWN_USE_X11=OFF` on this box (no
  `libxrandr-dev` / `libx11-xcb-dev`; Dawn's own GLFW/samples are unused here).
- The `TINT_BUILD_TESTS` fix (bug 5) **is real on Linux too**: without it the configure log says
  `-- Tint build tests: ON` and Dawn's bootstrapper fetches googletest; with it, `-- Tint build tests: OFF`.
  Here the dependency fetch succeeds, so missing googletest is *not* fatal — the Mac's fatal failure is
  fetch-dependent — but the fix is still correct and required for the no-fetch path.
- wgpu: `wgpu-native` builds from source with the toolchain pinned by its `rust-toolchain.toml`
  (**Rust 1.91.1**), and bindgen needs
  `BINDGEN_EXTRA_CLANG_ARGS=-I/usr/lib/gcc/x86_64-linux-gnu/15/include -I/usr/include/x86_64-linux-gnu`
  (libclang-21 is installed here without clang's resource headers).
- **Upstream defect found:** `metrics/linux-webgpu-dawn.json` and `metrics/linux-webgpu-wgpu.json` both list
  `ignores/platform-linux-webgpu.json`, which **is not in the repository** (only
  `platform-macos-webgpu.json`, on `main` and on all three PR heads). Every group exits **5** with
  `Invalid path is provided inside the manifest file`. The suites were run with an empty, untracked
  `metrics/ignores/platform-linux-webgpu.json` (`{}`).

**Results** (unit = `mbgl-test-runner`; render = 183 groups on #4533, 184 on #4534/#4190, one process per group):

| Branch | Backend | Unit | Render (passed / failed / errored / ignored) |
|---|---|---|---|
| #4533 `ff96700` | Dawn | **1258/1258** | **1334 / 25 / 3 / 56** |
| #4533 `ff96700` | wgpu | **1258/1258** | **1331 / 28 / 3 / 56** |
| #4534 `38dac5b8` | Dawn | **1260/1260** | **1336 / 26 / 3 / 56** |
| #4534 `38dac5b8` | wgpu | **1260/1260** | **1334 / 28 / 3 / 56** |
| #4190 `c6b31b7` | Dawn | **1160/1160** | **1244 / 27 / 3 / 66** |
| #4190 `c6b31b7` | wgpu | **1160/1160** | **1243 / 28 / 3 / 66** |

- **#4533 is the control** (no WebGPU changes): its Dawn failure set is a **strict subset** of #4534's —
  \#4534 adds only `feature-state/symbol-paint`, #4190 adds `feature-state/composite-expression` and
  `global-state/with-feature-state/basic` on top. The **14 "not ignored anywhere" diffs are identical on
  \#4533**, so they are baseline Linux-WebGPU behaviour, not caused by either PR. Those three extras are also
  **flaky, not branch-specific**: re-running them 3× per branch gave e.g. #4534 `symbol-paint` 3,0,0 and
  \#4190 `composite-expression` 3,3,0 (they flip between runs; all three pass 3/3 on #4533).

- `projection/globe/fill-seams/checkerboard` **passes on Linux WebGPU** (both backends), where RADV Vulkan
  fails it by 10 px — the WebGPU output matches the Metal-rendered expectation.

- **Unit suites are fully green on both backends.** With wgpu the suite must be run in per-suite processes:
  in one process it aborts around test \~90 with `radv/amdgpu: Not enough memory for command submission` →
  `wgpuQueueSubmit: Validation Error … Parent device is lost` — a wgpu-native/RADV per-process resource
  leak, not a failing test. Every one of the 145 (#4534) / 140 (#4190) suites passes in a fresh process
  (`[       OK ]` count equals the full test count). Dawn runs end-to-end in one process.

- The **3 errors** in all six runs are `text-font/{burmese,khmer,devanagari}` — the same pre-existing Linux
  glyph-range gap (`Failed to load glyph range 4096-4351 for font stack Noto Sans Regular`) as the
  Vulkan/OpenGL baseline.

- The same wgpu leak also hit **render**: #4190's `combinations` group (127 tests in one process) aborted
  twice with `amdgpu: The CS has been rejected … (-12)` (re-run one test per process: 121 passed / 3 failed /
  3 ignored, identical to Dawn), and #4533's `combinations` and `projection` groups aborted once each — both
  completed when run on their own (combinations 124 passed / 3 failed, projection 74 passed + 1 ignored). The
  counts above include those re-runs.

- **Failures split in two.** (a) Tests already ignored on another platform, i.e. what the missing
  `platform-linux-webgpu.json` presumably carries: `fill-extrusion-pattern/*` (8),
  `fill-outline-color/{property,zoom-and-property}-function`, `fill-extrusion-color/function`,
  `regressions/mapbox-gl-js#5642` and `#7066`, `icon-text-fit/textFit-grid-long`. (b) **Not ignored on any
  platform** — the residual Linux-WebGPU image diffs, **identical on the #4533 control**:
  `fill-extrusion-base/{default,function,literal,negative}`,
  `fill-extrusion-translate-anchor/{map,viewport}`, `within/{filter-with-inlined-geojson,paint-line}`,
  `combinations/{heatmap,hillshade,raster}-translucent--*` and the three `text-font` errors; wgpu adds the two
  flaky `fill-pattern/{uneven-pattern,wrapping-with-interpolation}`.

- The same tests **pass on Vulkan** on this machine and on macOS WebGPU, so this is a **Linux-WebGPU image
  mismatch** (alpha/AA compositing of translucent layers and extrusions against the shared
  `expectations/platform-linux`), not a branch regression. It must be investigated before anyone claims
  Linux WebGPU parity; macOS hides part of the same class behind `platform-macos-webgpu.json`.

- Both backends log `maxDynamicUniformBuffersPerPipelineLayout artificially reduced from 500000 to 16`
  (portability clamp; harmless, but worth knowing).

Per-group summaries and failing-test lists for all six runs:
`~/dev/tmp/upstream-report-evidence/webgpu/`.

**Reproducing (Linux, verified 2026-10-23):**

```bash
# Dawn sources: one checkout shared by all worktrees (the FetchContent git clone fails here)
curl --http1.1 -L -o /tmp/opencode/dawn.tar.gz \
  https://dawn.googlesource.com/dawn/+archive/c20ab4b1a2ca72eefedae3d831f058a577837df8.tar.gz
mkdir -p ~/dev/tmp/dawn-src && tar -xzf /tmp/opencode/dawn.tar.gz -C ~/dev/tmp/dawn-src

cd ~/dev/tmp/mln-pr4534                     # ff96700 / 38dac5b8 / c6b31b7
ln -sfn ~/dev/tmp/dawn-src vendor/dawn
printf '{}\n' > metrics/ignores/platform-linux-webgpu.json   # missing upstream (see above)
export PATH=$HOME/Qt/Tools/Ninja:$HOME/.cargo/bin:$PATH
COMMON="-G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DMLN_WITH_WEBGPU=ON -DMLN_WITH_WAYLAND=OFF \
  -DMLN_WITH_X11=ON -DMLN_WITH_METAL=OFF -DMLN_WITH_OPENGL=OFF -DMLN_WITH_VULKAN=OFF \
  -DMLN_WITH_GLFW=OFF -DMLN_TEXT_SHAPING_HARFBUZZ=OFF -DMLN_WITH_WERROR=OFF \
  -DMLN_WITH_CLANG_TIDY=OFF -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON"

cmake -S . -B ~/dev/tmp/build-pr4534-webgpu-dawn $COMMON -DMLN_WEBGPU_IMPL_DAWN=ON \
  -DDAWN_USE_GLFW=OFF -DDAWN_USE_X11=OFF
BINDGEN_EXTRA_CLANG_ARGS="-I/usr/lib/gcc/x86_64-linux-gnu/15/include -I/usr/include/x86_64-linux-gnu" \
  cmake -S . -B ~/dev/tmp/build-pr4534-webgpu-wgpu $COMMON -DMLN_WEBGPU_IMPL_WGPU=ON
cmake --build ~/dev/tmp/build-pr4534-webgpu-dawn --target mbgl-test-runner mbgl-render-test-runner -j 8
cmake --build ~/dev/tmp/build-pr4534-webgpu-wgpu --target mbgl-test-runner mbgl-render-test-runner -j 8

# tests, from the worktree root
~/dev/tmp/build-pr4534-webgpu-dawn/mbgl-test-runner     # one process is fine
# wgpu: one gtest suite per process (see the RADV leak above), and the runtime lib:
export LD_LIBRARY_PATH=$PWD/vendor/wgpu-native/target/x86_64-unknown-linux-gnu/release
~/dev/tmp/build-pr4534-webgpu-wgpu/mbgl-test-runner --gtest_filter='<Suite>.*'
# render: one group per process, -p metrics/linux-webgpu-{dawn,wgpu}.json
```

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

### CI state re-read with `gh` (2026-10-23)

Read again on **2026-10-23**. **No PR head has moved and no run has executed since the 2026-10-22 check** —
the three heads are exactly the ones in the local worktrees, so everything reproduced and fixed here still
corresponds to what upstream CI sees.

| PR | Head | Merge state | Checks on record | Last run |
|---|---|---|---|---|
| #4533 | `ff96700517b9` | `MERGEABLE`, `BLOCKED` (review required) | **53 pass, 0 fail**, 1 skipped (`Deploy`), 3 never-report (`codecov/patch`, `codecov/project`, `pre-commit.ci`) | 2026-10-20 |
| #4534 | `38dac5b8a4ec` | `MERGEABLE`, `BLOCKED` — **no longer `DIRTY`** | only `labeler` (pass) + `pre-commit.ci` (pending): **no CI has run on this head** | 10 workflows `action_required` since 2026-10-21T16:48Z |
| #4190 | `c6b31b76056a` | **draft**, `CONFLICTING`, `DIRTY` | 39 pass, **7 fail**, 1 pending | 2026-10-19 |

- **#4534's 10 `action_required` workflows** are `android-ci`, `gh-pages-mdbook`, `ios-ci`, `linux-ci`,
  `macos-ci`, `node-ci`, `ohos-ci`, `qt-ci`, `rust-ci` and `validate-scripts`, all created
  2026-10-21T16:48:55Z on `38dac5b8a4ec`. **No CI has executed on the current head**; the most recent
  executed head is 2026-10-16 `2a85b5d66848` (the branch's earlier heads carry 13 successful and 27 failed
  runs, plus a 2026-09-28 `action_required` set on `5f8dbc2f9f08`). Approval — and pushing the fixes — are
  not ours to do.
- **New since the 2026-10-22 read:** #4534 now reports `MERGEABLE`/`BLOCKED` instead of `CONFLICTING`/`DIRTY`,
  so it merges cleanly against its base and is blocked only on review/approval. It is stacked on an **older
  globe head**: `phased/12h...codex/sky-style-spec-4414` is `diverged`, 89 ahead / **5 behind**, so the globe
  branch gained five commits after the sky branch was cut — a rebase onto the current globe head is the
  author's call.
- **#4190's 7 failures are unchanged**, and are exactly the ones analysed above: `test (windows-2022)`,
  `test (windows-11-arm)`, `macOS WebGPU (Dawn)`, `macOS WebGPU (wgpu)`, `ios-build-webgpu-dawn`,
  `android-build-webgpu-wgpu` and the aggregate `android-ci-result`. The two macOS WebGPU jobs are fixed
  locally (unpushed); `ios-build-webgpu-dawn` is the pre-existing `main` bug.

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
| `Map.*` | **hangs** — headless command buffers are allocated per pass and never committed, so the Metal queue's in-flight slots run out after \~32 frames and `-[MTLCommandQueue commandBuffer]` blocks. Root-caused and filed as [#4822](https://github.com/maplibre/maplibre-native/issues/4822); the local `if (!commandBuffer)` guard makes `Map.*` 55/55, not shipped as a fork patch |
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

- PR clone: `C:\hda\dev\tmp\maplibre-native-pr`; branches `pr4533`, `pr4534`, `pr4190`; currently on **pr4534** — the branch moved from `2a85b5d` to **`38dac5b8`**, and the Windows Vulkan results above were re-run there (Linux re-ran it at the new head: unit 1245, render unchanged; the WebGPU runs use the same head); build tree `build-windows-vulkan`.
- To refresh a branch head on Windows: `git fetch https://github.com/maplibre/maplibre-native refs/pull/4534/head:pr4534` (same pattern for 4533/4190) after clearing the vendor/platform reparse points, then `git switch pr4534` and recreate them.
- **Local fix set** (only needed for the WebGPU backends; Vulkan is unaffected): `git apply wiki/references/patches/pr4534-wgsl-and-ios-test.patch` on `pr4534`, `git apply wiki/references/patches/pr4190-webgpu-dawn-ios.patch` on `pr4190`; `pr4533` needs no patch. The `vendor/dawn.cmake` `TINT_BUILD_TESTS` one-liner (in the #4190 patch) is a `main`-side fix and is required for any Dawn build.
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

### Linux (works — updated 2026-10-23)

- Source trees: `git worktree add ~/dev/tmp/mln-pr<NNNN> pr<NNNN>` inside the existing clone `~/dev/projects/maplibre-native` (PR refs fetched with `git fetch https://github.com/maplibre/maplibre-native refs/pull/<n>/head:refs/heads/pr<n>`; submodule pointers are unchanged by all three, so no re-download). Populate submodules by hard-linking the clone's checkouts and pointing each `.git` file at the shared `…/.git/modules/<name>` (helper `/tmp/opencode/link-submodules.sh`).
- Configure: `cmake -B ~/dev/tmp/build-pr<NNNN>-vk -S . -G Ninja -DCMAKE_BUILD_TYPE=Release -DMLN_WITH_VULKAN=ON -DMLN_WITH_X11=ON -DMLN_WITH_GLFW=OFF -DMLN_WITH_OPENGL=OFF -DMLN_WITH_PMTILES=ON` — GLFW defaults ON and then demands `glfw3`.
- Build (`PATH=$HOME/Qt/Tools/Ninja:$PATH`): `ninja -C ~/dev/tmp/build-pr<NNNN>-vk mbgl-test-runner mbgl-render-test-runner mbgl-expression-test` (≈2.5 min, 16 cores).
- Run: unit tests from the source dir, one runner at a time (port 3000); render tests `-p metrics/linux-vulkan.json -f render-tests/<group>/`; all 184 groups via `/tmp/opencode/render-suite.sh <src> <bin> metrics/linux-vulkan.json <outdir>`.
- Force software Vulkan (what CI uses) for AA comparisons: `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json`.
- Qt tests: N/A — none of the three branches touches the Qt wrapper.
- **What is left here:** nothing report-critical. Vulkan is green as recorded above; the **Linux WebGPU** runs
  (all three branches × Dawn/wgpu, with the [local fix set](../references/local-fixes.md) applied) are done and
  in [§ Linux WebGPU](#linux-webgpu-dawn--wgpu--2026-10-23). The **#4533 control** proves the residual image
  diffs are baseline Linux-WebGPU behaviour, not PR defects. Re-run only if a PR head moves.
- Local artifacts in these worktrees that must not be committed: the `vendor/dawn` symlink, the empty
  `metrics/ignores/platform-linux-webgpu.json`, and the fix-set patches. That ignore file is **missing
  upstream** (still 404 on `main`), which is itself a report item.
- Temp helpers (`/tmp/opencode/link-submodules.sh`, `/tmp/opencode/render-suite.sh`) live in that machine's
  temp dir and `/tmp` is wiped on reboot — recreate them from this page if missing.

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

**Local only**: the three worktrees are experiments; the fixes are uncommitted and nothing was pushed. The
portable copy of the whole fix set is now **in the wiki** —
[local fix set](../references/local-fixes.md) + `wiki/references/patches/*.patch` — covering all seven files
(the two WGSL files, `texture2d.cpp`, `vendor/dawn.cmake`'s `TINT_BUILD_TESTS` one-liner, the
`MLNMapView+WebGPU.mm` include and `MLNSkyTest.mm.ejs`). Apply with `git apply` in the matching worktree;
`#4533` needs none. The older Mac-local copies (`~/dev/tmp/webgpu-pr-fixes/`) are superseded.

### iOS / Xcode (works — 2026-10-23: builds for simulator **and** device, runs on the simulator)

Machine changes on the Mac mini (one-off; repeat if this Mac is reimaged):
`xcodebuild -runFirstLaunch` — it had been returning **69**, Xcode's components were never installed, so
`CoreSimulator.framework` was missing and every iOS CMake preset died in compiler detection — then
`xcodebuild -downloadPlatform iOS` (iOS 27.0 + 27.1 simulator runtimes, \~16 min, disk 88 → 71 GB); and
`brew install bazelisk`, because two iOS phase scripts shell out to `bazel` (the repo's `.bazelversion`
pins 8.6.0, fetched on first use). Verify: `xcodebuild -checkFirstLaunchStatus` → 0,
`xcrun simctl list runtimes` → 27.0/27.1, `cmake --preset ios-webgpu-dawn` configures in \~78 s.

- Build from worktree `~/dev/tmp/mln-pr4190` (presets default to the **simulator**):
  `cmake --preset ios-metal` / `ios-webgpu-dawn`, then
  `cmake --build build-ios-webgpu-dawn --target mbgl-core ios-sdk-static app`. `ios-metal` builds clean
  (`libmbgl-core.a` + fat `ios-sdk-static.framework` + ObjC demo `app`); `ios-webgpu-dawn` needs the
  local uncommitted one-line `#import <mln/gfx/context.hpp>` in `platform/ios/src/MLNMapView+WebGPU.mm`
  (next-actions 11a). Uncommitted in that worktree now: the three WebGPU shader/stat fixes, this include,
  and the shared `vendor/dawn.cmake` `TINT_BUILD_TESTS OFF` one-liner (next-actions 3).
- Blocked: this Xcode 27.1 install has **no `Simulator.app`**, so simulator *screenshots* stay blank
  (needs an Xcode repair) — textual simulator runs are unaffected. The upstream iOS test suite now runs here:
  `bazel test //platform/ios/test:ios_test --//:renderer=metal` → **302 tests, 5 skipped, 0 failures** after
  the `Mapbox.h` fix (next-actions 4). Device **builds** work, device **runs** need Apple ID signing (not set
  up) — and an iOS 18 runtime floor makes an iPhone 6 unusable. Detail:
  [macOS verification → iOS on this Mac](../verification/macos.md#ios-on-this-mac-toolchain-fixed-2026-10-23),
  [device build](../verification/macos.md#ios-device-build--2026-10-23).

## Next actions (ordered)

1. ~~**Linux**: build/test #4533/#4534/#4190; run `fill-seams` and `raster-warped`~~ **Done 2026-10-21**: all three build, unit tests all pass; `raster-warped` is Windows-only; `fill-seams/checkerboard` fails on both Windows and Linux/RADV but by one pixel (10 mismatched vs 9.83 allowed) against the Metal expectation, and passes on lavapipe. Diffs saved. Full render suites also finished: #4534 matches #4533's two failures; #4190 has only the pre-existing `fill-extrusion-pattern/tile-buffer`.
2. **~~macOS WebGPU~~** **Done 2026-10-22**: rebuilt all three PR branches locally (wgpu **and** Dawn). Five bugs fixed in the PR worktrees — #4534: `target` reserved keyword + duplicate `PI` (abort → full render suite 1485/0); #4190: duplicate `GlobalPaintParamsUBO` in `circle.hpp` (abort), stray `drape_tile` fields bloating the WebGPU `line.hpp` drawable/props structs (17 of 18 image diffs), and missing texture-upload stats in `src/mln/webgpu/texture2d.cpp` (last unit failure) → unit 1157/0, render 1368/0. Both also built against Dawn (`macos-webgpu-dawn`): CI's 14 unit failures and `sky/atmosphere-globe` pass, totals identical to wgpu. #4533 on Metal: globe group 71 passed + 1 ignored, `fill-seams/checkerboard` passes. Uncommitted, nothing pushed; see [macOS WebGPU](#macos-webgpu--reproduced-and-fixed-2026-10-22).
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
4. **`#4534`'s iOS fix — verified locally 2026-10-23** (was: hand it to the author):
   `platform/darwin/test/MLNSkyTest.mm.ejs:8` imports `<Mapbox.h>`; it must be `<MapLibre.h>` like
   `MLNLightTest.mm.ejs:8`. Reproduced CI's `ios-build` failure here with bazel 8.6.0
   (`MLNSkyTest.mm:5:9: fatal error: 'Mapbox.h' file not found` → `FAILED TO BUILD`), applied the one-line
   fix (generated line 5 becomes `#import <MapLibre.h>`), and the same command then **passes: 302 tests,
   5 skipped, 0 failures** — including all three `MLNSkyTest` cases — so that import is the *only* defect
   behind the red job. Fix is applied **locally, uncommitted** in `~/dev/tmp/mln-pr4534`; run details and
   the Xcode-27.1 simulator-runner quirk are in
   [macOS verification](../verification/macos.md#4534s-ios-test-build-mapboxh--reproduced-and-fixed-2026-10-23).
   Still to do when GitHub scope re-opens: hand it to the author and ask a maintainer to approve that PR's
   pending runs (all `action_required` since 2026-10-21).
5. **Post one consolidated test report — drafted at [upstream-report-drafts](../references/upstream-report-drafts.md), awaiting John's review/go** (nothing has been posted yet — GitHub activity is on
   hold until John says go). All platform data is in: Windows, Android, Linux Vulkan, **Linux WebGPU incl. the
   \#4533 control**, macOS (Metal from CI; WebGPU reproduced and fixed). Include the `Mapbox.h` iOS fix, the
   `TINT_BUILD_TESTS` fix and the missing `platform-linux-webgpu.json` as separate findings. Content: #4533 (seams + platform), #4534 (Windows Vulkan render pass; the two WGSL bugs; the `Mapbox.h` iOS build failure — now reproduced and fixed locally, suite green), #4190 (Windows terrain tests pass; CI Windows job failures are platform tests; iOS Dawn failure is pre-existing on `main`).
6. **Qt wrapper**: adapt the 63-commit QMapLibre API to the upstream core, split into focused `maplibre-native-qt` PRs, coordinate with maintainers.
7. **Unique core pieces**: verify the terrain-camera ray scan against #4190's `TerrainCamera`/#4711; then RTT pool/pole caps if still gaps. Target `feature/terrain-3d`.
8. **Existing PRs**: #4752 review/CI, #323 CI approval, #326.
9. **Design proposal only** if `TerrainPass`/`terrain_stitch` is materially better than `RenderTerrain`; write a comparison for the TSC first.
10. **iPhone (deferred; iOS toolchain fixed 2026-10-23)**: QMapLibre *does* have upstream iOS support (`cmake/presets/iOS.json`, Qt6 toolchain, `MLN_WITH_METAL=ON`, deployment target 17.0) and the Mac has Qt's `ios_device` kit, so MapLibreEarth-on-device (real device Metal for the fork) and upstream's bazel-built `RenderTest`/`CppUnitTests` iOS schemes are both plausible. The Xcode gap is **fixed** (`xcodebuild -runFirstLaunch` + `-downloadPlatform iOS` → iOS 27.0/27.1 simulator runtimes, `ios-*` presets configure in \~78 s) and **bazel is now installed** (`brew install bazelisk`, 2026-10-23; the repo pins bazel 8.6.0), so the CMake iOS build runs: `ios-metal` builds core + SDK + demo app, `ios-webgpu-dawn` builds once the missing include in item 11(a) is applied. The **Qt wrapper itself** now builds for iOS as well (2026-10-23): `cmake --preset iOS-ccache` with the `ios_simulator_arm64` kit plus `-DCMAKE_OSX_ARCHITECTURES=arm64` → **551 steps, 0 warnings, 0 errors**, producing static `libQMapLibre*.a` libs and the `MapLibre` QML module (objects `platform IOSSIMULATOR, minos 17.0, sdk 27.1`); canonical tree `~/dev/tmp/build-maplibre-native-qt-ios-sim`, so the wrapper-side prerequisite for MapLibreEarth-on-iPhone is done — [build-macos](../runbooks/build-macos.md#ios-simulator-library-tree--2026-10-23). The **app** builds and runs there too: a flat, fully static \~54 MB `MapLibreEarth.app` installs and launches on the `iPhone Duo` simulator (stays alive, core Metal shaders compile, `import MapLibre 4.0` resolves from the static plugin), needing one app-side guard — `QProcess::startDetached` does not exist on iOS — and it exposed the wrapper bug in item 12. Both halves also **build for the device** (`ios_device` kit, arm64; trees `~/dev/tmp/build-maplibre-native-qt-ios-device` and `~/dev/tmp/build-MapLibreEarth-ios-device`, installed prefix `~/dev/tmp/install-maplibre-native-qt-ios-device`; the app is `platform IOS, minos 18.0`, unsigned). Deploying is blocked on three things: (i) **no signing identity** on this Mac (`security find-identity -v -p codesigning` → 0, no profiles), (ii) **no iPhone visible** on USB/`devicectl`, and (iii) a hard floor — Qt 6.12's prebuilt iOS libs are `minos 18.0`, so an **iPhone 6 (iOS 12.5.7) cannot run this build**; details in [macOS verification](../verification/macos.md#ios-device-build--2026-10-23). Still missing for a *device* run: Apple ID signing (not set up as of 2026-10-23 — a free personal team would do). For a *simulator* run there is no visual capture on this Mac yet (no `Simulator.app`, item 11). Details: [macOS verification](../verification/macos.md#ios-on-this-mac-toolchain-fixed-2026-10-23).
11. **iOS gaps found while building locally 2026-10-23** (all pre-existing on `main`, each hidden by another blocker; details in [macOS verification](../verification/macos.md#what-the-ios-build-revealed-2026-10-23)): (a) `platform/ios/src/MLNMapView+WebGPU.mm` never includes `mln/gfx/context.hpp`, so `context.reset()` on `unique_ptr<mln::gfx::Context>` cannot compile — one-line fix, applied **locally, uncommitted** in the `#4190` worktree; worth upstreaming together with the Dawn configure fix (item 3), since that configure failure is the only reason CI has not seen it; (b) `platform/ios/app` cannot build with `MLN_WITH_WEBGPU` — it needs the `platform/darwin/app` include directory that only `custom-layer-examples` provides, and `darwin.cmake` skips that target for WebGPU; (c) the CMake ObjC demo `app` crashes on launch against the iOS 27.1 SDK (legacy lifecycle, `_UIApplicationRuntimeIssueForNoSceneLifecycleAdoption`) — upstream's current iOS app is the Swift `app-swift` built by bazel. Also: this Xcode 27.1 install has **no `Simulator.app`**, so simulator screenshots are all-black; repairing Xcode is separate work.
12. **Wrapper iOS bug: `TextureNodeMetal` mutates UIKit off the main thread** (found 2026-10-23 running the app on the simulator; **wrapper-side, not upstream core**): `TextureNodeMetal::render()` (`maplibre-native-qt/src/quick/texture_node_metal.mm:93`) creates its own `CAMetalLayer` and calls `[view.layer addSublayer:]` on `window->winId()`, but `render()` runs on the Qt Quick **render thread**, so iOS logs `[com.apple.UIKit:Assert] Modifying properties of a view's layer off the main thread is not allowed: view <QUIMetalView …>` once per launch (backtrace: `-[CALayer addSublayer:]` → `QMapLibre::TextureNodeMetal::render(QQuickWindow*)` → `MapQuickItem::updatePaintNode`). Only iOS is affected: Qt's `QSGRendererInterface` supplies no `"MetalLayer"` resource there, forcing the wrapper's `m_ownsLayer` fallback, which macOS's AppKit tolerates off-thread. Not fixed; any fix must create/attach the layer on the GUI thread. Details: [macOS verification](../verification/macos.md#maplibreearth-on-the-ios-simulator--2026-10-23).

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
- ~~Are the Linux-WebGPU render diffs caused by #4534/#4190?~~ **Answered 2026-10-23**: no — the #4533 control (which touches no WebGPU code) fails the same 14 tests; the only extras are flaky `feature-state`/`global-state` cases that flip between runs.

## Related

- [Contribution plan](upstream-contribution-plan.md) · [Upstream PRs](../references/upstream-prs.md) · [Upstream issues](../references/upstream-issues.md) · [D6](../decisions/d6-draft-upstream-prs.md)
- [Linux tests](../verification/linux-tests.md) · [macOS tests](../verification/macos.md) · [Windows](../verification/windows.md) · [Android](../verification/android.md)
