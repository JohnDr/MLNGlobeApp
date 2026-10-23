---
type: History
title: Project history
description: Dated milestones for MapLibreEarth and the MapLibre Native / Native Qt work behind it.
tags: [ history, project ]
status: draft
---
## Summary

Dated milestones for MapLibreEarth and the MapLibre work behind it. The detailed build handover is preserved in the [JDReadme reference](./references/handover-jdreadme.md); the reasoning is in [Decisions](./decisions/index.md).

## Milestones

**2026-10-07** — MapLibre Native Qt built for Windows (Vulkan) and the `quick-standalone` example built for Android arm64-v8a / x86_64. The example gained its feature set: style picker, camera presets, settings/scale, dark mode, 2D/3D toggle, 3D-buildings toggle, gestures ([handover §6–7](./references/handover-jdreadme.md)).

**2026-10-10**
- Vendored MapLibre Native upgraded `android-v13.4.0` → `android-v13.6.1`; the public API `mbgl` → `mln` rename was ported across `src/` (commit `6db61e9`). See [D2](./decisions/d2-upgrade-13-6-1.md).
- A downstream [style-spec patch](./references/fork-patches.md) added so the Open Waters style renders its buoys / marks / lights (0 style-parse warnings; was 16 *doesn't support property* + 2 *data expressions*).
- Right-drag smooth zoom fixed on Windows (commit `1177540`). See [D4](./decisions/d4-right-drag-zoom.md).
- Qt's WebP imageformats plugin installed for Windows and Android (Open Waters elevation tiles are WebP).

**2026-10-11**
- The `quick-standalone` example was split out into its own project, **MapLibreEarth** (`C:\hda\dev\Projects\MapLibreEarth`, private repo `JohnDr/MapLibreEarth`). See [D1](./decisions/d1-standalone-app.md).
- Five upstream PRs opened and then marked **Draft**: MapLibre Native Qt #323–#326, MapLibre Native #4752. See [references/upstream-prs.md](./references/upstream-prs.md) and [D6](./decisions/d6-draft-upstream-prs.md).
- A **Debug** `QMapLibre` was built and the Debug/Release QML-plugin mismatch fixed; a second downstream [patch](./references/fork-patches.md) relaxed a MapLibre Native Debug assert on data-driven `line-dasharray`. See [D5](./decisions/d5-debug-release-libraries.md) and [D3](./decisions/d3-downstream-patches.md).
- MapLibreEarth built, signed and deployed to a Galaxy S23 (`RFCW910087W`). See the [Android runbook](./runbooks/deploy-android.md).
- Globe projection ported from `maplibre-native` PR #4533, carried as seven downstream [patches](./references/fork-patches.md): the **API seam** + **phase 1** (`955e04af`), **phase 2** (`642c2973`), **phase 3** (`69376bbd`), **phase 4 fast-pathed to Vulkan**, **phase 5 subdivision** (`aef0619`), **phase 7 tile cover** (`4e83526f`), **phase 6 globe transform/gestures** (`2f7bcd9e`) and the **globe→Mercator hand-off** — the sphere is **curved**, loads only the visible hemisphere, and **morphs back to flat** past zoom ~11 (which also fixed a zoom-to-single-colour bug found by hand); then **lines on the globe** (the Vulkan line shaders) fixed the road-casing smear that looked like a single-colour fill, **rasters/hillshade/color-relief on the globe** (Vulkan) made the `natural_earth` shaded relief wrap onto the sphere, **circles/heatmaps (9b) + fill-extrusions (9d)** followed — the latter with a globe depth prepass so 3D buildings occlude correctly — and finally **symbols/labels (phase 8)** completed the set: **every layer family is now globe-aware on Vulkan**. See [Globe projection](./concepts/globe-projection.md).

## Related

- [Next steps](./next-steps.md) · [Wiki log](./log.md) · [Decisions](./decisions/index.md) · [Handover](./references/handover-jdreadme.md)

## 2026-10-16/17 — terrain z>=15 fixed, steep-pitch hang fixed

Started from the "z15 terrain draw renders nothing" wiki theory; tint-only shader test showed the terrain drew fine and the drape was empty. Found and fixed (patch 0040): elevation scaled by pixels-per-metre twice; covers ignoring terrain height; frustum z units and elevation-blind `intersects`; pan unprojection plane in the wrong unit (high-pitch pan "crazy"); an unbounded terrain tile set (16,679 tiles at pitch 71) that exhausted GPU memory and crashed the PC; far-terrain flattening (17x17 mesh); Debug `BackendScope` assertions (Qt wrapper); `-Wmissing-field-initializers`. Added vendored core/render/benchmark tests in a dedicated build tree, the scripted screenshot-sweep method and `memguard.sh`. See [log](./log.md).


## 2026-10-17/18 — sky, GL JS alignment, drape and terrain fidelity

Added the sky (expressions, transitions, globe atmosphere, QML API), a GL JS reference harness and the Mapterhorn "3D Terrain" example style, then closed the visible differences against GL JS in order: terrain LOD centre bug (tiles one level too deep), TileJSON DEM sources, hillshade not draping (only the raster tweaker kept per-drape-target UBOs), baked mesh shade removal, GL JS DEM zoom/RTT size, RTT pool and fingerprint (re-render storm), mipmaps, fog far plane, LOD edge stitching, GL JS projection planes and skirts, `roundZoom` for raster tiles, half-DEM-pixel sampling. Decisions: keep the 192-tile cap, accept the ~5-15 % hillshade sharpness gap. See [log](./log.md) and the [alignment audit](./references/gljs-alignment.md).

## 2026-10-18 — globe + terrain fixed (patches 0050, 0051)

Reproduced the globe problems with scripted sweeps on both terrain styles and compared with GL JS (`globe=1` in the harness). Root cause: terrain drape targets were rendered with the globe projection; they are now flat Mercator (GL JS `applyGlobeMatrix: false`), use the wrap-0 tile matrix (antimeridian) and polar tiles are capped (GL JS `_buildSkirts` pole rows). The `main.qml` auto-switch of the globe off for terrain styles was removed. Open: sky colour above the horizon at z11 pitch 70 on the globe. Details: [log 2026-10-18 part 10](./log.md).

**2026-10-18** — Pointer gestures aligned with MapLibre GL JS: left-drag pan with inertia and terrain anchoring, GL JS scroll zoom (calibrated to John's browser), right/ctrl-drag rotate+pitch, double-click zoom, middle-drag kept as smooth zoom. Found and fixed a y-flip bug in the first terrain unprojection with an automated render check (patch 0053). See [gesture page](./references/gesture-gljs-alignment.md).

## 2026-10-22/23 — macOS Metal, iOS, and the upstream WebGPU PRs

**Metal on macOS reached parity with Linux.** The app and the vendored core now build and run on this Mac (Metal), which exposed a real core bug: the Metal symbol shaders never received the per-tile projection, so symbols rendered blank — **patch 0057** ports `ProjectionUBO` to them (**104/175 render groups before, 175/175 after**). **Patch 0058** is test-only (one `TerrainCamera` test pixel moved off a sea-level crossing). Core render tests **175/175 groups**, server suites **60/60**; the earlier `Map.*` hang was traced to an upstream Metal deadlock, not the fork.

**iOS became buildable and partly runnable.** Xcode's components had never been installed (`xcodebuild -runFirstLaunch` → 69), so `CoreSimulator.framework` was missing and every iOS CMake preset failed in compiler detection; after repair, `ios-metal`/`ios-webgpu-dawn` configure and build, QMapLibre builds for the iOS simulator and device, and MapLibreEarth builds and launches on a simulator (static `MapLibre.app`, Metal shaders compiling, QML module resolving). Device builds are produced but **unsigned**; a device run is blocked by signing, a USB link macOS never enumerated, and an **iOS 18 runtime floor** (Qt 6.12's iOS libraries are `minos 18.0`). Details: [macOS verification](./verification/macos.md), [build-macos](./runbooks/build-macos.md).

**The three upstream PR branches were reproduced and fixed here** (#4533/#4534/#4190): five WGSL/generated-header bugs plus the Dawn `TINT_BUILD_TESTS` configure failure that makes `main`'s `ios-build-webgpu-dawn` red, and #4534's iOS `<Mapbox.h>` test import — reproduced verbatim, fixed, and `//platform/ios/test:ios_test` then **302 tests / 0 failures**. The whole fix set is portable: [local fix set](./references/local-fixes.md). Tracker: [upstream contribution progress](./runbooks/upstream-contribution-progress.md).

**Linux re-verified after 0057/0058 (2026-10-23).** The Metal-only symbol patch and the test-only patch were applied to the vendored core on the Linux PC, both configs and installs rebuilt, and every suite re-run: Vulkan **1110/1110**, OpenGL **1145/1145**, expression **332/0**, Qt `ctest` pass in Release and Debug, render failure lists identical to pristine (Vulkan 4, OpenGL 5). No regression from the Mac-side work. The **Debug app** was rebuilt against the Debug install and ran for 60 s with no QML or GL errors (`gljs-3d-terrain-example` loads), closing the "Debug not rebuilt since the sky/drape work" item. **Linux WebGPU (same day):** all three upstream PR branches (#4533/#4534/#4190) were built and tested on Linux against both **Dawn** and **wgpu** with the local fix set — unit suites fully green (1258/1258, 1260/1260, 1160/1160); the #4533 control reproduced the same 14 residual render diffs, proving they are baseline Linux-WebGPU behaviour rather than PR regressions. Also found that the Linux WebGPU metric profiles reference an ignore file that is missing from upstream `main`.

**2026-10-23 — consolidated upstream report posted.** The reviewed drafts were posted as one text-only comment per PR: [#4533](https://github.com/maplibre/maplibre-native/pull/4533#issuecomment-6376827154), [#4534](https://github.com/maplibre/maplibre-native/pull/4534#issuecomment-6376827512), [#4190](https://github.com/maplibre/maplibre-native/pull/4190#issuecomment-6376827810). Bodies remain in [upstream report drafts](./references/upstream-report-drafts.md). Next: Qt wrapper PRs (#323–#326) and the terrain-camera question.
