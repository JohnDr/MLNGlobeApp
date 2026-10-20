---
type: Runbook
title: Upstream contribution progress
description: "Live tracker for offering the fork's terrain/globe/sky work upstream: branch status, per-platform test results, and pickup steps across Windows, Android and Linux."
tags:
  - runbook
  - upstream
  - status
  - testing
status: current
---
# Upstream contribution progress

> Live tracker, updated 2026-10-20. Strategy: join the existing upstream feature branches, report test results, and contribute focused gaps (Qt/QMapLibre wrapper first). **Do not** submit the 56-patch fork stack or a competing globe/terrain/sky implementation.

## Strategy (agreed 2026-10-20)

1. **Join the existing branches** — test them on Windows/Android/Linux and report; they explicitly need testers.
2. **Focused PRs** against `feature/terrain-3d` / the globe branch for gaps. The unique, working stack is the **Qt/QMapLibre wrapper + app API** (63 commits in `maplibre-native-qt`), which the core PRs need.
3. **Only if the implementation is materially different/better**: write a comparison/design proposal for the TSC first; no competing PRs.

## Upstream landscape

| Effort | Owner | Branch / base | State | Notes |
|---|---|---|---|---|
| Globe #4533 | johncarmack1984 | `phased/12h` → `main` | open, not draft, `BLOCKED`, CI green (2026-10-20) | Issue #3161; design proposal #4525 closed; 673 files. |
| Sky #4534 | ClayWarren | `codex/sky-style-spec-4414`, stacked on globe | open, not draft, `DIRTY` | Issue #4414; CI fails Android OpenGL instrumentation/render, iOS, macOS WebGPU; Metal/Vulkan render pass. |
| Terrain #4190 | NathanMOlson | `feature/terrain-3d` → `main` | **draft**, `DIRTY` | Maintainer `louwers` coordinating; follow-ups #4558, #4790, #4791, #4801, #4809, #4810 target `feature/terrain-3d`; issue #252. |
| Overlap #4752 | JohnDr | `mln-icon-text-overlap` → `main` | **draft**, `BLOCKED`, pre-commit green | Our icon/text-overlap implementation; build workflows await approval; refs #251. |
| Qt #323–#326 | JohnDr | fork branches → `maplibre-native-qt` `main` | #323 draft; #324/#325/#326 ready | #323 Metal fix at `91297dd`, CI approval pending; #326 has empty-style fallback + `styleChanged` NOTIFY at `5d1077a`. |

## Gap analysis (summary)

- Fork work: 56 core patches on 13.6.1, 258 files, all authored by JohnD (audit on 2026-10-20).
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

### Linux

Pending (planned 2026-10-21). The existing [Linux tests](../verification/linux-tests.md) cover the fork on 13.6.1, not these PR branches.

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

### Linux (next)

1. Build `pr4533`, `pr4534`, `pr4190` from a normal clone (submodules initialised; no junctions).
2. Run `mbgl-test-runner` and the render suite per group; compare `fill-seams/checkerboard` and `raster-warped` with Windows.
3. Run its Qt tests if the wrapper is under test.

## Next actions (ordered)

1. **Linux**: build/test #4533/#4534/#4190; run `fill-seams` and `raster-warped` to establish whether the seams are Windows-only. Save diffs.
2. **Post one consolidated test report** after Linux: #4533 (seams + platform), #4534 (Windows Vulkan render pass, CI failures), #4190 (Windows terrain tests pass; CI Windows job failures are platform tests).
3. **Qt wrapper**: adapt the 63-commit QMapLibre API to the upstream core, split into focused `maplibre-native-qt` PRs, coordinate with maintainers.
4. **Unique core pieces**: verify the terrain-camera ray scan against #4190's `TerrainCamera`/#4711; then RTT pool/pole caps if still gaps. Target `feature/terrain-3d`.
5. **Existing PRs**: #4752 review/CI, #323 CI approval, #326.
6. **Design proposal only** if `TerrainPass`/`terrain_stitch` is materially better than `RenderTerrain`; write a comparison for the TSC first.

## Guardrails

- No competing full implementation; no 56-patch dump.
- Keep MapLibreEarth on 13.6.1 until upstream features land.
- GL JS is the reference; disclose AI use; each PR needs tests and a platform statement.

## Open questions

- Are the two Windows/Vulkan seam failures platform-specific or a stale globe snapshot?
- Does #4190 already cover the terrain-camera ray scan (it has `TerrainCamera` tests and #4711)?
- Which Qt API shape should the upstream core expose?
- Which Linux build/deps path is fastest for the PR branches?

## Related

- [Contribution plan](upstream-contribution-plan.md) · [Upstream PRs](../references/upstream-prs.md) · [Upstream issues](../references/upstream-issues.md) · [D6](../decisions/d6-draft-upstream-prs.md)
- [Linux tests](../verification/linux-tests.md) · [Windows](../verification/windows.md) · [Android](../verification/android.md)
