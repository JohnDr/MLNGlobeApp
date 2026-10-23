---
type: Reference
title: Consolidated upstream test report — drafts
description: "One comment per upstream PR (#4533, #4534, #4190), text-only, drafted for John's review before posting."
tags:
  - reference
  - upstream
  - report
  - draft
status: draft
---
# Consolidated upstream test report — drafts

> **Status: posted 2026-10-23.** One text-only comment per PR: [#4533](https://github.com/maplibre/maplibre-native/pull/4533#issuecomment-6376827154), [#4534](https://github.com/maplibre/maplibre-native/pull/4534#issuecomment-6376827512), [#4190](https://github.com/maplibre/maplibre-native/pull/4190#issuecomment-6376827810). The bodies are kept for the record.
>
> Each `POST` block below is the exact comment body. Evidence notes outside the markers are for us and are not posted.
>
> AI assistance: each comment ends with an AI-assistance disclosure; all results were verified by me.

## Shared methodology (not posted verbatim)

- Independent testing, no code changes pushed. Tester: JohnDr.
- Branches tested at the heads listed in each comment; dates are 2026-10-23.
- Builds: CMake/Ninja; unit suites via `mbgl-test-runner` (one suite per process where needed); render tests via `mbgl-render-test-runner`, one group per process, platform metrics profile; pixelmatch threshold `0.1285`, `allowed = 0.00015`; server suites with the Windows `USE_CPP_TEST_SERVER` build.
- Platforms: Windows 11 `26300` / Intel Iris Xe `32.0.101.7088` / Vulkan; Linux Ubuntu 26.04 / AMD Radeon 780M RADV, Mesa 26.0.8, Vulkan 1.4.335, plus lavapipe; Android S23 Vulkan artifact; macOS from PR CI logs plus local reproduction where noted.
- Keep comments self-contained: no local paths, no personal-wiki links, no images.

---

<!-- BEGIN POST #4533 -->
## Independent test report — #4533 (globe)

Tested at `ff96700` (2026-10-23) on Windows 11 / Intel Iris Xe / Vulkan, Linux Ubuntu 26.04 / AMD Radeon 780M RADV (plus lavapipe), Android S23 (Vulkan CI artifact), and macOS Metal/WebGPU from the PR CI logs.

Method: built the branch, ran `mbgl-test-runner` per suite and `mbgl-render-test-runner` one group per process with the platform metrics; pixelmatch threshold 0.1285, `allowed` 0.00015. No code changes pushed.

| Platform | Unit | Globe render | Notes |
|---|---|---|---|
| Linux/Vulkan (RADV) | 1243/1243, 145 suites | 72 tests: 66 pass, 3 ignored, 2 passed-but-ignored, 1 fail (`fill-seams/checkerboard`) | Full 184-group suite: only `checkerboard` and the pre-existing `fill-extrusion-pattern/tile-buffer` baseline failure. |
| Linux/Vulkan (lavapipe) | — | `checkerboard` passes (9 px vs 9.83 allowed) | CI's software Vulkan. |
| Linux/WebGPU (Dawn + wgpu) | 1258/1258 each | `checkerboard` passes | macOS/WebGPU expectations hold; residual failures are baseline Linux-WebGPU, identical on the control. |
| macOS/Metal | — | 71 pass + 1 ignored; `checkerboard` passes | From CI; the Metal expectation is the reference. |
| macOS/WebGPU | — | Passes | From CI. |
| Windows/Vulkan (Iris Xe) | — | 53 groups: same 2 failures (`checkerboard`, `raster-warped`); 5 ignored groups | Full sweep through #4534 `38dac5b8` (current globe + main merge); #4533 itself is `ff96700`. |
| Android | — | `GlobeActivity` renders correctly | Vulkan artifact. |

### `projection/globe/fill-seams/checkerboard`

One-pixel threshold miss, not a visible seam:
- RADV Vulkan: 10 mismatched px of 65536 vs 9.83 allowed; lavapipe: 9 px and passes; Linux WebGPU and macOS Metal pass.
- Windows: independent mapbox pixelmatch gives 8–9 px; the runner's C++ pixelmatch crosses the threshold.
- All counted pixels sit on the globe-wrap border; the other ~4180 differing pixels are anti-aliasing only.

Would you welcome a PR to update this expectation (or the tolerance) rather than change the renderer? I can prepare one if you want it.

### `projection/globe/raster-warped`

Windows-only: 284 mismatched px of 262144 vs 39.32 allowed (7.2×), horizontal edge lines; it passes on Linux/RADV. This looks like an Intel-Xe/Vulkan rasterization/AA difference, not a globe seam. Is this known? I can investigate further if useful.

No code changes pushed.

AI assistance: this report was prepared with AI assistance; every result was verified by me.
<!-- END POST #4533 -->

> Evidence (not posted): tracker `wiki/runbooks/upstream-contribution-progress.md`; Windows diffs in `%LOCALAPPDATA%\Temp\opencode\consolidated-report\windows`; Linux logs in `~/dev/tmp/upstream-report-evidence/`; full Windows sweep CSV in `%LOCALAPPDATA%\Temp\opencode\globe-sweep\results.csv`.

---

<!-- BEGIN POST #4534 -->
## Independent test report — #4534 (sky)

Tested at `38dac5b8` (2026-10-23) on Windows 11 / Intel Iris Xe / Vulkan, Linux Ubuntu 26.04 / RADV Vulkan, macOS WebGPU (CI logs plus local reproduction), and Android (CI artifact).

Method: built the branch, ran `mbgl-test-runner` per suite and `mbgl-render-test-runner` one group per process with the platform metrics; pixelmatch threshold 0.1285 / `allowed` 0.00015. No code changes pushed.

| Platform | Result |
|---|---|
| Windows/Vulkan | `sky/basic`, `sky/atmosphere-globe`, `sky/zoom-expression`: **3/3 pass**. |
| Linux/Vulkan | unit **1245/1245**; `sky/` **3/3 pass**; full 184 groups: 1337 pass / 2 fail / 62 ignored — only the globe `checkerboard` and the pre-existing `fill-extrusion-pattern/tile-buffer`. |
| macOS/WebGPU (wgpu) | CI abort: WGSL `name 'target' is a reserved keyword` (`atmosphere.vertex.glsl` emits `vec4 target`). After fixing that, a second WGSL error (duplicate `PI`); with both fixed locally, unit and render suites pass. |
| macOS/WebGPU (Dawn) | After the fixes, `sky/atmosphere-globe` passes locally on the same worktrees; totals equal wgpu. |
| iOS | `ios-build` fails because the new `MLNSkyTest.mm.ejs` imports `<Mapbox.h>`; I have a local one-line fix. |
| Android | CI OpenGL instrumentation/render tests fail; the APK has no Sky activity, so this is not visually verified. |

The build workflows have not run on this head yet (awaiting approval). The branch is also stacked on an older globe (five commits behind #4533).

I can open a small PR against this branch for the two WGSL fixes and the iOS test include, or attach a patch — whichever you prefer. No changes have been pushed.

AI assistance: this report was prepared with AI assistance; every result was verified by me.
<!-- END POST #4534 -->

> Evidence (not posted): WGSL/iOS patch `wiki/references/patches/pr4534-wgsl-and-ios-test.patch`; macOS results in the tracker; Windows/Linux logs as above.

---

<!-- BEGIN POST #4190 -->
## Independent test report — #4190 (Terrain 3D)

Tested at `c6b31b7` (2026-10-23) on Windows 11 / Intel Iris Xe / Vulkan, Linux Ubuntu 26.04 / RADV Vulkan, macOS WebGPU (CI logs plus local reproduction), and Android (CI artifact).

Method: built the branch, ran `mbgl-test-runner` per suite, render tests one group per process, and the Windows server suites with `USE_CPP_TEST_SERVER`; pixelmatch 0.1285 / `allowed` 0.00015. No code changes pushed.

| Platform | Result |
|---|---|
| Windows/Vulkan | `*Terrain*` **30/30 pass**; terrain render tests are ignored upstream. Server suites **58/60** — `ConnectionError` and `NetworkStatusChangePreempt` fail with `Reason::Temporary` instead of `Connection` and then hang (`LocalFileSource.InvalidUTF8Path` also stops the full suite). These are Windows platform/libcurl issues, not this PR. |
| Linux/Vulkan | unit **1145/1145** (30 `*Terrain*` included); full 184 groups: only the pre-existing `fill-extrusion-pattern/tile-buffer`. |
| macOS/WebGPU (wgpu) | CI abort: duplicate `GlobalPaintParamsUBO` in the generated WGSL. Locally also found stray `drape_tile` fields bloating the WebGPU line drawable/props structs (17 of 18 image diffs) and missing texture-upload stats in `src/mln/webgpu/texture2d.cpp`. With the three fixes: unit **1157/0**, render **1368/0**. |
| macOS/WebGPU (Dawn) | The 14 unit diffs pass locally after the fixes; totals equal wgpu. |
| iOS Dawn | CI failure is pre-existing on `main` (`TINT_BUILD_TESTS` pulls googletest); not this PR. |
| Android | `TerrainActivity` renders pitched 3D terrain with draped imagery; Android WebGPU CI still fails. |

Windows CI test failures are the platform tests above. I can open a small PR against `feature/terrain-3d` for the three WebGPU fixes, or attach a patch — whichever you prefer. No changes have been pushed.

AI assistance: this report was prepared with AI assistance; every result was verified by me.
<!-- END POST #4190 -->

> Evidence (not posted): WebGPU patch `wiki/references/patches/pr4190-webgpu-dawn-ios.patch`; macOS results in the tracker; Windows server-suite logs in `%LOCALAPPDATA%\Temp\opencode\online-tests`.

---

## Posting checklist (after John's go)

1. Re-check heads/CI: #4533 `ff96700`, #4534 `38dac5b8`, #4190 `c6b31b7` (update if moved).
2. Re-read each block between the markers and confirm no local paths or personal-wiki links.
3. Confirm the local macOS/WebGPU/iOS fixes are clean enough to offer; if not, change the offer to "I can prepare".
4. Extract each block to a temp Markdown file.
5. Post one comment per PR: `gh pr comment <n> --repo maplibre/maplibre-native --body-file <file>`.
6. Record the three comment URLs here and in the tracker.

## Review status

- [x] John reviewed
- [x] Explicit post go received
- [x] #4533 posted — https://github.com/maplibre/maplibre-native/pull/4533#issuecomment-6376827154
- [x] #4534 posted — https://github.com/maplibre/maplibre-native/pull/4534#issuecomment-6376827512
- [x] #4190 posted — https://github.com/maplibre/maplibre-native/pull/4190#issuecomment-6376827810
