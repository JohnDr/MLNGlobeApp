---
type: Reference
title: Local fix set (uncommitted PR experiments)
description: The seven-file patch set that makes #4534's and #4190's WebGPU builds and tests pass locally — the portable copy, so the work can be picked up on any machine.
tags: [ wiki, reference, upstream ]
status: draft
---
# Local fix set (uncommitted PR experiments)

Six defects across **seven files**, found and fixed on the Mac (2026-10-22/23) in **uncommitted** working
trees. Nothing is pushed: the PR heads are untouched, so CI cannot show any of this until an author commits it
(and `#4534`'s runs are still `action_required`). These patches are the portable copy of that state — the
canonical record, because the only other copy (`~/dev/tmp/webgpu-pr-fixes/*.patch` on the Mac) is stale and
machine-local.

## Applying them

From any checkout that has the PR branch at the recorded head:

```bash
git switch pr4534   # 38dac5b8a4ec
git apply wiki/references/patches/pr4534-wgsl-and-ios-test.patch

git switch pr4190   # c6b31b76056a
git apply wiki/references/patches/pr4190-webgpu-dawn-ios.patch
```

`git apply --check --reverse <patch>` in the Mac worktrees confirms each patch matches that working tree
byte-for-byte. `#4533` (`ff96700517b9`) needs **no** patch — it passes on every backend tried.

| Patch | Files | Fixes |
|---|---|---|
| `pr4534-wgsl-and-ios-test.patch` | `include/mln/shaders/webgpu/sky.hpp`, `platform/darwin/test/MLNSkyTest.mm.ejs` | WGSL: `target` is a reserved word → renamed, and a duplicate `const PI` removed; iOS: `<Mapbox.h>` → `<MapLibre.h>` |
| `pr4190-webgpu-dawn-ios.patch` | `include/mln/shaders/webgpu/circle.hpp`, `include/mln/shaders/webgpu/line.hpp`, `src/mln/webgpu/texture2d.cpp`, `platform/ios/src/MLNMapView+WebGPU.mm`, `vendor/dawn.cmake` | duplicate `GlobalPaintParamsUBO`; stray `drape_tile` fields shifting every line drawable; missing texture-upload stats; missing `mln/gfx/context.hpp` include; Dawn's `TINT_BUILD_TESTS` defaulting ON |

## What each one is

1. **`sky.hpp` (#4534, WGSL)** — the sky vertex shader named a variable `target`, which is reserved in WGSL,
   so wgpu-native aborted the module; the fragment shader also redeclared `const PI`, already provided by the
   shared prelude. This was the macOS WebGPU abort in both backends.
2. **`circle.hpp` (#4190, WGSL)** — the per-shader prelude carried a pre-terrain 48-byte
   `GlobalPaintParamsUBO` while the vertex shader redeclared the 64-byte one, so the concatenated module
   redefined both the struct and its `paintParams` binding.
3. **`line.hpp` (#4190, WGSL)** — `drape_tile` had been added to the WGSL `LineDrawableUBO` (112 B vs the
   C++ 96 B) and `LineEvaluatedPropsUBO` (64 B vs 48 B). The CPU uploads a 128-byte-stride
   `LineDrawableUnionUBO`, so every line drawable was read at the wrong offset (tile-border lines became giant
   red quads, annotation lines collapsed, pitched circles misplaced) — 17 of the 18 image diffs.
4. **`texture2d.cpp` (#4190, WebGPU)** — the backend never bumped
   `RenderingStats::numTextureUpdates`/`textureUpdateBytes` (GL, Vulkan and Metal all do), tripping
   `ColorRelief.UploadsDEMTextureOncePerTile`'s "this test proves nothing" guard.
5. **`vendor/dawn.cmake` (`main`, not just these PRs)** — `vendor/dawn.cmake` forces `DAWN_BUILD_TESTS OFF`
   but leaves Dawn's `TINT_BUILD_TESTS` at its default **ON** (`vendor/dawn/CMakeLists.txt:249`; only
   Emscripten turns it off), so `vendor/dawn/third_party/CMakeLists.txt:91` pulls in googletest anyway and the
   configure dies when it is absent. This is what makes `main`'s `ios-build-webgpu-dawn` red, and it affects
   **every WebGPU-Dawn job, Linux and Windows included**. One line:
   `set(TINT_BUILD_TESTS OFF CACHE BOOL "Disable Tint tests" FORCE)`. Raise it **separately** from the PRs.
6. **`MLNMapView+WebGPU.mm` (`main`, iOS WebGPU)** — the file calls `context.reset()` on a
   `std::unique_ptr<mln::gfx::Context>` without including `mln/gfx/context.hpp`, so the iOS WebGPU SDK had never
   compiled. The Dawn configure failure above is the only reason CI has not seen it.
7. **`MLNSkyTest.mm.ejs` (#4534, iOS tests)** — the generated test imports the old umbrella header
   `<Mapbox.h>`; it must be `<MapLibre.h>` like its siblings. With it, `//platform/ios/test:ios_test` builds and
   passes (302 tests, 5 skipped, 0 failures) instead of failing to build.

## Evidence

- macOS WebGPU (bugs 1–4, both backends):
  [macOS verification → WebGPU PR branches](../verification/macos.md#webgpu-pr-branches-2026-10-22)
- Dawn `TINT_BUILD_TESTS` (bug 5, verified 2026-10-23):
  [macOS verification → Dawn's TINT_BUILD_TESTS](../verification/macos.md#dawns-tint_build_tests--mains-red-ios-dawn-job-2026-10-23)
- iOS `Mapbox.h` (bug 7, reproduced and fixed 2026-10-23):
  [macOS verification → #4534's iOS test build](../verification/macos.md#4534s-ios-test-build-mapboxh--reproduced-and-fixed-2026-10-23)
- iOS WebGPU include (bug 6): [macOS verification → what the iOS build revealed](../verification/macos.md#what-the-ios-build-revealed-2026-10-23)
- **Linux WebGPU (bugs 1-4, both backends, 2026-10-23):** the same fix set was applied to the PR worktrees on
  the Linux PC. Unit suites **1260/1260** (#4534) and **1160/1160** (#4190) pass on **Dawn and wgpu** (wgpu in
  per-suite processes because of a wgpu-native/RADV leak). Bug 5 is reproduced there too: without the one-liner
  the configure log says `-- Tint build tests: ON`; with it, `OFF`. Render results and the residual
  Linux-WebGPU image diffs: [progress → Linux WebGPU](../runbooks/upstream-contribution-progress.md#linux-webgpu-dawn--wgpu--2026-10-23).

## Keeping this current

After changing a fix in a worktree, regenerate and re-verify:

```bash
git -C ~/dev/tmp/mln-pr4534 diff > wiki/references/patches/pr4534-wgsl-and-ios-test.patch
git -C ~/dev/tmp/mln-pr4190 diff > wiki/references/patches/pr4190-webgpu-dawn-ios.patch
git -C ~/dev/tmp/mln-pr4190 apply --check --reverse "$PWD/wiki/references/patches/pr4190-webgpu-dawn-ios.patch"
```

Untracked files (`test/fixtures/offline_database/offline.db-shm`) are deliberately excluded: they are test
run leftovers, not fixes.
